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

    private var hasSource: Bool {
        #if canImport(AmigoFaceSwapSDK)
        return engine.targetLatent != nil
        #else
        return sourceImage != nil
        #endif
    }

    var body: some View {
        ZStack {
            realtimeView
                .ignoresSafeArea()

            VStack {
                HStack(alignment: .top) {
                    Label("FaceLive AI", systemImage: "face.smiling")
                        .font(.headline)
                        .padding(10)
                        .background(.black.opacity(0.72))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    Spacer()

                    Text(engine.status)
                        .font(.caption)
                        .multilineTextAlignment(.trailing)
                        .padding(10)
                        .background(.black.opacity(0.72))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .frame(maxWidth: 230, alignment: .trailing)
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
                    Text("FaceLive xử lý live trực tiếp trên iPhone ở 512px.")
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
                    .disabled(engine.isBusy)

                Button {
                    Task {
                        await engine.initialize(apiKey: apiKey)
                        if engine.isInitialized {
                            apiKey = ""
                        }
                    }
                } label: {
                    HStack {
                        if engine.isBusy {
                            ProgressView().tint(.white)
                            Text("ĐANG KHỞI TẠO…")
                        } else {
                            Image(systemName: "bolt.fill")
                            Text("KHỞI TẠO FACE AI")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || engine.isBusy ? .gray : .green)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || engine.isBusy)
                .padding(.horizontal)
            } else {
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    HStack {
                        if engine.isBusy {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: hasSource ? "photo.on.rectangle" : "photo.badge.plus")
                        }
                        Text(engine.isBusy ? "ĐANG NHẬN DIỆN ẢNH…" : (hasSource ? "ĐỔI ẢNH MẪU" : "CHỌN ẢNH MẪU"))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(engine.isBusy ? .gray : .blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(engine.isBusy)
                .padding(.horizontal)
                .onChange(of: selectedPhoto) { item in
                    Task {
                        guard let item,
                              let data = try? await item.loadTransferable(type: Data.self),
                              let image = UIImage(data: data) else {
                            return
                        }

                        let enrolled = await engine.enroll(sourceImage: image)
                        if enrolled {
                            sourceImage = image
                        }
                    }
                }

                if hasSource {
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
                    .disabled(engine.isBusy)
                    .padding(.horizontal)
                }
            }
        }
        .padding(.bottom, 12)
    }
}
