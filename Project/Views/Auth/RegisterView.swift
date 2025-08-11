//
//  RegisterView.swift
//  Project
//
//  Created by 高見聡 on 2025/07/19.
//

import SwiftUI

struct RegisterView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var registrationSuccess = false
    @State private var errorMessage = ""

    var body: some View {
        VStack(spacing: 16) {
            Text("アカウント作成")
                .font(.title)
                .bold()

            TextField("Email", text: $email)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)

            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)

            SecureField("Confirm Password", text: $confirmPassword)
                .textFieldStyle(.roundedBorder)

            Button("登録する") {
                register()
            }
            .buttonStyle(.borderedProminent)

            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            // 登録成功時に表示（または別画面に遷移させてもOK）
            if registrationSuccess {
                Text("登録が完了しました。ログインしてください。")
                    .foregroundColor(.green)
                    .font(.caption)
            }
        }
        .padding()
    }

    func register() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "全ての項目を入力してください"
            return
        }

        guard password == confirmPassword else {
            errorMessage = "パスワードが一致しません"
            return
        }

        guard let url = URL(string: "https://moguroku.com/api/auth/register") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let body = ["email": email, "password": password]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "通信エラー: \(error.localizedDescription)"
                }
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else { return }

            DispatchQueue.main.async {
                if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                    self.registrationSuccess = true
                    self.errorMessage = ""
                } else {
                    self.errorMessage = "登録に失敗しました（\(httpResponse.statusCode)）"
                }
            }
        }.resume()
    }
}
