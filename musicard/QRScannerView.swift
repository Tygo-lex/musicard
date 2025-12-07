import AVFoundation
import SwiftUI

struct QRScannerView: UIViewRepresentable {
    typealias UIViewType = CameraPreview

    final class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        var parent: QRScannerView

        init(parent: QRScannerView) {
            self.parent = parent
        }

        func metadataOutput(_ output: AVCaptureMetadataOutput,
                            didOutput metadataObjects: [AVMetadataObject],
                            from connection: AVCaptureConnection) {
            guard let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
                  let value = object.stringValue else {
                return
            }

            parent.handleDetectedValue(value)
        }
    }

    final class CameraPreview: UIView {
        var session: AVCaptureSession? {
            didSet {
                previewLayer.session = session
            }
        }

        private let previewLayer = AVCaptureVideoPreviewLayer()

        override init(frame: CGRect) {
            super.init(frame: frame)
            previewLayer.videoGravity = .resizeAspectFill
            layer.addSublayer(previewLayer)
        }

        required init?(coder: NSCoder) {
            nil
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            previewLayer.frame = bounds
        }
    }

    let handleDetectedValue: (String) -> Void

    func makeUIView(context: Context) -> CameraPreview {
        let preview = CameraPreview()
        #if targetEnvironment(simulator)
        return preview
        #else
        let session = AVCaptureSession()

        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            return preview
        }

        session.addInput(input)

        let output = AVCaptureMetadataOutput()
        if session.canAddOutput(output) {
            session.addOutput(output)
            output.setMetadataObjectsDelegate(context.coordinator, queue: DispatchQueue.main)
            output.metadataObjectTypes = [.qr]
        }

        preview.session = session
        session.startRunning()
        return preview
        #endif
    }

    func updateUIView(_ uiView: CameraPreview, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
}
