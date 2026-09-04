import Foundation
import UIKit

#if canImport(AmigoFaceSwapSDK)
import AmigoFaceSwapSDK
#endif

@MainActor
final class FaceSwapEngine: ObservableObject {
    @Published var status = "Chưa khởi tạo Face AI"
    @Published private(set) var isInitialized = false
    @Published private(set) var isBusy = false

    #if canImport(AmigoFaceSwapSDK)
    @Published private(set) var targetLatent: FaceLatent?
    #endif

    func setStatus(_ value: String) {
        status = value
    }

    func initialize(apiKey: String) async {
        guard !isInitialized, !isBusy else { return }
        let key = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else {
            status = "Hãy nhập API key Face AI"
            return
        }

        #if canImport(AmigoFaceSwapSDK)
        isBusy = true
        defer { isBusy = false }
        do {
            status = "Đang khởi tạo Face AI…"
            try await AmigoFaceSwap.initialize(apiKey: key) { progress in
                let percent = max(0, min(100, Int(progress * 100)))
                Task { @MainActor [weak self] in
                    self?.status = "Đang tải model Face AI… \(percent)%"
                }
            }
            isInitialized = true
            status = "Face AI đã sẵn sàng — chọn ảnh mẫu"
        } catch {
            status = "LỖI khởi tạo: \(error.localizedDescription)"
        }
        #else
        status = "Chưa thêm AmigoFaceSwapSDK vào Xcode"
        #endif
    }

    func enroll(sourceImage: UIImage) async {
        guard isInitialized else {
            status = "Hãy khởi tạo Face AI trước"
            return
        }

        #if canImport(AmigoFaceSwapSDK)
        isBusy = true
        defer { isBusy = false }
        do {
            status = "Đang nhận diện khuôn mặt mẫu…"
            targetLatent = try await AmigoFaceSwap.enrollFace(from: sourceImage)
            status = "Face AI sẵn sàng — camera live 512px"
        } catch {
            targetLatent = nil
            status = "LỖI ảnh mẫu: \(error.localizedDescription)"
        }
        #else
        status = "Chưa thêm AmigoFaceSwapSDK vào Xcode"
        #endif
    }

    func resetSource() {
        #if canImport(AmigoFaceSwapSDK)
        targetLatent = nil
        #endif
        status = isInitialized ? "Đã khởi tạo — hãy chọn ảnh mẫu" : "Chưa khởi tạo Face AI"
    }
}
