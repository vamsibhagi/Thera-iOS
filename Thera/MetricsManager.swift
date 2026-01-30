import Foundation
import OSLog

private let logger = Logger(subsystem: "com.vamsibhagi.Thera", category: "MetricsManager")

struct AppMetrics: Codable {
    var shieldShownCount: Int = 0
    var shieldUnlockedCount: Int = 0
    var lastConfigPing: Date?
    var lastActionPing: Date?
}

class MetricsManager {
    static let shared = MetricsManager()
    private let groupID = "group.com.thera.app"
    
    private var metricsURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID)?
            .appendingPathComponent("Library/Application Support", isDirectory: true)
            .appendingPathComponent("metrics.json")
    }
    
    private init() {
        ensureDirectoryExists()
    }
    
    private func ensureDirectoryExists() {
        guard let url = metricsURL?.deletingLastPathComponent() else { return }
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }
    
    func getMetrics() -> AppMetrics {
        guard let url = metricsURL,
              let data = try? Data(contentsOf: url),
              let metrics = try? JSONDecoder().decode(AppMetrics.self, from: data) else {
            return AppMetrics()
        }
        return metrics
    }
    
    func incrementShownCount() {
        var metrics = getMetrics()
        metrics.shieldShownCount += 1
        metrics.lastConfigPing = Date()
        save(metrics)
    }
    
    func incrementUnlockedCount() {
        var metrics = getMetrics()
        metrics.shieldUnlockedCount += 1
        metrics.lastActionPing = Date()
        save(metrics)
    }
    
    private func save(_ metrics: AppMetrics) {
        guard let url = metricsURL else { return }
        do {
            let data = try JSONEncoder().encode(metrics)
            try data.write(to: url, options: .atomic)
            logger.debug("✅ Metrics saved: \(metrics.shieldShownCount)/\(metrics.shieldUnlockedCount)")
        } catch {
            logger.error("❌ Failed to save metrics: \(error.localizedDescription)")
        }
    }
}
