import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var scanner: ScannerViewModel
    @AppStorage("scanOnLaunch") private var scanOnLaunch = true

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Ana Sayfa", systemImage: "house.fill") }

            FavoritesView()
                .tabItem { Label("Favoriler", systemImage: "star.fill") }

            ScannerView()
                .tabItem { Label("Tarayıcı", systemImage: "antenna.radiowaves.left.and.right") }
                .badge(scanner.strongSignalCount > 0 ? scanner.strongSignalCount : 0)

            SignalListView()
                .tabItem { Label("Sinyaller", systemImage: "chart.line.uptrend.xyaxis") }

            BilancoView()
                .tabItem { Label("Bilanço", systemImage: "building.columns.fill") }

            SettingsView()
                .tabItem { Label("Ayarlar", systemImage: "gearshape") }
        }
        .preferredColorScheme(.dark)
        .task {
            await NotificationManager.shared.requestPermission()
            if scanOnLaunch && !scanner.isScanning && scanner.signals.isEmpty {
                scanner.startScan()
            }
        }
    }
}
