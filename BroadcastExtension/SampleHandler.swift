import Foundation
import ReplayKit
import CoreMedia

/// Diagnostic only. Frames are counted in the extension's private sandbox.
/// NO frames are sent across the network or saved as images.
final class SampleHandler: RPBroadcastSampleHandler {
    private var count = 0
    private var lastWrite: CFAbsoluteTime = 0

    override func broadcastStarted(withSetupInfo setupInfo: [String : NSObject]?) {
        count = 0
        lastWrite = 0
        writeStatus("started; videoFrames=0")
    }

    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer,
                                      with sampleBufferType: RPSampleBufferType) {
        guard sampleBufferType == .video else { return }
        count += 1
        let now = CFAbsoluteTimeGetCurrent()
        if now - lastWrite >= 1 {
            lastWrite = now
            writeStatus("receiving; videoFrames=\(count)")
        }
    }

    override func broadcastFinished() {
        writeStatus("finished; videoFrames=\(count)")
    }

    private func writeStatus(_ value: String) {
        let folder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        guard let url = folder?.appendingPathComponent("broadcast-diagnostic.txt") else { return }
        try? value.write(to: url, atomically: true, encoding: .utf8)
        NSLog("Chess Coach ReplayKit: %@", value)
    }
}
