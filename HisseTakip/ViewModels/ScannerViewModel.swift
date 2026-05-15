import Foundation
import Combine
import UIKit

struct FailedStock: Identifiable {
    let id   = UUID()
    let stock: Stock
    let timeframe: Timeframe
}

@MainActor
final class ScannerViewModel: ObservableObject {
    @Published var signals: [Signal]     = []
    @Published var isScanning            = false
    @Published var progress: Double      = 0
    @Published var scannedCount: Int     = 0
    @Published var lastScanDate: Date?
    @Published var errorMessage: String?
    @Published var selectedTimeframes: Set<Timeframe> = [.daily]
    @Published var stockList: [Stock]    = BISTStockList.all
    @Published var currentSymbol: String? = nil
    @Published var fetchErrors: Int      = 0
    @Published var scanDuration: TimeInterval? = nil
    @Published var failedStocks: [FailedStock] = []
    @Published var liveSignalCount: Int  = 0

    private var scanTask: Task<Void, Never>?
    private var autoScanTask: Task<Void, Never>?
    private var bgTaskID: UIBackgroundTaskIdentifier = .invalid

    private var autoScanIntervalSeconds: TimeInterval {
        let v = UserDefaults.standard.integer(forKey: "autoScanIntervalMinutes")
        return TimeInterval((v > 0 ? v : 15) * 60)
    }

    init() {
        loadCachedSignals()
        Task { stockList = await StockListService.shared.loadStocks() }
    }

    var sortedSignals: [Signal] {
        signals.sorted {
            let order: [SignalStrength] = [.strong, .moderate, .weak]
            let li = order.firstIndex(of: $0.strength) ?? 2
            let ri = order.firstIndex(of: $1.strength) ?? 2
            if li != ri { return li < ri }
            return $0.timestamp > $1.timestamp
        }
    }

    var strongSignalCount: Int { signals.filter { $0.strength == .strong }.count }

    private var enabledStrategies: Set<SignalType> {
        Set(SignalType.allCases.filter {
            UserDefaults.standard.object(forKey: $0.storageKey) as? Bool ?? true
        })
    }

    // MARK: - Otomatik Tarama (15 dk)

    func startAutoScan() {
        autoScanTask?.cancel()
        autoScanTask = Task { @MainActor [weak self] in
            guard let self else { return }
            let interval = self.autoScanIntervalSeconds
            let elapsed = self.lastScanDate.map { Date().timeIntervalSince($0) } ?? .infinity
            if elapsed >= interval, !self.isScanning {
                await self.performScan()
            }
            while !Task.isCancelled {
                let nextInterval = self.autoScanIntervalSeconds
                try? await Task.sleep(for: .seconds(nextInterval))
                if !Task.isCancelled && !self.isScanning {
                    await self.performScan()
                }
            }
        }
    }

    func stopAutoScan() {
        autoScanTask?.cancel()
        autoScanTask = nil
    }

    // MARK: - Manuel Tarama

    func startScan() {
        guard !isScanning else { return }
        scanTask?.cancel()

        // Arka plan çalışma süresi talep et — uygulama arka plana geçse de tarama devam eder
        UIApplication.shared.isIdleTimerDisabled = true
        bgTaskID = UIApplication.shared.beginBackgroundTask(withName: "hissetakip.scan") { [weak self] in
            // iOS süreyi keseceği zaman buraya gelir; kısmi sonuçları koru
            self?.finishBackgroundTask()
        }

        scanTask = Task {
            await performScan()
            finishBackgroundTask()
        }
    }

    func cancelScan() {
        scanTask?.cancel()
        finishBackgroundTask()
        isScanning = false
    }

    private func finishBackgroundTask() {
        UIApplication.shared.isIdleTimerDisabled = false
        guard bgTaskID != .invalid else { return }
        UIApplication.shared.endBackgroundTask(bgTaskID)
        bgTaskID = .invalid
    }

    // MARK: - Arka Plan Tarama

    func startScanForBackground() async {
        let previousSignals = signals
        let stocks         = stockList
        let timeframes     = Array(selectedTimeframes)
        let strategies     = enabledStrategies
        let pairs          = stocks.flatMap { s in timeframes.map { tf in (s, tf) } }
        let total          = Double(pairs.count)
        var found: [Signal] = []
        var count          = 0
        let chunkSize      = 5

        let chunks = stride(from: 0, to: pairs.count, by: chunkSize).map {
            Array(pairs[$0 ..< min($0 + chunkSize, pairs.count)])
        }

        for (chunkIdx, chunk) in chunks.enumerated() {
            if Task.isCancelled { break }
            if chunkIdx > 0 {
                try? await Task.sleep(for: .milliseconds(120))
            }
            await withTaskGroup(of: [Signal].self) { group in
                for (stock, timeframe) in chunk {
                    group.addTask {
                        guard !Task.isCancelled else { return [] }
                        do {
                            let candles = try await YahooFinanceService.shared
                                .fetchCandles(symbol: stock.id, timeframe: timeframe)
                            return StrategyScanner.scan(
                                stock: stock, candles: candles,
                                timeframe: timeframe, enabledStrategies: strategies)
                        } catch {
                            return []
                        }
                    }
                }
                for await partialSignals in group {
                    found.append(contentsOf: partialSignals)
                    count += 1
                    _ = Double(count) / total
                }
            }
        }

        if !Task.isCancelled {
            found = applyRSIFilter(found)
            notifyDropped(previous: previousSignals, current: found)
            let prevKeys = Set(previousSignals.map { signalKey($0) })
            let brandNew = found.filter { !prevKeys.contains(signalKey($0)) }
            NotificationManager.shared.sendBatch(signals: brandNew)
            signals      = found
            lastScanDate = Date()
            saveSignals()
        }
    }

