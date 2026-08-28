import Foundation
import UIKit

#if canImport(AmigoFaceSwapSDK)
import AmigoFaceSwapSDK
#endif

@MainActor
final class FaceSwapEngine: ObservableObject {
    @Published private(set) var status = "Chưa khởi tạo Face AI"
    @Published private(set) var targetLatent: Any?

    func enroll(sourceImage: UIImage, apiKey: String) async {
        #if canImport(AmigoFaceSwapSDK)
        do {
            status = "Đang khởi tạo Face AI…"
            try await AmigoFaceSwap.initialize(apiKey: apiKey)
            status = "Đang tạo khuôn mặt mẫu…"
            let latent = try await AmigoFaceSwap.enrollFace(from: sourceImage)
            targetLatent = latent
            status = "Face AI sẵn sàng"
        } catch {
            status = "LỖI Face AI: \(error.localizedDescription)"
        }
        #else
        status = "Chưa thêm AmigoFaceSwapSDK vào Xcode"
        #endif
    }
}
