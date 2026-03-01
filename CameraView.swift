

import SwiftUI
import AVFoundation

struct CameraView: UIViewControllerRepresentable {

    var brightnessHandler: (Float) -> Void

    func makeUIViewController(context: Context) -> CameraController {
        let controller = CameraController()
        controller.brightnessHandler = brightnessHandler
        return controller
    }

    func updateUIViewController(_ uiViewController: CameraController, context: Context) {}
}
