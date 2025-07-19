//
//  MapView.swift
//  Project
//
//  Created by 高見聡 on 2025/06/21.
//
import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    @Binding var heading: CLHeading?
    @Binding var mapRotation: Double
    @Binding var shouldUpdateRegion: Bool
    //let results: [Place] // 検索結果。検索実行した時だけ反映でいい
    @Binding var results: [Place]
    @Binding var selectedPlace: Place?
    
    let mapView = MKMapView()
    
    func makeUIView(context: Context) -> MKMapView {
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.isRotateEnabled = true
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        if shouldUpdateRegion {
            uiView.setCenter(region.center, animated: true)
            DispatchQueue.main.async {
                shouldUpdateRegion = false
            }
        }
        
        if let heading = heading {
            context.coordinator.updateUserIconRotation(with: heading, mapRotation: mapRotation)
        }
        
        // 以降ピン更新
        //既存のピンと新しい results を比較して変化があるときだけ更新
        //MKMapView上に今表示されているPlaceAnnotation型だけを抽出して一括取得
        let currentPlaceAnnotations = uiView.annotations.compactMap { $0 as? PlaceAnnotation }
        
        //そのピンたちのタイトル（店名）だけの一覧を作成
        let currentSet = Set(currentPlaceAnnotations.map { $0.title ?? "" })
        
        //新しく表示したい results の中身から、店名の一覧を作成：
        let newSet = Set(results.map { $0.name })
        
        //中身が違うかどうかチェックして、違ったら更新：
        if currentSet != newSet {
            uiView.removeAnnotations(currentPlaceAnnotations)
            
            let newAnnotations = results.map { PlaceAnnotation(place: $0) }
            uiView.addAnnotations(newAnnotations)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView
        var annotationView: MKAnnotationView?
        let userDirectionLayer = CAShapeLayer() //扇形ビーム用レイヤー
        
        init(_ parent: MapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation {
                annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "UserLocation")
                ?? MKAnnotationView(annotation: annotation, reuseIdentifier: "UserLocation")
                
                let size: CGFloat = 32
                let backgroundView = UIView(frame: CGRect(x: 0, y: 0, width: size, height: size))
                
                let circleImageView = UIImageView(image: UIImage(systemName: "circle.fill"))
                circleImageView.frame = CGRect(x: 0, y: 0, width: size, height: size)
                circleImageView.tintColor = UIColor(red: 0.4, green: 0.7, blue: 1.0, alpha: 1.0)
                backgroundView.addSubview(circleImageView)
                
                let arrowImageView = UIImageView(image: UIImage(systemName: "arrow.up"))
                arrowImageView.frame = CGRect(x: (size - 17) / 2, y: (size - 17) / 2, width: 17, height: 17)
                arrowImageView.tintColor = .white
                backgroundView.addSubview(arrowImageView)
                
                // 扇形レイヤーの描画
                userDirectionLayer.path = makeFanShapePath(center: CGPoint(x: size/2, y: size/2), radius: 60, angle: 60)
                userDirectionLayer.fillColor = UIColor.systemBlue.withAlphaComponent(0.3).cgColor
                userDirectionLayer.position = CGPoint(x: size / 2, y: size / 2)
                userDirectionLayer.bounds = CGRect(x: 0, y: 0, width: size, height: size)
                circleImageView.layer.addSublayer(userDirectionLayer) // サブレイヤーとすることでannotationView に transform をかけると、中にいる全員が一緒に回転する
                // 扇形レイヤーの描画ここまで
                
                annotationView?.addSubview(backgroundView)
                annotationView?.bounds = backgroundView.bounds
                return annotationView
            }
            
            if annotation is PlaceAnnotation {
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "PlacePin") as? MKPinAnnotationView
                if annotationView == nil {
                    annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "PlacePin")
                    annotationView?.canShowCallout = true //吹き出しを表示
                    annotationView?.pinTintColor = .systemTeal //水色のピンにカスタマイズ
                } else {
                    annotationView?.annotation = annotation
                }
                
                return annotationView
            }
            
            return nil
        }
        
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            let camera = mapView.camera
            parent.mapRotation = camera.heading
        }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            if let placeAnnotation = view.annotation as? PlaceAnnotation {
                if let matchedPlace = parent.results.first(where: { $0.name == placeAnnotation.title }) {
                    print("一致したPlace: \(matchedPlace)")
                    parent.selectedPlace = matchedPlace
                }else {
                    print("results: \(parent.results)")
                    print("一致するPlaceが見つかりません")
                }
            }
        }
        
        func updateUserIconRotation(with heading: CLHeading, mapRotation: Double) {
            let headingRotation = CGFloat(heading.trueHeading / 180.0 * .pi)
            let mapRotationRadians = CGFloat(mapRotation / 180.0 * .pi)
            let totalRotation = headingRotation - mapRotationRadians
            
            if let annotationView = self.annotationView {
                UIView.animate(withDuration: 0.1) {
                    annotationView.transform = CGAffineTransform(rotationAngle: totalRotation)
                }
            }
        }
        //扇形という図形そのものを形づくり
        func makeFanShapePath(center: CGPoint, radius: CGFloat, angle: CGFloat) -> CGPath {
            // UIKit座標では -90度 = 上方向
            let baseAngle = -90.0
            let startAngle = CGFloat((baseAngle - angle / 2) * .pi / 180)
            let endAngle = CGFloat((baseAngle + angle / 2) * .pi / 180)
            let path = UIBezierPath()
            path.move(to: center)
            path.addArc(withCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
            path.close()
            return path.cgPath
        }
    }
}
