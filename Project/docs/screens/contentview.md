# ContentView 設計メモ（SwiftUI）

対象: `ContentView.swift`  
目的: 地図 + 検索 + ボトムシート + ピン選択オーバーレイ + アカウント画面

---

## 1. 画面の責務（役割）

- ログイン状態(`isLoggedIn`)で表示を切り替える
  - true: 地図画面（MapView + 検索UI + BottomSheet + OverlayCard）
  - false: LoginView
- 検索実行（Enter / 検索ボタン）で `NearbySearchViewModel.search()` を叩き、`results` に反映
- 検索結果はボトムシートに表示（`sheetOffset`で表示位置制御）
- ピンタップで `selectedPlace` がセットされ、PlaceOverlayCard が最前面に表示
- 現在地ボタンで `region.center` を現在地に更新し、MapViewへ反映

---

## 2. 状態（State）一覧

| State | 型 | 用途 |
|---|---|---|
| locationManager | LocationManager | 現在地/方位(heading)取得 |
| region | MKCoordinateRegion | 表示地図の中心/範囲 |
| mapRotation | Double | 地図回転角（MapViewへ渡す） |
| shouldUpdateRegion | Bool | region更新フラグ（MapView側で監視想定） |
| searchText | String | 検索入力 |
| isFocused | FocusState | TextFieldフォーカス |
| results | [ApplePlace] | 検索結果（地図ピン + リストに使用） |
| sheetOffset | CGFloat | BottomSheetのY位置 |
| selectedPlace | ApplePlace? | ピンタップで選択された場所 |
| isAccountSheetPresented | Bool | アカウント画面のsheet表示 |
| isLoggedIn | AppStorage Bool | ログイン状態 |
| favorites | [FavoriteRestaurant] | お気に入り一覧 |
| reviewedList | [ReviewedRestaurant] | レビュー済み一覧 |
| vm | NearbySearchViewModel | 検索実行/結果保持 |

---

## 3. 画面構造（UI構成）

- ZStack（地図を最背面）
  - MapView（ピン表示/選択反映）
  - 検索バー（TextField + アカウントボタン）
  - デバッグ情報表示（heading, mapRotation）
  - 現在地ボタン
  - BottomSheetView（SearchResultsView）
  - PlaceOverlayCard（selectedPlace != nil のとき最前面）
- sheet: AccountSheetView
- task: お気に入り、レビュー取得

---

## 4. コンポーネント関係図（Mermaid）

```mermaid
flowchart TD
    ContentView --> MapView
    ContentView --> BottomSheetView
    BottomSheetView --> SearchResultsView
    ContentView --> PlaceOverlayCard
    ContentView --> AccountSheetView
    ContentView --> LoginView

    ContentView --> LocationManager
    ContentView --> NearbySearchViewModel

    SearchResultsView -->|select| selectedPlace
    MapView -->|tap pin| selectedPlace
    selectedPlace --> PlaceOverlayCard