//
//  SearchResultsViewModel.swift
//  Project
//
//  Created by 高見聡 on 2025/10/02.
//


import Foundation
import SwiftUI

@MainActor
final class SearchResultsViewModel: ObservableObject {

    func favRestaurant(place: ApplePlace, completion: @escaping (Bool) -> Void) {
        guard let token = UserDefaults.standard.string(forKey: "token") else {
            print("トークンがありません")
            completion(false)
            return
        }
        guard let url = URL(string: "https://moguroku.com/favoriteRestaurant/add") else {
            print("URLが不正です")
            completion(false)
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
            completion(false)
            return
        }

        URLSession.shared.dataTask(with: request) { _, response, error in
            Task { @MainActor in
                if let error = error {
                    print("通信エラー: \(error.localizedDescription)")
                    completion(false); return
                }
                guard let http = response as? HTTPURLResponse else {
                    print("HTTPレスポンスが不正です")
                    completion(false); return
                }
                if http.statusCode == 401 {
                    print("認証エラー（ログインが必要）")
                    completion(false); return
                }
                guard (200...299).contains(http.statusCode) else {
                    print("APIエラー: \(http.statusCode)")
                    completion(false); return
                }
                print("登録成功")
                completion(true)
            }
        }.resume()
    }

    //
    func removeRestaurant(place: ApplePlace, completion: @escaping (Bool) -> Void) {
        guard let token = UserDefaults.standard.string(forKey: "token") else {
            print("トークンがありません")
            completion(false)
            return
        }
        guard let url = URL(string: "https://moguroku.com/favoriteRestaurant/delete") else {
            print("URLが不正です")
            completion(false)
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
            completion(false)
            return
        }

        URLSession.shared.dataTask(with: request) { _, response, error in
            Task { @MainActor in
                if let error = error {
                    print("通信エラー: \(error.localizedDescription)")
                    completion(false); return
                }
                guard let http = response as? HTTPURLResponse else {
                    print("HTTPレスポンスが不正です")
                    completion(false); return
                }
                if http.statusCode == 401 {
                    print("認証エラー（ログインが必要）")
                    completion(false); return
                }
                guard (200...299).contains(http.statusCode) else {
                    print("APIエラー: \(http.statusCode)")
                    completion(false); return
                }
                print("削除成功")
                completion(true)
            }
        }.resume()
    }
    
    
    func ReviewAddRestaurant(place: ApplePlace, completion: @escaping (Bool) -> Void) {
        guard let token = UserDefaults.standard.string(forKey: "token") else {
            print("トークンがありません")
            completion(false)
            return
        }
        guard let url = URL(string: "https://moguroku.com/reviewRestaurant/add") else {
            print("URLが不正です")
            completion(false)
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
            completion(false)
            return
        }

        URLSession.shared.dataTask(with: request) { _, response, error in
            Task { @MainActor in
                if let error = error {
                    print("通信エラー: \(error.localizedDescription)")
                    completion(false); return
                }
                guard let http = response as? HTTPURLResponse else {
                    print("HTTPレスポンスが不正です")
                    completion(false); return
                }
                if http.statusCode == 401 {
                    print("認証エラー（ログインが必要）")
                    completion(false); return
                }
                guard (200...299).contains(http.statusCode) else {
                    print("APIエラー: \(http.statusCode)")
                    completion(false); return
                }
                print("登録成功")
                completion(true)
            }
        }.resume()
    }
    
    
}
