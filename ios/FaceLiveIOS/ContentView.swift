import SwiftUI
import AVFoundation
import PhotosUI

struct ContentView: View {
    @StateObject private var camera = CameraModel()
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var sourceImage: UIImage?

    var body: some View {
        ZStack {
            CameraPreview(session: camera.session)
                .ignoresSafeArea()
            VStack {
                HStack {
                    Text("FaceLive AI")
                        .font(.headline).padding(10)
                        .background(.black.opacity(0.7))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    Spacer()
                    Text(camera.status)
                        .font(.caption).padding(10)
                        .background(.black.opacity(0.7))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                Spacer()
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Text(sourceImage == nil ? "CHỌN ẢNH MẪU" : "ĐỔI ẢNH MẪU")
                        .frame(maxWidth: .infinity).padding()
                        .background(.blue).foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding()
            }
        }
        .task {
            camera.start()
        }
        .onChange(of: selectedPhoto) { _, item in
            Task {
                if let data = try? await item?.loadTransferable(type: Data.self), let data,
                   let image = UIImage(data: data) {
                    sourceImage = image
                    camera.setSourceImage(image)
                }
            }
        }
    }
}
