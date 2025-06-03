//
//  ContentView.swift
//  Project
//
//  Created by 高見聡 on 2025/01/12.
//

//import SwiftUI
//
//struct ContentView: View {
//    var body: some View {
//        VStack {
//            Image(systemName: "globe")
//                .imageScale(.large)
//                .foregroundStyle(.tint)
//            Text("Hello, world!")
//        }
//        .padding()
//    }
//}
//
//#Preview {
//    ContentView()
//}

import SwiftUI
import MapKit
import CoreLocation
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
    
    
    var body: some View {
        ZStack {
            //MapView構造体を呼び出す
            MapView(region: $region, heading: $locationManager.heading, mapRotation: $mapRotation, shouldUpdateRegion: $shouldUpdateRegion) //＄記号は、State などで管理されている変数をバインディング形式（監視対象）で渡すために使う。
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    isFocused = false // フォーカスを解除
                    hideKeyboard() // キーボードを閉じる
                }
            
            VStack {
                // 検索バーを追加
                HStack {
                    // 検索バーを追加（TextFieldの内側にアイコンを配置）
                    TextField("検索", text: $searchText)
                        .padding(10)
                        .padding(.leading, 30) // アイコンのスペース分余白を追加
                        .background(Color.white)
                        .cornerRadius(8)
                        .shadow(radius: 3)
                        .overlay(
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.gray)
                                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading) // 左にアイコンを配置
                                    .padding(.leading, 8)
                                Spacer()
                            }
                        )
                        .padding()
                        .focused($isFocused) // フォーカス状態を監視
                    
                }
                .padding()//対象に周囲といい感じに余白を作るようにやってくれる
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
//                            region = MKCoordinateRegion(
//                                center: location,
//                                span: region.span // 現在のズーム率（span）を維持
//                            )
//                            shouldUpdateRegion = true // フラグを立てて地図を更新
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
        }
        .onAppear {
            locationManager.setup()
        }
    }
    // キーボードを閉じる関数
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
struct MapView: UIViewRepresentable {
    //親ビューと双方向(MapViewから来る、mapRotationは送る)に送り合うから型情報は省略できない
    @Binding var region: MKCoordinateRegion
    @Binding var heading: CLHeading?
    @Binding var mapRotation: Double
    @Binding var shouldUpdateRegion: Bool // フラグ
    
    let mapView = MKMapView()//UIKitの地図を表示し操作できるビュー
    
    func makeUIView(context: Context) -> MKMapView {
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.isRotateEnabled = true
        
        return mapView//MKMapView型のオブジェクトを返す
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {//UIViewRepresentableプロトコルの一つでstateの値が変更されるたびに呼び出される
        if shouldUpdateRegion {
            //uiView.setRegion(region, animated: true) // 地図を更新
            //span（ズーム率）を保持したまま地図の中心だけを更新
            uiView.setCenter(region.center, animated: true)
            DispatchQueue.main.async  {//値変更→SwiftUIの地図に反映→値変更→反映の順が守られる
                shouldUpdateRegion = false // フラグをリセット（非同期に変更）
            }
        }
        
        if let heading = heading {
            context.coordinator.updateUserIconRotation(with: heading, mapRotation: mapRotation)
        }
        
    }
    
    func makeCoordinator() -> Coordinator {//Coordinatorを作成するためのUIViewRepresentableプロトコルの一つ
        Coordinator(self)//引数はMapViewインスタンス
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {//MKMapView 上で発生するイベント（地図の表示や回転、ユーザーの移動など）を処理
        var parent: MapView
        var annotationView: MKAnnotationView?
        
        init(_ parent: MapView) {
            self.parent = parent//parentはインスタンス生成時に渡ってくるMapView
        }
        
        // MKMapViewDelegateのメソッド（プロトコルで決まってる）
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation {//annotation が MKUserLocation型（ユーザー位置型）であるかの条件
                annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "UserLocation") ?? MKAnnotationView(annotation: annotation, reuseIdentifier: "UserLocation")//A??B AがnilならB
                
                // カスタムビューを設定
                let size: CGFloat = 40
                let backgroundView = UIView(frame: CGRect(x: 0, y: 0, width: size, height: size))//x:0,y:0は親ビューの左上
                
                // 背景の青い丸を作成
                let circleImageView = UIImageView(image: UIImage(systemName: "circle.fill"))
                circleImageView.frame = CGRect(x: 0, y: 0, width: size, height: size)
                circleImageView.tintColor = UIColor(red: 0.4, green: 0.7, blue: 1.0, alpha: 1.0) // 丸の色を青に設定
                backgroundView.addSubview(circleImageView)
                
                // 矢印アイコン（白色）を作成
                let arrowImageView = UIImageView(image: UIImage(systemName: "arrow.up"))
                arrowImageView.frame = CGRect(x: (size - 20) / 2, y: (size - 20) / 2, width: 20, height: 20)
                arrowImageView.tintColor = .white // 矢印の色を白に設定
                backgroundView.addSubview(arrowImageView)
                
                // カスタムビューをアノテーションビューに設定
                annotationView?.addSubview(backgroundView)
                annotationView?.bounds = backgroundView.bounds // サイズを設定
                return annotationView
            }
            return nil
        }
        
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            // 地図が回転した時の処理
            let camera = mapView.camera
            print(camera.heading)
            parent.mapRotation = camera.heading
        }
        
        func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
            
        }
        // 方位が更新された際にアイコンを回転
        // heading に基づいてアノテーションビューを回転
        func updateUserIconRotation(with heading: CLHeading, mapRotation: Double) {
            // heading の回転（デバイスの向き）
            let headingRotation = CGFloat(heading.trueHeading / 180.0 * .pi) // ラジアンに変換
            // mapRotation の回転（地図の回転角度）
            let mapRotationRadians = CGFloat(mapRotation / 180.0 * .pi)
            // heading と mapRotation の差を計算してアイコンの回転角度を設定
            let totalRotation = headingRotation - mapRotationRadians
            
            if let annotationView = self.annotationView {
                UIView.animate(withDuration: 0.1) {
                    annotationView.transform = CGAffineTransform(rotationAngle: totalRotation)
                }
            }
        }
    }
}
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    private let manager = CLLocationManager()
    @Published var heading: CLHeading?//スマホの方向
    @Published var currentLocation: CLLocationCoordinate2D? // 現在地
    
    override init() {
        super.init()
        manager.delegate = self //LocationManagerインスタンスを CLLocationManagerDelegate として設定します。これにより、位置情報や方位情報の更新を受け取ることができるようになります。
        manager.desiredAccuracy = kCLLocationAccuracyBest //位置情報の取得精度が最大化される
        manager.requestWhenInUseAuthorization()
    }
    
    func setup() {
        manager.startUpdatingLocation()//デバイスの位置が変わるたびに CLLocationManagerDelegate のメソッドが呼ばれる
        manager.startUpdatingHeading()//デバイスの向きが変更されるたびに方位情報が更新
    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        DispatchQueue.main.async{
            self.heading = newHeading
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        DispatchQueue.main.async {
            self.currentLocation = locations.last?.coordinate
        }
    }
}



