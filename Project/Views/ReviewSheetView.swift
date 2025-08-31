//
//  ReviewSheetView.swift
//  Project
//
//  Created by 高見聡 on 2025/08/16.
//

import SwiftUI

// MARK: - スモールスタート方針
// ・Form + Section でシンプルな入力画面
// ・点数は整数(0-5)と小数(0-9)を Picker で分けて選択
// ・味/コスパ/接客/雰囲気は SegmentedPicker
// ・コメントは TextEditor
// ・保存(送信)とキャンセルボタンのみ
// ・onAppearで既存口コミを取得して初期値に反映
// ・API は URLSession + async/await。トークンは UserDefaults("token") を使用
// ・親側リフレッシュ用に onSubmitted コールバックを用意

// MARK: - View
public struct ReviewSheetView: View {
    let placeName: String
    var onSubmitted: (() -> Void)? = nil // 送信成功時に親へ通知
    @Environment(\.dismiss) private var dismiss

    @StateObject private var vm = ReviewViewModel()
    @FocusState private var commentFocused: Bool
    
    @State private var showDetail = false
    @State private var tempScore: Double = 0.0

    public init(placeName: String, onSubmitted: (() -> Void)? = nil) {
        self.placeName = placeName
        self.onSubmitted = onSubmitted
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section("点数") {
                    VStack(alignment: .leading, spacing: 10) {
                        // 0.5刻みで素早く選べる
                        Slider(value: $vm.score, in: 0...5, step: 0.5)

                        HStack {
                            // 現在値表示（0.1桁）
                            Text(String(format: "総評 %.1f", vm.score))
                                .font(.footnote)
                                .foregroundStyle(.secondary)

                            Spacer()

                            Menu {
                                // 現在の0.5刻みを基準に「帯の下端」を決める
                                let half = vm.roundToHalf(vm.score)        // 例: 3.0, 3.5
                                let lower = floor(half)                    // ← 整数に丸めて帯開始を決定
                                let upper = min(5.0, lower + 0.9)          // 例: 3.0〜3.9
                                
                                let from = Int((lower * 10).rounded())
                                let to   = Int((upper * 10).rounded())
                                
                                Picker("0.1刻みで調整", selection: $vm.score) {
                                    ForEach(from...to, id: \.self) { k in
                                        let v = Double(k) / 10.0
                                        Text(String(format: "%.1f", v)).tag(v)
                                    }
                                }
                                .labelsHidden()
                            } label: {
                                Label(String(format: "詳細 %.1f", vm.score), systemImage: "slider.horizontal.3")
                            }
//                            Button {
//                                tempScore = vm.score
//                                showDetail = true
//                            } label: {
//                                Label(String(format: "詳細 %.1f", vm.score), systemImage: "slider.horizontal.3")
//                            }
//                            .sheet(isPresented: $showDetail) {
//                                NavigationStack {
//                                    List {
//                                        // 0.1刻みの候補を大量に並べてもOK。スクロール位置は維持される
//                                        ForEach(0...50, id: \.self) { i in
//                                            let v = Double(i)/10.0
//                                            HStack {
//                                                Text(String(format: "%.1f", v))
//                                                Spacer()
//                                                if abs(v - tempScore) < 0.0001 {
//                                                    Image(systemName: "checkmark")
//                                                }
//                                            }
//                                            .contentShape(Rectangle())
//                                            .onTapGesture { tempScore = v }
//                                        }
//                                    }
//                                    .navigationTitle("詳細調整 (0.1刻み)")
//                                    .toolbar {
//                                        ToolbarItem(placement: .cancellationAction) {
//                                            Button("キャンセル") { showDetail = false }
//                                        }
//                                        ToolbarItem(placement: .confirmationAction) {
//                                            Button("適用") {
//                                                vm.score = tempScore   // ← ここで初めて親に反映
//                                                showDetail = false
//                                            }
//                                        }
//                                    }
//                                    .presentationDetents([.medium, .large]) // 好みで
//                                }
//                            }
                        }
                    }
                }

                Section("味") {
                    Picker("味", selection: $vm.tasteIndex) {
                        ForEach(0..<vm.levelOptions.count, id: \.self) { i in
                            Text(vm.levelOptions[i]).tag(i)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("コスパ") {
                    Picker("コスパ", selection: $vm.costPerfIndex) {
                        ForEach(0..<vm.levelOptions.count, id: \.self) { i in
                            Text(vm.levelOptions[i]).tag(i)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("接客") {
                    Picker("接客", selection: $vm.serviceIndex) {
                        ForEach(0..<vm.levelOptions.count, id: \.self) { i in
                            Text(vm.levelOptions[i]).tag(i)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("雰囲気") {
                    Picker("雰囲気", selection: $vm.atmosphereIndex) {
                        ForEach(0..<vm.levelOptions.count, id: \.self) { i in
                            Text(vm.levelOptions[i]).tag(i)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("口コミ") {
                    TextEditor(text: $vm.comment)
                        .frame(minHeight: 120)
                        .focused($commentFocused)
                }

                if let error = vm.errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("\(placeName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if vm.isLoading {
                        ProgressView()
                    } else {
                        Button("送信") { Task { await submit() } }
                    }
                }
            }
            //.task { await vm.loadExistingReview(for: placeName) }
        }
    }

    private func submit() async {
        let ok = await vm.submit(placeName: placeName)
        if ok {
            onSubmitted?()
            dismiss()
        }
    }
}
