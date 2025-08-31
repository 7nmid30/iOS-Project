//
//  ContentView.swift
//  Project
//
//  Created by 高見聡 on 2025/01/12.
//

import SwiftUI
import MapKit
struct ContentView: View { //メインビュー
    
    @StateObject private var locationManager = LocationManager()
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 35.681236, longitude: 139.767125), // 東京駅
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @State private var mapRotation: Double = 0.0//地図の回転角度
    @State private var shouldUpdateRegion: Bool = false
    @State private var searchText: String = "" // 検索テキストの状態
    @FocusState private var isFocused: Bool // 検索窓がフォーカスされているか
    //State private var results: [GooglePlace] = [] //Google用
    @State private var results: [ApplePlace] = []
    @State private var sheetOffset: CGFloat = 0 // ← 初期は0、onAppearでminYに自動セットされる
    //@State private var selectedPlace: GooglePlace? = nil //Google用
    @State private var selectedPlace: ApplePlace? = nil
    //アカウントボタン用の@Stateを用意
    @State private var isAccountSheetPresented = false
    
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    
    @State private var favorites: [FavoriteRestaurant] = []
    
    @StateObject private var vm = NearbySearchViewModel()
    
    var body: some View {
        Group {
            if isLoggedIn {
                //ログイン中の場合
                ZStack {
                    //MapView構造体を呼び出す
                    MapView(
                        region: $region,
                        heading: $locationManager.heading,
                        mapRotation: $mapRotation,
                        shouldUpdateRegion: $shouldUpdateRegion,
                        results: $results,
                        selectedPlace: $selectedPlace
                    ) //＄記号は、State などで管理されている変数をバインディング形式（監視対象）で渡すために使う。
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        isFocused = false // フォーカスを解除
                        hideKeyboard() // キーボードを閉じる
                    }
                    
                    VStack {
                        // 検索バーを追加
                        HStack {
                            // 検索バーを追加（TextFieldの内側にアイコンを配置）
                            TextField("検索", text: $searchText, onCommit: {
                                // Enterキー押下時
                                //search(keyword: searchText) //Google用
                                Task { // ← ここで非同期コンテキストを作る
                                        await vm.search(keyword: searchText, around: region.center)
                                    self.results = vm.results        // ← これが無いので画面に出ていない
                                }
                                self.sheetOffset = UIScreen.main.bounds.height * 0.6 // mid表示
                            })
                            .submitLabel(.search) // キーボード右下を「検索」に
                            .padding(10)
                            .padding(.leading, 30) // アイコンのスペース分余白を追加
                            .background(Color.white)
                            .cornerRadius(8)
                            .shadow(radius: 3)
                            .foregroundColor(.black) // テキストの色を黒に
                            .overlay(
                                HStack {
                                    Image(systemName: "magnifyingglass")
                                        .foregroundColor(.gray)
                                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading) // 左にアイコンを配置
                                        .padding(.leading, 8)
                                    
                                    Spacer()
                                    
                                    // アカウントボタン（右側）
                                    Button(action: {
                                        isAccountSheetPresented = true
                                        // アカウント画面に遷移する処理など
                                    }) {
                                        Image(systemName: "person.circle.fill")
                                            .resizable()
                                            .frame(width: 36, height: 36)
                                            .foregroundColor(.blue)
                                            .padding(.trailing, 8) // 左アイコンと同じ距離
                                    }
                                }
                            )
                            .padding()
                            .focused($isFocused) // フォーカス状態を監視
                            
                        }
                        .padding(.horizontal)//対象に周囲といい感じに余白を作るようにやってくれる
                        Spacer() // スペースを追加
                        HStack {
                            
                            if let heading = locationManager.heading {
                                // headingがnilでない場合にmagneticHeadingにアクセス
                                let trueHeading = heading.trueHeading
                                Text(String(format: "%.2f", trueHeading))
                            }
                            
                            //Text(String(format: "%.2f", locationManager.mapRotation))
                            Text(String(format: "%.2f", mapRotation))
                            
                            Spacer()//左側にスペースを追加
                            Button(action: {
                                if let location = locationManager.currentLocation {//currentLocationがnillでない場合のみlocationに代入して以下の処理実行
                                    region.center = location // region の中心を現在地に更新
                                    shouldUpdateRegion = true // フラグを立てる
                                }
                            }) {
                                ZStack {//現在地ボタン
                                    // 外側の白い円
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 50, height: 50) // 外側の円のサイズ
                                    
                                    // 内側の青い矢印
                                    Image(systemName: "location.fill") // 矢印のアイコン
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .foregroundColor(.blue) // 矢印を青に設定
                                        .frame(width: 21, height: 21) // 矢印を小さく設定
                                }
                                .padding()
                            }
                            
                        }
                    }
                    
                    // カスタムボトムシート表示
                    BottomSheetView(
                        //isVisible: $isSheetVisible,
                        offset: $sheetOffset,
                        
                    ) {
                        SearchResultsView(
                            results: results,
                            region: $region,
                            shouldUpdateRegion: $shouldUpdateRegion,
                            selectedPlace: $selectedPlace,
                            favorites: $favorites,
                        )
                    }
                }
                .onAppear {
                    locationManager.setup()
                }
                .sheet(isPresented: $isAccountSheetPresented) {
                    AccountSheetView(favorites: $favorites)
                }
                .task(id: isLoggedIn) {
                    await fetchMyRestaurants()
                }
            } else {
                LoginView(favorites: $favorites)
            }
        }
        
    }
    // キーボードを閉じる関数
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    func search(keyword: String) {
        guard let encodedQuery = searchText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://moguroku.com/searchdata") else {
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let requestBody: [String: String] = ["keyword": keyword]
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            print("リクエストボディのエンコードに失敗しました: \(error)")
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("エラー:", error)
                return
            }
            guard let data = data else {
                print("データが空です")
                return
            }
            do {
                // JSON を PlaceResponseWrapper としてデコード
                let decoded = try JSONDecoder().decode(PlaceResponseWrapper.self, from: data)
                let mapped = decoded.places.map {
                    GooglePlace(
                        name: $0.displayName.text,
                        coordinate: CLLocationCoordinate2D(latitude: $0.location.latitude, longitude: $0.location.longitude),
                        rating: $0.rating,
                        userRatingCount: $0.userRatingCount,
                        startPrice: $0.priceRange?.startPrice?.units,
                        endPrice: $0.priceRange?.endPrice?.units,
                        currencyCode: $0.priceRange?.startPrice?.currencyCode
                    )
                }
                
                //
                DispatchQueue.main.async {
                    //self.results = mapped
                }
                
            } catch {
                print("JSONパース失敗:", error)
            }
        }
        task.resume()
        
    }
    
    
    func fetchMyRestaurants() async {
        guard let token = UserDefaults.standard.string(forKey: "token") else {
            print("トークンが存在しません")
            return
        }
        
        guard let url = URL(string: "https://moguroku.com/getmyrestaurants") else {
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




