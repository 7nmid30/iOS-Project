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
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top, spacing: 10) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(place.name)
                                .font(.headline)
                                .foregroundStyle(.primary)
                                .lineLimit(2)
                            
                            if let address = place.address, !address.isEmpty {
                                Label(address, systemImage: "mappin.and.ellipse")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                        
                        Spacer(minLength: 8)
                        
                        if isFav {
                            Text(isRev ? "お気に入り" : "行ってみたい")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(isRev ? Color.green : Color.orange)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background((isRev ? Color.green : Color.orange).opacity(0.14))
                                .clipShape(Capsule())
                        }
                    }
                    
                    HStack(spacing: 10) {
                        Label(place.ratingText, systemImage: "star.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.orange)
                        
                        if let count = place.userRatingCount {
                            Text("(\(count)件)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        if let category = place.category, !category.isEmpty {
                            Text(category)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.black.opacity(0.05))
                                .clipShape(Capsule())
                        }
                        
                        Spacer()
                    }
                    
                    HStack {
                        if let phone = place.phoneNumber, !phone.isEmpty {
                            Label(phone, systemImage: "phone.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 10) {
                            Button(action: {
                                if isFav {
                                    vm.removeRestaurant(place: place) { success in
                                        if success {
                                            Task { await fetchMyRestaurants() }
                                        } else {
                                            print("削除失敗")
                                        }
                                    }
                                } else {
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
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(isFav ? Color.red : Color.secondary)
                                    .padding(10)
                                    .background(Color.white.opacity(0.9))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                            
                            // 口コミを書くボタン
                            Button(action: {
                                print("口コミを書く tapped: \(place.name)")
                                reviewPlace = place
                            }) {
                                Image(systemName: "text.bubble.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(isRev ? Color.blue : Color.secondary)
                                    .padding(10)
                                    .background(Color.white.opacity(0.9))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: place.id == selectedPlace?.id
                                ? [Color(red: 0.89, green: 0.95, blue: 1.0), Color.white]
                                : [Color.white.opacity(0.92), Color.white.opacity(0.84)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(
                            place.id == selectedPlace?.id ? Color.blue.opacity(0.35) : Color.black.opacity(0.08),
                            lineWidth: place.id == selectedPlace?.id ? 2 : 1
                        )
                )
                .shadow(color: Color.black.opacity(place.id == selectedPlace?.id ? 0.12 : 0.07), radius: 8, y: 4)
                .contentShape(Rectangle()) // 文字だけでなくList内の領域（文字を格納している領域）をタップ可能に
                .onTapGesture {
                    region.center = place.coordinate
                    shouldUpdateRegion = true
                    selectedPlace = place
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 14, bottom: 8, trailing: 14))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
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

private extension ApplePlace {
    var ratingText: String {
        guard let rating else { return "評価なし" }
        return String(format: "%.1f", rating)
    }
}
