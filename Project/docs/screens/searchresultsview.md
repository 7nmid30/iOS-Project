# SearchResultsView 設計書

## 1. 概要
検索で取得した店舗一覧（ApplePlace）を List で表示し、以下の操作を提供する。

- 行タップで地図の中心を更新し、選択状態を親へ通知
- お気に入り（heart）登録/解除
- 口コミ（吹き出し）ボタンで ReviewSheetView を表示

本Viewは **Map画面の子コンポーネント**として動作し、地図表示状態（region）・選択状態（selectedPlace）・お気に入り/レビュー済みリストを親から受け取って同期する。

---

## 2. 画面構成（UI）
- タイトル: 「検索結果」
- List:
  - 左: 店舗名
  - 右: お気に入りボタン（heart / heart.fill）
  - 右: 口コミボタン（text.bubble）
- 選択行の背景を `Color.blue.opacity(0.2)` で強調表示

---

## 3. 入出力（State / Binding）

### 3.1 入力（外部から受け取る）
| 名前 | 型 | 役割 |
|---|---|---|
| results | [ApplePlace] | 検索結果一覧 |
| region | Binding<MKCoordinateRegion> | 地図の表示位置（中心） |
| shouldUpdateRegion | Binding<Bool> | 親側 MapView 更新トリガ |
| selectedPlace | Binding<ApplePlace?> | 選択中の店舗 |
| favorites | Binding<[FavoriteRestaurant]> | お気に入り済みリスト |
| reviewedList | Binding<[ReviewedRestaurant]> | レビュー済みリスト |

### 3.2 内部状態
| 名前 | 型 | 役割 |
|---|---|---|
| reviewPlace | ApplePlace?（@State） | シート表示対象（item sheet 用） |
| vm | SearchResultsViewModel（@StateObject） | お気に入り登録/解除などの API 呼び出し |

---

## 4. 主要ロジック

### 4.1 行の描画
各 place について以下を計算し表示に反映する。

- `isFav = isFavorited(place)`
- `isRev = isReviewed(place)`

表示ルール
- heart アイコン
  - isFav == true → `heart.fill`（赤）
  - isFav == false → `heart`（赤）
- 口コミボタン
  - isRev == true → 青
  - isRev == false → グレー
- 選択行
  - `place.id == selectedPlace?.id` のとき背景を青系にする

---

### 4.2 行タップ（地図更新 + 選択）
`onTapGesture` で以下を実施する。

- `region.center = place.coordinate`
- `shouldUpdateRegion = true`
- `selectedPlace = place`

期待効果
- 親 MapView が `shouldUpdateRegion` を監視して region を反映する
- 選択状態が SearchResultsView と MapView で同期される

---

### 4.3 お気に入り（heart）登録/解除
heart ボタン押下でトグル動作。

- isFav == true（登録済み）
  - `vm.removeRestaurant(name: place.name)` を実行
  - 成功時: `fetchMyRestaurants()` を実行し favorites を最新化
- isFav == false（未登録）
  - `vm.favRestaurant(place: place)` を実行
  - 成功時: `fetchMyRestaurants()` を実行し favorites を最新化

備考
- favorites の判定は `restaurantName == place.name` で行う（現行実装）
- 同名店舗が存在する場合の衝突は課題として残る（将来的に restaurantId 等が望ましい）

---

### 4.4 口コミボタン（ReviewSheetView 表示）
吹き出しボタン押下で以下を実施。

- `reviewPlace = place`

`.sheet(item:)` で ReviewSheetView を表示する。
- place: `reviewPlace`（解決済みの place）
- isReviewed: `isReviewed(place)`
- reviewedList: 親バインディングをそのまま渡す
- onSubmitted: 投稿後に親を更新するためのコールバック（必要に応じて実装）

レビュー済みの場合の追加処理（TODO）
- レビュー内容取得（既存レビューを表示する/編集モードなど）
- `vm` 側に GetReviewedDetail 等を持たせることを想定

---

## 5. 参照関数

### 5.1 isFavorited
favorites 内に `restaurantName == place.name` が存在するか判定する。

### 5.2 isReviewed
reviewedList 内に `restaurantName == place.name` が存在するか判定する。

---

## 6. API/データ更新

### 6.1 fetchMyRestaurants（このView内）
- エンドポイント: `GET https://moguroku.com/FavoriteRestaurant/get`
- 認証: `Authorization: Bearer <token>`
- 成功時: favorites を `FavoriteRestaurantListResponse.userFavoriteRestaurants` で置換
- 401 の場合: 認証エラーとして終了

改善ポイント（設計としての提案）
- fetchMyRestaurants は View ではなく ViewModel（または親）に寄せると責務が明確になる
- 失敗時の UI 表示（Toast/Alert）を将来追加する余地あり

---

## 7. エラー・例外
- token がない → print して終了
- URL 不正 → print して終了
- 401 → 認証エラーとして終了
- 200 以外 → URLError(.badServerResponse)
- decode 失敗 → catch で出力

---

## 8. TODO（今後の拡張）
- place.name 比較ではなく restaurantId / placeId で判定できる設計へ移行
- レビュー済み時の「既存レビュー取得→初期値反映」フローを確立
- お気に入り更新のリフレッシュを差分更新にして通信回数削減（必要なら）
- エラーメッセージをUIに出す（Alert / Banner）