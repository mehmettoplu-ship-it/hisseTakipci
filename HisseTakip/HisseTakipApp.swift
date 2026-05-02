import SwiftUI
import BackgroundTasks
import UserNotifications

@main
struct HisseTakipApp: App {
    @Environment(\.scenePhase) private var scenePhase
    private let scanner = ScannerViewModel()

    init() {
        // Ön planda bildirim göstermek için delegate'i hemen set et
        UNUserNotificationCenter.current().delegate = NotificationManager.shared
        registerBackgroundTask()
        scheduleNextBackgroundTask()
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
                scheduleNextBackgroundTask()
            case .background:
                scanner.stopAutoScan()
                scheduleNextBackgroundTask()
            default:
                break
            }
        }
    }

    // MARK: - BGAppRefreshTask

    private func registerBackgroundTask() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.mehmet.hissetakip.scan",
            using: nil
        ) { task in
            self.handleBackgroundScan(task: task as! BGAppRefreshTask)
        }
    }

    private func handleBackgroundScan(task: BGAppRefreshTask) {
        scheduleNextBackgroundTask()

        let scanTask = Task {
            await scanner.startScanForBackground()
        }

        task.expirationHandler = {
            scanTask.cancel()
        }

        Task {
            await scanTask.value
            task.setTaskCompleted(success: true)
        }
    }

    private func scheduleNextBackgroundTask() {
        let minutes = {
            let v = UserDefaults.standard.integer(forKey: "autoScanIntervalMinutes")
            return v > 0 ? v : 15
        }()
        let request = BGAppRefreshTaskRequest(identifier: "com.mehmet.hissetakip.scan")
        request.earliestBeginDate = Date(timeIntervalSinceNow: Double(minutes) * 60)
        try? BGTaskScheduler.shared.submit(request)
    }
}
