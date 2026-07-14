import AVFoundation
import UIKit
import Vision

enum OrbitISBNResolver {
    static let tunnelCodes: [VNBarcodeSymbology] = [.ean13, .ean8, .code128, .qr, .code39]

    static func resolve(_ payload: String) -> String? {
        let cleaned = payload.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return nil }
        let upper = cleaned.uppercased()
        if let labeled = matchLabel(upper) { return labeled }
        let body = String(upper.filter { $0.isNumber || $0 == "X" })
        if body.count >= 13 { return String(body.suffix(13)) }
        if body.count == 12 { return "0\(body)" }
        if body.count >= 10 { return String(body.suffix(10)) }
        return nil
    }

    private static func matchLabel(_ text: String) -> String? {
        let rx = try? NSRegularExpression(pattern: #"ISBN[\s:/_-]*([0-9X]{10,13})"#, options: .caseInsensitive)
        guard let rx,
              let m = rx.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let r = Range(m.range(at: 1), in: text) else { return nil }
        return resolve(String(text[r]))
    }
}

enum OrbitLensClearance {
    static var status: AVAuthorizationStatus {
        AVCaptureDevice.authorizationStatus(for: .video)
    }

    static func requestPassage() async -> Bool {
        switch status {
        case .authorized: true
        case .notDetermined:
            await withCheckedContinuation { cont in
                AVCaptureDevice.requestAccess(for: .video) { cont.resume(returning: $0) }
            }
        default: false
        }
    }
}

final class WarpFrameInterceptor: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    private let sink: @Sendable (String) -> Void
    private let lock = NSLock()
    private var locked = false

    init(sink: @escaping @Sendable (String) -> Void) {
        self.sink = sink
    }

    func unlock() {
        lock.lock(); locked = false; lock.unlock()
    }

    private func scanning() -> Bool {
        lock.lock(); defer { lock.unlock() }
        return !locked
    }

    private func lockOn() -> Bool {
        lock.lock(); defer { lock.unlock() }
        if locked { return false }
        locked = true
        return true
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard scanning(), let buf = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let request = VNDetectBarcodesRequest { [weak self] req, _ in
            guard let self, self.scanning(),
                  let rows = req.results as? [VNBarcodeObservation] else { return }
            for row in rows {
                guard let payload = row.payloadStringValue,
                      let isbn = OrbitISBNResolver.resolve(payload),
                      self.lockOn() else { continue }
                DispatchQueue.main.async {
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                    self.sink(isbn)
                }
                return
            }
        }
        request.symbologies = OrbitISBNResolver.tunnelCodes
        try? VNImageRequestHandler(cvPixelBuffer: buf, options: [:]).perform([request])
    }
}

final class WarpTunnelScannerController: UIViewController {
    var onDetect: ((String) -> Void)?
    private let warpQueue = DispatchQueue(label: "orbitreads.warp.scan")
    private let session = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var interceptor: WarpFrameInterceptor?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        warpQueue.async { self.openTunnel() }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        interceptor?.unlock()
        warpQueue.async { if !self.session.isRunning { self.session.startRunning() } }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        warpQueue.async { if self.session.isRunning { self.session.stopRunning() } }
    }

    private func openTunnel() {
        let interceptor = WarpFrameInterceptor { [weak self] isbn in self?.onDetect?(isbn) }
        self.interceptor = interceptor
        session.beginConfiguration()
        session.sessionPreset = .hd1920x1080
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            session.commitConfiguration()
            return
        }
        session.addInput(input)
        if let device = AVCaptureDevice.default(for: .video),
           device.isFocusModeSupported(.continuousAutoFocus) {
            try? device.lockForConfiguration()
            device.focusMode = .continuousAutoFocus
            device.unlockForConfiguration()
        }
        let output = AVCaptureVideoDataOutput()
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(interceptor, queue: warpQueue)
        guard session.canAddOutput(output) else {
            session.commitConfiguration()
            return
        }
        session.addOutput(output)
        session.commitConfiguration()
        DispatchQueue.main.async {
            let layer = AVCaptureVideoPreviewLayer(session: self.session)
            layer.videoGravity = .resizeAspectFill
            layer.frame = self.view.bounds
            self.view.layer.insertSublayer(layer, at: 0)
            self.previewLayer = layer
        }
    }
}
