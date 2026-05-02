import SwiftUI
import BackgroundTasks
import UserNotifications

@main
struct HisseTakipApp: App {
    @Environment(\.scenePhase) private var scenePhase
    private let scanner = ScannerViewModel()

    // Info.plist → BGTaskSchedulerPermittedIdentifiers dizisine her ikisi de eklenmiş olmalı
    private let refreshID = "com.mehmet.hissetakip.scan"    // BGAppRefreshTask  (~30s, hafif)
    private let processID = "com.mehmet.hissetakip.process" // BGProcessingTask  (uzun, tam tarama)

    init() {
        UNUserNotificationCenter.current().delegate = NotificationManager.shared
        registerBackgroundTasks()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(scanner)
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                scanner.startAutoScan()
            case .background:
                scanner.stopAutoScan()
                scheduleRefreshTask()
                scheduleProcessTask()
            default:
                break
            }
        }
        .task {
            await NotificationManager.shared.requestPermission()
        }
    }

    // MARK: - Kayıt

    private func registerBackgroundTasks() {
        // Hafif tetikleyici — yalnızca process task'ı yeniden planlar, hızla döner
        BGTaskScheduler.shared.register(forTaskWithIdentifier: refreshID, using: nil) { task in
            self.handleRefreshTask(task: task as! BGAppRefreshTask)
        }
        // Tam tarama — wifi'de, daha uzun bütçeyle çalışır
        BGTaskScheduler.shared.register(forTaskWithIdentifier: processID, using: nil) { task in
            self.handleProcessTask(task: task as! BGProcessingTask)
        }
    }

    // MARK: - BGAppRefreshTask (~30 saniye bütçe)
    // Sadece bir sonraki task'ı planlar ve biter — asla ağır iş yapma

    private func handleRefreshTask(task: BGAppRefreshTask) {
        scheduleRefreshTask()
        scheduleProcessTask()
        task.setTaskCompleted(success: true)
    }

    // MARK: - BGProcessingTask (wifi olduğunda, dakikalarca çalışabilir)

    private func handleProcessTask(task: BGProcessingTask) {
        scheduleProcessTask() // Bir sonrakini hemen planla

        let scanTask = Task {
            await scanner.startScanForBackground()
        }

        task.expirationHandler = {
            scanTask.cancel()
            task.setTaskCompleted(success: false)
        }

        Task {
            await scanTask.value
            task.setTaskCompleted(success: true)
        }
    }

    // MARK: - Zamanlama

    private func scheduleRefreshTask() {
        let req = BGAppRefreshTaskRequest(identifier: refreshID)
        req.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        try? BGTaskScheduler.shared.submit(req)
    }

    private func scheduleProcessTask() {
        let minutes = max(UserDefaults.standard.integer(forKey: "autoScanIntervalMinutes"), 15)
        let req = BGProcessingTaskRequest(identifier: processID)
        req.earliestBeginDate    = Date(timeIntervalSinceNow: Double(minutes) * 60)
        req.requiresNetworkConnectivity = true
        req.requiresExternalPower       = false // Pille de çalışsın
        try? BGTaskScheduler.shared.submit(req)
    }
}
