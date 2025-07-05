//
//  Place.swift
//  Project
//
//  Created by 高見聡 on 2025/06/15.
//
import Foundation
import CoreLocation

struct Place: Identifiable{
    let id = UUID()  // List用に必須
    let name: String
    let coordinate: CLLocationCoordinate2D

}

struct PlaceResponseWrapper: Codable {
    let places: [PlaceResponse]
}

// APIレスポンスを受け取る用のCodable構造体
struct PlaceResponse: Codable {
    let displayName: DisplayName
    let location: Location

    struct DisplayName: Codable {
        let text: String
    }

    struct Location: Codable {
        let latitude: Double
        let longitude: Double
    }
}

//import Foundation
//
//struct Place: Codable, Identifiable {
//    var id = UUID()
//    let userRatingCount: Int?
//    let priceRange: Int?
//    let displayName: DisplayName?
//    let formattedAddress: String?
//    let location: Location?
//    let rating: Double?
//}
//
//struct DisplayName: Codable {
//    let text: String
//    let languageCode: String?
//}
//
//struct Location: Codable {
//    let latitude: Double
//    let longitude: Double
//}
