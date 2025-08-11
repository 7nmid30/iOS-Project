//
//  LoginView.swift
//  Project
//
//  Created by 高見聡 on 2025/07/19.
//

import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    
    @Binding var favorites: [FavoriteRestaurant]
    
    @Environment(\.dismiss) var dismiss

    var body: some View {

        NavigationStack {
            
            VStack {
                Spacer()
                
                VStack(spacing: 16) {
                    Text("ログイン")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    VStack(spacing: 12) {
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(radius: 2)
                        
                        SecureField("Password", text: $password)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(radius: 2)
                    }
                    
                    Button(action: {
                        login()
                        Task {
                            await fetchMyRestaurants()
                        }
                    }) {
                        HStack {
                            Image(systemName: "lock.open.fill")
                            Text("ログイン")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(radius: 3)
                    }
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    NavigationLink("アカウントを作成する", destination: RegisterView())
                        .font(.footnote)
                        .foregroundColor(.blue)
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(20)
                .shadow(radius: 10)
                .padding(.horizontal, 32)
                
                Spacer()
            }
        }
    }

    func login() {
        guard let url = URL(string: "https://moguroku.com/api/auth/login") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let body = ["email": email, "password": password]//これは辞書型（[String: String]）
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "通信エラー: \(error.localizedDescription)"
                }
                return
            }

            guard let data = data else { return }

            if let result = try? JSONDecoder().decode(LoginResponse.self, from: data) {
                UserDefaults.standard.set(result.token, forKey: "token")
                DispatchQueue.main.async {
                    isLoggedIn = true
                }
            } else {
                DispatchQueue.main.async {
                    self.errorMessage = "認証失敗：メールアドレスまたはパスワードが間違っています"
                }
            }
        }.resume()
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

struct LoginResponse: Decodable {
    let token: String
}
