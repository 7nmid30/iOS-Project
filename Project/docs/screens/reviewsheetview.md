# 口コミ機能 設計書（ReviewSheetView）

## 1. 目的
飲食店（ApplePlace）に対して、ユーザーが **点数・各項目評価・コメント・写真（最大5枚）** を入力し、サーバーへ送信できるようにする。

## 2. 対象ファイル
- ReviewSheetView.swift（UI/画面）
- ReviewViewModel.swift（状態管理・API通信） ※別設計書

## 3. 画面仕様（UI）
### 3.1 画面タイトル
- NavigationTitle: `place.name`

### 3.2 入力項目
- 総評スコア（Double）
  - Slider: 0.0〜5.0（step 0.5）
  - Menu内 Picker: 現在の 0.5 刻み帯に対して 0.1 刻み調整（例：3.0〜3.9）
- 味（SegmentedPicker）
- コスパ（SegmentedPicker）
- 接客（SegmentedPicker）
- 雰囲気（SegmentedPicker）
  - 表示選択肢：`["-","⭐️1","⭐️2","⭐️3","⭐️4","⭐️5"]`
- 口コミコメント
  - TextEditor（高さ min 120）
- 写真（任意）
  - PhotosPickerで追加、最大5枚
  - 横スクロールでサムネイル表示
  - サムネイル右上の × で削除可能

### 3.3 ボタン
- キャンセル：dismiss()
- 送信：`submit()` を実行（Taskでasync処理）
- 送信中：ProgressView 表示（vm.isLoading）

### 3.4 エラー表示
- `vm.errorMessage` があれば赤文字で表示

## 4. 画面の振る舞い（ライフサイクル）
### 4.1 画面表示時に走る非同期処理
#### 既存口コミの取得
- 条件：`isReviewed == true`
- `GetReviewedDetail(place: place)` で実行
- `fetchReviewedPhotosByApplePlace(place: place)` で実行
- 取得成功時、`vm.apply(existing:)` により入力欄へ反映

### 4.2 画面表示開始以降、特定のStateの変化を監視（初回実行なし）
#### 写真選択の反映
- `.onChange(of: pickerItems)` で画像を `UIImage` に変換し `selectedImages` に追記
- 最大5枚に丸める：`prefix(5)`

## 5. 送信フロー
- submit()
  1. `vm.submitReview(place:)` で口コミ（JSON）送信
  2. 成功した場合、`selectedImages` があれば `vm.uploadPhotos(place:images:)` で画像送信（multipart）
  3. `fetchReviewedRestaurants()` でレビュー済み一覧を再取得し `reviewedList` 更新
  4. `onSubmitted?()` で親へ通知
  5. dismiss()

## 6. API（画面側が呼ぶもの）
### 6.1 既存口コミ取得
- POST `https://moguroku.com/reviewRestaurant/get`
- Authorization: Bearer token（UserDefaults "token"）
- Body: ApplePlace（JSON）
- Response: `ReviewedRestaurantDetailResponse` を decode

### 6.2 レビュー済み一覧取得
- GET `https://moguroku.com/reviewRestaurant/list`
- Authorization: Bearer token
- Response: `ReviewedRestaurantListResponse` を decode
- `reviewedList` を更新

## 関数仕様（詳細）

### 1. `submit() async`
**所属**：`ReviewSheetView`  
**目的**：口コミ送信 →（任意）写真送信 → 画面表示データ再取得 → 親通知 → dismiss までを一連で行う。  
**呼び出し契機**：UI「送信」ボタン押下（`Task { await submit() }`）  
**入力**：なし（Viewの `place`, `selectedImages`, `vm`, `reviewedList` など状態を参照）  
**出力**：なし（副作用で状態更新・画面遷移）

**前提条件**
- `vm.submitReview(place:)` が成功すると `restaurantId` が返る（失敗時は `nil`）。
- 画像送信は `selectedImages` が空でない場合のみ実行する。

**処理手順**
1. `vm.submitReview(place: place)` を実行し、`restaurantId` を取得する  
   - `restaurantId == nil` の場合は終了（以降の処理は実施しない）
2. `selectedImages` が空でない場合、`vm.uploadPhotos(place: place, images: selectedImages)` を実行する  
   - 失敗時は「画像だけ失敗」などの表示を行う余地がある（現状コメントのみ）
