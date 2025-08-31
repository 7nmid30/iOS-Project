//
//  ReviewAddRequest.swift
//  Project
//
//  Created by 高見聡 on 2025/08/28.
//
import Foundation
// MARK: - API DTO（Data Transfer Object）
struct ReviewAddRequest: Encodable {
    let place: String
    let score: Double
    let taste: Int
    let costPerformance: Int
    let service: Int
    let atmosphere: Int
    let comment: String
}
