import SwiftUI
import Combine

class CalendarViewModel: ObservableObject {
    @Published var selectedDate: Date = Date()
    @Published var currentMonth: Date = Date()
    @Published var isDarkMode: Bool = false
    @Published var showSettings: Bool = false
    @Published var lunarDate: LunarDate
    @Published var todayHolidays: [VietnameseHoliday] = []
    @Published var zodiacAnimal: String = ""
    @Published var zodiacAnimalEnglish: String = ""
    @Published var canChi: String = ""
    
    private var cancellables = Set<AnyCancellable>()
    
    // Caching for lunar dates and auspicious hours - FIXED with NSLock
    private var lunarDateCache: [String: LunarDate] = [:]
    private let cacheLock = NSLock() // Use NSLock instead of DispatchQueue
    
    init() {
        var calendar = Calendar.current
        calendar.locale = Locale(identifier: "vi_VN")
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
        preloadNearbyMonths()
    }
    
    private func setupObservers() {
        $selectedDate
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .sink { [weak self] date in
                self?.updateCalendarData()
            }
            .store(in: &cancellables)
        
        if let storedDarkMode = UserDefaults.standard.value(forKey: "isDarkMode") as? Bool {
            isDarkMode = storedDarkMode
        }
        
        // Observe current month changes to preload nearby data
        $currentMonth
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.preloadNearbyMonths()
            }
            .store(in: &cancellables)
    }
    
    func updateCalendarData() {
        var calendar = Calendar.current
        calendar.locale = Locale(identifier: "vi_VN")
        let components = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        
        guard let day = components.day,
              let month = components.month,
              let year = components.year else { return }
        
        // Use cached lunar date if available
        let cacheKey = "\(year)-\(month)-\(day)"
        if let cachedLunarDate = getCachedLunarDate(for: cacheKey) {
            lunarDate = cachedLunarDate
        } else {
            lunarDate = LunarCalendarCalculator.convertSolarToLunar(
                day: day,
                month: month,
                year: year
            )
            cacheLunarDate(lunarDate, for: cacheKey)
        }
        
        zodiacAnimal = LunarCalendarCalculator.getZodiacAnimal(year: lunarDate.year)
        zodiacAnimalEnglish = LunarCalendarCalculator.getZodiacAnimalEnglish(year: lunarDate.year)
        canChi = LunarCalendarCalculator.getCanChi(year: lunarDate.year)
        
        todayHolidays = HolidayManager.getHolidaysForSolarDate(
            day: day,
            month: month,
            year: year
        )
    }
    
    // MARK: - Caching Methods (FIXED)
    
    private func getCachedLunarDate(for key: String) -> LunarDate? {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        return lunarDateCache[key]
    }
    
    private func cacheLunarDate(_ date: LunarDate, for key: String) {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        
        lunarDateCache[key] = date
        
        // Limit cache size
        if lunarDateCache.count > 500 {
            let keysToRemove = Array(lunarDateCache.keys.prefix(100))
            keysToRemove.forEach { lunarDateCache.removeValue(forKey: $0) }
        }
    }

    
    private func preloadNearbyMonths() {
        // Run preloading on background queue
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let calendar = Calendar.current
            
            // Preload previous and next 2 months
            for offset in -2...2 {
                guard let targetMonth = calendar.date(byAdding: .month, value: offset, to: self.currentMonth) else { continue }
                
                let monthComponents = calendar.dateComponents([.year, .month], from: targetMonth)
                guard let year = monthComponents.year,
                      let month = monthComponents.month,
                      let range = calendar.range(of: .day, in: .month, for: targetMonth) else { continue }
                
                for day in range {
                    let cacheKey = "\(year)-\(month)-\(day)"
                    
                    // Only preload if not already cached
                    if self.getCachedLunarDate(for: cacheKey) == nil {
                        let lunarDate = LunarCalendarCalculator.convertSolarToLunar(
                            day: day,
                            month: month,
                            year: year
                        )
                        self.cacheLunarDate(lunarDate, for: cacheKey)
                    }
                }
            }
        }
    }
    
    // MARK: - Navigation Methods
    
    func toggleDarkMode() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isDarkMode.toggle()
        }
        UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
    }
    
    func selectDate(_ date: Date) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            selectedDate = date
            
            let calendar = Calendar.current
            if let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: date)) {
                currentMonth = monthStart
            }
        }
        
        updateCalendarData()
    }
    
    func goToToday() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            selectedDate = Date()
            currentMonth = Date()
            
            let calendar = Calendar.current
            if let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedDate)) {
                currentMonth = monthStart
            }
        }
        
        updateCalendarData()
    }
    
    func previousMonth() {
        let calendar = Calendar.current
        if let newMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentMonth = newMonth
            }
        }
    }
    
    func nextMonth() {
        let calendar = Calendar.current
        if let newMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentMonth = newMonth
            }
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
    
    func getLunarDateForDate(_ date: Date) -> LunarDate {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        
        let cacheKey = "\(components.year!)-\(components.month!)-\(components.day!)"
        if let cached = getCachedLunarDate(for: cacheKey) {
            return cached
        }
        
        let lunarDate = LunarCalendarCalculator.convertSolarToLunar(
            day: components.day!,
            month: components.month!,
            year: components.year!
        )
        cacheLunarDate(lunarDate, for: cacheKey)
        return lunarDate
    }
}
