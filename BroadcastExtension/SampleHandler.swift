import Foundation
import ReplayKit
import CoreMedia
import CoreVideo
import CoreImage
import UserNotifications

/// V3 diagnostic: distinguish broadcast startup, video arrival, crop and notifications.
/// No frames are saved or transmitted.
final class SampleHandler: RPBroadcastSampleHandler {
    private let context = CIContext(options: [.useSoftwareRenderer: false])
    private let sampleSize = 128
    private var baseline: [UInt8]?
    private var lastSample: TimeInterval = 0
    private var candidate: Set<Int> = []
    private var candidateSince: TimeInterval = 0
    private var totalFrames = 0
    private var sampledFrames = 0
    private var invalidCrops = 0
    private var reportedEvents = 0
    private var heartbeatSent = false

    override func broadcastStarted(withSetupInfo setupInfo: [String: NSObject]?) {
        baseline = nil
        lastSample = 0
        candidate = []
        candidateSince = 0
        totalFrames = 0
        sampledFrames = 0
        invalidCrops = 0
        reportedEvents = 0
        heartbeatSent = false
        NSLog("ChessCoach V3: broadcastStarted")
        notify("Chess Coach V3: uitzending gestart", "Extensie is gestart; videoframes nog niet bevestigd.")
    }

    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer,
                                      with sampleBufferType: RPSampleBufferType) {
        guard sampleBufferType == .video else { return }
        totalFrames += 1
        if !heartbeatSent && totalFrames >= 30 {
            heartbeatSent = true
            NSLog("ChessCoach V3: received at least 30 video buffers")
            notify("Chess Coach V3: videoframes ontvangen", "Minstens 30 videobuffers aangekomen.")
        }
        let now = ProcessInfo.processInfo.systemUptime
        guard now - lastSample >= 0.65 else { return }
        lastSample = now
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
              let current = boardPixels(from: pixelBuffer) else {
            invalidCrops += 1
            if invalidCrops == 5 {
                notify("Chess Coach V3: uitsnede mislukt", "5 videoframes konden niet als portretbord worden verwerkt.")
            }
            return
        }
        sampledFrames += 1
        if sampledFrames == 3 {
            notify("Chess Coach V3: beeld verwerkt", "Bordregio 3 keer succesvol bemonsterd.")
        }
        guard let previous = baseline else { baseline = current; return }
        let changed = differentSquares(previous, current)
        guard changed.count >= 2 && changed.count <= 6 else {
            candidate = []
            candidateSince = 0
            if changed.isEmpty { baseline = current }
            return
        }
        if changed != candidate { candidate = changed; candidateSince = now; return }
        guard now - candidateSince >= 1.0 else { return }
        baseline = current
        candidate = []
        candidateSince = 0
        reportedEvents += 1
        let coords = changed.sorted().map(squareName).joined(separator: ", ")
        notify("Chess Coach V3: bordactiviteit", "Veranderde vakjes: \(coords)")
    }

    override func broadcastFinished() {
        NSLog("ChessCoach V3: finished frames=%d samples=%d badCrops=%d events=%d", totalFrames, sampledFrames, invalidCrops, reportedEvents)
    }

    private func boardPixels(from buffer: CVPixelBuffer) -> [UInt8]? {
        let width = CGFloat(CVPixelBufferGetWidth(buffer))
        let height = CGFloat(CVPixelBufferGetHeight(buffer))
        guard height > width && width > 0 else { return nil }
        let image = CIImage(cvPixelBuffer: buffer)
        let rect = CGRect(x: image.extent.minX,
                          y: image.extent.minY + height * (1 - 2016.0 / 2556.0),
                          width: width * 1172.0 / 1179.0,
                          height: height * (2016.0 - 836.0) / 2556.0)
        guard rect.width > 0 && rect.height > 0 else { return nil }
        let cropped = image.cropped(to: rect)
        let normalized = cropped.transformed(by: CGAffineTransform(translationX: -rect.minX, y: -rect.minY))
        let resized = normalized.transformed(by: CGAffineTransform(scaleX: CGFloat(sampleSize)/rect.width,
                                                                   y: CGFloat(sampleSize)/rect.height))
        var result = [UInt8](repeating: 0, count: sampleSize * sampleSize * 4)
        result.withUnsafeMutableBytes { bytes in
            guard let pointer = bytes.baseAddress else { return }
            context.render(resized, toBitmap: pointer, rowBytes: sampleSize * 4,
                           bounds: CGRect(x: 0, y: 0, width: sampleSize, height: sampleSize),
                           format: .RGBA8, colorSpace: CGColorSpaceCreateDeviceRGB())
        }
        return result
    }

    private func differentSquares(_ a: [UInt8], _ b: [UInt8]) -> Set<Int> {
        var output = Set<Int>()
        for rank in 0..<8 {
            for file in 0..<8 {
                var diff = 0
                for y in (rank * 16 + 3)..<(rank * 16 + 13) {
                    for x in (file * 16 + 3)..<(file * 16 + 13) {
                        let offset = (y * sampleSize + x) * 4
                        for channel in 0..<3 { diff += abs(Int(a[offset+channel])-Int(b[offset+channel])) }
                    }
                }
                if Double(diff) / 300.0 > 21.0 { output.insert(rank * 8 + file) }
            }
        }
        return output
    }

    private func squareName(_ index: Int) -> String {
        return "\(Array("abcdefgh")[index % 8])\(index / 8 + 1)"
    }

    private func notify(_ title: String, _ body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error { NSLog("ChessCoach V3 notification failed: %@", error.localizedDescription) }
        }
    }
}
