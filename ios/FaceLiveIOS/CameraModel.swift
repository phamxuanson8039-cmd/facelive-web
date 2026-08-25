import Foundation
import AVFoundation
import UIKit
import Vision

final class CameraModel: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let session = AVCaptureSession()
    @Published var status = "Camera đang khởi động..."
    private let queue = DispatchQueue(label: "facelive.camera")
    private var sourceImage: UIImage?
    private var faceRequest: VNDetectFaceLandmarksRequest!

    func start() {
        guard AVCaptureDevice.authorizationStatus(for: .video) != .denied else {
            status = "Camera bị từ chối quyền"; return
        }
        AVCaptureDevice.requestAccess(for: .video) { [weak self] ok in
            guard let self else { return }
            DispatchQueue.main.async { self.status = ok ? "Đang nhận diện..." : "Cần quyền camera" }
            guard ok else { return }
            self.configure()
        }
    }

    func setSourceImage(_ image: UIImage) {
        sourceImage = image
        DispatchQueue.main.async { self.status = "Ảnh mẫu đã chọn — AI swap đang chờ engine" }
    }

    private func configure() {
        queue.async {
            self.session.beginConfiguration()
            self.session.sessionPreset = .hd1280x720
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
                  let input = try? AVCaptureDeviceInput(device: device), self.session.canAddInput(input) else { return }
            self.session.addInput(input)
            let output = AVCaptureVideoDataOutput()
            output.alwaysDiscardsLateVideoFrames = true
            output.setSampleBufferDelegate(self, queue: self.queue)
            guard self.session.canAddOutput(output) else { return }
            self.session.addOutput(output)
            self.session.commitConfiguration()
            self.session.startRunning()
        }
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let request = VNDetectFaceLandmarksRequest { [weak self] request, _ in
            let count = (request.results as? [VNFaceObservation])?.count ?? 0
            DispatchQueue.main.async { self?.status = count > 0 ? "Khuôn mặt đang được theo dõi" : "Đang tìm khuôn mặt..." }
        }
        let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: .leftMirrored, options: [:])
        try? handler.perform([request])
    }
}

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView(); view.videoPreviewLayer.session = session; view.videoPreviewLayer.videoGravity = .resizeAspectFill; return view
    }
    func updateUIView(_ uiView: PreviewView, context: Context) { uiView.videoPreviewLayer.session = session }
}

final class PreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var videoPreviewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
}
