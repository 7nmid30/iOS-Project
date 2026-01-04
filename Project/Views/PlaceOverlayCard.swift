//
//  Untitled.swift
//  Project
//
//  Created by 高見聡 on 2025/11/17.
//
import SwiftUI
// “店名だけ”の極薄カード
struct PlaceOverlayCard: View {
    let name: String
    let phoneNumber: String?
    let address: String?
    var onClose: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack(alignment: .top, spacing: 12) {
                // 左側の情報ブロック
                VStack(alignment: .leading, spacing: 8) {
                    // 店名
                    Text(name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    // 電話番号
                    HStack(alignment: .center, spacing: 6) {
                        Image(systemName: "phone.fill")
                            .font(.subheadline)
                            .opacity(0.7)
                        
                        Text(phoneNumber ?? "TEL不明")
                            .font(.subheadline)
                            .lineLimit(1)
                    }
                    
                    // 住所
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.subheadline)
                            .opacity(0.7)
                        
                        Text(address ?? "住所不明")
                            .font(.subheadline)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                }
                
                Spacer()
                
                // 右上のバツ印ボタン
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .opacity(0.9)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(.black.opacity(0.06))
            )
            .shadow(radius: 12, y: 4)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }
}
