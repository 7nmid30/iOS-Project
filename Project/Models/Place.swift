//
//  Place.swift
//  Project
//
//  Created by 高見聡 on 2025/06/15.
//
import Foundation
import CoreLocation
import MapKit

struct Place: Identifiable{
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
    //let id: UUID  // ← 追加！

    init(place: Place) {
        self.coordinate = place.coordinate
        self.title = place.name
        //self.id = place.id
    }
}
