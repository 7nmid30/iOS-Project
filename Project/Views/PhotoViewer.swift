//
//  PhotoViewer.swift
//  Project
//
//  Created by 高見聡 on 2026/02/21.
//

import SwiftUI

// MARK: - 写真アイテム（remote/localを同じ配列で扱う）
enum PhotoItem: Identifiable {
    case remote(URL)
    case local(UIImage)

    var id: String {
        switch self {
        case .remote(let url):
            return "r:\(url.absoluteString)"
        case .local:
            return "l:\(UUID().uuidString)" // 閲覧用途なので毎回変わってOK
        }
    }
}

// MARK: - 写真ビューア（横スワイプで切替）
struct PhotoViewer: View {
    let items: [PhotoItem]
    let startIndex: Int
    @Environment(\.dismiss) private var dismiss
    @State private var index: Int

    init(items: [PhotoItem], startIndex: Int) {
        self.items = items
        self.startIndex = startIndex
        _index = State(initialValue: startIndex)
    }

    var body: some View {
        NavigationStack {
            TabView(selection: $index) {
                ForEach(Array(items.enumerated()), id: \.offset) { i, item in
                    ZoomablePage(item: item)
                        .tag(i)
                        .background(Color.black)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .background(Color.black)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("閉じる") { dismiss() }
                }
                ToolbarItem(placement: .principal) {
                    Text("\(index + 1)/\(max(items.count, 1))")
                        .foregroundStyle(.white)
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.black, for: .navigationBar)
        }
    }
}

// MARK: - 1枚をズーム可能に表示（remoteはURL→UIImage取得してズーム）
struct ZoomablePage: View {
    let item: PhotoItem

    @State private var remoteImage: UIImage? = nil
    @State private var failed = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch item {
            case .local(let uiImage):
                ZoomableImage(uiImage: uiImage)

            case .remote(let url):
                if let img = remoteImage {
                    ZoomableImage(uiImage: img)
                } else if failed {
                    Image(systemName: "photo")
                        .foregroundStyle(.white)
                } else {
                    ProgressView().tint(.white)
                        .task {
                            await loadRemote(url: url)
                        }
                }
            }
        }
    }

    private func loadRemote(url: URL) async {
        // 二重ロード防止
        if remoteImage != nil || failed { return }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse,
                  (200..<300).contains(http.statusCode),
                  let img = UIImage(data: data) else {
                failed = true
                return
            }
            remoteImage = img
        } catch {
            failed = true
        }
    }
}

// MARK: - UIScrollViewベースのズームビュー（ピンチ/ダブルタップ）
struct ZoomableImage: UIViewRepresentable {
    let uiImage: UIImage

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.backgroundColor = .black
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 4.0
        scrollView.delegate = context.coordinator
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false

        let imageView = UIImageView(image: uiImage)
        imageView.contentMode = .scaleAspectFit
        imageView.frame = scrollView.bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scrollView.addSubview(imageView)
        context.coordinator.imageView = imageView

        // ダブルタップでズーム
        let doubleTap = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleDoubleTap(_:))
        )
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)

        return scrollView
    }

    func updateUIView(_ uiView: UIScrollView, context: Context) {
        context.coordinator.imageView?.image = uiImage
        // 必要ならここで zoomScale を戻す処理も可能（今は何もしない）
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject, UIScrollViewDelegate {
        weak var imageView: UIImageView?

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            imageView
        }

        @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
            guard let scrollView = gesture.view as? UIScrollView else { return }
            if scrollView.zoomScale > 1.0 {
                scrollView.setZoomScale(1.0, animated: true)
            } else {
                scrollView.setZoomScale(2.5, animated: true)
            }
        }
    }
}
