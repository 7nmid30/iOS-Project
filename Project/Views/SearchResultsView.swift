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
    //@Binding var sheetHeight: PresentationDetent

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
                }
                .onTapGesture {
                    region.center = place.coordinate
                    shouldUpdateRegion = true
                }
            }
        }
//        .interactiveDismissDisabled(true) //シートを下方向へのスワイプで閉じさせない
//        .presentationDetents(
//            [.fraction(0.1), .fraction(0.3), .medium, .large],
//            selection: $sheetHeight
//        )
    }
}
