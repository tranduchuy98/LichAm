import SwiftUI
import Combine

class CalendarViewModel: ObservableObject {
    @Published var selectedDate: Date = Date()
    @Published var currentMonth: Date = Date()
    @Published var isDarkMode: Bool = false
    @Published var showSettings: Bool = false
    @Published var lunarDate: LunarDate
    @Published var todayHolidays: [VietnameseHoliday] = []
    @Published var auspiciousHours: [AuspiciousHour] = []
    @Published var zodiacAnimal: String = ""
    @Published var zodiacAnimalEnglish: String = ""
    @Published var canChi: String = ""
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: Date())
        
        self.lunarDate = LunarCalendarCalculator.convertSolarToLunar(
            day: components.day!,
            month: components.month!,
            year: components.year!
        )
        
        self.zodiacAnimal = LunarCalendarCalculator.getZodiacAnimal(year: lunarDate.year)
        self.zodiacAnimalEnglish = LunarCalendarCalculator.getZodiacAnimalEnglish(year: lunarDate.year)
        self.canChi = LunarCalendarCalculator.getCanChi(year: lunarDate.year)
        
        setupObservers()
        updateCalendarData()
    }
    
    private func setupObservers() {
        $selectedDate
            .sink { [weak self] date in
                self?.updateCalendarData()
            }
            .store(in: &cancellables)
        
        if let storedDarkMode = UserDefaults.standard.value(forKey: "isDarkMode") as? Bool {
            isDarkMode = storedDarkMode
        }
    }
    
    func updateCalendarData() {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        
        guard let day = components.day,
              let month = components.month,
              let year = components.year else { return }
        
        lunarDate = LunarCalendarCalculator.convertSolarToLunar(
            day: day,
            month: month,
            year: year
        )
        
        zodiacAnimal = LunarCalendarCalculator.getZodiacAnimal(year: lunarDate.year)
        zodiacAnimalEnglish = LunarCalendarCalculator.getZodiacAnimalEnglish(year: lunarDate.year)
        canChi = LunarCalendarCalculator.getCanChi(year: lunarDate.year)
        
        todayHolidays = HolidayManager.getHolidaysForSolarDate(
            day: day,
            month: month,
            year: year
        )
        
        auspiciousHours = LunarCalendarCalculator.getAuspiciousHours(
            day: day,
            month: month,
            year: year
        )
    }
    
    func toggleDarkMode() {
        isDarkMode.toggle()
        UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
    }
    
    func selectDate(_ date: Date) {
        selectedDate = date

        let calendar = Calendar.current
        if let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: date)) {
            currentMonth = monthStart
        }

        updateCalendarData()
    }
    
    func goToToday() {
        selectedDate = Date()
        currentMonth = Date()
        
        let calendar = Calendar.current
        if let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedDate)) {
            currentMonth = monthStart
        }

        updateCalendarData()
    }
    
    func previousMonth() {
        let calendar = Calendar.current
        if let newMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) {
            currentMonth = newMonth
        }
    }
    
    func nextMonth() {
        let calendar = Calendar.current
        if let newMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) {
            currentMonth = newMonth
        }
    }
    
    func getDaysInMonth() -> [Date?] {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: currentMonth)
        
        guard let firstDayOfMonth = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: firstDayOfMonth) else {
            return []
        }
        
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        var days: [Date?] = Array(repeating: nil, count: firstWeekday - 1)
        
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) {
                days.append(date)
            }
        }
        
        return days
    }
    
    func isToday(_ date: Date?) -> Bool {
        guard let date = date else { return false }
        return Calendar.current.isDateInToday(date)
    }
    
    func isSelected(_ date: Date?) -> Bool {
        guard let date = date else { return false }
        return Calendar.current.isDate(date, inSameDayAs: selectedDate)
    }
    
    func hasHoliday(_ date: Date?) -> Bool {
        guard let date = date else { return false }
        let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        let holidays = HolidayManager.getHolidaysForSolarDate(
            day: components.day!,
            month: components.month!,
            year: components.year!
        )
        return !holidays.isEmpty
    }
}
