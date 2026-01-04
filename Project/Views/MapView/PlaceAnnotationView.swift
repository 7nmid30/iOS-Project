////
////  PlaceAnnotationView.swift
////  Project
////
////  Created by 高見聡 on 2025/11/02.
////

import MapKit
import UIKit

final class PlaceAnnotationView: MKAnnotationView {
    static let reuseID = "PlaceAnnotationView"

    private let container = UIView()
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let bubbleLayer = CAShapeLayer() // 吹き出し形状レイヤー

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        backgroundColor = .clear

        // 吹き出し背景レイヤーを container に追加
        container.layer.insertSublayer(bubbleLayer, at: 0)

        // レイヤー共通設定
        bubbleLayer.fillColor = UIColor.white.cgColor
        bubbleLayer.shadowColor = UIColor.black.cgColor
        bubbleLayer.shadowOpacity = 0.2
        bubbleLayer.shadowRadius = 5
        bubbleLayer.shadowOffset = CGSize(width: 0, height: 2)

        addSubview(container)
        container.translatesAutoresizingMaskIntoConstraints = false

        // アイコン
        iconView.image = UIImage(systemName: "mappin.circle.fill")
        iconView.tintColor = .systemTeal
        iconView.contentMode = .scaleAspectFit

        // タイトル
        titleLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        titleLabel.textColor = .label

        container.addSubview(iconView)
        container.addSubview(titleLabel)
        iconView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),
            container.topAnchor.constraint(equalTo: topAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor),

            iconView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 8),
            iconView.centerYAnchor.constraint(equalTo: container.centerYAnchor, constant: -5), // 少し上げて中央寄せ
            iconView.widthAnchor.constraint(equalToConstant: 30),
            iconView.heightAnchor.constraint(equalToConstant: 30),

            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 6),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -8),
            titleLabel.centerYAnchor.constraint(equalTo: iconView.centerYAnchor)
        ])

        canShowCallout = false
        collisionMode = .rectangle
    }

    // 吹き出し形状（角丸＋下三角）を生成
    private func bubblePath(in rect: CGRect) -> UIBezierPath {
        let cornerRadius: CGFloat = 10
        let tailHeight: CGFloat = 10
        let tailWidth: CGFloat = 14

        let path = UIBezierPath()
        let bubbleRect = CGRect(x: rect.minX,
                                y: rect.minY,
                                width: rect.width,
                                height: rect.height - tailHeight)

        // 角丸の上部長方形部分
        path.move(to: CGPoint(x: bubbleRect.minX + cornerRadius, y: bubbleRect.minY))
        path.addLine(to: CGPoint(x: bubbleRect.maxX - cornerRadius, y: bubbleRect.minY))
        path.addArc(withCenter: CGPoint(x: bubbleRect.maxX - cornerRadius, y: bubbleRect.minY + cornerRadius),
                    radius: cornerRadius, startAngle: -.pi/2, endAngle: 0, clockwise: true)
        path.addLine(to: CGPoint(x: bubbleRect.maxX, y: bubbleRect.maxY - cornerRadius))
        path.addArc(withCenter: CGPoint(x: bubbleRect.maxX - cornerRadius, y: bubbleRect.maxY - cornerRadius),
                    radius: cornerRadius, startAngle: 0, endAngle: .pi/2, clockwise: true)
        // 右下 → 三角しっぽ
        let tailMidX = rect.midX
        path.addLine(to: CGPoint(x: tailMidX + tailWidth/2, y: bubbleRect.maxY))
        path.addLine(to: CGPoint(x: tailMidX, y: rect.maxY)) // しっぽ先端
        path.addLine(to: CGPoint(x: tailMidX - tailWidth/2, y: bubbleRect.maxY))
        // 左下角丸へ戻る
        path.addLine(to: CGPoint(x: bubbleRect.minX + cornerRadius, y: bubbleRect.maxY))
        path.addArc(withCenter: CGPoint(x: bubbleRect.minX + cornerRadius, y: bubbleRect.maxY - cornerRadius),
                    radius: cornerRadius, startAngle: .pi/2, endAngle: .pi, clockwise: true)
        path.addLine(to: CGPoint(x: bubbleRect.minX, y: bubbleRect.minY + cornerRadius))
        path.addArc(withCenter: CGPoint(x: bubbleRect.minX + cornerRadius, y: bubbleRect.minY + cornerRadius),
                    radius: cornerRadius, startAngle: .pi, endAngle: -.pi/2, clockwise: true)
        path.close()
        return path
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        bubbleLayer.frame = container.bounds
        bubbleLayer.path = bubblePath(in: container.bounds).cgPath
        bubbleLayer.shadowPath = bubbleLayer.path
    }

    override var intrinsicContentSize: CGSize {
        let icon: CGFloat = 30
        let padL: CGFloat = 8
        let padBetween: CGFloat = 6
        let padR: CGFloat = 8
        let tail: CGFloat = 10
        let hPad: CGFloat = 12

        let titleW = titleLabel.intrinsicContentSize.width
        let height = max(30, titleLabel.intrinsicContentSize.height) + hPad + tail
        let width  = padL + icon + padBetween + titleW + padR
        return CGSize(width: width, height: height)
    }

    override func prepareForDisplay() {
        super.prepareForDisplay()
        if let p = annotation as? PlaceAnnotation {
            titleLabel.text = p.title
        }
        invalidateIntrinsicContentSize()
        let size = intrinsicContentSize
        bounds = CGRect(origin: .zero, size: size)

        // しっぽ分だけ上に持ち上げる（＝地点を指す）
        centerOffset = CGPoint(x: 0, y: -size.height / 2 + 8)
        setNeedsLayout()
        layoutIfNeeded()
    }
}
