//
//  NearbySearchViewModel.swift
//  Project
//
//  Created by 高見聡 on 2025/08/24.
//

import SwiftUI
import CoreLocation

@MainActor
final class NearbySearchViewModel: ObservableObject {
    @Published var results: [ApplePlace] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func search(keyword: String, around center: CLLocationCoordinate2D) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            results = try await PlaceSearchManager.shared.searchPlaces(
                keyword: keyword,
                around: center,
                minCount: 20
            )
        } catch {
            errorMessage = "検索に失敗しました：\(error.localizedDescription)"
            results = []
        }
    }
}