3. `fetchReviewedRestaurants()` を実行し、レビュー済み一覧を更新する
4. `fetchReviewedPhotos(restaurantId)` を実行し、レビュー写真一覧を更新する
5. `onSubmitted?()` を呼び出し、親画面へ「送信完了」を通知する
6. `dismiss()` を呼び出し、シートを閉じる

**更新される状態（副作用）**
- `reviewedList`（`fetchReviewedRestaurants()` により更新）
- `reviewedPhotos`（`fetchReviewedPhotos()` により更新）
- 画面遷移：シート閉じる（dismiss）

**エラー/例外**
- 各ネットワーク関数の失敗時は内部でログ出力し、基本的に silent failure（画面維持 or 途中終了）
- 画像送信だけ失敗のハンドリングは今後UI要件で追加可能


---

### 2. `GetReviewedDetail(place: ApplePlace) async`
**所属**：`ReviewSheetView`  
**目的**：既存口コミ（スコア・各項目・コメント）を取得し、入力欄へ反映する（編集モード初期化）。  
**呼び出し契機**：`.task { ... }`（`isReviewed == true` のとき）  
**入力**：`place: ApplePlace`  
**出力**：なし（副作用で `vm` の入力値を更新）

**使用API**
- `POST https://moguroku.com/reviewRestaurant/get`
- Header:
  - `Authorization: Bearer {token}`
  - `Content-Type: application/json`
- Body: `place` を JSON で送信
- Response: `ReviewedRestaurantDetailResponse`

**前提条件**
- `UserDefaults("token")` が存在すること（無ければ処理終了）

**処理手順**
1. `token` を取得（無ければログ出力して終了）
2. URL を生成（失敗時はログ出力して終了）
3. `URLRequest` を作成し、`POST` + ヘッダー設定
4. `place` を JSON エンコードし `httpBody` に設定（失敗時は終了）
5. `URLSession.shared.data(for:)` で通信
6. `response` が `HTTPURLResponse` でなければ終了
7. `statusCode == 401` の場合は認証エラーとして終了
8. `statusCode != 200` の場合は `URLError(.badServerResponse)` を投げて catch へ
9. `ReviewedRestaurantDetailResponse` にデコード
10. `result.reviewedDetail` を取り出し `vm.apply(existing:)` で入力欄へ反映

**更新される状態（副作用）**
- `vm.score`
- `vm.tasteIndex`
- `vm.costPerfIndex`
- `vm.serviceIndex`
- `vm.atmosphereIndex`
- `vm.comment`

**エラー/例外**
- エンコード失敗、通信失敗、デコード失敗、ステータス不正はログ出力のみ（現状UI表示なし）


---

### 3. `fetchReviewedRestaurants() async`
**所属**：`ReviewSheetView`  
**目的**：ユーザーの「レビューしたマイレストラン一覧」を再取得し、画面状態（`reviewedList`）を更新する。  
**呼び出し契機**：
- `submit()` 成功後の再取得
- （必要なら他画面の再同期にも利用可能）

**使用API**
- `GET https://moguroku.com/reviewRestaurant/list`
- Header:
  - `Authorization: Bearer {token}`
  - `Accept: application/json`
- Response: `ReviewedRestaurantListResponse`

**前提条件**
- `UserDefaults("token")` が存在すること

**処理手順**
1. `token` を取得（無ければ終了）
2. URL を生成（失敗時は終了）
3. `URLRequest` を作成し、`GET` + ヘッダー設定
4. `URLSession` で通信し `data/response` を取得
5. `response` が `HTTPURLResponse` でなければ終了
6. `statusCode == 401` は認証エラーとして終了
7. `statusCode != 200` は `URLError(.badServerResponse)` を投げて catch へ
8. `ReviewedRestaurantListResponse` にデコード
9. `result.userReviewedList` を `reviewedList` に反映（メインスレッド）

**更新される状態（副作用）**
- `reviewedList: [ReviewedRestaurant]`

**エラー/例外**
- 失敗時はログ出力のみ  
- UIエラー表示が必要なら、ViewModel 側に `errorMessage` を持たせる等の設計に拡張可能


---

### 4. `fetchReviewedPhotos(_ restaurantId: Int) async`
**所属**：`ReviewSheetView`  
**目的**：restaurantId をキーに「レビュー写真一覧」を取得し、`reviewedPhotos` を更新する。  
**呼び出し契機**：`submit()` 成功後（restaurantId が確定した後）  
**入力**：`restaurantId: Int`  
**出力**：なし（副作用で `reviewedPhotos` 更新）

