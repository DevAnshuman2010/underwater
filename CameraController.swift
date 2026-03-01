import UIKit
import AVFoundation

class CameraController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    var videoDevice: AVCaptureDevice?
    var captureSession = AVCaptureSession()
    var previewLayer: AVCaptureVideoPreviewLayer!
    var brightnessHandler: ((Float) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }

    func setupCamera() {

        guard let device = AVCaptureDevice.default(for: .video) else {
            print("No camera available")
            return
        }

        do {
            videoDevice = device   

            let input = try AVCaptureDeviceInput(device: device)

            captureSession.beginConfiguration()

            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }

            let output = AVCaptureVideoDataOutput()
            output.setSampleBufferDelegate(self,
                                           queue: DispatchQueue(label: "videoQueue"))

            if captureSession.canAddOutput(output) {
                captureSession.addOutput(output)
            }

            captureSession.commitConfiguration()

            try device.lockForConfiguration()

            if device.isExposureModeSupported(.custom) {

                let minISO = device.activeFormat.minISO
                let iso = max(minISO, 30)

                let duration = CMTimeMake(value: 1, timescale: 1000)

                device.setExposureModeCustom(duration: duration,
                                             iso: iso,
                                             completionHandler: nil)
            }

            device.unlockForConfiguration()

            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.frame = view.bounds
            view.layer.addSublayer(previewLayer)

            DispatchQueue.global(qos: .userInitiated).async {
                if !self.captureSession.isRunning {
                    self.captureSession.startRunning()
                }
            }

        } catch {
            print("Camera setup error:", error)
        }
    }

    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)

        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else {
            CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
            return
        }

        let buffer = baseAddress.assumingMemoryBound(to: UInt8.self)

        var maxBrightness: Float = 0

        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        for y in stride(from: 0, to: height, by: 10) {
            for x in stride(from: 0, to: width, by: 10) {

                let offset = y * bytesPerRow + x * 4

                let r = Float(buffer[offset])
                let g = Float(buffer[offset + 1])
                let b = Float(buffer[offset + 2])

                let brightness = (0.299*r + 0.587*g + 0.114*b) / 255.0

                if brightness > maxBrightness {
                    maxBrightness = brightness
                }
            }
        }

        CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)

        DispatchQueue.main.async {
            self.brightnessHandler?(maxBrightness)
        }
    }

    func stopSession() {
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopSession()
    }

    deinit {
        stopSession()
    }
}
