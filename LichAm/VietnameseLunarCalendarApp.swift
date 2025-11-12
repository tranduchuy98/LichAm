//
//  LichAmApp.swift
//  LichAm
//
//  Created by Huy Tran on 12/11/25.
//

import SwiftUI
import UserNotifications

@main
struct VietnameseLunarCalendarApp: App {
    @StateObject private var calendarViewModel = CalendarViewModel()
    @StateObject private var notificationManager = NotificationManager()
    
    init() {
        // Request notification permissions on app launch
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(calendarViewModel)
                .environmentObject(notificationManager)
                .preferredColorScheme(calendarViewModel.isDarkMode ? .dark : .light)
        }
    }
}
