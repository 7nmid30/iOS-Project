//
//  ReviewViewModel.swift
//  Project
//
//  Created by 高見聡 on 2025/08/28.
//
import SwiftUI
// MARK: - ViewModel
@MainActor
final class ReviewViewModel: ObservableObject {
    // スコア(整数/小数) の選択肢
    let onesPlaceOptions: [Int] = Array(0...5)
    let firstDecimalOptions: [Int] = Array(0...9)

    // レベル表示
    //let levelOptions = ["😢","😔","😐","🙂","😊"]
    let levelOptions = ["-","⭐️1","⭐️2","⭐️3","⭐️4","⭐️5"]

    // 入力値(公開)
    @Published var whole: Int = 0
    @Published var decimal: Int = 0
    // ViewModel 側
    @Published var score: Double = 0.0

    @Published var tasteIndex: Int = 0
    @Published var costPerfIndex: Int = 0
    @Published var serviceIndex: Int = 0
    @Published var atmosphereIndex: Int = 0

    @Published var comment: String = ""

    // 画面状態
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    func makeScore() -> Double {
        Double(whole) + Double(decimal) / 10.0
    }

    func roundToHalf(_ v: Double) -> Double {
            (v * 2).rounded() / 2.0
    }

    // 口コミ送信
    func submit(placeName: String) async -> Bool {
        isLoading = true
        defer { isLoading = false }

        guard let url = URL(string: "/userreviewrestaurant/add") else {
            errorMessage = "URL が不正です"; return false
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = UserDefaults.standard.string(forKey: "token") {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let payload = ReviewAddRequest(
            place: placeName,
            score: makeScore(),
            taste: tasteIndex,
            costPerformance: costPerfIndex,
            service: serviceIndex,
            atmosphere: atmosphereIndex,
            comment: comment
        )
        do {
            req.httpBody = try JSONEncoder().encode(payload)
        } catch {
            errorMessage = "エンコードに失敗しました"; return false
        }

        do {
            let (_, resp) = try await URLSession.shared.data(for: req)
            if let http = resp as? HTTPURLResponse, http.statusCode == 401 {
                errorMessage = "ログインしてください (401)"
                return false
            }
            guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                errorMessage = "送信に失敗しました"
                return false
            }
            return true
        } catch {
            errorMessage = "通信に失敗しました: \(error.localizedDescription)"
            return false
        }
    }
    

}
