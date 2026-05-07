import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var scanner: ScannerViewModel
    @AppStorage("scanOnLaunch") private var scanOnLaunch = false
    @State var selectedTab = 0

    private var multiSignalStockCount: Int {
        Dictionary(grouping: scanner.signals, by: \.stock).filter { $0.value.count >= 2 }.count
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(selectedTab: $selectedTab)
                .tabItem { Label("Ana Sayfa", systemImage: "house.fill") }
                .tag(0)

            StockSearchView(selectedTab: $selectedTab)
                .tabItem { Label("Analiz", systemImage: "magnifyingglass.circle.fill") }
                .tag(1)

            ScannerView()
                .tabItem { Label("Tarayıcı", systemImage: "antenna.radiowaves.left.and.right") }
                .badge(scanner.strongSignalCount > 0 ? scanner.strongSignalCount : 0)
                .tag(2)

            SignalListView()
                .tabItem { Label("Sinyaller", systemImage: "chart.line.uptrend.xyaxis") }
                .badge(multiSignalStockCount > 0 ? multiSignalStockCount : 0)
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
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .preferredColorScheme(.dark)
        .task {
            await NotificationManager.shared.requestPermission()
            if scanOnLaunch && !scanner.isScanning && scanner.signals.isEmpty {
                scanner.startScan()
            }
        }
    }
}
