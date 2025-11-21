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
    
    // ✅ FIXED: Thêm support cho repeatType và reminderMinutes
    func createEvent(
        title: String,
        date: Date,
        notes: String? = nil,
        isAllDay: Bool = true,
        duration: TimeInterval = 3600,
        repeatType: EventRepeatType = .never,
        reminderMinutes: Int? = nil,
        completion: @escaping (Bool, String?, Error?) -> Void
    ) {
        guard hasCalendarAccess else {
            requestCalendarAccess { [weak self] granted, error in
                if granted {
                    self?.createEvent(
                        title: title,
                        date: date,
                        notes: notes,
                        isAllDay: isAllDay,
                        duration: duration,
                        repeatType: repeatType,
                        reminderMinutes: reminderMinutes,
                        completion: completion
                    )
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
        event.calendar = eventStore.defaultCalendarForNewEvents
        
        // ✅ FIX 1: Xử lý recurrence rules
        if let recurrenceRule = repeatType.ekRecurrenceRule {
            event.recurrenceRules = [recurrenceRule]
        } else if repeatType == .lunarMonthly || repeatType == .lunarYearly {
            // Âm lịch không được EventKit hỗ trợ - thêm cảnh báo vào notes
            let lunarWarning = """
            
            
            ⚠️ LƯU Ý QUAN TRỌNG:
            Sự kiện này được đặt lặp lại theo Âm lịch (\(repeatType.displayName)).
            
            Do hạn chế của Calendar hệ thống, tính năng lặp lại theo Âm lịch CHỈ hoạt động trong app Lịch Âm Việt Nam.
            
            Sự kiện này trong Calendar sẽ KHÔNG tự động lặp lại. Bạn cần:
            • Sử dụng app Lịch Âm để xem các lần lặp lại
            • Hoặc tạo từng sự kiện riêng lẻ trong Calendar
            """
            event.notes = (notes ?? "") + lunarWarning
        } else {
            event.notes = notes
        }
        
        // ✅ FIX 2: Thêm alarm/reminder
        if let reminderMinutes = reminderMinutes {
            let alarm = EKAlarm(relativeOffset: -Double(reminderMinutes * 60))
            event.addAlarm(alarm)
        }
        
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
