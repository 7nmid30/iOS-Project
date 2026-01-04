//
//  ReviewRequest.swift
//  Project
//
//  Created by 高見聡 on 2025/08/28.
//
import Foundation
// MARK: - API DTO（Data Transfer Object）
struct ReviewRequest: Encodable {
    let place: ApplePlace
    let score: Double
    let taste: Int
    let costPerformance: Int
    let service: Int
    let atmosphere: Int
    let comment: String
}

//Listを受け取る
struct ReviewedRestaurantListResponse: Codable {
    let userReviewedList: [ReviewedRestaurant]//変数名がAPI側のオブジェクトに対応している
}

struct ReviewedRestaurant: Codable, Identifiable {
    var id: Int { restaurantId }   //一意になるように設定する
    let restaurantId: Int
    let restaurantName: String
}

struct ReviewedRestaurantDetailResponse: Codable {
    let reviewedDetail: ReviewedRestaurantDetail //配列型でなくて一件だけ受け取る
}
//
struct ReviewedRestaurantDetail: Codable, Identifiable {
    //var id: Int { restaurantId }  // SwiftUIのListで使えるように
    var id: Int
    //let userId: String
    let restaurantId: Int
    let restaurantName: String
    let totalScore: Double   // JSONにある
    let taste: Int
    let costPerformance: Int
    let service: Int
    let atmosphere: Int
    let comment: String
    let createdAt: String // 必要ならDateにしてもよい
//    // 追加フィールド（nullが来る場合はOptionalに）
//    let applicationUser: String?
//    let restaurant: String?
}
