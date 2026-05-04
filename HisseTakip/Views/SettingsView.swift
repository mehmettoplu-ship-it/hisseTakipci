import SwiftUI
import UIKit

struct SettingsView: View {
    // Genel
    @AppStorage("scanOnLaunch")          private var scanOnLaunch          = false
    @AppStorage("notificationsEnabled")  private var notificationsEnabled  = true
    @AppStorage("onlyStrongAlert")       private var onlyStrongAlert       = false
    @AppStorage("minRSIFilter")          private var minRSIFilter: Double  = 0
    @AppStorage("maxRSIFilter")          private var maxRSIFilter: Double  = 100

    // Otomatik Tarama
    @AppStorage("autoScanIntervalMinutes") private var autoScanInterval: Int = 15

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
    @State private var showDetail = false

    init(type: SignalType) {
        self.type = type
        _isEnabled = AppStorage(wrappedValue: true, type.storageKey)
    }

    var body: some View {
        HStack {
            Toggle(isOn: $isEnabled) {
                Text(type.emoji + " " + type.rawValue)
            }
            Button {
                showDetail = true
            } label: {
                Image(systemName: "info.circle")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 17))
            }
            .buttonStyle(.plain)
        }
        .sheet(isPresented: $showDetail) {
            StrategyDetailView(type: type)
        }
    }
}

private struct StrategyDetailView: View {
    let type: SignalType
    @Environment(\.dismiss) private var dismiss

    private var frequencyColor: Color {
        type.firingFrequency == "Seyrek"
            ? Color(red: 0.1, green: 0.85, blue: 0.55)
            : Color(red: 1.0, green: 0.62, blue: 0.0)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // Başlık kartı
                    VStack(spacing: 10) {
                        Text(type.emoji)
                            .font(.system(size: 52))
                        Text(type.rawValue)
                            .font(.title2.weight(.black))
                        Text(type.shortDescription)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 12)
                        Label(type.firingFrequency, systemImage: "timer")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(frequencyColor)
                            .padding(.horizontal, 12).padding(.vertical, 5)
                            .background(frequencyColor.opacity(0.12))
                            .clipShape(Capsule())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)

                    Divider()

                    // Koşullar
                    infoSection(title: "Tetiklenme Koşulları", icon: "checklist") {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(Array(type.conditionsList.enumerated()), id: \.offset) { _, cond in
                                HStack(alignment: .top, spacing: 10) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 13))
                                        .foregroundStyle(Color(red: 0.2, green: 0.5, blue: 1.0))
                                        .padding(.top, 2)
                                    Text(cond)
                                        .font(.subheadline)
                                }
                            }
                        }
                    }

                    // Mantık
                    infoSection(title: "Strateji Mantığı", icon: "brain.fill") {
                        Text(type.strategyLogic)
                            .font(.subheadline)
                            .lineSpacing(4)
                    }

                    // Güçlü sinyal kriterleri
                    infoSection(title: "Güçlü Sinyal Kriteri", icon: "bolt.fill") {
                        Text(type.strongSignalCriteria)
                            .font(.subheadline)
                            .lineSpacing(4)
                    }

                    Text("Bu bilgiler yatırım tavsiyesi değildir.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.bottom, 8)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kapat") { dismiss() }
                        .font(.system(size: 15, weight: .semibold))
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    @ViewBuilder
    private func infoSection<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.footnote.weight(.bold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            content()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
}
