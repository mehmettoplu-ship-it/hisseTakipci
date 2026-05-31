import SwiftUI
import Charts

struct StockChartView: View {
    let candles: [Candle]
    let indicators: TechnicalIndicators?

    @State private var windowSize: Int = 60
    @State private var selectedCandle: Candle? = nil

    private var displayCandles: [Candle] { Array(candles.suffix(windowSize)) }

    private var ema9Points: [(date: Date, value: Double)] {
        let closes = displayCandles.map(\.close)
        let emas = TechnicalAnalysis.ema(values: closes, period: 9)
        let startIdx = closes.count - emas.count
        return emas.enumerated().map { (i, v) in (date: displayCandles[startIdx + i].timestamp, value: v) }
    }

    private var ema21Points: [(date: Date, value: Double)] {
        let closes = displayCandles.map(\.close)
        let emas = TechnicalAnalysis.ema(values: closes, period: 21)
        let startIdx = closes.count - emas.count
        return emas.enumerated().map { (i, v) in (date: displayCandles[startIdx + i].timestamp, value: v) }
    }

    private var ema50Points: [(date: Date, value: Double)] {
        let closes = displayCandles.map(\.close)
        let emas = TechnicalAnalysis.ema(values: closes, period: 50)
        let startIdx = closes.count - emas.count
        return emas.enumerated().map { (i, v) in (date: displayCandles[startIdx + i].timestamp, value: v) }
    }

    private var rsiPoints: [(date: Date, value: Double)] {
        let closes = candles.map(\.close)
        let rsis = TechnicalAnalysis.rsiArray(closes: closes)
        let n = min(displayCandles.count, rsis.count)
        return zip(displayCandles.suffix(n), rsis.suffix(n)).map { (c, r) in (date: c.timestamp, value: r) }
    }

    private var macdHistPoints: [(date: Date, value: Double)] {
        let closes = candles.map(\.close)
        let (_, _, hist) = TechnicalAnalysis.macd(closes: closes)
        let n = min(displayCandles.count, hist.count)
        return zip(displayCandles.suffix(n), hist.suffix(n)).map { (c, h) in (date: c.timestamp, value: h) }
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar
                .padding(.horizontal, 8)
                .padding(.top, 6)

            if let sel = selectedCandle {
                crosshairCallout(sel)
                    .padding(.horizontal, 8)
                    .padding(.top, 4)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            candleChart
                .frame(height: 210)
            Divider()
            volumeChart
                .frame(height: 44)
            if indicators != nil {
                Divider()
                rsiChartView
                    .frame(height: 78)
                Divider()
                macdChartView
                    .frame(height: 78)
            }
        }
    }

    // MARK: - Üst Bar (Lejant + Pencere Seçici)