    // MARK: - Ana Tarama

    private func performScan() async {
        isScanning      = true
        progress        = 0
        scannedCount    = 0
        fetchErrors     = 0
        liveSignalCount = 0
        failedStocks    = []
        errorMessage    = nil
        currentSymbol   = nil
        let scanStart   = Date()

        let previousSignals = signals
        let hadPreviousScan = lastScanDate != nil

        let stocks     = stockList
        let timeframes = Array(selectedTimeframes)
        let strategies = enabledStrategies
        let pairs      = stocks.flatMap { s in timeframes.map { tf in (s, tf) } }
        let total      = Double(pairs.count)
        let chunkSize  = 5   // Yahoo rate-limit'i azaltmak için küçük tutuldu

        let chunks = stride(from: 0, to: pairs.count, by: chunkSize).map {
            Array(pairs[$0 ..< min($0 + chunkSize, pairs.count)])
        }

        var newSignals: [Signal] = []

        for (chunkIdx, chunk) in chunks.enumerated() {
            if Task.isCancelled { break }
            // İlk chunk hariç kısa bekleme — Yahoo rate-limit'ini önler
            if chunkIdx > 0 {
                try? await Task.sleep(for: .milliseconds(120))
            }
            currentSymbol = chunk.first?.0.symbol
            await withTaskGroup(of: ([Signal], FailedStock?, (String, Double)?).self) { group in
                for (stock, timeframe) in chunk {
                    group.addTask {
                        guard !Task.isCancelled else { return ([], nil, nil) }
                        do {
                            let candles = try await YahooFinanceService.shared
                                .fetchCandles(symbol: stock.id, timeframe: timeframe)
                            let sigs = StrategyScanner.scan(
                                stock: stock, candles: candles,
                                timeframe: timeframe, enabledStrategies: strategies)
                            let latestPrice = candles.last?.close
                            return (sigs, nil, latestPrice.map { (stock.symbol, $0) })
                        } catch FetchError.noData {
                            return ([], nil, nil)
                        } catch {
                            return ([], FailedStock(stock: stock, timeframe: timeframe), nil)
                        }
                    }
                }
                for await (partialSignals, failed, priceUpdate) in group {
                    newSignals.append(contentsOf: partialSignals)
                    liveSignalCount += partialSignals.count
                    if let (sym, price) = priceUpdate {
                        SignalHistoryManager.shared.updatePrice(symbol: sym, price: price)
                    }
                    if let f = failed {
                        fetchErrors  += 1
                        failedStocks.append(f)
                    }
                    scannedCount += 1
                    progress = Double(scannedCount) / total
                }
            }
        }

        currentSymbol = nil
        scanDuration  = Date().timeIntervalSince(scanStart)

        if !Task.isCancelled {
            newSignals = applyRSIFilter(newSignals)
            let prevKeys = Set(previousSignals.map { signalKey($0) })
            let brandNew = newSignals.filter { !prevKeys.contains(signalKey($0)) }
            if hadPreviousScan {
                notifyDropped(previous: previousSignals, current: newSignals)
            }
            NotificationManager.shared.sendBatch(signals: brandNew)
            signals      = newSignals
            lastScanDate = Date()
            saveSignals()
            SignalHistoryManager.shared.save(signals: newSignals)
        }
        isScanning = false
    }

    // MARK: - Düşen Sinyal Tespiti

    private func notifyDropped(previous: [Signal], current: [Signal]) {
        let currentKeys = Set(current.map { signalKey($0) })
        let dropped = previous.filter { !currentKeys.contains(signalKey($0)) }
        NotificationManager.shared.sendDropped(signals: dropped)
    }

    private func signalKey(_ s: Signal) -> String {
        "\(s.stock.id)|\(s.type.rawValue)|\(s.timeframe.rawValue)"
    }

    // MARK: - Yardımcı

    private func applyRSIFilter(_ input: [Signal]) -> [Signal] {
        let minRSI = UserDefaults.standard.object(forKey: "minRSIFilter") as? Double ?? 0
        let maxRSI = UserDefaults.standard.object(forKey: "maxRSIFilter") as? Double ?? 100
        guard minRSI > 0 || maxRSI < 100 else { return input }
        return input.filter { signal in
            guard let rsi = signal.rsi else { return true }
            return rsi >= minRSI && rsi <= maxRSI
        }
    }

    private func saveSignals() {
        guard let data = try? JSONEncoder().encode(signals) else { return }
        UserDefaults.standard.set(data, forKey: "cachedSignals")
        if let date = lastScanDate {
            UserDefaults.standard.set(date, forKey: "lastScanDate")
        }
    }

    private func loadCachedSignals() {
        if let data = UserDefaults.standard.data(forKey: "cachedSignals"),
           let decoded = try? JSONDecoder().decode([Signal].self, from: data) {
            signals = decoded
        }
        lastScanDate = UserDefaults.standard.object(forKey: "lastScanDate") as? Date
    }
}
