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
    @State private var showSettings = false

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
                header
                Spacer()
                controls
            }
            .padding(.top, 6)
        }
        .sheet(isPresented: $showSettings) {
            settingsView
                .presentationDetents([.medium])
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 10) {
            Label("FaceLive AI", systemImage: "face.smiling")
                .font(.headline)
                .padding(10)
                .background(.black.opacity(0.72))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(engine.status)
                    .font(.caption)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 230, alignment: .trailing)

                if engine.isInitialized {
                    Text("512 LIVE • ON-DEVICE")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.green)
                }
            }
            .padding(10)
            .background(.black.opacity(0.72))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            if engine.isInitialized {
                Button { showSettings = true } label: {
                    Image(systemName: "gearshape.fill")
                        .foregroundStyle(.white)
                        .padding(11)
                        .background(.black.opacity(0.72))
                        .clipShape(Circle())
                }
            }
        }
        .padding(.horizontal, 12)
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
                    Text(engine.isInitialized
                         ? "Ảnh mẫu sẽ được dùng để tạo FaceLatent. Sau đó camera chạy live 512px trực tiếp trên iPhone."
                         : "Sau khi khởi tạo, chọn một ảnh có khuôn mặt rõ và nhìn gần chính diện.")
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

                if engine.isBusy {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Đang tải model AI")
                                .font(.caption)
                            Spacer()
                            Text("\(Int(engine.progress * 100))%")
                                .font(.caption.monospacedDigit())
                        }
                        ProgressView(value: engine.progress)
                            .tint(.green)
                    }
                    .padding(.horizontal)
                }

                Button {
                    Task {
                        await engine.initialize(apiKey: apiKey)
                        if engine.isInitialized { apiKey = "" }
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

                Text("API key chỉ dùng để khởi tạo SDK trong phiên này và không được lưu vào app.")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
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
                            engine.setStatus("Không đọc được ảnh mẫu")
                            return
                        }

                        let enrolled = await engine.enroll(sourceImage: image)
                        if enrolled { sourceImage = image }
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
        .background(.black.opacity(0.76))
    }

    private var settingsView: some View {
        NavigationStack {
            Form {
                Section("FaceLive AI") {
                    LabeledContent("Trạng thái", value: engine.status)
                    LabeledContent("Chế độ", value: hasSource ? "512 LIVE • ON-DEVICE" : "Chưa có ảnh mẫu")
                }
                Section {
                    Button("Đóng") { showSettings = false }
                }
            }
            .navigationTitle("Cài đặt")
        }
    }
}
