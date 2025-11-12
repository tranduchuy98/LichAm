import Foundation
import UserNotifications

class NotificationManager: ObservableObject {
    @Published var notificationsEnabled: Bool = false
    
    init() {
        checkNotificationStatus()
    }
    
    func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationsEnabled = settings.authorizationStatus == .authorized
            }
        }
    }
    
    func requestNotificationPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                self.notificationsEnabled = granted
                completion(granted)
            }
        }
    }
    
    func scheduleHolidayNotifications() {
        // Cancel existing notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        
        // Schedule notifications for major holidays
        scheduleNotificationsForYear(year: currentYear)
        scheduleNotificationsForYear(year: currentYear + 1)
        
        // Schedule notifications for new and full moon days
        scheduleMonthlyLunarNotifications()
    }
    
    private func scheduleNotificationsForYear(year: Int) {
        // Solar holidays
        let solarHolidays = HolidayManager.solarHolidays.filter { !$0.isLunar }
        for holiday in solarHolidays {
            scheduleNotification(
                for: holiday,
                day: holiday.day,
                month: holiday.month,
                year: year,
                isLunar: false
            )
        }
        
        // Lunar holidays - need to convert to solar dates
        let lunarHolidays = HolidayManager.lunarHolidays
        for holiday in lunarHolidays {
            // Convert lunar date to solar date for the given year
            if let solarDate = convertLunarToSolar(
                day: holiday.day,
                month: holiday.month,
                year: year
            ) {
                let components = Calendar.current.dateComponents([.year, .month, .day], from: solarDate)
                scheduleNotification(
                    for: holiday,
                    day: components.day!,
                    month: components.month!,
                    year: components.year!,
                    isLunar: true
                )
            }
        }
    }
    
    private func scheduleNotification(
        for holiday: VietnameseHoliday,
        day: Int,
        month: Int,
        year: Int,
        isLunar: Bool
    ) {
        let content = UNMutableNotificationContent()
        content.title = "\(holiday.emoji) \(holiday.name)"
        content.body = holiday.description
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = day
        dateComponents.hour = 8
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(
            identifier: "holiday_\(year)_\(month)_\(day)_\(holiday.name)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
    
    private func scheduleMonthlyLunarNotifications() {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        let currentMonth = calendar.component(.month, from: Date())
        
        // Schedule for next 12 months
        for monthOffset in 0..<12 {
            if let date = calendar.date(byAdding: .month, value: monthOffset, to: Date()) {
                let components = calendar.dateComponents([.year, .month], from: date)
                
                // Schedule notification for 1st lunar day
                scheduleSpecialLunarDayNotification(
                    year: components.year!,
                    month: components.month!,
                    lunarDay: 1,
                    title: "🌑 Mồng 1",
                    body: "Hôm nay là ngày Sóc - Mồng 1 Âm lịch"
                )
                
                // Schedule notification for 15th lunar day
                scheduleSpecialLunarDayNotification(
                    year: components.year!,
                    month: components.month!,
                    lunarDay: 15,
                    title: "🌕 Rằm",
                    body: "Hôm nay là ngày Vọng - Rằm Âm lịch"
                )
            }
        }
    }
    
    private func scheduleSpecialLunarDayNotification(
        year: Int,
        month: Int,
        lunarDay: Int,
        title: String,
        body: String
    ) {
        // Find the solar date for this lunar day
        for day in 1...31 {
            let lunarDate = LunarCalendarCalculator.convertSolarToLunar(
                day: day,
                month: month,
                year: year
            )
            
            if lunarDate.day == lunarDay {
                let content = UNMutableNotificationContent()
                content.title = title
                content.body = body
                content.sound = .default
                
                var dateComponents = DateComponents()
                dateComponents.year = year
                dateComponents.month = month
                dateComponents.day = day
                dateComponents.hour = 7
                dateComponents.minute = 0
                
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
                let request = UNNotificationRequest(
                    identifier: "lunar_\(year)_\(month)_\(day)_\(lunarDay)",
                    content: content,
                    trigger: trigger
                )
                
                UNUserNotificationCenter.current().add(request)
                break
            }
        }
    }
    
    private func convertLunarToSolar(day: Int, month: Int, year: Int) -> Date? {
        // This is a simplified approach - we'll search through the year to find the matching lunar date
        let calendar = Calendar.current
        
        for solarMonth in 1...12 {
            for solarDay in 1...31 {
                let lunarDate = LunarCalendarCalculator.convertSolarToLunar(
                    day: solarDay,
                    month: solarMonth,
                    year: year
                )
                
                if lunarDate.day == day && lunarDate.month == month && lunarDate.year == year {
                    var components = DateComponents()
                    components.year = year
                    components.month = solarMonth
                    components.day = solarDay
                    return calendar.date(from: components)
                }
            }
        }
        
        return nil
    }
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
