//
//  PlaceSearchManager.swift
//  Project
//
//  Created by 高見聡 on 2025/08/24.
//

import Foundation
import MapKit
import CoreLocation
import Contacts

final class PlaceSearchManager {
    static let shared = PlaceSearchManager() // シングルトンにしてもよい
    private init() {}

    private func distance(from a: CLLocationCoordinate2D, to b: CLLocationCoordinate2D) -> CLLocationDistance {
        CLLocation(latitude: a.latitude, longitude: a.longitude)
            .distance(from: CLLocation(latitude: b.latitude, longitude: b.longitude))
    }

    private func addressString(_ postal: CNPostalAddress?) -> String? {
        guard let a = postal else { return nil }
        return CNPostalAddressFormatter.string(from: a, style: .mailingAddress)
    }

    /// 距離順に上位 minCount 件を取得
    func searchPlaces(
        keyword: String,
        around center: CLLocationCoordinate2D,
        minCount: Int = 20,
        initialRadiusMeters: CLLocationDistance = 1000,
        maxRadiusMeters: CLLocationDistance = 50_000
    ) async throws -> [ApplePlace] {
        var collected: [MKMapItem] = []
        var seen = Set<String>()
        var radius = max(200, initialRadiusMeters)

        while collected.count < minCount && radius <= maxRadiusMeters {
            var req = MKLocalSearch.Request()
            req.naturalLanguageQuery = keyword
            req.region = MKCoordinateRegion(center: center,
                                            latitudinalMeters: radius * 2,
                                            longitudinalMeters: radius * 2)

            let res = try await MKLocalSearch(request: req).start()
            for item in res.mapItems {
                let c = item.placemark.coordinate
                let key = "\(item.name ?? "")_\(round(c.latitude * 10000))_\(round(c.longitude * 10000))"
                if !seen.contains(key) {
                    seen.insert(key)
                    collected.append(item)
                }
            }

            radius *= 2
        }

        let sorted = collected.sorted {
            distance(from: center, to: $0.placemark.coordinate) <
            distance(from: center, to: $1.placemark.coordinate)
        }
        let topN = Array(sorted.prefix(minCount))

        return topN.map { item in
            ApplePlace(
                name: item.name ?? "名称不明",
                coordinate: item.placemark.coordinate,
                phoneNumber: item.phoneNumber,
                url: item.url,
                address: addressString(item.placemark.postalAddress)
            )
        }
    }
}
