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
    
    @Binding var favorites: [FavoriteRestaurant] //お気に入りのマイレストラン
    
    //@State private var favoritePlaces: Set<Place.ID> = [] //いいねされた飲食店
    
    @State private var showLoginView = false
    
    var body: some View {
        VStack {
            Text("検索結果")
                .font(.headline)
                .padding()
            
            List(results) { place in
                let isFav = isFavorited(place)
                
                HStack {
                    Text(place.name)
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(action: {
                        if isFav {
                            // isFavがtrue（すでにお気に入り） のときの処理
                            // 削除処理
                            removeRestaurant(name: place.name) { success in
                                if success {
                                    Task { await fetchMyRestaurants() }
                                } else {
                                    print("削除失敗")
                                }
                            }
                        } else {
                            // isFavがfalse（お気に入りではない） のときの処理
                            // 登録処理
                            registerRestaurant(name: place.name) { success in
                                if success {
                                    Task { await fetchMyRestaurants() }
                                } else {
                                    print("登録失敗")
                                }
                            }
                        }
                    }) {
                        Image(systemName: isFav ? "heart.fill" : "heart")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .sheet(isPresented: $showLoginView) {
                        //LoginView(favorites: $favorites) // ログイン画面に飛ばす
                    }
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
    
    
    // すでにお気に入りか判定（名前一致で判定）
    private func isFavorited(_ place: Place) -> Bool {
        favorites.contains { fav in
            fav.restaurantName == place.name
        }
    }
    
    
    func registerRestaurant(name: String, completion: @escaping (Bool) -> Void) {
        guard let token = UserDefaults.standard.string(forKey: "token") else {
            print("トークンがありません")
            completion(false)
            return
        }
        
        guard let url = URL(string: "https://moguroku.com/myrestaurantlist/add") else {
            print("URLが不正です")
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["keyword": name]
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            print("リクエストボディ作成エラー: \(error)")
            completion(false)
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("通信エラー: \(error.localizedDescription)")
                    completion(false)
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("HTTPレスポンスが不正です")
                    completion(false)
                    return
                }
                
                if httpResponse.statusCode == 401 {
                    print("認証エラー（ログインが必要）")
                    completion(false)
                    return
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    print("APIエラー: \(httpResponse.statusCode)")
                    completion(false)
                    return
                }
                
                print("登録成功")
                completion(true)
            }
        }.resume()
    }
    
    func removeRestaurant(name: String, completion: @escaping (Bool) -> Void) {
        guard let token = UserDefaults.standard.string(forKey: "token") else {
            print("トークンがありません")
            completion(false)
            return
        }
        
        guard let url = URL(string: "https://moguroku.com/myrestaurantlist/delete") else {
            print("URLが不正です")
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["keyword": name]
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            print("リクエストボディ作成エラー: \(error)")
            completion(false)
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("通信エラー: \(error.localizedDescription)")
                    completion(false)
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("HTTPレスポンスが不正です")
                    completion(false)
                    return
                }
                
                if httpResponse.statusCode == 401 {
                    print("認証エラー（ログインが必要）")
                    completion(false)
                    return
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    print("APIエラー: \(httpResponse.statusCode)")
                    completion(false)
                    return
                }
                
                print("削除成功")
                completion(true)
            }
        }.resume()
    }
    
    func fetchMyRestaurants() async {
        guard let token = UserDefaults.standard.string(forKey: "token") else {
            print("トークンが存在しません")
            return
        }
        
        guard let url = URL(string: "https://moguroku.com/getmyrestaurants") else {
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
