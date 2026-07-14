import AVFoundation
import UIKit
import Vision

enum OrbitReadsISBNScannerEngine {
    static let captureQueueLabel = "orbitreads.isbn.scan"

    static var authorizationStatus: AVAuthorizationStatus {
        OrbitLensClearance.status
    }

    static func ensureCameraAuthorized() async -> Bool {
        await OrbitLensClearance.requestPassage()
    }

    static func normalizedISBN(from payload: String) -> String? {
        OrbitISBNResolver.resolve(payload)
    }

    static func makeCaptureController() -> WarpTunnelScannerController {
        WarpTunnelScannerController()
    }
}
