import SwiftUI
import UserNotifications

@main
struct VietnameseLunarCalendarApp: App {
    @StateObject private var calendarViewModel = CalendarViewModel()
    @StateObject private var notificationManager = NotificationManager()
    @StateObject private var calendarIntegration = CalendarIntegrationManager()
    @StateObject private var eventManager = EventManager() // NEW!
    
    init() {
        // Request notification permissions on app launch
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            }
        }
        
        // Configure app appearance
        configureAppearance()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(calendarViewModel)
                .environmentObject(notificationManager)
                .environmentObject(calendarIntegration)
                .environmentObject(eventManager) // NEW!
                .preferredColorScheme(calendarViewModel.isDarkMode ? .dark : .light)
                .animation(.easeInOut(duration: 0.3), value: calendarViewModel.isDarkMode)
        }
    }
    
    private func configureAppearance() {
        // Navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.titleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        appearance.largeTitleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
        // Tab bar appearance (if needed in future)
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithDefaultBackground()
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
}
