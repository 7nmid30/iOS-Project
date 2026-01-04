//
//  ReviewSheetView.swift
//  Project
//
//  Created by 高見聡 on 2025/08/16.
//

import SwiftUI
import PhotosUI

// MARK: - スモールスタート方針
// ・Form + Section でシンプルな入力画面
// ・点数は整数(0-5)と小数(0-9)を Picker で分けて選択
// ・味/コスパ/接客/雰囲気は SegmentedPicker
// ・コメントは TextEditor
// ・保存(送信)とキャンセルボタンのみ
// ・onAppearで既存口コミを取得して初期値に反映
// ・API は URLSession + async/await。トークンは UserDefaults("token") を使用
// ・親側リフレッシュ用に onSubmitted コールバックを用意

// MARK: - View
struct ReviewSheetView: View {
    let place: ApplePlace
    let isReviewed: Bool
    @Binding var reviewedList: [ReviewedRestaurant] //レビューしたマイレストラン
    var onSubmitted: (() -> Void)? = nil // 送信成功時に親へ通知
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var vm = ReviewViewModel()
    @FocusState private var commentFocused: Bool
    
    @State private var showDetail = false
    @State private var tempScore: Double = 0.0
    //@State private var isLoading = false
    @State private var loadedForId: Int? = nil  // 二重取得防止
    
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = [] // 送信する候補
    
    @State private var reviewedPhotos: [ReviewedPhoto] = []
    
    
    @State private var restaurantId: Int? = nil
    
    //削除用の
    @State private var deleteTarget: ReviewedPhoto? = nil
    @State private var showDeleteDialog = false
    @State private var isDeletingPhoto = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("点数") {
                    VStack(alignment: .leading, spacing: 10) {
                        // 0.5刻みで素早く選べる
                        Slider(value: $vm.score, in: 0...5, step: 0.5)
                        
                        HStack {
                            // 現在値表示（0.1桁）
                            Text(String(format: "総評 %.1f", vm.score))
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            
                            Spacer()
                            
                            Menu {
                                // 現在の0.5刻みを基準に「帯の下端」を決める
                                let half = vm.roundToHalf(vm.score)        // 例: 3.0, 3.5
                                let lower = floor(half)                    // ← 整数に丸めて帯開始を決定
                                let upper = min(5.0, lower + 0.9)          // 例: 3.0〜3.9
                                
                                let from = Int((lower * 10).rounded())
                                let to   = Int((upper * 10).rounded())
                                
                                Picker("0.1刻みで調整", selection: $vm.score) {
                                    ForEach(from...to, id: \.self) { k in
                                        let v = Double(k) / 10.0
                                        Text(String(format: "%.1f", v)).tag(v)
                                    }
                                }
                                .labelsHidden()
                            } label: {
                                Label(String(format: "詳細 %.1f", vm.score), systemImage: "slider.horizontal.3")
                            }
                            
                        }
                    }
                }
                
