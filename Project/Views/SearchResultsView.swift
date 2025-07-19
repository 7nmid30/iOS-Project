//
//  SearchResultsView.swift
//  Project
//
//  Created by 高見聡 on 2025/06/22.
//
import SwiftUI
import MapKit

struct SearchResultsView: View {
    let results: [Place]
    @Binding var region: MKCoordinateRegion
    @Binding var shouldUpdateRegion: Bool
    @Binding var selectedPlace: Place?  // 選択された場所
    
    var body: some View {
        VStack {
            Text("検索結果")
                .font(.headline)
                .padding()
            
            //place構造体がIdentifiable に準拠してるためid定義不要
            //\.nameは KeyPath（キーパス） と呼ばれる Swift の構文
            //            List(results, id: \.name) { place in
            //            }
            
            List(results) { place in
                VStack(alignment: .leading) {//縦並びの左寄せ
                    Text(place.name)
                        .font(.body)
                        .foregroundColor(.primary)
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading) // 選択されたList内の領域（文字を格納している領域）全体のセル背景を青くする
                .background(
                    place.id == selectedPlace?.id ? Color.blue.opacity(0.2) : Color.clear
                )
                .cornerRadius(8)
                .contentShape(Rectangle()) // 文字だけでなくList内の領域（文字を格納している領域）をタップ可能に
                .onTapGesture {
                    region.center = place.coordinate
                    shouldUpdateRegion = true
                    selectedPlace = place
                }
            }
        }
    }
}
