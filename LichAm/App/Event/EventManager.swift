import Foundation
import Combine
import UserNotifications

class EventManager: ObservableObject {
    @Published var events: [LichAmEvent] = []
    
    private let userDefaultsKey = "LichAmEvents"
    private let notificationManager = UNUserNotificationCenter.current()
    
    init() {
        loadEvents()
    }
    
    // MARK: - CRUD Operations
    
    func addEvent(_ event: LichAmEvent) {
        var newEvent = event
        newEvent.createdAt = Date()
        newEvent.updatedAt = Date()
        events.append(newEvent)
        saveEvents()
        scheduleNotification(for: newEvent)
    }
    
    func updateEvent(_ event: LichAmEvent) {
        guard let index = events.firstIndex(where: { $0.id == event.id }) else { return }
        var updatedEvent = event
        updatedEvent.updatedAt = Date()
        events[index] = updatedEvent
        saveEvents()
        
        // Cancel old notification and schedule new one
        cancelNotification(for: event)
        scheduleNotification(for: updatedEvent)
    }
    
    func deleteEvent(_ event: LichAmEvent) {
        events.removeAll { $0.id == event.id }
        saveEvents()
        cancelNotification(for: event)
    }
    
    func deleteEvent(at offsets: IndexSet) {
        let eventsToDelete = offsets.map { events[$0] }
        events.remove(atOffsets: offsets)
        saveEvents()
        
        eventsToDelete.forEach { cancelNotification(for: $0) }
    }
    
    // MARK: - Persistence
    
    private func saveEvents() {
        if let encoded = try? JSONEncoder().encode(events) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    private func loadEvents() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let decoded = try? JSONDecoder().decode([LichAmEvent].self, from: data) else {
            return
        }
        events = decoded
    }
    
    // MARK: - Query Operations
    
    func getEvents(for date: Date) -> [LichAmEvent] {
        let calendar = Calendar.current
        return events.filter { event in
            if event.isLunarDateBased {
                // Check lunar date
                return isEventOnLunarDate(event, date: date)
            } else {
                // Check solar date
                return calendar.isDate(event.startDate, inSameDayAs: date) ||
                       (event.startDate <= date && event.endDate >= date)
            }
        }.sorted { $0.startDate < $1.startDate }
    }
    
    func getEvents(in dateRange: DateInterval) -> [LichAmEvent] {
        events.filter { event in
            let eventInterval = DateInterval(start: event.startDate, end: event.endDate)
            return dateRange.intersects(eventInterval)
        }.sorted { $0.startDate < $1.startDate }
    }
    
    func getUpcomingEvents(limit: Int = 10) -> [LichAmEvent] {
        let now = Date()
        return events
            .filter { $0.startDate >= now }
            .sorted { $0.startDate < $1.startDate }
            .prefix(limit)
            .map { $0 }
    }
    
    private func isEventOnLunarDate(_ event: LichAmEvent, date: Date) -> Bool {
        guard let lunarDay = event.lunarDay,
              let lunarMonth = event.lunarMonth else {
            return false
        }
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        
        let lunarDate = LunarCalendarCalculator.convertSolarToLunar(
            day: components.day!,
            month: components.month!,
            year: components.year!
        )
        
        switch event.repeatType {
        case .lunarMonthly:
            return lunarDate.day == lunarDay
        case .lunarYearly:
            return lunarDate.day == lunarDay && lunarDate.month == lunarMonth
        case .never:
            return lunarDate.day == lunarDay && lunarDate.month == lunarMonth
        default:
            return false
        }
    }
    
    // MARK: - Notifications
    
    private func scheduleNotification(for event: LichAmEvent) {
        guard let reminderMinutes = event.reminderMinutesBefore else { return }
        
        let content = UNMutableNotificationContent()
        content.title = event.title
        content.body = event.notes ?? "Sự kiện sắp bắt đầu"
        content.sound = .default
        content.badge = 1
        
        let reminderDate = event.startDate.addingTimeInterval(-Double(reminderMinutes * 60))
        
        // Only schedule if reminder date is in the future
        guard reminderDate > Date() else { return }
        
        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: reminderDate
        )
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: event.repeatType != .never
        )
        
        let request = UNNotificationRequest(
            identifier: "event_\(event.id)",
            content: content,
            trigger: trigger
        )
        
        notificationManager.add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
    
    private func cancelNotification(for event: LichAmEvent) {
        notificationManager.removePendingNotificationRequests(withIdentifiers: ["event_\(event.id)"])
    }
    
    // MARK: - Statistics
    
    func getTotalEventsCount() -> Int {
        return events.count
    }
    
    func getEventsCount(for date: Date) -> Int {
        return getEvents(for: date).count
    }
    
    func hasEvents(for date: Date) -> Bool {
        return !getEvents(for: date).isEmpty
    }
}
