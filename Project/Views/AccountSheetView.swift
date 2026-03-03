//
//  AccountSheetView.swift
//  Project
//
//  Created by 高見聡 on 2025/07/21.
//
import SwiftUI
import PhotosUI
import UIKit

struct AccountSheetView: View {
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    @AppStorage("profileImageData") private var profileImageData: Data = Data()
    
    @Binding var favorites: [FavoriteRestaurant]
    var onSelectFavorite: ((FavoriteRestaurant) -> Void)? = nil
    @State private var showFavoritesSheet = false
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var isLoadingFavorites = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.96, green: 0.98, blue: 1.0),
                        Color(red: 0.90, green: 0.95, blue: 1.0)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        profileCard
                        
                        MenuCardButton(
                            title: "いいねリスト",
                            subtitle: "保存したお店を確認",
                            icon: "heart.fill",
                            tint: Color.pink,
                            trailing: isLoadingFavorites ? AnyView(ProgressView()) : AnyView(Text("\(favorites.count)件").font(.subheadline.weight(.semibold)).foregroundStyle(.secondary))
                        ) {
                            Task {
                                isLoadingFavorites = true
                                await fetchMyRestaurants()
                                isLoadingFavorites = false
                                showFavoritesSheet = true
                            }
                        }
                        
                        MenuCardButton(
                            title: "ログアウト",
                            subtitle: "現在のアカウントからサインアウト",
                            icon: "rectangle.portrait.and.arrow.right",
                            tint: Color.red,
                            trailing: AnyView(Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary))
                        ) {
                            UserDefaults.standard.removeObject(forKey: "token")
                            isLoggedIn = false
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    .padding(.bottom, 24)
                }
            }
            .sheet(isPresented: $showFavoritesSheet) {
                FavoriteRestaurantsView(
                    favorites: $favorites,
                    onSelectRestaurant: { restaurant in
                        onSelectFavorite?(restaurant)
                    }
                )
            }
            .onChange(of: selectedPhotoItem) { newItem in
                guard let newItem else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self),
                       let image = UIImage(data: data),
                       let jpegData = image.jpegData(compressionQuality: 0.82) {
                        await MainActor.run {
                            profileImageData = jpegData
                        }
                    }
                }
            }
            .navigationTitle("アカウント")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.fraction(0.42), .medium, .large])
    }
    
    private var profileCard: some View {
        VStack(spacing: 14) {
            ZStack(alignment: .bottomTrailing) {
                profileImageView
                
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Image(systemName: "camera.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(9)
                        .background(Color.blue)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                }
            }
            
            Text("Moguroku User")
                .font(.headline)
            
            Text("プロフィール写真はタップで変更できます")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.86))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.black.opacity(0.07), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
    }
    
    @ViewBuilder
    private var profileImageView: some View {
        if let uiImage = UIImage(data: profileImageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 96, height: 96)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 3))
                .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
        } else {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.35), Color.cyan.opacity(0.35)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 96, height: 96)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 38))
                        .foregroundStyle(Color.white.opacity(0.92))
                )
                .overlay(Circle().stroke(Color.white, lineWidth: 3))
                .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
        }
    }
    
    func fetchMyRestaurants() async {
        guard let token = UserDefaults.standard.string(forKey: "token") else {
            print("トークンが存在しません")
            return
        }
        
        guard let url = URL(string: "https://moguroku.com/FavoriteRestaurant/get") else {
            print("URLが不正です")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("無効なレスポンス")
                return
            }
            
            if httpResponse.statusCode == 401 {
                print("認証エラー")
                return // 認証エラー時は何もしない
            }
            
            guard httpResponse.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }
            
            let decoder = JSONDecoder()
            let result = try decoder.decode(FavoriteRestaurantListResponse.self, from: data)
            
            DispatchQueue.main.async {
                self.favorites = result.userFavoriteRestaurants
            }
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print("レスポンスのJSON文字列: \(jsonString)")
            } else {
                print("データの文字列変換に失敗しました")
            }
            //
            //                // デコード結果を安全に取り出す
            //                if let favorites = result.userFavoriteRestaurants {
            //                    DispatchQueue.main.async {
            //                        self.myRestaurants = favorites
            //                    }
            //                } else {
            //                    DispatchQueue.main.async {
            //                        self.myRestaurants = []
            //                    }
            //                }
            
        } catch {
            print("エラーが発生しました: \(error.localizedDescription)")
        }
    }
}

private struct MenuCardButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let tint: Color
    let trailing: AnyView
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(tint.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(tint)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                trailing
            }
            .padding(14)
            .frame(maxWidth: .infinity)
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
        .buttonStyle(.plain)
    }
}
