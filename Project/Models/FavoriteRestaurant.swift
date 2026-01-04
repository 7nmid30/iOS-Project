//
//  FavoriteRestaurant.swift
//  Project
//
//  Created by 高見聡 on 2025/07/28.
//

import Foundation

struct FavoriteRestaurantListResponse: Codable {
    let userFavoriteRestaurants: [FavoriteRestaurant]
}

struct FavoriteRestaurant: Codable, Identifiable {
    var id: Int { restaurantId }  // SwiftUIのListで使えるように
    //let userId: String
    let restaurantId: Int
    let restaurantName: String
//    let createdAt: String // 必要ならDateにしてもよい
//    // 追加フィールド（nullが来る場合はOptionalに）
//    let applicationUser: String?
//    let restaurant: String?
}
