//
//  SearchResultsView.swift
//  Project
//
//  Created by 高見聡 on 2025/06/22.
//
import SwiftUI
import MapKit

struct SearchResultsView: View {
    //let results: [GooglePlace] //Google用
    let results: [ApplePlace]
    @Binding var region: MKCoordinateRegion
    @Binding var shouldUpdateRegion: Bool
    //@Binding var selectedPlace: GooglePlace?  // 選択された場所
    @Binding var selectedPlace: ApplePlace?  // 選択された場所
    
    @Binding var favorites: [FavoriteRestaurant] //お気に入りのマイレストラン
    @Binding var reviewedList: [ReviewedRestaurant] //レビューしたマイレストラン
    
    @State private var reviewPlace: ApplePlace? = nil   // ← 行でセットする“対象”
    
    @StateObject private var vm = SearchResultsViewModel() // ← 追加
    
    var body: some View {
        VStack {
            Text("検索結果")
                .font(.headline)
                .padding()
            
            List(results) { place in
                let isFav = isFavorited(place)
                let isRev = isReviewed(place)
                
                HStack {
                    Text(place.name)
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(action: {
                        if isFav {
                            // isFavがtrue（すでにお気に入り） のときの処理
                            // 削除処理
                            vm.removeRestaurant(place: place) { success in
                                if success {
                                    Task { await fetchMyRestaurants() }
                                } else {
                                    print("削除失敗")
                                }
                            }
                        } else {
                            // isFavがfalse（お気に入りではない） のときの処理
                            // 登録処理
                            vm.favRestaurant(place: place) { success in
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
                    
                    // 口コミを書くボタン
                    Button(action: {
                        if(isRev){
                            //レビュー済みならレビュー内容を取得する
                            
                        }
                        print("口コミを書く tapped: \(place.name)")
                        reviewPlace = place     // ← シートは開かない。対象だけセット

                    }) {
                        Image(systemName: "text.bubble") // 💬 吹き出し
                            .foregroundColor(isRev ? .blue : .gray)
                    }
                    .buttonStyle(PlainButtonStyle())
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
        .sheet(item: $reviewPlace) { place in          // ← 親に1つだけ
            ReviewSheetView(
                place: place,
                isReviewed: isReviewed(place),
                reviewedList: $reviewedList 
            ) {
                // 投稿後のリフレッシュが必要ならここ
            }
        }
        
        
    }
    
    private func isFavorited(_ place: ApplePlace) -> Bool {
        favorites.contains { fav in
            fav.restaurantName == place.name
        }
    }
    
    private func isReviewed(_ place: ApplePlace) -> Bool {
        reviewedList.contains { rev in
            rev.restaurantName == place.name
        }
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
            
        } catch {
            print("エラーが発生しました: \(error.localizedDescription)")
        }
        
    }
}
