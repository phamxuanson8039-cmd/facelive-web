import SwiftUI
import PhotosUI
import UIKit

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
                        .multilineTextAlignment(.trailing)
                        .padding(10)
                        .background(.black.opacity(0.7))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                Spacer()
                controls
            }
            .padding(.top, 6)
        }
    }

    @ViewBuilder
    private var realtimeView: some View {
        #if canImport(AmigoFaceSwapSDK)
        if let latent = engine.targetLatent {
            AmigoLiveCameraView(targetLatent: latent)
        } else {
            Color.black.overlay(
                VStack(spacing: 12) {
                    Image(systemName: "camera.fill")
                        .font(.largeTitle)
                    Text(engine.isInitialized ? "Chọn ảnh mẫu để bắt đầu" : "Khởi tạo Face AI trước")
                        .font(.headline)
                    Text("FaceLive xử lý live trực tiếp trên iPhone.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding()
            )
        }
        #else
        Color.black.overlay(Text("FaceSwap SDK chưa được thêm vào Xcode").foregroundStyle(.white))
        #endif
    }

    private var controls: some View {
        VStack(spacing: 10) {
            if !engine.isInitialized {
                SecureField("API key Face AI", text: $apiKey)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.done)

                Button {
                    Task {
                        await engine.initialize(apiKey: apiKey)
                    }
                } label: {
                    HStack {
                        Image(systemName: "bolt.fill")
                        Text("KHỞI TẠO FACE AI")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .green)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .padding(.horizontal)
            } else {
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    HStack {
                        Image(systemName: sourceImage == nil ? "photo.badge.plus" : "photo.on.rectangle")
                        Text(sourceImage == nil ? "CHỌN ẢNH MẪU" : "ĐỔI ẢNH MẪU")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal)
                .onChange(of: selectedPhoto) { item in
                    Task {
                        guard let item,
                              let data = try? await item.loadTransferable(type: Data.self),
                              let image = UIImage(data: data) else {
                            return
                        }
                        sourceImage = image
                        await engine.enroll(sourceImage: image)
                    }
                }

                if sourceImage != nil {
                    Button(role: .destructive) {
                        selectedPhoto = nil
                        sourceImage = nil
                        engine.resetSource()
                    } label: {
                        HStack {
                            Image(systemName: "xmark.circle")
                            Text("BỎ ẢNH MẪU")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding(.bottom, 12)
    }
}
