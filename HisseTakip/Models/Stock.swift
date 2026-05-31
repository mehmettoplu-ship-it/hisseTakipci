import Foundation

struct Stock: Identifiable, Codable, Hashable {
    let id: String      // Yahoo sembolü: "THYAO.IS"
    let symbol: String  // Borsa kodu: "THYAO"
    let name: String
    let sector: String

    static func == (lhs: Stock, rhs: Stock) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
