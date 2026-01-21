import UserNotifications
import Foundation
import Combine

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isAuthorized = false
    
    private init() {
        Task {
            await checkAuthorization()
        }
    }
    
    @MainActor
    func requestAuthorization() async {
        do {
            let center = UNUserNotificationCenter.current()
            let options: UNAuthorizationOptions = [.alert, .sound, .badge]
            let granted = try await center.requestAuthorization(options: options)
            self.isAuthorized = granted
        } catch {
            print("Failed to authorize notifications: \(error)")
            self.isAuthorized = false
        }
    }
    
    @MainActor
    func checkAuthorization() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        self.isAuthorized = (settings.authorizationStatus == .authorized)
    }
    
    func scheduleGoalMetNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Goal Met!"
        content.body = "You've reached your creation goal. Consumption apps are now unlocked."
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "goalMet", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
}
