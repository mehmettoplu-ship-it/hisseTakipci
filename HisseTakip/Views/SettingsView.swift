import SwiftUI
import UIKit

struct SettingsView: View {
    @AppStorage("scanOnLaunch")            private var scanOnLaunch          = false
    @AppStorage("notificationsEnabled")    private var notificationsEnabled  = true
    @AppStorage("onlyStrongAlert")         private var onlyStrongAlert       = false
    @AppStorage("minRSIFilter")            private var minRSIFilter: Double  = 0
    @AppStorage("maxRSIFilter")            private var maxRSIFilter: Double  = 100
    @AppStorage("autoScanIntervalMinutes") private var autoScanInterval: Int = 15

    private let intervalOptions = [5, 10, 15, 30, 60]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    appHeaderCard
                    scanSection
                    notificationSection
                    strategySection
                    aboutSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(Color(.systemBackground))
            .navigationTitle("Ayarlar")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Uygulama Başlığı

    private var appHeaderCard: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 24)
                .fill(LinearGradient(
                    colors: [Color(red: 0.14, green: 0.28, blue: 0.78),
                             Color(red: 0.06, green: 0.12, blue: 0.48)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))

            Circle()
                .fill(Color.white.opacity(0.07))
                .frame(width: 140, height: 140).blur(radius: 28)
                .offset(x: 220, y: -20).allowsHitTesting(false)
            Circle()
                .fill(Color.white.opacity(0.05))
                .frame(width: 90, height: 90).blur(radius: 18)
                .offset(x: -20, y: 40).allowsHitTesting(false)

            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.18))
                        .frame(width: 60, height: 60)
                    Image(systemName: "chart.xyaxis.line")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text("Hisse Takip")
                        .font(.system(size: 22, weight: .black))
                        .foregroundStyle(.white)
                    Text("Akıllı BIST Tarayıcı")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                    Text("v1.0.0")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white.opacity(0.9))
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(.white.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 20)
        }
        .frame(height: 118)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: Color(red: 0.14, green: 0.28, blue: 0.78).opacity(0.45), radius: 20, y: 8)
    }

    // MARK: - Tarama

    private var scanSection: some View {
        settingsCard(header: "Tarama", icon: "scope") {
            settingsRow(icon: "power", iconColor: Color(red: 0.1, green: 0.85, blue: 0.55)) {
                Toggle("Açılışta otomatik tara", isOn: $scanOnLaunch)
                    .tint(Color(red: 0.1, green: 0.85, blue: 0.55))
            }
            rowDivider
            intervalPickerRow
            rowDivider
            rsiFilterRow
        }
    }

    private var intervalPickerRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                iconBox("timer", color: Color(red: 0.2, green: 0.5, blue: 1.0))
                Text("Arka plan tarama aralığı")
                    .font(.system(size: 15, weight: .medium))
            }
            HStack(spacing: 6) {
                ForEach(intervalOptions, id: \.self) { min in
                    let selected = autoScanInterval == min
                    Button { autoScanInterval = min } label: {
                        Text("\(min)d")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(selected ? .white : Color(red: 0.2, green: 0.5, blue: 1.0))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                selected
                                    ? Color(red: 0.2, green: 0.5, blue: 1.0)
                                    : Color(red: 0.2, green: 0.5, blue: 1.0).opacity(0.1)
                            )
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .animation(.spring(response: 0.25), value: selected)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
    }

    private var rsiFilterRow: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                iconBox("waveform.path.ecg", color: Color(red: 1.0, green: 0.62, blue: 0.0))
                Text("RSI Filtresi")
                    .font(.system(size: 15, weight: .medium))
                Spacer()
                Text("\(Int(minRSIFilter)) – \(Int(maxRSIFilter))")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color(red: 1.0, green: 0.62, blue: 0.0))
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Color(red: 1.0, green: 0.62, blue: 0.0).opacity(0.1))
                    .clipShape(Capsule())
            }
            VStack(spacing: 8) {
                sliderRow("Alt", value: $minRSIFilter, range: 0...50,
                          color: Color(red: 0.2, green: 0.5, blue: 1.0))
                sliderRow("Üst", value: $maxRSIFilter, range: 50...100,
                          color: Color(red: 0.1, green: 0.85, blue: 0.55))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
    }

    // MARK: - Bildirimler

    private var notificationSection: some View {
        settingsCard(header: "Bildirimler", icon: "bell.fill") {
            settingsRow(icon: "bell.badge.fill", iconColor: Color(red: 1.0, green: 0.28, blue: 0.32)) {
                Toggle("Bildirimleri Etkinleştir", isOn: $notificationsEnabled)
                    .tint(Color(red: 0.1, green: 0.85, blue: 0.55))
            }
            if notificationsEnabled {
                rowDivider
                settingsRow(icon: "bolt.fill", iconColor: Color(red: 1.0, green: 0.62, blue: 0.0)) {
                    Toggle("Sadece güçlü sinyaller", isOn: $onlyStrongAlert)
                        .tint(Color(red: 1.0, green: 0.62, blue: 0.0))
                }
            }
            rowDivider
            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                HStack(spacing: 12) {
                    iconBox("gear.badge", color: Color(.secondaryLabel))
                    Text("Sistem Bildirim Ayarları")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Image(systemName: "arrow.up.forward.app")
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 13)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Stratejiler

    private var strategySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Stratejiler", icon: "chart.xyaxis.line")
            VStack(spacing: 0) {
                ForEach(Array(SignalType.allCases.enumerated()), id: \.element) { idx, type in
                    if idx > 0 { rowDivider }
                    StrategyToggleRow(type: type)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(.secondarySystemBackground))
            )
        }
    }

    // MARK: - Hakkında

    private var aboutSection: some View {
        settingsCard(header: "Hakkında", icon: "info.circle.fill") {
            infoRow(icon: "tag.fill",
                    iconColor: Color(red: 0.2, green: 0.5, blue: 1.0),
                    label: "Versiyon", value: "1.0.0")
            rowDivider
            infoRow(icon: "chart.line.uptrend.xyaxis",
                    iconColor: Color(red: 1.0, green: 0.62, blue: 0.0),
                    label: "Veri Kaynağı", value: "Yahoo Finance")
            rowDivider
            infoRow(icon: "person.fill",
                    iconColor: Color(red: 0.1, green: 0.85, blue: 0.55),
                    label: "Geliştirici", value: "Mehmet Toplu")
            rowDivider
            Text("Bu uygulama yatırım tavsiyesi değildir.\nTüm kararlar kullanıcıya aittir.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
        }
    }

    // MARK: - Builders

    @ViewBuilder
    private func settingsCard<Content: View>(
        header: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(header, icon: icon)
            VStack(spacing: 0) {
                content()
            }
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(.secondarySystemBackground))
            )
        }
    }

    @ViewBuilder
    private func settingsRow<Control: View>(
        icon: String,
        iconColor: Color,
        @ViewBuilder control: () -> Control
    ) -> some View {
        HStack(spacing: 12) {
            iconBox(icon, color: iconColor)
            control()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
    }

    private func sectionHeader(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 4)
    }

    private func iconBox(_ systemName: String, color: Color) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(color)
            .frame(width: 28, height: 28)
            .background(color.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 7))
    }

    private func sliderRow(_ label: String, value: Binding<Double>,
                           range: ClosedRange<Double>, color: Color) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 24, alignment: .leading)
            Slider(value: value, in: range, step: 5)
                .tint(color)
            Text("\(Int(value.wrappedValue))")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(color)
                .frame(width: 28, alignment: .trailing)
        }
    }

    private func infoRow(icon: String, iconColor: Color, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            iconBox(icon, color: iconColor)
            Text(label)
                .font(.system(size: 15, weight: .medium))
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
    }

    private var rowDivider: some View {
        Divider().padding(.leading, 54)
    }
}

// MARK: - Strateji Satırı

private struct StrategyToggleRow: View {
    let type: SignalType
    @AppStorage private var isEnabled: Bool
    @State private var showDetail = false

    init(type: SignalType) {
        self.type = type
        _isEnabled = AppStorage(wrappedValue: true, type.storageKey)
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(type.emoji)
                .font(.system(size: 16))
                .frame(width: 28, height: 28)
                .background(Color(.tertiarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 7))
            Toggle(isOn: $isEnabled) {
                Text(type.rawValue)
                    .font(.system(size: 15, weight: .medium))
                    .lineLimit(1)
            }
            .tint(Color(red: 0.1, green: 0.85, blue: 0.55))
            Button { showDetail = true } label: {
                Image(systemName: "info.circle")
                    .foregroundStyle(Color(red: 0.2, green: 0.5, blue: 1.0).opacity(0.75))
                    .font(.system(size: 16))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .sheet(isPresented: $showDetail) {
            StrategyDetailView(type: type)
        }
    }
}

// MARK: - Strateji Detay

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

                    infoSection(title: "Strateji Mantığı", icon: "brain.fill") {
                        Text(type.strategyLogic)
                            .font(.subheadline)
                            .lineSpacing(4)
                    }

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
