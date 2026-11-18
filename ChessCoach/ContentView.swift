import SwiftUI
import ReplayKit
import UserNotifications

struct ContentView: View {
    @State private var notificationStatus = "Meldingen zijn nog niet ingeschakeld"

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkerboard.rectangle").font(.system(size: 54))
            Text("Chess Coach V2").font(.largeTitle.bold())
            Text("Realtime bordactiviteit — diagnostische test").font(.headline)
                .multilineTextAlignment(.center)
            Text("Deze versie onderzoekt lokaal de 64 vakjes van een schermstream. Er wordt nog geen schaakzet gevalideerd of Stockfish gebruikt.")
                .multilineTextAlignment(.center)

            Button("1. Meldingen toestaan") {
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge]) { granted, error in
                    DispatchQueue.main.async {
                        notificationStatus = error?.localizedDescription ?? (granted ? "Meldingen toegestaan" : "Meldingen geweigerd")
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            Text(notificationStatus).font(.caption).foregroundStyle(.secondary)

            Text("2. Start schermuitzending:")
            BroadcastPicker().frame(width: 65, height: 65)

            Text("3. Open een oefenpartij tegen een bot. Speel een zet en controleer of je een melding over veranderde vakjes krijgt. Stop de uitzending via het iOS-menu.")
                .multilineTextAlignment(.center)

            Text("Vaste uitsnede: iPhone 14 Pro, portret, Chess.com-bord op de locatie van je oorspronkelijke kalibratie. Foutieve detecties zijn mogelijk; geen beelden worden verzonden.")
                .font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .padding(22)
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
