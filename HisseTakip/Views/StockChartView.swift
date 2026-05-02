import SwiftUI
import Charts

struct StockChartView: View {
    let candles: [Candle]
    let indicators: TechnicalIndicators?

    private var displayCandles: [Candle] { Array(candles.suffix(60)) }

    var body: some View {
        VStack(spacing: 0) {
            candleChart
                .frame(height: 220)
            if let ind = indicators {
                Divider()
                rsiChart(rsi: ind.rsi)
                    .frame(height: 80)
                Divider()
                macdChart(ind: ind)
                    .frame(height: 80)
            }
        }
    }

    private var candleChart: some View {
        Chart(displayCandles) { candle in
            // Gövde
            RectangleMark(
                x: .value("Zaman", candle.timestamp),
                yStart: .value("Açılış", min(candle.open, candle.close)),
                yEnd:   .value("Kapanış", max(candle.open, candle.close)),
                width:  4
            )
            .foregroundStyle(candle.isGreen ? Color.green : Color.red)

            // Fitil
            RectangleMark(
                x: .value("Zaman", candle.timestamp),
                yStart: .value("Düşük", candle.low),
                yEnd:   .value("Yüksek", candle.high),
                width:  1
            )
            .foregroundStyle(candle.isGreen ? Color.green : Color.red)
        }
        .chartXAxis(.hidden)
        .chartYAxis {
            AxisMarks(position: .trailing) {
                AxisValueLabel().foregroundStyle(Color.secondary)
                AxisGridLine().foregroundStyle(Color.gray.opacity(0.2))
            }
        }
        .padding(.horizontal, 4)
    }

    private func rsiChart(rsi: Double) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("RSI  \(String(format: "%.1f", rsi))")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(.leading, 8)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle().fill(Color(.systemGray5)).cornerRadius(4)
                    Rectangle()
                        .fill(rsiColor(rsi))
                        .frame(width: geo.size.width * rsi / 100)
                        .cornerRadius(4)
                    // Aşırı alım/satım çizgileri
                    Rectangle().fill(Color.red.opacity(0.4))
                        .frame(width: 1).offset(x: geo.size.width * 70 / 100)
                    Rectangle().fill(Color.green.opacity(0.4))
                        .frame(width: 1).offset(x: geo.size.width * 30 / 100)
                }
            }
            .padding(.horizontal, 8)
        }
        .padding(.vertical, 6)
    }

    private func rsiColor(_ rsi: Double) -> Color {
        if rsi < 30 { return .green }
        if rsi > 70 { return .red }
        return .blue
    }

    private func macdChart(ind: TechnicalIndicators) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 8) {
                Text("MACD")
                    .font(.caption2).foregroundStyle(.secondary)
                Text(String(format: "%.4f", ind.macdHistogram))
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(ind.macdHistogram >= 0 ? .green : .red)
                Text(ind.macdHistogram >= 0 ? "▲ Boğa" : "▼ Ayı")
                    .font(.caption2)
                    .foregroundStyle(ind.macdHistogram >= 0 ? .green : .red)
            }
            .padding(.leading, 8)
            Spacer()
        }
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
