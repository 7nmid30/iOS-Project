//
//  FavoriteRestaurantsView.swift
//  Project
//
//  Created by 高見聡 on 2025/07/28.
//

import SwiftUI

struct FavoriteRestaurantsView: View {
    
    @Binding var favorites: [FavoriteRestaurant]
    var onSelectRestaurant: ((FavoriteRestaurant) -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.98, green: 0.99, blue: 1.0),
                        Color(red: 0.92, green: 0.96, blue: 1.0)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                List {
                    summaryCard
                        .listRowInsets(EdgeInsets(top: 8, leading: 14, bottom: 8, trailing: 14))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    
                    if favorites.isEmpty {
                        emptyCard
                            .listRowInsets(EdgeInsets(top: 8, leading: 14, bottom: 8, trailing: 14))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                    } else {
                        ForEach(Array(favorites.enumerated()), id: \.element.id) { index, restaurant in
                            FavoriteRestaurantCard(
                                restaurant: restaurant,
                                rank: index + 1
                            )
                            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .onTapGesture {
                                onSelectRestaurant?(restaurant)
                                dismiss()
                            }
                            .listRowInsets(EdgeInsets(top: 8, leading: 14, bottom: 8, trailing: 14))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    withAnimation(.easeInOut) {
                                        favorites.removeAll { $0.restaurantId == restaurant.restaurantId }
                                    }
                                } label: {
                                    Label("削除", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("お気に入りリスト")
        }
    }
    
    private var summaryCard: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.pink.opacity(0.16))
                    .frame(width: 44, height: 44)
                
                Image(systemName: "heart.fill")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(Color.pink)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("登録済み \(favorites.count)件")
                    .font(.headline)
                Text("スワイプで削除できます")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.9))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.black.opacity(0.07), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.07), radius: 8, y: 4)
    }
    
    private var emptyCard: some View {
        VStack(spacing: 10) {
            Image(systemName: "heart.slash")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("お気に入りはまだありません")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.9))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.black.opacity(0.07), lineWidth: 1)
        )
    }
}

private struct FavoriteRestaurantCard: View {
    let restaurant: FavoriteRestaurant
    let rank: Int
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.14))
                    .frame(width: 40, height: 40)
                Text("\(rank)")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.blue)
            }
            
            VStack(alignment: .leading, spacing: 5) {
                Text(restaurant.restaurantName)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                
                Text("ID: \(restaurant.restaurantId)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.95), Color.white.opacity(0.88)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.black.opacity(0.07), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
    }
}
