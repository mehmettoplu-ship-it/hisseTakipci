import SwiftUI
import UIKit

struct SettingsView: View {
    // Genel
    @AppStorage("scanOnLaunch")          private var scanOnLaunch          = true
    @AppStorage("notificationsEnabled")  private var notificationsEnabled  = true
    @AppStorage("onlyStrongAlert")       private var onlyStrongAlert       = false
    @AppStorage("minRSIFilter")          private var minRSIFilter: Double  = 0
    @AppStorage("maxRSIFilter")          private var maxRSIFilter: Double  = 70

    // Otomatik Tarama
    @AppStorage("autoScanIntervalMinutes") private var autoScanInterval: Int = 15

    // EC HFT Pro Parametreleri
    @AppStorage("echft_multiplier") private var ecMultiplier: Double = 1.5
    @AppStorage("echft_period")     private var ecPeriod:     Int    = 10
    @AppStorage("echft_emaShort")   private var ecEmaShort:   Int    = 2
    @AppStorage("echft_emaLong")    private var ecEmaLong:    Int    = 17

    private let intervalOptions = [5, 10, 15, 30, 60]

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Tarama
                Section("Tarama") {
                    Toggle("Açılışta otomatik tara", isOn: $scanOnLaunch)

                    Picker("Arka plan tarama süresi", selection: $autoScanInterval) {
                        ForEach(intervalOptions, id: \.self) { min in
                            Text("\(min) dakika").tag(min)
                        }
                    }

                    HStack {
                        Text("RSI filtresi")
                        Spacer()
                        Text("\(Int(minRSIFilter)) – \(Int(maxRSIFilter))")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("\(Int(minRSIFilter))").font(.caption).frame(width: 28)
                        Slider(value: $minRSIFilter, in: 0...50, step: 5)
                        Text("Alt").font(.caption).foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("\(Int(maxRSIFilter))").font(.caption).frame(width: 28)
                        Slider(value: $maxRSIFilter, in: 50...100, step: 5)
                        Text("Üst").font(.caption).foregroundStyle(.secondary)
                    }
                }

                // MARK: - Bildirimler
                Section("Bildirimler") {
                    Toggle("Bildirimleri Etkinleştir", isOn: $notificationsEnabled)

                    if notificationsEnabled {
                        Toggle("Sadece güçlü sinyaller", isOn: $onlyStrongAlert)
                    }

                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label("Sistem Bildirim Ayarları", systemImage: "gear.badge")
                            .foregroundStyle(.secondary)
                    }
                }

                // MARK: - EC HFT Pro Parametreleri
                Section {
                    HStack {
                        Text("SuperTrend Çarpan")
                        Spacer()
                        Text(String(format: "%.1f", ecMultiplier))
                            .foregroundStyle(.secondary).monospacedDigit()
                    }
                    Slider(value: $ecMultiplier, in: 0.5...5.0, step: 0.5)
                        .tint(.yellow)

                    Stepper("ST Periyot: \(ecPeriod)", value: $ecPeriod, in: 3...30)

                    Stepper("EMA Kısa: \(ecEmaShort)", value: $ecEmaShort, in: 1...15)

                    Stepper("EMA Uzun: \(ecEmaLong)", value: $ecEmaLong, in: 5...50)

                    Button("Varsayılana Sıfırla") {
                        ecMultiplier = 1.5
                        ecPeriod     = 10
                        ecEmaShort   = 2
                        ecEmaLong    = 17
                    }
                    .foregroundStyle(.orange)
                } header: {
                    Text("EC HFT Pro Parametreleri")
                } footer: {
                    Text("Değişiklikler bir sonraki taramada uygulanır.")
                        .font(.caption)
                }

                // MARK: - Stratejiler
                Section("Stratejiler") {
                    ForEach(SignalType.allCases, id: \.self) { type in
                        StrategyToggleRow(type: type)
                    }
                }

                // MARK: - Hakkında
                Section("Hakkında") {
                    LabeledContent("Versiyon", value: "1.0.0")
                    LabeledContent("Veri Kaynağı", value: "Yahoo Finance")
                    LabeledContent("Geliştirici", value: "Mehmet Toplu")
                    Text("Bu uygulama yatırım tavsiyesi değildir. Tüm kararlar kullanıcıya aittir.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Ayarlar")
        }
    }
}

private struct StrategyToggleRow: View {
    let type: SignalType
    @AppStorage private var isEnabled: Bool

    init(type: SignalType) {
        self.type = type
        _isEnabled = AppStorage(wrappedValue: true, type.storageKey)
    }

    var body: some View {
        Toggle(isOn: $isEnabled) {
            Text(type.emoji + " " + type.rawValue)
        }
    }
}
