# FaceLive 512-Live Native Route

## Why this route

The official `inswapper-512-live` project documents an on-device iOS live face-swap app based on the 512-live model. The public model repository does not publish the model weights for direct Safari embedding; licensing/support is directed to InsightFace/Picsi.Ai.

For FaceLive, the practical native route is an iOS wrapper using AmigoFaceSwapSDK. Its public SDK documentation describes CoreML on-device processing, 512px output, a reusable `FaceLatent`, and a per-frame `processFrame()` API suitable for WebRTC/custom pipelines.

## Native flow

1. Add `AmigoFaceSwapSDK` with Swift Package Manager.
2. Initialize once with the developer API key stored outside the repository.
3. Enroll the selected source photo once to produce a `FaceLatent`.
4. Feed the front-camera `CVPixelBuffer` frames into `AmigoLiveCameraView` or `processFrame()`.
5. Render/stream the processed 512px frames.

## SwiftUI skeleton

```swift
import SwiftUI
import AmigoFaceSwapSDK

struct FaceLiveView: View {
    let targetLatent: FaceLatent

    var body: some View {
        AmigoLiveCameraView(targetLatent: targetLatent)
            .ignoresSafeArea()
    }
}
```

## Source enrollment skeleton

```swift
let latent = try await AmigoFaceSwap.enrollFace(from: sourcePhoto)
```

## Important

Do not commit an API key to this repository. The GitHub Pages version remains browser-based. A native iOS build requires an iOS build environment and signing; GitHub Pages cannot execute Swift/CoreML inside Safari.

## Current browser fallback

The web version keeps MediaPipe dense tracking plus the existing remote AI swap. This is intentionally labeled as a hybrid fallback and is not represented as true 30fps on-device inference.
