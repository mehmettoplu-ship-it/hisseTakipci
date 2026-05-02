import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var scanner: ScannerViewModel
    @AppStorage("scanOnLaunch") private var scanOnLaunch = true
    @State var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(selectedTab: $selectedTab)
                .tabItem { Label("Ana Sayfa", systemImage: "house.fill") }
                .tag(0)

            StockSearchView()
                .tabItem { Label("Analiz", systemImage: "magnifyingglass.circle.fill") }
                .tag(1)

            ScannerView()
                .tabItem { Label("Tarayıcı", systemImage: "antenna.radiowaves.left.and.right") }
                .badge(scanner.strongSignalCount > 0 ? scanner.strongSignalCount : 0)
                .tag(2)

            SignalListView()
                .tabItem { Label("Sinyaller", systemImage: "chart.line.uptrend.xyaxis") }
                .tag(3)

            BilancoView()
                .tabItem { Label("Bilanço", systemImage: "building.columns.fill") }
                .tag(4)

            FavoritesView()
                .tabItem { Label("Favoriler", systemImage: "star.fill") }
                .tag(5)

            SettingsView()
                .tabItem { Label("Ayarlar", systemImage: "gearshape") }
                .tag(6)
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
