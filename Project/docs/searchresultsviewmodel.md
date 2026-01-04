# SearchResultsViewModel 設計書

## 1. 概要
SearchResultsView から呼び出される「お気に入り登録/解除」などの API 呼び出しを担当する ViewModel。

責務
- お気に入り登録（favRestaurant）
- お気に入り削除（removeRestaurant）
- （将来）レビュー取得/送信などの検索結果画面周辺ロジック

---

## 2. クラス定義
- クラス名: `SearchResultsViewModel`
- 属性: `@MainActor`（UI更新が絡む場合は MainActor に寄せる）
- 準拠: `ObservableObject`

---

## 3. 公開プロパティ

| 名前 | 型 | 役割 |
|---|---|---|
| errorMessage | String?（@Published） | UIへ表示するエラーメッセージ（現状はprint運用でも可） |
| isLoading | Bool（@Published） | 通信中フラグ（必要なら） |

※現行のView側は print しかしていないが、設計としてはエラーを View へ返せるようにしておく。

---

## 4. 依存（トークン/通信）
- token: `UserDefaults.standard.string(forKey: "token")`
- 通信: `URLSession`（async/await または completion）

改善提案
- token 取得を共通化（AuthStore / TokenProvider）
- URL/Path を enum で定義し散らばりを防止

---

## 5. 公開メソッド

### 5.1 favRestaurant(place:completion:)
#### 目的
指定した place をお気に入り登録する。

#### 入力
- place: ApplePlace
- completion: (Bool) -> Void（成功/失敗）

#### 処理フロー（例）
1. token を取得（なければ失敗）
2. URL を生成（例: `POST https://moguroku.com/FavoriteRestaurant/add` 等）
3. リクエスト作成
   - Authorization: Bearer token
   - Content-Type: application/json
4. body に place 情報（ApplePlaceDto 等）を encode
5. レスポンスを判定
   - 200~299: success
   - 401: 認証エラー
   - その他: failure
6. completion を呼ぶ

#### 出力
- completion(true/false)

---

### 5.2 removeRestaurant(name:completion:)
#### 目的
指定した店舗名をお気に入りから削除する。

#### 入力
- name: String
- completion: (Bool) -> Void

#### 処理フロー（例）
1. token を取得
2. URL を生成（例: `POST https://moguroku.com/FavoriteRestaurant/delete` 等）
3. リクエスト作成
   - Authorization: Bearer token
   - Content-Type: application/x-www-form-urlencoded もしくは json
4. body に name（または restaurantId）をセット
5. レスポンス判定 → completion

---

### 5.3 （将来）GetReviewedDetail(place:)
#### 目的
レビュー済みの場合に既存レビュー詳細を取得し、ReviewSheetView の初期値に反映する。

#### 入力
- place: ApplePlace

#### 出力
- ReviewedDetail（モデル） or ViewModel 内 Published に保持

---

## 6. エラーハンドリング方針
- token 無し: `errorMessage = "認証情報がありません"`
- URL 不正: `errorMessage = "URLが不正です"`
- 401: `errorMessage = "認証エラー"`
- decode 失敗/通信失敗: `errorMessage = error.localizedDescription`

View 側では
- とりあえず print
- 余裕が出たら Alert 表示などに拡張

---

## 7. ログ方針
- デバッグ時はレスポンス文字列をログに出す（本番は抑制）
- API 失敗時は statusCode と body を出すと原因追いやすい

---

## 8. テスト観点（最低限）
- token なしで fav/remove を呼ぶ → false になる
- 401 が返る → errorMessage 設定 + false
- 200 が返る → true
- サーバーエラー（500） → false