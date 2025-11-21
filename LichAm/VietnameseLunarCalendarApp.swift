import SwiftUI
import UserNotifications
import GoogleMobileAds

@main
struct VietnameseLunarCalendarApp: App {
    @StateObject private var calendarViewModel = CalendarViewModel()
    @StateObject private var notificationManager = NotificationManager()
    @StateObject private var calendarIntegration = CalendarIntegrationManager()
    @StateObject private var eventManager = EventManager()
    
    // Ad Managers
    @StateObject private var appOpenAdManager = AppOpenAdManager.shared
    @StateObject private var interstitialAdManager = InterstitialAdManager.shared
    
    init() {
        // Initialize Google Mobile Ads SDK
        MobileAds.shared.start { status in
            print("🎯 Google Mobile Ads SDK initialized")
            // Load ads after SDK is initialized
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                AppOpenAdManager.shared.loadAd()
                InterstitialAdManager.shared.loadAd()
            }
        }
        
        // Request notification permissions
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("✅ Notification permission granted")
            }
        }
        
        configureAppearance()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(calendarViewModel)
                .environmentObject(notificationManager)
                .environmentObject(calendarIntegration)
                .environmentObject(eventManager)
                .environmentObject(appOpenAdManager)
                .environmentObject(interstitialAdManager)
        }
    }
    
    private func configureAppearance() {
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
        
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithDefaultBackground()
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
}
