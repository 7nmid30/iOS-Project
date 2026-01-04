# 口コミ機能 設計書（ReviewViewModel）

## 1. 目的
ReviewSheetView から利用される ViewModel として、以下を担当する。

- 入力状態（スコア・各評価・コメント）
- 既存レビューの反映
- 口コミ送信（JSON）
- 写真送信（multipart/form-data）

## 2. 対象ファイル
- `ReviewViewModel.swift`

## 3. 責務（Responsibilities）
- 画面入力値の保持（`@Published`）
- サーバーから取得した既存レビューを入力欄に反映（`apply`）
- スコアの丸め補助（0.5刻み）
- 口コミ送信 API 呼び出し（`submitReview`）
- 写真アップロード API 呼び出し（`uploadPhotos`）
- エラー状態保持（`errorMessage`）

## 4. 状態（State）
- `score: Double`（初期値 3.0）
- `tasteIndex: Int`（初期値 0）
- `costPerfIndex: Int`（初期値 0）
- `serviceIndex: Int`（初期値 0）
- `atmosphereIndex: Int`（初期値 0）
- `comment: String`（初期値 ""）
- `isLoading: Bool`（初期値 false）※現状は利用コメントアウト気味
- `errorMessage: String?`（初期値 nil）

## 5. 入力選択肢（Options）
- `levelOptions`: `["-","⭐️1","⭐️2","⭐️3","⭐️4","⭐️5"]`
- `onesPlaceOptions` / `firstDecimalOptions` は現状未使用（過去案の名残）

## 6. 関数仕様

### 6.1 `apply(existing:)`
**目的**：既存レビュー情報を ViewModel の入力欄へ反映  
**入力**：`ReviewedRestaurantDetail`  
**処理**：
- `totalScore` → `score`
- `taste` / `costPerformance` / `service` / `atmosphere` → 各Index
- `comment` → `comment`

### 6.2 `roundToHalf(_:)`
**目的**：`Double` を 0.5 刻みに丸める（Slider/詳細Picker用）  
**定義**：
- `(v * 2).rounded() / 2.0`

### 6.3 `submitReview(place:)`
**目的**：口コミ（JSON）をサーバーへ送る  
**入力**：`ApplePlace`  
**出力**：`Bool`（成功 `true` / 失敗 `false`）

**前提**：
- `UserDefaults("token")` が存在すること（なければ `false`）
- エンドポイント：`POST https://moguroku.com/reviewrestaurant/add`

**HTTP**：
- Header
  - `Content-Type: application/json`
  - `Accept: application/json`
  - `Authorization: Bearer {token}`
- Body
  - `ReviewRequest(place, score, taste, costPerformance, service, atmosphere, comment)`

**レスポンス処理**：
- `401`：認証エラー → `false`
- `2xx`：成功 → `true`
- それ以外：
  - `ErrorResponse { error, details? }` として decode できれば `errorMessage` に反映
  - decode できなければ `errorMessage = "不明なサーバーエラー (status)"`

### 6.4 `uploadPhotos(place:images:)`
**目的**：写真を `multipart/form-data` でサーバーへ送る（最大5枚想定、制限は呼び出し側）  
**入力**：
- `place: ApplePlace`
- `images: [UIImage]`  
**出力**：`Bool`（成功 `true` / 失敗 `false`）

**前提**：
- `images` が空なら `true`（成功扱い）
- `UserDefaults("token")` が存在すること（なければ `false`）
- エンドポイント：`POST https://moguroku.com/photorestaurant/upload`

**HTTP**：
- Header
  - `Accept: application/json`
  - `Authorization: Bearer {token}`
  - `Content-Type: multipart/form-data; boundary=...`
- Body（画像1枚ごとに別リクエスト）
  - part1: `place`（`application/json`）
  - part2: `File`（`image/jpeg`）

**レスポンス処理**：
- `401`：認証エラー → `false`
- `2xx`：その画像は成功 → 次へ
- それ以外：`ErrorResponse` decode を試み、失敗時は本文ログ → `false`

## 7. Mermaid（ViewModel内部の送信シーケンス）
```mermaid
sequenceDiagram
  autonumber
  participant V as ReviewSheetView
  participant VM as ReviewViewModel
  participant UD as UserDefaults
  participant API as Server API

  V->>VM: submitReview(place)
  VM->>UD: token取得
  alt tokenなし
    VM-->>V: false
  else tokenあり
    VM->>API: POST /reviewrestaurant/add (JSON ReviewRequest)
    alt 2xx
      VM-->>V: true
    else 401
      VM-->>V: false（認証）
    else error
      VM-->>V: false（errorMessage設定）
    end
  end

  V->>VM: uploadPhotos(place, images)
  alt images空
    VM-->>V: true
  else imagesあり
    VM->>UD: token取得
    loop 各画像
      VM->>API: POST /photorestaurant/upload (multipart)
      alt 2xx
        VM-->>V: continue
      else error/401
        VM-->>V: false
        break
      end
    end
    VM-->>V: true（全画像成功時）
  end