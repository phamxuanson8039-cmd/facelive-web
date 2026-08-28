import SwiftUI
import PhotosUI

#if canImport(AmigoFaceSwapSDK)
import AmigoFaceSwapSDK
#endif

struct ContentView: View {
    @StateObject private var engine = FaceSwapEngine()
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var sourceImage: UIImage?
    @State private var apiKey = ""

    var body: some View {
        ZStack {
            realtimeView
                .ignoresSafeArea()

            VStack {
                HStack {
                    Text("FaceLive AI")
                        .font(.headline)
                        .padding(10)
                        .background(.black.opacity(0.7))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    Spacer()
                    Text(engine.status)
                        .font(.caption)
                        .padding(10)
                        .background(.black.opacity(0.7))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                Spacer()
                controls
            }
        }
    }

    @ViewBuilder
    private var realtimeView: some View {
        #if canImport(AmigoFaceSwapSDK)
        if let latent = engine.targetLatent as? FaceLatent {
            AmigoLiveCameraView(targetLatent: latent)
        } else {
            Color.black.overlay(Text("Chọn ảnh mẫu để bắt đầu").foregroundStyle(.white))
        }
        #else
        Color.black.overlay(Text("FaceSwap SDK chưa được thêm vào Xcode").foregroundStyle(.white))
        #endif
    }

    private var controls: some View {
        VStack(spacing: 10) {
            SecureField("API key Face AI", text: $apiKey)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                Text(sourceImage == nil ? "CHỌN ẢNH MẪU" : "ĐỔI ẢNH MẪU")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal)
            .onChange(of: selectedPhoto) { _, item in
                Task {
                    guard let data = try? await item?.loadTransferable(type: Data.self),
                          let data,
                          let image = UIImage(data: data) else { return }
                    sourceImage = image
                    guard !apiKey.isEmpty else {
                        engine.status = "Hãy nhập API key trước"
                        return
                    }
                    await engine.enroll(sourceImage: image, apiKey: apiKey)
                }
            }
        }
        .padding(.bottom, 12)
    }
}
