import Foundation
import UIKit

#if canImport(AmigoFaceSwapSDK)
import AmigoFaceSwapSDK
#endif

@MainActor
final class FaceSwapEngine: ObservableObject {
    @Published var status = "Chưa khởi tạo Face AI"
    @Published private(set) var targetLatent: FaceLatent?
    @Published private(set) var isInitialized = false

    func setStatus(_ value: String) {
        status = value
    }

    func initialize(apiKey: String) async {
        guard !isInitialized else { return }
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            status = "Hãy nhập API key Face AI"
            return
        }

        #if canImport(AmigoFaceSwapSDK)
        do {
            status = "Đang khởi tạo Face AI…"
            try await AmigoFaceSwap.initialize(apiKey: apiKey) { progress in
                let percent = Int(progress * 100)
                Task { @MainActor [weak self] in
                    self?.status = "Đang tải model Face AI… \(percent)%"
                }
            }
            isInitialized = true
            status = "Face AI đã sẵn sàng"
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
        do {
            status = "Đang nhận diện khuôn mặt mẫu…"
            targetLatent = try await AmigoFaceSwap.enrollFace(from: sourceImage)
            status = "Face AI sẵn sàng — camera live"
        } catch {
            status = "LỖI ảnh mẫu: \(error.localizedDescription)"
        }
        #else
        status = "Chưa thêm AmigoFaceSwapSDK vào Xcode"
        #endif
    }

    func resetSource() {
        targetLatent = nil
        status = isInitialized ? "Đã khởi tạo — hãy chọn ảnh mẫu" : "Chưa khởi tạo Face AI"
    }
}
