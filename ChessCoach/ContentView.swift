import SwiftUI
import ReplayKit
import UserNotifications

struct ContentView: View {
    @State private var status = "Nog niet gecontroleerd"
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Image(systemName: "checkerboard.rectangle").font(.system(size: 48))
                Text("Chess Coach V3").font(.largeTitle.bold())
                Text("Diagnose: meldingen → frames → borduitsnede")
                    .font(.headline).multilineTextAlignment(.center)
                Button("1. Meldingen toestaan / status controleren") { checkPermission() }
                    .buttonStyle(.borderedProminent)
                Text(status).font(.footnote).multilineTextAlignment(.center)
                Button("2. Stuur testmelding over 5 seconden") { testNotification() }
                    .buttonStyle(.bordered)
                Text("Verlaat na deze knop de app. Als de testmelding niet verschijnt: controleer Instellingen → Meldingen → Chess Coach, en Focus.")
                    .font(.footnote).multilineTextAlignment(.center)
                Text("3. Start schermuitzending:")
                BroadcastPicker().frame(width: 65, height: 65)
                Text("4. Open een toegestane oefenpartij. Verwachte diagnosemeldingen: uitzending gestart, ≥30 videoframes, beeld verwerkt; daarna eventueel bordactiviteit.")
                    .multilineTextAlignment(.center)
                Text("Let op: meldingen vanuit een broadcast-extensie kunnen door iOS worden beperkt. Geen melding is dus niet automatisch bewijs dat er geen frames zijn. Deze app verstuurt of bewaart geen schermbeelden.")
                    .font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.center)
            }.padding(22)
        }
    }
    private func checkPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                DispatchQueue.main.async {
                    status = "Toestemming: \(granted ? "ja" : "nee"), statuscode: \(settings.authorizationStatus.rawValue)" + (error.map { ", fout: \($0.localizedDescription)" } ?? "")
                }
            }
        }
    }
    private func testNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Chess Coach V3: testmelding"
        content.body = "Meldingen vanuit de hoofdapp werken."
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content,
                                            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false))
        UNUserNotificationCenter.current().add(request) { error in
            DispatchQueue.main.async {
                status = error.map { "Testmelding fout: \($0.localizedDescription)" } ?? "Testmelding gepland: verlaat nu de app."
            }
        }
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
