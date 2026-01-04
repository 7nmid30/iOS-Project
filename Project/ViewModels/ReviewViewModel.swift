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
    //@Published var whole: Int = 0
    //@Published var decimal: Int = 0
    // ViewModel 側
    @Published var score: Double = 3.0
    
    @Published var tasteIndex: Int = 0
    @Published var costPerfIndex: Int = 0
    @Published var serviceIndex: Int = 0
    @Published var atmosphereIndex: Int = 0
    
    @Published var comment: String = ""
    
    // 画面状態
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    // サーバーから取得した既存レビューを入力欄へ反映する
    func apply(existing: ReviewedRestaurantDetail) {
        score = existing.totalScore
        tasteIndex = existing.taste
        costPerfIndex = existing.costPerformance
        serviceIndex = existing.service
        atmosphereIndex = existing.atmosphere
        comment = existing.comment
    }
    
    //    func makeScore() -> Double {
    //        Double(whole) + Double(decimal) / 10.0
    //    }
    
    func roundToHalf(_ v: Double) -> Double {
        (v * 2).rounded() / 2.0
    }
    
    // 口コミ内容送信
    func submitReview(place: ApplePlace) async -> Int? {
        isLoading = true
        defer { isLoading = false }
        
        guard let token = UserDefaults.standard.string(forKey: "token") else {
            print("トークンが存在しません")
            return nil
        }
        
        guard let url = URL(string: "https://moguroku.com/reviewrestaurant/add") else {
            print("URLが不正です")
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let payload = ReviewRequest(
            place: place,
            score: score,
            taste: tasteIndex,
            costPerformance: costPerfIndex,
            service: serviceIndex,
            atmosphere: atmosphereIndex,
            comment: comment
        )
        do {
            request.httpBody = try JSONEncoder().encode(payload)
            let data2 = try JSONEncoder().encode(payload)
            print(String(data: data2, encoding: .utf8)!) // 期待形になっているか確認
        } catch {
            errorMessage = "エンコードに失敗しました"; return nil
        }
        
        
        struct ErrorResponse: Decodable {
            let error: String
            let details: String?
        }
        
        struct SubmitReviewResponse: Decodable {
            let success: Bool
            let restaurantId: Int
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let http = response as? HTTPURLResponse {
                print("Status Code: \(http.statusCode)")
            }
            if let responseBody = String(data: data, encoding: .utf8) {
                print("レスポンス: \(responseBody)")
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("無効なレスポンス")
                return nil
            }
            
            if httpResponse.statusCode == 401 {
                print("認証エラー")
                return nil// 認証エラー時は何もしない
            }
            
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                // JSONをデコードしてエラーメッセージを表示
                if let decoded = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    print("サーバーエラー: \(decoded.error)")
                    if let details = decoded.details {
                        print("詳細: \(details)")
                    }
                    errorMessage = decoded.error // Viewに表示
                } else {
                    // JSONが想定外の形式だった場合
                    let text = String(data: data, encoding: .utf8) ?? "不明なエラー"
                    print("レスポンス本文: \(text)")
                    errorMessage = "不明なサーバーエラー (\(httpResponse.statusCode))"
                }
                //errorMessage = "送信に失敗しました"
                return nil
            }
            //成功
            let decoded = try JSONDecoder().decode(SubmitReviewResponse.self, from: data)
            return decoded.restaurantId
            
        } catch {
            errorMessage = "通信に失敗しました: \(error.localizedDescription)"
            return nil
        }
    }
    
    
    //口コミ内容とは別に画像だけ送る
    func uploadPhotos(place: ApplePlace, images: [UIImage]) async -> Bool {
        // multipart/form-data で images を送る
        // 画像がなければ何もしない（成功扱いでOK）
        guard !images.isEmpty else { return true }
        
        // トークン取得
        guard let token = UserDefaults.standard.string(forKey: "token") else {
            print("トークンが存在しません")
            return false
        }
        
        // PhotoRestaurant コントローラ宛の API
        // 実際のルートに合わせて変更してください
        guard let url = URL(string: "https://moguroku.com/photorestaurant/upload") else {
            print("URLが不正です")
            return false
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // マルチパートの boundary
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // ---- 全画像を1枚ずつ送信----
        for (index, image) in images.enumerated() {
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                print("画像\(index)の変換に失敗")
                continue
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            
            let boundary = "Boundary-\(UUID().uuidString)"
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            
            var body = Data()
            
            // --- Place フィールド(JSON) ---
            do {
                let placeJson = try JSONEncoder().encode(place)
                let placeJsonString = String(data: placeJson, encoding: .utf8)!
                
                body.append("--\(boundary)\r\n")
                body.append("Content-Disposition: form-data; name=\"place\"\r\n")
                body.append("Content-Type: application/json\r\n\r\n")
                body.append(placeJsonString)
                body.append("\r\n")
            } catch {
                print("place の JSON エンコードに失敗: \(error)")
            }
            
            // --- ファイルフィールド (name=\"File\" or \"file\") ---
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"File\"; filename=\"photo\(index).jpg\"\r\n")
            body.append("Content-Type: image/jpeg\r\n\r\n")
            body.append(imageData)
            body.append("\r\n")
            
            // 終端
            body.append("--\(boundary)--\r\n")
            
            request.httpBody = body
            
            // --- 通信 ---
            struct ErrorResponse: Decodable {
                let error: String
                let details: String?
            }
            
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                
                if let http = response as? HTTPURLResponse {
                    print("Photo upload[\(index)] Status Code: \(http.statusCode)")
                }
                if let text = String(data: data, encoding: .utf8) {
                    print("Photo upload[\(index)] response: \(text)")
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("無効なレスポンス")
                    return false
                }
                
                if httpResponse.statusCode == 401 {
                    print("認証エラー（写真アップロード）")
                    return false
                }
                
                guard (200..<300).contains(httpResponse.statusCode) else {
                    if let decoded = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                        print("サーバーエラー: \(decoded.error)")
                        if let details = decoded.details {
                            print("詳細: \(details)")
                        }
                    } else {
                        let text = String(data: data, encoding: .utf8) ?? "不明なエラー"
                        print("レスポンス本文: \(text)")
                    }
                    return false
                }
                
                // この1枚は成功 → 次のループへ
            } catch {
                print("写真アップロード失敗[\(index)]: \(error.localizedDescription)")
                return false
            }
        }
        // 正常終了
        return true
    }
    
    struct DeletePhotoRequest: Encodable {
        let restaurantId: Int?
        let photoId: Int
    }
    
    func deletePhoto(restaurantId: Int?,photoId: Int) async -> Bool {
        
        // トークン取得
        guard let token = UserDefaults.standard.string(forKey: "token") else {
            print("トークンが存在しません")
            return false
        }
        
        // PhotoRestaurant コントローラ宛のAPI
        // 実際のルートに合わせて変更してください
        guard let url = URL(string: "https://moguroku.com/photorestaurant/delete") else {
            print("URLが不正です")
            return false
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let body = DeletePhotoRequest(restaurantId: restaurantId, photoId: photoId)
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            errorMessage = "リクエストボディ作成エラー: \(error.localizedDescription)"
            return false
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let http = response as? HTTPURLResponse else {
                errorMessage = "無効なレスポンスです"
                return false
            }
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print("deletePhoto response: \(jsonString)")
            }
            
            if http.statusCode == 401 {
                errorMessage = "認証エラーが発生しました"
                return false
            }
            
            guard (200..<300).contains(http.statusCode) else {
                errorMessage = "削除に失敗しました（\(http.statusCode)）"
                return false
            }
            
            return true
            
        } catch {
            errorMessage = "通信エラー: \(error.localizedDescription)"
            return false
        }
    }
}

extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            self.append(data)
        }
    }
}
