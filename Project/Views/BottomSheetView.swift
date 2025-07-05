//
//  BottomSheetView.swift
//  Project
//
//  Created by 高見聡 on 2025/06/28.
//
import SwiftUI

struct BottomSheetView<Content: View>: View {
    @Binding var offset: CGFloat
    let content: () -> Content
    
    var body: some View {
        GeometryReader { geometry in
            let screenHeight = geometry.size.height
            let minY = screenHeight * 0.9  // ← 少しだけ見せる（10%見せる）
            let midY2 = screenHeight * 0.65   // ← 中間表示（35%見せる）
            let midY1 = screenHeight * 0.3   // ← 中間表示（70%見せる）
            let maxY = screenHeight * 0.05   // ← しっかり表示（95%見せる）
            
            VStack {
                content()
                    .frame(height: screenHeight - maxY)//大きさのマックスを端末高さの0.95にしてる。Listがそれ以上ならスクロールがつく
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                    .shadow(radius: 10)
                    .offset(y: offset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in //ドラッグ操作が始まり指が動いている
                                let newoffset = offset + value.translation.height
                                offset = min(max(newoffset, maxY), minY)
                            }
                            .onEnded { value in //ドラッグ操作が終わり指が離れている
                                withAnimation {
                                    let newoffset = offset + value.translation.height
                                    let nearest: CGFloat
                                    if newoffset < (maxY + midY1) / 2 {
                                        nearest = maxY
                                    } else if newoffset < (midY1 + midY2) / 2 {
                                        nearest = midY1
                                    } else if newoffset < (midY2 + minY) / 2 {
                                        nearest = midY2
                                    } else {
                                        nearest = minY
                                    }
                                    offset = nearest
                                }
                            }
                    )
            }
            .onAppear {
                // 最初は最小状態に表示させておく（常に少し見える）
                if offset == 0 {
                    //offset = screenHeight //本番ではこっち
                    offset = minY
                }
            }
        }
        .ignoresSafeArea()
    }
}