    private var topBar: some View {
        HStack(spacing: 0) {
            legendDot(color: Color(red: 1.0, green: 0.72, blue: 0.0), label: "EMA9")
            legendDot(color: Color(red: 0.3, green: 0.7, blue: 1.0),  label: "EMA21")
                .padding(.leading, 10)
            legendDot(color: Color(red: 0.95, green: 0.35, blue: 0.6), label: "EMA50")
                .padding(.leading, 10)
            Spacer()
            HStack(spacing: 3) {
                ForEach([30, 60, 90], id: \.self) { size in
                    Button("\(size)") {
                        withAnimation(.spring(response: 0.25)) {
                            windowSize = size
                            selectedCandle = nil
                        }
                    }
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(windowSize == size ? .white : .secondary)
                    .frame(width: 28, height: 20)
                    .background(
                        windowSize == size
                            ? Color(red: 0.2, green: 0.5, blue: 1.0)
                            : Color(.tertiarySystemFill)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(label).font(.system(size: 9, weight: .semibold)).foregroundStyle(.secondary)
        }
    }

    // MARK: - Crosshair Callout

    private func crosshairCallout(_ c: Candle) -> some View {
        let change = c.close - c.open
        let changePct = c.open > 0 ? change / c.open * 100 : 0
        let color: Color = c.isGreen
            ? Color(red: 0.1, green: 0.85, blue: 0.55)
            : Color(red: 1.0, green: 0.28, blue: 0.32)
        return HStack(spacing: 8) {
            Text(c.timestamp, format: .dateTime.month(.abbreviated).day().year(.twoDigits))
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .foregroundStyle(.secondary)
            kvLabel("A", String(format: "%.2f", c.open))
            kvLabel("Y", String(format: "%.2f", c.high))
            kvLabel("D", String(format: "%.2f", c.low))
            kvLabel("K", String(format: "%.2f", c.close), valueColor: color)
            Text(String(format: "%+.2f%%", changePct))
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(color)
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 7))
    }

    private func kvLabel(_ key: String, _ val: String, valueColor: Color = .primary) -> some View {
        HStack(spacing: 2) {
            Text(key)
                .font(.system(size: 8, weight: .semibold))
                .foregroundStyle(.tertiary)
            Text(val)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(valueColor)
        }
    }

    // MARK: - Mum + EMA Grafiği

    private var candleChart: some View {
        Chart {
            ForEach(displayCandles) { candle in
                RectangleMark(
                    x: .value("Zaman", candle.timestamp),
                    yStart: .value("Low", candle.low),
                    yEnd:   .value("High", candle.high),
                    width:  1
                )
                .foregroundStyle(candle.isGreen
                    ? Color(red: 0.1, green: 0.85, blue: 0.55)
                    : Color(red: 1.0, green: 0.28, blue: 0.32))

                RectangleMark(
                    x: .value("Zaman", candle.timestamp),
                    yStart: .value("Open", min(candle.open, candle.close)),
                    yEnd:   .value("Close", max(candle.open, candle.close)),
                    width:  4
                )
                .foregroundStyle(candle.isGreen
                    ? Color(red: 0.1, green: 0.85, blue: 0.55)
                    : Color(red: 1.0, green: 0.28, blue: 0.32))
            }

            ForEach(Array(ema9Points.enumerated()), id: \.offset) { _, pt in
                LineMark(
                    x: .value("Zaman", pt.date),
                    y: .value("EMA9", pt.value),
                    series: .value("Çizgi", "EMA9")
                )
                .foregroundStyle(Color(red: 1.0, green: 0.72, blue: 0.0))
                .lineStyle(StrokeStyle(lineWidth: 1.2))
                .interpolationMethod(.linear)
            }

            ForEach(Array(ema21Points.enumerated()), id: \.offset) { _, pt in
                LineMark(
                    x: .value("Zaman", pt.date),
                    y: .value("EMA21", pt.value),
                    series: .value("Çizgi", "EMA21")
                )
                .foregroundStyle(Color(red: 0.3, green: 0.7, blue: 1.0))
                .lineStyle(StrokeStyle(lineWidth: 1.2))
                .interpolationMethod(.linear)
            }

            ForEach(Array(ema50Points.enumerated()), id: \.offset) { _, pt in
                LineMark(
                    x: .value("Zaman", pt.date),
                    y: .value("EMA50", pt.value),
                    series: .value("Çizgi", "EMA50")
                )
                .foregroundStyle(Color(red: 0.95, green: 0.35, blue: 0.6))
                .lineStyle(StrokeStyle(lineWidth: 1.5))
                .interpolationMethod(.linear)
            }

            if let sel = selectedCandle {
                RuleMark(x: .value("Seçili", sel.timestamp))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                    .foregroundStyle(Color.secondary.opacity(0.6))
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis {
            AxisMarks(position: .trailing, values: .automatic(desiredCount: 4)) {
                AxisValueLabel().foregroundStyle(Color.secondary).font(.system(size: 9))
                AxisGridLine().foregroundStyle(Color.gray.opacity(0.15))
            }
        }
        .chartLegend(.hidden)
        .chartOverlay { proxy in
            GeometryReader { geo in
                Rectangle().fill(.clear).contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { drag in
                                let plotOriginX = geo[proxy.plotAreaFrame].origin.x
                                let xInPlot = drag.location.x - plotOriginX
                                if let date = proxy.value(atX: xInPlot, as: Date.self) {
                                    let nearest = displayCandles.min {
                                        abs($0.timestamp.timeIntervalSince(date)) <
                                        abs($1.timestamp.timeIntervalSince(date))
                                    }
                                    if nearest?.id != selectedCandle?.id {
                                        selectedCandle = nearest
                                    }
                                }
                            }
                            .onEnded { _ in
                                withAnimation(.easeOut(duration: 0.25)) { selectedCandle = nil }
                            }
                    )
            }
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Hacim Grafiği

    private var volumeChart: some View {
        let maxVol = displayCandles.map(\.volume).max() ?? 1
        return Chart(displayCandles) { candle in
            BarMark(
                x: .value("Zaman", candle.timestamp),
                yStart: .value("0", 0.0),
                yEnd:   .value("Hacim", candle.volume),
                width:  .fixed(4)
            )
            .foregroundStyle(candle.isGreen
                ? Color(red: 0.1, green: 0.85, blue: 0.55).opacity(0.55)
                : Color(red: 1.0, green: 0.28, blue: 0.32).opacity(0.55))
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartYScale(domain: 0...(maxVol * 1.2))
        .padding(.horizontal, 4)
    }

    // MARK: - RSI Grafiği

    private var rsiChartView: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("RSI  \(String(format: "%.1f", indicators?.rsi ?? 50))")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("30 · 70")
                    .font(.system(size: 8))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 8)
            .padding(.top, 4)

            Chart {
                ForEach(Array(rsiPoints.enumerated()), id: \.offset) { _, pt in
                    LineMark(
                        x: .value("Zaman", pt.date),
                        y: .value("RSI", pt.value)
                    )
                    .foregroundStyle(Color(red: 0.3, green: 0.7, blue: 1.0))
                    .lineStyle(StrokeStyle(lineWidth: 1.5))
                    .interpolationMethod(.linear)
                }
                RuleMark(y: .value("Aşırı Satım", 30.0))
                    .lineStyle(StrokeStyle(lineWidth: 0.5, dash: [3]))
                    .foregroundStyle(Color.green.opacity(0.6))
                RuleMark(y: .value("Aşırı Alım", 70.0))
                    .lineStyle(StrokeStyle(lineWidth: 0.5, dash: [3]))
                    .foregroundStyle(Color.red.opacity(0.6))
                if let sel = selectedCandle {
                    RuleMark(x: .value("Seçili", sel.timestamp))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                        .foregroundStyle(Color.secondary.opacity(0.5))
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks(position: .trailing, values: [30, 50, 70]) {
                    AxisValueLabel().foregroundStyle(Color.secondary).font(.system(size: 8))
                    AxisGridLine().foregroundStyle(Color.gray.opacity(0.15))
                }
            }
            .chartYScale(domain: 0...100)
            .chartLegend(.hidden)
            .padding(.horizontal, 4)
            .padding(.bottom, 4)
        }
    }

    // MARK: - MACD Histogram Grafiği

    private var macdChartView: some View {
        let rawMax = macdHistPoints.map { abs($0.value) }.max() ?? 0
        let maxAbs = rawMax > 0 ? rawMax : 1
        return VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("MACD Hist.  \(String(format: "%+.4f", indicators?.macdHistogram ?? 0))")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.top, 4)

            Chart {
                ForEach(Array(macdHistPoints.enumerated()), id: \.offset) { _, pt in
                    BarMark(
                        x: .value("Zaman", pt.date),
                        yStart: .value("0", 0.0),
                        yEnd:   .value("Hist", pt.value),
                        width:  .fixed(4)
                    )
                    .foregroundStyle(pt.value >= 0
                        ? Color(red: 0.1, green: 0.85, blue: 0.55).opacity(0.8)
                        : Color(red: 1.0, green: 0.28, blue: 0.32).opacity(0.8))
                }
                RuleMark(y: .value("Sıfır", 0.0))
                    .lineStyle(StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color.secondary.opacity(0.4))
                if let sel = selectedCandle {
                    RuleMark(x: .value("Seçili", sel.timestamp))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                        .foregroundStyle(Color.secondary.opacity(0.5))
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks(position: .trailing, values: .automatic(desiredCount: 3)) {
                    AxisValueLabel().foregroundStyle(Color.secondary).font(.system(size: 8))
                    AxisGridLine().foregroundStyle(Color.gray.opacity(0.15))
                }
            }
            .chartYScale(domain: -maxAbs...maxAbs)
            .chartLegend(.hidden)
            .padding(.horizontal, 4)
            .padding(.bottom, 4)
        }
    }
}
