import Foundation

struct Candle: Identifiable {
    let id = UUID()
    let timestamp: Date
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let volume: Double

    var isGreen: Bool { close >= open }
    var body: Double { abs(close - open) }
    var range: Double { high - low }
}
