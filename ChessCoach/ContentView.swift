import SwiftUI
import ReplayKit

struct ContentView: View {
    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "checkerboard.rectangle")
                .font(.system(size: 54))
            Text("Chess Coach")
                .font(.largeTitle.bold())
            Text("Diagnostische ReplayKit-test")
                .font(.headline)
            Text("Tik op de uitzendknop. Als 'Chess Coach Broadcast' verschijnt, is de extensie geregistreerd. Start een uitzending, open alleen een toegestane oefenpartij en keer daarna terug.")
                .multilineTextAlignment(.center)
            BroadcastPicker()
                .frame(width: 65, height: 65)
            Text("Let op: iOS 27 kan deze verouderde ReplayKit-API weigeren. Deze test verstuurt geen schermbeelden en bevat geen schaakengine.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(25)
    }
}

struct BroadcastPicker: UIViewRepresentable {
    func makeUIView(context: Context) -> RPSystemBroadcastPickerView {
        let view = RPSystemBroadcastPickerView(frame: CGRect(x: 0, y: 0, width: 65, height: 65))
        view.preferredExtension = "org.example.chesscoach.practice.BroadcastExtension"
        view.showsMicrophoneButton = false
        return view
    }
    func updateUIView(_ uiView: RPSystemBroadcastPickerView, context: Context) {}
}