**使用API**
- `GET https://moguroku.com/photorestaurant/reviewedphotos?restaurantId={id}`
- Header:
  - `Authorization: Bearer {token}`
  - `Accept: application/json`
- Response: `ReviewedPhotosResponse`

**前提条件**
- `UserDefaults("token")` が存在すること
- URLComponents でクエリ `restaurantId` を付与できること

**処理手順**
1. token 取得（無ければ終了）
2. URLComponents で URL 生成（失敗時は終了）
3. `URLRequest` を作成し、`GET` + ヘッダー設定
4. 通信して `HTTPURLResponse` を取得（無ければ終了）
5. `401` は認証エラーとして終了
6. `200..<300` 以外はログ出力して終了
7. `ReviewedPhotosResponse` にデコード
8. `reviewedPhotos = result.photos` を MainActor で反映

**更新される状態（副作用）**
- `reviewedPhotos: [ReviewedPhoto]`

**エラー/例外**
- ステータス不正・デコード失敗・通信失敗はログ出力のみ


---

### 5. `fetchReviewedPhotosByApplePlace(place: ApplePlace) async`
**所属**：`ReviewSheetView`  
**目的**：ApplePlace をキーに「レビュー写真一覧」を取得し、URLを絶対URLに補正した上で `reviewedPhotos` を更新する。  
**呼び出し契機**：`.task { ... }`（編集モード初期化時）  
**入力**：`place: ApplePlace`  
**出力**：なし（副作用で `reviewedPhotos` 更新）

**使用API**
- `POST https://moguroku.com/photorestaurant/reviewedphotosbyappleplace`
- Header:
  - `Authorization: Bearer {token}`
  - `Content-Type: application/json`
- Body: `place` を JSON で送信
- Response: `ReviewedPhotosResponse`

**前提条件**
- `UserDefaults("token")` が存在すること

**処理手順**
1. token 取得（無ければ終了）
2. URL 生成（失敗時は終了）
3. `URLRequest` を作成し、`POST` + ヘッダー設定
4. `place` を JSON エンコードして `httpBody` に設定（失敗時は終了）
5. 通信して `HTTPURLResponse` を取得（無ければ終了）
6. `401` は認証エラーとして終了
7. `200..<300` 以外はログ出力して終了（throwしない）
8. `ReviewedPhotosResponse` にデコード
9. 返却された `photos` を絶対URLへ補正
   - `photoUrl = "https://moguroku.com/" + p.photoUrl`
10. `reviewedPhotos = fixed` を MainActor で反映

**更新される状態（副作用）**
- `reviewedPhotos: [ReviewedPhoto]`（URL補正済み）

**エラー/例外**
- エンコード失敗・通信失敗・デコード失敗はログ出力のみ
- 200台以外は throw せず return（デバッグしやすい方針）

## 7. Mermaid（画面フロー）
```mermaid
sequenceDiagram
  autonumber
  actor U as User
  participant V as ReviewSheetView
  participant VM as ReviewViewModel
  participant API as Server API

  Note over V: 画面表示
  V->>V: .task (isReviewed==true?)
  alt isReviewed == true
    V->>API: POST /reviewRestaurant/get (place)
    API-->>V: ReviewedRestaurantDetailResponse
    V->>VM: apply(existing)
  else isReviewed == false
    V-->>V: 取得なし
  end

  U->>V: 入力（スコア/各項目/コメント/写真）
  U->>V: 送信ボタン
  V->>VM: submitReview(place)
  VM->>API: POST /reviewrestaurant/add (ReviewRequest)
  API-->>VM: 2xx or Error

  alt submitReview 成功
    alt 写真あり
      V->>VM: uploadPhotos(place, images)
      loop 画像を1枚ずつ
        VM->>API: POST /photorestaurant/upload (multipart)
        API-->>VM: 2xx or Error
      end
    else 写真なし
      V-->>V: 写真送信スキップ
    end

    V->>V: fetchReviewedRestaurants()
    V->>API: GET /reviewRestaurant/list
    API-->>V: ReviewedRestaurantListResponse
    V-->>V: reviewedList 更新
    V-->>V: onSubmitted?()
    V-->>V: dismiss()
  else submitReview 失敗
    V-->>V: vm.errorMessage 表示
  end