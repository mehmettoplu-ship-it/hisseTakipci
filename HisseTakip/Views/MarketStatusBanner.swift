import SwiftUI

struct MarketStatusBanner: View {
    @StateObject private var vm = MarketStatusViewModel()

    var body: some View {
        Group {
            if vm.isLoading && vm.status == nil {
                skeletonView
            } else if let status = vm.status {
                bannerContent(status)
            } else if vm.failed {
                failedView
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .onAppear { vm.refresh() }
    }

    // MARK: - Banner içeriği

    private func bannerContent(_ status: MarketStatus) -> some View {
        HStack(spacing: 0) {
            // BIST100 fiyat
            VStack(alignment: .leading, spacing: 1) {
                Text("BIST 100")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text(String(format: "%,.0f", status.price))
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(.primary)
            }
            .frame(minWidth: 72, alignment: .leading)

            separator

            // Günlük değişim
            HStack(spacing: 3) {
                Image(systemName: status.changePercent >= 0
                      ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill")
                    .font(.system(size: 9))
                Text(String(format: "%+.2f%%", status.changePercent))
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
            }
            .foregroundStyle(status.changePercent >= 0 ? Color.green : Color.red)
            .frame(minWidth: 70)

            separator

            // Piyasa durumu
            HStack(spacing: 4) {
                Image(systemName: status.condition.systemImage)
                    .font(.system(size: 11))
                Text(status.condition.label)
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(status.condition.color)

            // Uyarılar
            if status.isBelowSupport || !status.isAboveEMA50 {
                separator
                warningBadges(status)
            }

            Spacer(minLength: 8)

            // Güncelleme zamanı + yenile
            VStack(alignment: .trailing, spacing: 1) {
                Button { vm.refresh() } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .disabled(vm.isLoading)

                Text(status.updatedAt, style: .time)
                    .font(.system(size: 8))
                    .foregroundStyle(.tertiary)
                    .monospacedDigit()
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
    }

    @ViewBuilder
    private func warningBadges(_ status: MarketStatus) -> some View {
        HStack(spacing: 6) {
            if !status.isAboveEMA50 {
                badge("EMA50 Altı", icon: "chart.line.downtrend.xyaxis", color: .orange)
            }
            if status.isBelowSupport {
                badge("Destek Kırıldı", icon: "exclamationmark.triangle.fill", color: .red)
            }
        }
    }

    private func badge(_ text: String, icon: String, color: Color) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon).font(.system(size: 9))
            Text(text).font(.system(size: 9, weight: .medium))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 5).padding(.vertical, 3)
        .background(color.opacity(0.15))
        .clipShape(Capsule())
    }

    private var separator: some View {
        Divider()
            .frame(height: 22)
            .padding(.horizontal, 10)
    }

    // MARK: - Yükleniyor

    private var skeletonView: some View {
        HStack(spacing: 8) {
            ProgressView().scaleEffect(0.7)
            Text("Piyasa verisi yükleniyor…")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    // MARK: - Hata

    private var failedView: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.slash").font(.caption).foregroundStyle(.secondary)
            Text("Piyasa verisi alınamadı")
                .font(.caption).foregroundStyle(.secondary)
            Spacer()
            Button("Tekrar") { vm.refresh() }
                .font(.caption.weight(.medium))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }
}
