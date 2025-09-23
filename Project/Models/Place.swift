//
//  Place.swift
//  Project
//
//  Created by 高見聡 on 2025/06/15.
//
import Foundation
import CoreLocation
import MapKit

struct GooglePlace: Identifiable{
    let id = UUID()  // List用に必須
    let name: String
    let coordinate: CLLocationCoordinate2D
    let rating: Double?
    let userRatingCount: Int?
    let startPrice: String?
    let endPrice: String?
    let currencyCode: String?
}

struct PlaceResponseWrapper: Codable {
    let places: [PlaceResponse]
}

// APIレスポンスを受け取る用のCodable構造体
struct PlaceResponse: Codable {
    let displayName: DisplayName
    let location: Location
    let rating: Double?
    let userRatingCount: Int?
    let priceRange: PriceRange?

    struct DisplayName: Codable {
        let text: String
    }

    struct Location: Codable {
        let latitude: Double
        let longitude: Double
    }
    
    struct PriceRange: Codable {
        let startPrice: StartPrice?
        let endPrice: EndPrice?
    }
    
    struct StartPrice: Codable {
        let units: String?
        let currencyCode: String?
    }
    
    struct EndPrice: Codable {
        let units: String?
        let currencyCode: String?
    }
}

class PlaceAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let title: String?

    //GoogleMap用
    init(place: GooglePlace) {
        self.coordinate = place.coordinate
        self.title = place.name
        //self.id = place.id
    }
    
    init(place: ApplePlace) {
        self.coordinate = place.coordinate
        self.title = place.name
        //self.id = place.id
    }
}

//MapKit用
struct ApplePlace: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
    let phoneNumber: String?
    let url: URL?
    let address: String?
    let rating: Double?
    let userRatingCount: Int?
    let startPrice: String?
    let endPrice: String?
    let currencyCode: String?
    let category: String?
}

// extension を追加（Encodableにもできるようにということで）
extension ApplePlace: Encodable {
    enum CodingKeys: String, CodingKey {
        case name, latitude, longitude, phoneNumber, url, address,
             rating, userRatingCount, startPrice, endPrice, currencyCode, category
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(name, forKey: .name)
        try c.encode(coordinate.latitude, forKey: .latitude)
        try c.encode(coordinate.longitude, forKey: .longitude)
        try c.encodeIfPresent(phoneNumber, forKey: .phoneNumber)
        if let url = url { try c.encode(url.absoluteString, forKey: .url) }
        try c.encodeIfPresent(address, forKey: .address)
        try c.encodeIfPresent(rating, forKey: .rating)
        try c.encodeIfPresent(userRatingCount, forKey: .userRatingCount)
        try c.encodeIfPresent(startPrice, forKey: .startPrice)
        try c.encodeIfPresent(endPrice, forKey: .endPrice)
        try c.encodeIfPresent(currencyCode, forKey: .currencyCode)
        try c.encodeIfPresent(category, forKey: .category)
    }
}
