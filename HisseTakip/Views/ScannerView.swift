import SwiftUI

struct ScannerView: View {
    @EnvironmentObject private var vm: ScannerViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                timeframeSelector
                Divider().opacity(0.4)
                statsRow
                    .padding(.vertical, 14)
                Divider().opacity(0.4)
                Spacer()
                if vm.isScanning {
                    scanningView
                } else {
                    idleView
                }
                Spacer()
                scanButton
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
            }
            .navigationTitle("Tarayıcı")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if let date = vm.lastScanDate {
                        Text(date.formatted(.dateTime.hour().minute()))
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Zaman Dilimi Seçici

    private var timeframeSelector: some View {
        HStack(spacing: 8) {
            ForEach(Timeframe.allCases) { tf in
                let selected = vm.selectedTimeframes.contains(tf)
                Button {
                    if selected && vm.selectedTimeframes.count > 1 {
                        vm.selectedTimeframes.remove(tf)
                    } else {
                        vm.selectedTimeframes.insert(tf)
                    }
                } label: {
                    Text(tf.displayName)
                        .font(.system(size: 13, weight: .bold))
                        .padding(.vertical, 9)
                        .frame(maxWidth: .infinity)
                        .background(
                            selected
                                ? LinearGradient(colors: [Color(red: 0.2, green: 0.5, blue: 1.0),
                                                          Color(red: 0.1, green: 0.3, blue: 0.9)],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing)
                                : LinearGradient(colors: [Color(.tertiarySystemFill), Color(.tertiarySystemFill)],
                                                 startPoint: .leading, endPoint: .trailing)
                        )
                        .foregroundStyle(selected ? .white : .secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .shadow(color: selected ? Color(red: 0.2, green: 0.5, blue: 1.0).opacity(0.35) : .clear,
                                radius: 6, y: 3)
                }
                .animation(.spring(response: 0.3), value: selected)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    // MARK: - İstatistik Satırı

    private var statsRow: some View {
        HStack(spacing: 0) {
            statBox(value: "\(vm.signals.count)",
                    label: "Toplam",
                    icon: "chart.bar.fill",
                    color: Color(red: 0.2, green: 0.5, blue: 1.0))
            Divider().frame(height: 40).opacity(0.5)
            statBox(value: "\(vm.strongSignalCount)",
                    label: "Güçlü",
                    icon: "bolt.fill",
                    color: Color(red: 0.1, green: 0.85, blue: 0.55))
            Divider().frame(height: 40).opacity(0.5)
            statBox(value: "\(vm.signals.filter { $0.type == .smartMomentum }.count)",
                    label: "Akıllı Momentum",
                    icon: "brain.fill",
                    color: Color(red: 1.0, green: 0.72, blue: 0.0))
        }
    }

    private func statBox(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(color)
                Text(value)
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(.primary)
            }
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Taranıyor

    private var scanningView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 5)
                    .frame(width: 100, height: 100)
                Circle()
                    .trim(from: 0, to: vm.progress)
                    .stroke(
                        LinearGradient(colors: [Color(red: 0.2, green: 0.5, blue: 1.0),
                                                Color(red: 0.4, green: 0.8, blue: 1.0)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                        style: StrokeStyle(lineWidth: 5, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 100, height: 100)
                    .animation(.easeInOut(duration: 0.35), value: vm.progress)
                    .shadow(color: Color(red: 0.2, green: 0.5, blue: 1.0).opacity(0.4), radius: 6)

                VStack(spacing: 0) {
                    Text("\(Int(vm.progress * 100))")
                        .font(.system(size: 22, weight: .black, design: .monospaced))
                    Text("%")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            }

            VStack(spacing: 6) {
                Text("\(vm.scannedCount) / \(vm.stockList.count * vm.selectedTimeframes.count)")
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                    .foregroundStyle(.primary)
                Text("hisse analiz ediliyor…")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Boş Ekran

    private var idleView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(red: 0.2, green: 0.5, blue: 1.0).opacity(0.2), .clear],
                            center: .center, startRadius: 0, endRadius: 55
                        )
                    )
                    .frame(width: 110, height: 110)
                Image(systemName: vm.signals.isEmpty ? "chart.xyaxis.line" : "checkmark.seal.fill")
                    .font(.system(size: 44, weight: .medium))
                    .foregroundStyle(
                        vm.signals.isEmpty
                            ? LinearGradient(colors: [Color(red: 0.2, green: 0.5, blue: 1.0), .cyan],
                                             startPoint: .top, endPoint: .bottom)
                            : LinearGradient(colors: [Color(red: 0.1, green: 0.85, blue: 0.55), .mint],
                                             startPoint: .top, endPoint: .bottom)
                    )
            }

            VStack(spacing: 6) {
                if vm.signals.isEmpty {
                    Text("Taramaya Hazır")
                        .font(.title3.weight(.bold))
                    Text("\(vm.stockList.count) hisse analiz edilecek")
                        .font(.subheadline).foregroundStyle(.secondary)
                } else {
                    Text("\(vm.signals.count) sinyal bulundu")
                        .font(.title3.weight(.bold))
                    Text("Sinyaller sekmesinden inceleyin")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Tara / İptal Butonu

    private var scanButton: some View {
        Button {
            if vm.isScanning { vm.cancelScan() } else { vm.startScan() }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: vm.isScanning ? "stop.circle.fill" : "play.circle.fill")
                    .font(.system(size: 20, weight: .semibold))
                Text(vm.isScanning ? "Taramayı Durdur" : "Tüm BIST'i Tara")
                    .font(.system(size: 16, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 17)
            .background(
                Group {
                    if vm.isScanning {
                        LinearGradient(colors: [Color(red: 0.9, green: 0.15, blue: 0.15),
                                                Color(red: 0.75, green: 0.08, blue: 0.08)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    } else {
                        LinearGradient(colors: [Color(red: 0.2, green: 0.5, blue: 1.0),
                                                Color(red: 0.08, green: 0.28, blue: 0.95)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    }
                }
            )
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(
                color: vm.isScanning
                    ? Color.red.opacity(0.35)
                    : Color(red: 0.2, green: 0.5, blue: 1.0).opacity(0.4),
                radius: 12, y: 5
            )
        }
        .scaleEffect(vm.isScanning ? 0.98 : 1.0)
        .animation(.spring(response: 0.3), value: vm.isScanning)
    }
}
