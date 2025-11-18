import Foundation
import EventKit

class CalendarIntegrationManager: ObservableObject {
    @Published var hasCalendarAccess: Bool = false
    @Published var isRequestingAccess: Bool = false
    
    private let eventStore = EKEventStore()
    
    init() {
        checkCalendarAccess()
    }
    
    func checkCalendarAccess() {
        let status = EKEventStore.authorizationStatus(for: .event)
        DispatchQueue.main.async {
            self.hasCalendarAccess = (status == .authorized)
        }
    }
    
    func requestCalendarAccess(completion: @escaping (Bool, Error?) -> Void) {
        isRequestingAccess = true
        
        eventStore.requestAccess(to: .event) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.isRequestingAccess = false
                self?.hasCalendarAccess = granted
                completion(granted, error)
            }
        }
    }
    
    // UPDATED: Now returns the actual EventKit identifier
    func createEvent(
        title: String,
        date: Date,
        notes: String? = nil,
        isAllDay: Bool = true,
        duration: TimeInterval = 3600,
        completion: @escaping (Bool, String?, Error?) -> Void
    ) {
        guard hasCalendarAccess else {
            requestCalendarAccess { [weak self] granted, error in
                if granted {
                    self?.createEvent(title: title, date: date, notes: notes, isAllDay: isAllDay, duration: duration, completion: completion)
                } else {
                    completion(false, nil, error)
                }
            }
            return
        }
        
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = date
        event.endDate = isAllDay ? Calendar.current.date(byAdding: .day, value: 1, to: date) : date.addingTimeInterval(duration)
        event.isAllDay = isAllDay
        event.notes = notes
        event.calendar = eventStore.defaultCalendarForNewEvents
        
        do {
            try eventStore.save(event, span: .thisEvent)
            // Return the actual EventKit identifier
            completion(true, event.eventIdentifier, nil)
        } catch {
            completion(false, nil, error)
        }
    }
    
    func createHolidayEvent(
        holiday: VietnameseHoliday,
        date: Date,
        completion: @escaping (Bool, String?, Error?) -> Void
    ) {
        let title = "\(holiday.emoji) \(holiday.name)"
        let notes = """
        \(holiday.nameEnglish)
        
        \(holiday.description)
        """
        
        createEvent(
            title: title,
            date: date,
            notes: notes,
            isAllDay: true,
            completion: completion
        )
    }
    
    func createLunarDateReminder(
        lunarDate: LunarDate,
        solarDate: Date,
        completion: @escaping (Bool, String?, Error?) -> Void
    ) {
        let title = "🌙 Ngày \(lunarDate.displayString)"
        let notes = "Âm lịch: \(lunarDate.displayString)"
        
        createEvent(
            title: title,
            date: solarDate,
            notes: notes,
            isAllDay: true,
            completion: completion
        )
    }
}
