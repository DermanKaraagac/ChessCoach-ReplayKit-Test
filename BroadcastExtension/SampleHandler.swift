import Foundation
import ReplayKit
import CoreMedia
import CoreVideo
import CoreImage
import UserNotifications

/// V2: private, on-device diagnostic for chessboard activity.
/// A portrait iPhone frame is cropped using calibrated screenshot fractions.
/// No screenshots or screen data leave the phone.
final class SampleHandler: RPBroadcastSampleHandler {
    private let context = CIContext(options: [.useSoftwareRenderer: false])
    private let sampleSize = 128
    private var baseline: [UInt8]?
    private var lastSample: TimeInterval = 0
    private var candidate: Set<Int> = []
    private var candidateSince: TimeInterval = 0
    private var totalFrames = 0
    private var reportedEvents = 0

    override func broadcastStarted(withSetupInfo setupInfo: [String: NSObject]?) {
        baseline = nil
        candidate = []
        candidateSince = 0
        totalFrames = 0
        reportedEvents = 0
        NSLog("ChessCoach V2: broadcast started, awaiting video frames")
    }

    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer,
                                      with sampleBufferType: RPSampleBufferType) {
        guard sampleBufferType == .video else { return }
        totalFrames += 1
        let now = ProcessInfo.processInfo.systemUptime
        guard now - lastSample >= 0.65 else { return }
        lastSample = now
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
              let current = boardPixels(from: pixelBuffer) else { return }

        guard let previous = baseline else {
            baseline = current
            NSLog("ChessCoach V2: first board region sampled, frame %d", totalFrames)
            return
        }

        let changed = differentSquares(previous, current)
        // Whole-screen transitions, highlights and animations often produce many changes.
        guard changed.count >= 2 && changed.count <= 6 else {
            candidate = []
            candidateSince = 0
            if changed.isEmpty { baseline = current }
            return
        }

        if changed != candidate {
            candidate = changed
            candidateSince = now
            return
        }
        // Require the same squares to differ for at least 1 second.
        guard now - candidateSince >= 1.0 else { return }

        baseline = current
        candidate = []
        candidateSince = 0
        reportedEvents += 1
        let coordinates = changed.sorted().map(squareName).joined(separator: ", ")
        NSLog("ChessCoach V2: region change #%d: %@", reportedEvents, coordinates)
        notify("Bordactiviteit gedetecteerd", "Veranderde vakjes: \(coordinates)")
    }

    override func broadcastFinished() {
        NSLog("ChessCoach V2: ended, total video frames=%d, events=%d", totalFrames, reportedEvents)
    }

    /// Returns 128 x 128 RGBA pixels from the board crop, or nil in landscape.
    private func boardPixels(from buffer: CVPixelBuffer) -> [UInt8]? {
        let width = CGFloat(CVPixelBufferGetWidth(buffer))
        let height = CGFloat(CVPixelBufferGetHeight(buffer))
        guard height > width, width > 0, height > 0 else { return nil }
        let image = CIImage(cvPixelBuffer: buffer)
        // From original 1179 x 2556 reference screenshot: x=0..1172, y=836..2016.
        // CIImage coordinates start at the bottom; screenshot coordinates at the top.
        let rectangle = CGRect(x: image.extent.minX,
                               y: image.extent.minY + height * (1 - 2016.0 / 2556.0),
                               width: width * 1172.0 / 1179.0,
                               height: height * (2016.0 - 836.0) / 2556.0)
        guard rectangle.width > 0, rectangle.height > 0 else { return nil }
        let cropped = image.cropped(to: rectangle)
        let adjusted = cropped.transformed(by: CGAffineTransform(translationX: -rectangle.minX, y: -rectangle.minY))
        let resized = adjusted.transformed(by: CGAffineTransform(scaleX: CGFloat(sampleSize) / rectangle.width,
                                                                 y: CGFloat(sampleSize) / rectangle.height))
        var pixels = [UInt8](repeating: 0, count: sampleSize * sampleSize * 4)
        pixels.withUnsafeMutableBytes { bytes in
            guard let pointer = bytes.baseAddress else { return }
            context.render(resized, toBitmap: pointer,
                           rowBytes: sampleSize * 4,
                           bounds: CGRect(x: 0, y: 0, width: sampleSize, height: sampleSize),
                           format: .RGBA8, colorSpace: CGColorSpaceCreateDeviceRGB())
        }
        return pixels
    }

    private func differentSquares(_ a: [UInt8], _ b: [UInt8]) -> Set<Int> {
        var changes = Set<Int>()
        // CIImage output has origin at bottom left. Index 0 = a1, index 63 = h8.
        for rank in 0..<8 {
            for file in 0..<8 {
                var totalDifference = 0
                var count = 0
                for y in (rank * 16 + 3)..<(rank * 16 + 13) {
                    for x in (file * 16 + 3)..<(file * 16 + 13) {
                        let offset = (y * sampleSize + x) * 4
                        for channel in 0..<3 {
                            totalDifference += abs(Int(a[offset + channel]) - Int(b[offset + channel]))
                            count += 1
                        }
                    }
                }
                if count > 0 && Double(totalDifference) / Double(count) > 21.0 {
                    changes.insert(rank * 8 + file)
                }
            }
        }
        return changes
    }

    private func squareName(_ index: Int) -> String {
        let names = Array("abcdefgh")
        return "\(names[index % 8])\(index / 8 + 1)"
    }

    private func notify(_ title: String, _ body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = nil
        let request = UNNotificationRequest(identifier: UUID().uuidString,
                                            content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                NSLog("ChessCoach V2: notification not delivered: %@", error.localizedDescription)
            }
        }
    }
}