                Section("味") {
                    Picker("味", selection: $vm.tasteIndex) {
                        ForEach(0..<vm.levelOptions.count, id: \.self) { i in
                            Text(vm.levelOptions[i]).tag(i)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("コスパ") {
                    Picker("コスパ", selection: $vm.costPerfIndex) {
                        ForEach(0..<vm.levelOptions.count, id: \.self) { i in
                            Text(vm.levelOptions[i]).tag(i)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("接客") {
                    Picker("接客", selection: $vm.serviceIndex) {
                        ForEach(0..<vm.levelOptions.count, id: \.self) { i in
                            Text(vm.levelOptions[i]).tag(i)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("雰囲気") {
                    Picker("雰囲気", selection: $vm.atmosphereIndex) {
                        ForEach(0..<vm.levelOptions.count, id: \.self) { i in
                            Text(vm.levelOptions[i]).tag(i)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("口コミ") {
                    TextEditor(text: $vm.comment)
                        .frame(minHeight: 120)
                        .focused($commentFocused)
                }
                
                Section("写真") {
                    VStack(alignment: .leading, spacing: 8) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                // 既存(サーバー)写真：URLで表示
                                ForEach(reviewedPhotos) { p in
                                    ZStack(alignment: .topTrailing) {
                                        AsyncImage(url: URL(string: p.photoUrl)) { phase in
                                            switch phase {
                                            case .empty:
                                                ProgressView()
                                                    .frame(width: 80, height: 80)
                                            case .success(let image):
                                                image.resizable()
                                                    .scaledToFill()
                                                    .frame(width: 80, height: 80)
                                                    .clipped()
                                                    .cornerRadius(12)
                                                    .shadow(radius: 2)
                                            case .failure:
                                                Image(systemName: "photo")
                                                    .frame(width: 80, height: 80)
                                            @unknown default:
                                                EmptyView()
                                            }
                                        }
                                        
                                        // 右上「…」ボタン（削除メニュー）
                                        Button {
                                            deleteTarget = p
                                            showDeleteDialog = true
                                        } label: {
                                            Image(systemName: "ellipsis.circle.fill")
                                                .font(.caption)
                                                .padding(4)
                                                .background(.thinMaterial)
                                                .clipShape(Circle())
                                        }
                                        .disabled(isDeletingPhoto) // 削除中の連打防止
                                        .offset(x: 4, y: -4)
                                    }
                                }
                                
                                
                                // 新規(送信候補)写真
                                ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, uiImage in
                                    ZStack(alignment: .topTrailing) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 80, height: 80)
                                            .clipped()
                                            .cornerRadius(12)
                                            .shadow(radius: 2)
                                        
                                        // 削除ボタン
                                        Button {
                                            selectedImages.remove(at: index)
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.caption)
                                                .padding(4)
                                                .background(.thinMaterial)
                                                .clipShape(Circle())
                                        }
                                        .offset(x: 4, y: -4)
                                    }
                                }
                                
                                // 追加ボタン（PhotosPicker）
                                PhotosPicker(
                                    selection: $pickerItems,
                                    maxSelectionCount: 5, // 最大枚数
                                    matching: .images
                                ) {
                                    VStack {
                                        Image(systemName: "plus")
                                            .font(.title2)
                                        Text("追加")
                                            .font(.caption)
                                    }
                                    .frame(width: 80, height: 80)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [5]))
                                    )
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        
                        Text("最大5枚まで追加できます")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                if let error = vm.errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("\(place.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if vm.isLoading {
                        ProgressView()
                    } else {
                        Button("送信") { Task { await submit() } }
                    }
                }
            }
            .task() {
                guard isReviewed else { return }         // 未レビューなら何もしない
                //guard loadedForId != place.restaurantId else { return } // 取得済みなら二重取得しない
                await GetReviewedDetail(place: place)
                await fetchReviewedPhotosByApplePlace(place: place)
            }
            .onChange(of: pickerItems) { newItems in
                Task {
                    // 追加分だけ読み込むシンプル実装
                    var newImages: [UIImage] = []
                    
                    for item in newItems {
                        if let data = try? await item.loadTransferable(type: Data.self),
                           let uiImage = UIImage(data: data) {
                            newImages.append(uiImage)
                        }
                    }
                    
                    await MainActor.run {
                        // 既存 + 新規（枚数制限もここで調整可）
                        selectedImages = Array((selectedImages + newImages).prefix(5))
                    }
                }
            }
            .confirmationDialog(
                "写真を削除しますか？",
                isPresented: $showDeleteDialog,
                titleVisibility: .visible
            ) {
                Button("削除", role: .destructive) {
                    Task { await deleteSelectedPhoto() }
                }
                Button("キャンセル", role: .cancel) { }
            } message: {
                Text("この操作は取り消せません。")
            }
        }
    }
    
    func submit() async {
        guard let id = await vm.submitReview(place: place) else {
            return
        }
        
        await MainActor.run {
            self.restaurantId = id
        }
        //画像があれば別APIで送信
        if !selectedImages.isEmpty {
            let photoOk = await vm.uploadPhotos(place: place, images: selectedImages)
            if !photoOk {
                // 画像だけ失敗しました的なメッセージ表示
            }
        }
        
        await fetchReviewedRestaurants()
        await fetchReviewedPhotos(id)
        
        onSubmitted?()
        dismiss()
    }
    
    func GetReviewedDetail(place: ApplePlace) async{
        guard let token = UserDefaults.standard.string(forKey: "token") else {
            print("トークンがありません")
            return
        }
        guard let url = URL(string: "https://moguroku.com/reviewRestaurant/get") else {
            print("URLが不正です")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(place)
        } catch {
            print("リクエストボディ作成エラー: \(error)")
            return
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let jsonString = String(data: data, encoding: .utf8) {
                print("レスポンスのJSON文字列: \(jsonString)")
            } else {
                print("データの文字列変換に失敗しました")
            }
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
            let result = try decoder.decode(ReviewedRestaurantDetailResponse.self, from: data)
            let detail = result.reviewedDetail
            vm.apply(existing: detail)
            
        } catch {
            print("エラーが発生しました: \(error.localizedDescription)")
        }
    }
    
    func fetchReviewedRestaurants() async {
        guard let token = UserDefaults.standard.string(forKey: "token") else {
            print("トークンが存在しません")
            return
        }
        
        guard let url = URL(string: "https://moguroku.com/reviewRestaurant/list") else {
            print("URLが不正です")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print("レスポンスのJSON文字列: \(jsonString)")
            } else {
                print("データの文字列変換に失敗しました")
            }
            
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
            let result = try decoder.decode(ReviewedRestaurantListResponse.self, from: data)
            
            DispatchQueue.main.async {
                self.reviewedList = result.userReviewedList
            }
            
            
        } catch {
            print("エラーが発生しました: \(error.localizedDescription)")
        }
        
    }
    
    func fetchReviewedPhotos(_ restaurantId: Int) async {
        guard let token = UserDefaults.standard.string(forKey: "token") else {
            print("トークンが存在しません")
            return
        }
        
        var components = URLComponents(string: "https://moguroku.com/photorestaurant/reviewedphotos")
        components?.queryItems = [
            URLQueryItem(name: "restaurantId", value: String(restaurantId))
        ]
        
        guard let url = components?.url else {
            print("URLが不正です")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let http = response as? HTTPURLResponse else {
                print("無効なレスポンス")
                return
            }
            
            if http.statusCode == 401 {
                print("認証エラー")
                return
            }
            
            guard (200..<300).contains(http.statusCode) else {
                print("bad status: \(http.statusCode)")
                return
            }
            
            let decoder = JSONDecoder()
            let result = try decoder.decode(ReviewedPhotosResponse.self, from: data)
            
            await MainActor.run {
                self.reviewedPhotos = result.photos
            }
            
        } catch {
            print("エラーが発生しました: \(error.localizedDescription)")
        }
    }
    
    func fetchReviewedPhotosByApplePlace(place: ApplePlace) async {
        guard let token = UserDefaults.standard.string(forKey: "token") else {
            print("トークンが存在しません")
            return
        }
        
        guard let url = URL(string: "https://moguroku.com/photorestaurant/reviewedphotosbyappleplace") else {
            print("URLが不正です")
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(place)
        } catch {
            print("リクエストボディ作成エラー: \(error)")
            return
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let jsonString = String(data: data, encoding: .utf8) {
                print("レスポンスのJSON文字列: \(jsonString)")
            } else {
                print("データの文字列変換に失敗しました")
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                print("無効なレスポンス")
                return
            }
            
            if httpResponse.statusCode == 401 {
                print("認証エラー")
                return // 認証エラー時は何もしない
            }
            
            // 200台以外ならここで止める（throwしない方がデバッグしやすい）
            guard (200..<300).contains(httpResponse.statusCode) else {
                print("サーバーエラー/不正リクエスト: \(httpResponse.statusCode)")
                return
            }
            
            let decoder = JSONDecoder()
            let result = try decoder.decode(ReviewedPhotosResponse.self, from: data)
            
            //URLを絶対URLに直す
            let fixed = result.photos.map { p in
                ReviewedPhoto(
                    photoId: p.photoId,
                    photoUrl: "https://moguroku.com/" + p.photoUrl,
                    createdAt: p.createdAt
                )
            }
            
            await MainActor.run {
                self.reviewedPhotos = fixed
            }
            
        } catch {
            print("エラー: \(error)")
            print("エラーが発生しました: \(error.localizedDescription)")
        }
    }
    
    func deleteSelectedPhoto() async {
        guard let target = deleteTarget else { return }
        guard !isDeletingPhoto else { return }

        isDeletingPhoto = true
        defer {
            isDeletingPhoto = false
            deleteTarget = nil
        }

        // ここでAPIを叩く（vm側で実装）
        let ok = await vm.deletePhoto(restaurantId: restaurantId, photoId: target.photoId)

        if ok {
            await MainActor.run {
                reviewedPhotos.removeAll { $0.photoId == target.photoId }
            }
        } else {
            // 必要ならエラーメッセージ表示（vm.errorMessage使うならそこへ）
            await MainActor.run {
                vm.errorMessage = "写真の削除に失敗しました。"
            }
        }
    }
    
    struct ReviewedPhotosResponse: Decodable {
        let id: Int?
        let photos: [ReviewedPhoto]
    }
    
    struct ReviewedPhoto: Decodable, Identifiable {
        let photoId: Int
        let photoUrl: String
        let createdAt: String// ← Date じゃなく String
        
        var id: Int { photoId }
    }
}
