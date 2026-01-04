//
//  FavoriteRestaurantsView.swift
//  Project
//
//  Created by 高見聡 on 2025/07/28.
//

import SwiftUI

struct FavoriteRestaurantsView: View {
    
    @Binding var favorites: [FavoriteRestaurant]
    
    var body: some View {
        //        NavigationView {
        //            List(favorites) { restaurant in
        //                VStack(alignment: .leading, spacing: 4) {
        //                    Text(restaurant.restaurantName)
        //                        .font(.headline)
        //
        //                    Text("登録日時: \(restaurant.createdAt)")
        //                        .font(.caption)
        //                        .foregroundColor(.gray)
        //                }
        //                .padding(.vertical, 6)
        //            }
        //            .navigationTitle("お気に入りリスト")
        //        }
        NavigationStack {
            List {
                ForEach(favorites) { restaurant in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(restaurant.restaurantName)
                            .font(.headline)
//                        Text("登録日時: \(restaurant.createdAt)")
//                            .font(.caption)
//                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 6)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            // --- 削除処理（サーバー側） ---
                            // 例）requestDeleteFavorite(name: restaurant.restaurantName)
                            
                            // --- 画面反映（名前で判定して即削除） ---
                            withAnimation(.easeInOut) {
                                favorites.removeAll { $0.restaurantName == restaurant.restaurantName }
                            }
                        } label: {
                            Label("削除", systemImage: "trash")
                        }
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("お気に入りリスト")
        }
    }
}
