//
//  AccountSheetView.swift
//  Project
//
//  Created by 高見聡 on 2025/07/21.
//
import SwiftUI

struct AccountSheetView: View {
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    
    @Binding var favorites: [FavoriteRestaurant]
    @State private var showFavoritesSheet = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("アカウントメニュー")
                .font(.title2)
                .padding()
            
            // いいねリストボタン
            Button(action: {
                // ボタン押された時の処理
                Task{
                    await fetchMyRestaurants()
                    showFavoritesSheet = true
                }
                
                // 例: 別の画面を表示、シート表示、ナビゲーションなど
                
            }) {
                Text("いいねリスト")
                    .foregroundColor(.blue)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            .sheet(isPresented: $showFavoritesSheet) {
                
                FavoriteRestaurantsView(favorites: $favorites)
            }
            
            Button(action: {
                // ログアウト処理を書く（例: トークン削除・画面遷移など）
                print("ログアウトされました")
                UserDefaults.standard.removeObject(forKey: "token")
                isLoggedIn = false // ログアウト後ログイン画面へ
                
            }) {
                Text("ログアウト")
                    .foregroundColor(.red)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            
            Spacer()
        }
        .padding()
        .presentationDetents([.fraction(0.3), .medium])
    }
    
    func fetchMyRestaurants() async {
        guard let token = UserDefaults.standard.string(forKey: "token") else {
            print("トークンが存在しません")
            return
        }
        
        guard let url = URL(string: "https://moguroku.com/FavoriteRestaurant/get") else {
            print("URLが不正です")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("無効なレスポンス")
                return
            }
            
            if httpResponse.statusCode == 401 {
                print("認証エラー")
                return // 認証エラー時は何もしない
            }
            
            guard httpResponse.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }
            
            let decoder = JSONDecoder()
            let result = try decoder.decode(FavoriteRestaurantListResponse.self, from: data)
            
            DispatchQueue.main.async {
                self.favorites = result.userFavoriteRestaurants
            }
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print("レスポンスのJSON文字列: \(jsonString)")
            } else {
                print("データの文字列変換に失敗しました")
            }
            //
            //                // デコード結果を安全に取り出す
            //                if let favorites = result.userFavoriteRestaurants {
            //                    DispatchQueue.main.async {
            //                        self.myRestaurants = favorites
            //                    }
            //                } else {
            //                    DispatchQueue.main.async {
            //                        self.myRestaurants = []
            //                    }
            //                }
            
        } catch {
            print("エラーが発生しました: \(error.localizedDescription)")
        }
    }
}
