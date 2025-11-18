import WidgetKit
import SwiftUI

// MARK: - Widget Timeline Provider
struct LunarCalendarProvider: TimelineProvider {
    func placeholder(in context: Context) -> LunarCalendarEntry {
        LunarCalendarEntry(date: Date(), lunarDate: sampleLunarDate(), holidays: [], auspiciousHours: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (LunarCalendarEntry) -> Void) {
        let entry = createEntry(for: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LunarCalendarEntry>) -> Void) {
        var entries: [LunarCalendarEntry] = []
        let currentDate = Date()

        // Create entries for every hour for the next 24 hours
        for hourOffset in 0..<24 {
            if let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate) {
                let entry = createEntry(for: entryDate)
                entries.append(entry)
            }
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }

    private func createEntry(for date: Date) -> LunarCalendarEntry {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)

        let lunarDate = LunarCalendarCalculator.convertSolarToLunar(
            day: components.day!,
            month: components.month!,
            year: components.year!
        )

        let holidays = HolidayManager.getHolidaysForSolarDate(
            day: components.day!,
            month: components.month!,
            year: components.year!
        )
        
        // Calculate auspicious hours
        let jdn = julianDayNumber(day: components.day!, month: components.month!, year: components.year!)
        let dayChiIndex = positiveMod(jdn + 1, 12)
        let chiOrder = ["Tý","Sửu","Dần","Mão","Thìn","Tỵ","Ngọ","Mùi","Thân","Dậu","Tuất","Hợi"]
        let dayChi = chiOrder[dayChiIndex]
        let auspiciousHours = AuspiciousHoursManager.gioHoangDaoMapping[dayChi] ?? []

        return LunarCalendarEntry(
            date: date,
            lunarDate: lunarDate,
            holidays: holidays,
            auspiciousHours: auspiciousHours
        )
    }

    private func sampleLunarDate() -> LunarDate {
        return LunarDate(day: 15, month: 8, year: 2024, isLeapMonth: false)
    }
    
    private func julianDayNumber(day: Int, month: Int, year: Int) -> Int {
        let a = (14 - month) / 12
        let y = year + 4800 - a
        let m = month + 12 * a - 3
        var jd = day + (153 * m + 2) / 5 + 365 * y + y / 4 - y / 100 + y / 400 - 32045
        
        if jd < 2299161 {
            jd = day + (153 * m + 2) / 5 + 365 * y + y / 4 - 32083
        }
        
        return jd
    }
    
    private func positiveMod(_ a: Int, _ m: Int) -> Int {
        let r = a % m
        return r >= 0 ? r : r + m
    }
}

// MARK: - Widget Entry
struct LunarCalendarEntry: TimelineEntry {
    let date: Date
    let lunarDate: LunarDate
    let holidays: [VietnameseHoliday]
    let auspiciousHours: [String]
}

// MARK: - Small Widget View WITH AUSPICIOUS HOURS
struct SmallWidgetView: View {
    var entry: LunarCalendarProvider.Entry
    
    private var canChi: String {
        LunarCalendarCalculator.getCanChi(year: entry.lunarDate.year)
    }
    
    private var dayChi: String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: entry.date)
        return LunarCalendarCalculator.getDayCanChi(
            day: components.day!,
            month: components.month!,
            year: components.year!
        )
    }
    
    private var currentHour: String {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: entry.date)
        let chiOrder = ["Tý","Sửu","Dần","Mão","Thìn","Tỵ","Ngọ","Mùi","Thân","Dậu","Tuất","Hợi"]
        
        // Calculate chi index for current hour
        // Tý: 23-1, Sửu: 1-3, Dần: 3-5, etc.
        let chiIndex: Int
        if hour == 23 || hour == 0 {
            chiIndex = 0 // Tý
        } else {
            chiIndex = (hour + 1) / 2
        }
        
        return chiOrder[chiIndex]
    }
    
    private var isCurrentHourAuspicious: Bool {
        entry.auspiciousHours.contains(currentHour)
    }

    var body: some View {
        if #available(iOS 17.0, *) {
            VStack(spacing: 6) {
                // Can Chi at top
                Text(dayChi)
                    .font(.system(size: 10, weight: .semibold, design: .serif))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.red))
                
                // LARGE LUNAR DATE - PRIMARY FOCUS
                HStack(spacing: 6) {
                    Image(systemName: "moon.fill")
                        .font(.title2)
                        .foregroundColor(.red.opacity(0.8))
                    
                    VStack(spacing: 1) {
                        Text("\(entry.lunarDate.day)")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.red)
                        
                        Text("T\(entry.lunarDate.month)")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.red.opacity(0.7))
                    }
                }
                
                // Smaller solar date
                Text("Dương: \(Calendar.current.component(.day, from: entry.date))/\(Calendar.current.component(.month, from: entry.date))")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.primary.opacity(0.7))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.red.opacity(0.1)))
                
                // AUSPICIOUS HOUR INDICATOR
                HStack(spacing: 4) {
                    Image(systemName: isCurrentHourAuspicious ? "star.fill" : "moon.stars.fill")
                        .font(.system(size: 9))
                        .foregroundColor(isCurrentHourAuspicious ? .yellow : .gray)
                    
                    Text(currentHour)
                        .font(.system(size: 10, weight: .bold, design: .serif))
                        .foregroundColor(isCurrentHourAuspicious ? .yellow : .secondary)
                    
                    Text(isCurrentHourAuspicious ? "Tốt" : "Hắc")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundColor(isCurrentHourAuspicious ? .yellow : .secondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isCurrentHourAuspicious ? Color.yellow.opacity(0.2) : Color.gray.opacity(0.1))
                )
                
                // Holiday indicator
                if !entry.holidays.isEmpty {
                    Text(entry.holidays[0].emoji)
                        .font(.caption)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .containerBackground(for: .widget) {
                ZStack {
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 1.0, green: 0.95, blue: 0.9),
                            Color(red: 1.0, green: 0.92, blue: 0.85)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    Circle().fill(Color.red.opacity(0.05)).frame(width: 120, height: 120).offset(x: -30, y: -40)
                    Circle().fill(Color.orange.opacity(0.05)).frame(width: 100, height: 100).offset(x: 50, y: 60)
                }
            }
        } else {
            // iOS 16 fallback
            VStack(spacing: 6) {
                Text(dayChi)
                    .font(.system(size: 10, weight: .semibold, design: .serif))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.red))
                
                HStack(spacing: 6) {
                    Image(systemName: "moon.fill")
                        .font(.title2)
                        .foregroundColor(.red.opacity(0.8))
                    
                    VStack(spacing: 1) {
                        Text("\(entry.lunarDate.day)")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.red)
                        Text("T\(entry.lunarDate.month)")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.red.opacity(0.7))
                    }
                }
                
                Text("Dương: \(Calendar.current.component(.day, from: entry.date))/\(Calendar.current.component(.month, from: entry.date))")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.primary.opacity(0.7))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.red.opacity(0.1)))
                
                HStack(spacing: 4) {
                    Image(systemName: isCurrentHourAuspicious ? "star.fill" : "moon.stars.fill")
                        .font(.system(size: 9))
                        .foregroundColor(isCurrentHourAuspicious ? .yellow : .gray)
                    Text(currentHour)
                        .font(.system(size: 10, weight: .bold, design: .serif))
                        .foregroundColor(isCurrentHourAuspicious ? .yellow : .secondary)
                    Text(isCurrentHourAuspicious ? "Tốt" : "Hắc")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundColor(isCurrentHourAuspicious ? .yellow : .secondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isCurrentHourAuspicious ? Color.yellow.opacity(0.2) : Color.gray.opacity(0.1))
                )
                
                if !entry.holidays.isEmpty {
                    Text(entry.holidays[0].emoji)
                        .font(.caption)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                ZStack {
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 1.0, green: 0.95, blue: 0.9),
                            Color(red: 1.0, green: 0.92, blue: 0.85)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Circle().fill(Color.red.opacity(0.05)).frame(width: 120, height: 120).offset(x: -30, y: -40)
                    Circle().fill(Color.orange.opacity(0.05)).frame(width: 100, height: 100).offset(x: 50, y: 60)
                }
            )
        }
    }
}
// MARK: - Medium Widget View (continued from Part 1)
struct MediumWidgetView: View {
    var entry: LunarCalendarProvider.Entry
    
    private var canChi: String {
        LunarCalendarCalculator.getCanChi(year: entry.lunarDate.year)
    }
    
    private var dayChi: String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: entry.date)
        return LunarCalendarCalculator.getDayCanChi(
            day: components.day!,
            month: components.month!,
            year: components.year!
        )
    }

    var body: some View {
        if #available(iOS 17.0, *) {
            HStack(spacing: 16) {
                // Left side - Large lunar day number
                VStack(spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: "moon.fill")
                            .font(.title2)
                            .foregroundColor(.red)
                        
                        VStack(spacing: 2) {
                            Text("\(entry.lunarDate.day)")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundColor(.red)
                            
                            Text("Tháng \(entry.lunarDate.month)")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.red.opacity(0.7))
                        }
                    }
                    
                    Text("Âm lịch")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .frame(width: 130)
                
                Divider()
                    .frame(height: 80)
                
                // Right side - Additional info
                VStack(alignment: .leading, spacing: 10) {
                    // Month and year
                    Text(entry.date, formatter: monthYearFormatter)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    // Solar date
                    HStack(spacing: 6) {
                        Image(systemName: "sun.max.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Dương lịch")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.secondary)
                            HStack(spacing: 2) {
                                Text("\(Calendar.current.component(.day, from: entry.date))")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.primary)
                                Text("/")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                                Text("\(Calendar.current.component(.month, from: entry.date))")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                    
                    // Can Chi
                    HStack(spacing: 6) {
                        Image(systemName: "star.circle")
                            .foregroundColor(.red)
                            .font(.caption)
                        Text(dayChi)
                            .font(.system(size: 11, weight: .semibold, design: .serif))
                            .foregroundColor(.primary)
                    }
                    
                    // Holiday
                    if !entry.holidays.isEmpty {
                        HStack(spacing: 6) {
                            Text(entry.holidays[0].emoji)
                                .font(.caption)
                            Text(entry.holidays[0].name)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.red)
                                .lineLimit(1)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .containerBackground(for: .widget) {
                ZStack {
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 1.0, green: 0.95, blue: 0.9),
                            Color(red: 1.0, green: 0.92, blue: 0.85)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    Circle()
                        .fill(Color.red.opacity(0.04))
                        .frame(width: 180, height: 180)
                        .offset(x: -60, y: -30)
                    
                    Circle()
                        .fill(Color.orange.opacity(0.04))
                        .frame(width: 150, height: 150)
                        .offset(x: 100, y: 50)
                }
            }
        } else {
            HStack(spacing: 16) {
                VStack(spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: "moon.fill")
                            .font(.title2)
                            .foregroundColor(.red)
                        
                        VStack(spacing: 2) {
                            Text("\(entry.lunarDate.day)")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundColor(.red)
                            
                            Text("Tháng \(entry.lunarDate.month)")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.red.opacity(0.7))
                        }
                    }
                    
                    Text("Âm lịch")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .frame(width: 130)
                
                Divider().frame(height: 80)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text(entry.date, formatter: monthYearFormatter)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 6) {
                        Image(systemName: "sun.max.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Dương lịch")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.secondary)
                            HStack(spacing: 2) {
                                Text("\(Calendar.current.component(.day, from: entry.date))")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.primary)
                                Text("/")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                                Text("\(Calendar.current.component(.month, from: entry.date))")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                    
                    HStack(spacing: 6) {
                        Image(systemName: "star.circle")
                            .foregroundColor(.red)
                            .font(.caption)
                        Text(dayChi)
                            .font(.system(size: 11, weight: .semibold, design: .serif))
                            .foregroundColor(.primary)
                    }
                    
                    if !entry.holidays.isEmpty {
                        HStack(spacing: 6) {
                            Text(entry.holidays[0].emoji)
                                .font(.caption)
                            Text(entry.holidays[0].name)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.red)
                                .lineLimit(1)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                ZStack {
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 1.0, green: 0.95, blue: 0.9),
                            Color(red: 1.0, green: 0.92, blue: 0.85)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    Circle().fill(Color.red.opacity(0.04)).frame(width: 180, height: 180).offset(x: -60, y: -30)
                    Circle().fill(Color.orange.opacity(0.04)).frame(width: 150, height: 150).offset(x: 100, y: 50)
                }
            )
        }
    }

    private var monthYearFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale(identifier: "vi_VN")
        return formatter
    }
}

// MARK: - Large Widget View WITH AUSPICIOUS HOURS
struct LargeWidgetView: View {
    var entry: LunarCalendarProvider.Entry
    
    private var canChi: String {
        LunarCalendarCalculator.getCanChi(year: entry.lunarDate.year)
    }
    
    private var dayChi: String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: entry.date)
        return LunarCalendarCalculator.getDayCanChi(
            day: components.day!,
            month: components.month!,
            year: components.year!
        )
    }

    var body: some View {
        if #available(iOS 17.0, *) {
            VStack(spacing: 12) {
                // Header with current date info
                VStack(spacing: 8) {
                    Text(entry.date, formatter: monthYearFormatter)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.red)
                    
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Âm: \(entry.lunarDate.day)/\(entry.lunarDate.month)")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.red)
                            Text("Dương: \(Calendar.current.component(.day, from: entry.date))/\(Calendar.current.component(.month, from: entry.date))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Divider().frame(height: 30)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(dayChi)
                                .font(.system(size: 11, weight: .semibold, design: .serif))
                                .foregroundColor(.primary)
                            Text(canChi)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal)
                
                Divider()
                
                // Mini Calendar
                WidgetCalendarView(currentDate: entry.date, lunarDate: entry.lunarDate)
                    .padding(.horizontal, 8)
                
                // Holiday indicator at bottom
                if !entry.holidays.isEmpty {
                    HStack {
                        Text(entry.holidays[0].emoji)
                        Text(entry.holidays[0].name)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                        Spacer()
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .containerBackground(for: .widget) {
                ZStack {
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 1.0, green: 0.95, blue: 0.9),
                            Color(red: 1.0, green: 0.92, blue: 0.85)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    Circle()
                        .fill(Color.red.opacity(0.03))
                        .frame(width: 240, height: 240)
                        .offset(x: -80, y: -60)
                    
                    Circle()
                        .fill(Color.orange.opacity(0.03))
                        .frame(width: 200, height: 200)
                        .offset(x: 120, y: 100)
                }
            }
        } else {
            VStack(spacing: 12) {
                // Header with current date info
                VStack(spacing: 8) {
                    Text(entry.date, formatter: monthYearFormatter)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.red)
                    
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Âm: \(entry.lunarDate.day)/\(entry.lunarDate.month)")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.red)
                            Text("Dương: \(Calendar.current.component(.day, from: entry.date))/\(Calendar.current.component(.month, from: entry.date))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Divider().frame(height: 30)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(dayChi)
                                .font(.system(size: 11, weight: .semibold, design: .serif))
                                .foregroundColor(.primary)
                            Text(canChi)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal)
                
                Divider()
                
                // Mini Calendar
                WidgetCalendarView(currentDate: entry.date, lunarDate: entry.lunarDate)
                    .padding(.horizontal, 8)
                
                // Holiday indicator at bottom
                if !entry.holidays.isEmpty {
                    HStack {
                        Text(entry.holidays[0].emoji)
                        Text(entry.holidays[0].name)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                        Spacer()
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                ZStack {
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 1.0, green: 0.95, blue: 0.9),
                            Color(red: 1.0, green: 0.92, blue: 0.85)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    Circle()
                        .fill(Color.red.opacity(0.03))
                        .frame(width: 240, height: 240)
                        .offset(x: -80, y: -60)
                    
                    Circle()
                        .fill(Color.orange.opacity(0.03))
                        .frame(width: 200, height: 200)
                        .offset(x: 120, y: 100)
                }
            )
        }
    }
    
    private var monthYearFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale(identifier: "vi_VN")
        return formatter
    }
}

struct WidgetCalendarView: View {
    let currentDate: Date
    let lunarDate: LunarDate
    
    let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    let weekdays = ["CN", "T2", "T3", "T4", "T5", "T6", "T7"]
    
    private func getDaysInMonth() -> [Date?] {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: currentDate)
        
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
    
    var body: some View {
        VStack(spacing: 6) {
            // Weekday headers
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(weekdays, id: \.self) { weekday in
                    Text(weekday)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Calendar days
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(getDaysInMonth(), id: \.self) { date in
                    if let date = date {
                        let calendar = Calendar.current
                        let components = calendar.dateComponents([.year, .month, .day], from: date)
                        let dayLunarDate = LunarCalendarCalculator.convertSolarToLunar(
                            day: components.day!,
                            month: components.month!,
                            year: components.year!
                        )
                        let isToday = calendar.isDateInToday(date)
                        let isCurrentDate = calendar.isDate(date, inSameDayAs: currentDate)
                        
                        VStack(spacing: 1) {
                            Text("\(components.day!)")
                                .font(.system(size: 12, weight: isToday ? .bold : .semibold))
                                .foregroundColor(isCurrentDate ? .white : (isToday ? .red : .primary))
                            
                            Text("\(dayLunarDate.day)")
                                .font(.system(size: 8))
                                .foregroundColor(isCurrentDate ? .white.opacity(0.8) : .secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(isCurrentDate ? Color.red : (isToday ? Color.red.opacity(0.1) : Color.clear))
                        )
                    } else {
                        Color.clear
                            .frame(height: 36)
                    }
                }
            }
        }
    }
}

// MARK: - IMPROVED ACCESSORY VIEWS FOR LOCK SCREEN

// MARK: - Accessory Circular - Lunar Date Focus
@available(iOS 16.0, *)
struct AccessoryCircularView: View {
    var entry: LunarCalendarProvider.Entry
    
    var body: some View {
        if #available(iOSApplicationExtension 17.0, *) {
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: 0) {
                    Text("\(entry.lunarDate.day)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                    Text("T\(entry.lunarDate.month)")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.red)
                }
            }
            .containerBackground(for: .widget) {}
        } else {
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: 0) {
                    Text("\(entry.lunarDate.day)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                    Text("T\(entry.lunarDate.month)")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.red)
                }
            }
        }
    }
}

// MARK: - Accessory Rectangular - IMPROVED with Can Chi and Clear Layout
@available(iOS 16.0, *)
struct AccessoryRectangularView: View {
    var entry: LunarCalendarProvider.Entry
    
    private var yearCanChi: String {
        LunarCalendarCalculator.getCanChi(year: entry.lunarDate.year)
    }
    
    var body: some View {
        if #available(iOSApplicationExtension 17.0, *) {
            VStack(alignment: .leading, spacing: 4) {
                // Top row: Large lunar date
                HStack(spacing: 6) {
                    Image(systemName: "moon.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                    
                    HStack(spacing: 2) {
                        Text("\(entry.lunarDate.day)")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                        Text("/")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                        Text("\(entry.lunarDate.month)")
                            .font(.system(size: 20, weight: .bold))
                    }
                    
                    Spacer()
                    
                    // Solar date (smaller)
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("Dương")
                            .font(.system(size: 7))
                            .foregroundColor(.secondary)
                        HStack(spacing: 1) {
                            Text("\(Calendar.current.component(.day, from: entry.date))")
                                .font(.system(size: 14, weight: .semibold))
                            Text("/\(Calendar.current.component(.month, from: entry.date))")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Bottom row: Can Chi and holiday
                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "star.circle.fill")
                            .font(.system(size: 8))
                            .foregroundColor(.yellow)
                        Text(yearCanChi)
                            .font(.system(size: 10, weight: .semibold, design: .serif))
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.yellow.opacity(0.15))
                    )
                    
                    if !entry.holidays.isEmpty {
                        HStack(spacing: 3) {
                            Text(entry.holidays[0].emoji)
                                .font(.system(size: 10))
                            Text(entry.holidays[0].name)
                                .font(.system(size: 9, weight: .medium))
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer()
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .containerBackground(for: .widget) {}
        } else {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "moon.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                    
                    HStack(spacing: 2) {
                        Text("\(entry.lunarDate.day)")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                        Text("/")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                        Text("\(entry.lunarDate.month)")
                            .font(.system(size: 20, weight: .bold))
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("Dương")
                            .font(.system(size: 7))
                            .foregroundColor(.secondary)
                        HStack(spacing: 1) {
                            Text("\(Calendar.current.component(.day, from: entry.date))")
                                .font(.system(size: 14, weight: .semibold))
                            Text("/\(Calendar.current.component(.month, from: entry.date))")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "star.circle.fill")
                            .font(.system(size: 8))
                            .foregroundColor(.yellow)
                        Text(yearCanChi)
                            .font(.system(size: 10, weight: .semibold, design: .serif))
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.yellow.opacity(0.15))
                    )
                    
                    if !entry.holidays.isEmpty {
                        HStack(spacing: 3) {
                            Text(entry.holidays[0].emoji)
                                .font(.system(size: 10))
                            Text(entry.holidays[0].name)
                                .font(.system(size: 9, weight: .medium))
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer()
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
        }
    }
}

// MARK: - Accessory Inline - BEAUTIFIED Lunar Only
@available(iOS 16.0, *)
struct AccessoryInlineView: View {
    var entry: LunarCalendarProvider.Entry
    
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "moon.fill")
            
            Text("Âm:")
                .fontWeight(.medium)
            
            HStack(spacing: 2) {
                Text("\(entry.lunarDate.day)")
                    .fontWeight(.bold)
                Text("/")
                    .fontWeight(.medium)
                Text("\(entry.lunarDate.month)")
                    .fontWeight(.bold)
                Text("/")
                    .fontWeight(.medium)
                Text("\(entry.lunarDate.year)")
                    .fontWeight(.medium)
            }
            
            if !entry.holidays.isEmpty {
                Text("•")
                    .fontWeight(.light)
                Text(entry.holidays[0].emoji)
            }
        }
    }
}

// MARK: - Widget Entry View
struct LunarCalendarWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: LunarCalendarProvider.Entry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        case .accessoryCircular:
            if #available(iOS 16.0, *) {
                AccessoryCircularView(entry: entry)
            } else {
                SmallWidgetView(entry: entry)
            }
        case .accessoryRectangular:
            if #available(iOS 16.0, *) {
                AccessoryRectangularView(entry: entry)
            } else {
                SmallWidgetView(entry: entry)
            }
        case .accessoryInline:
            if #available(iOS 16.0, *) {
                AccessoryInlineView(entry: entry)
            } else {
                SmallWidgetView(entry: entry)
            }
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Widget Configuration
struct LunarCalendarWidget: Widget {
    let kind: String = "LunarCalendarWidget"

    var body: some WidgetConfiguration {
        if #available(iOS 16.0, *) {
            return StaticConfiguration(kind: kind, provider: LunarCalendarProvider()) { entry in
                LunarCalendarWidgetEntryView(entry: entry)
            }
            .configurationDisplayName("Lịch Âm Việt Nam")
            .description("Hiển thị ngày Âm lịch, Can Chi, Giờ Hoàng Đạo và các ngày lễ truyền thống")
            .supportedFamilies([
                .systemSmall,
                .systemMedium,
                .systemLarge,
                .accessoryCircular,
                .accessoryRectangular,
                .accessoryInline
            ])
        } else {
            return StaticConfiguration(kind: kind, provider: LunarCalendarProvider()) { entry in
                LunarCalendarWidgetEntryView(entry: entry)
            }
            .configurationDisplayName("Lịch Âm Việt Nam")
            .description("Hiển thị ngày Âm lịch, Can Chi, Giờ Hoàng Đạo và các ngày lễ truyền thống")
            .supportedFamilies([
                .systemSmall,
                .systemMedium,
                .systemLarge
            ])
        }
    }
}

// MARK: - Widget Bundle
@main
struct LunarCalendarWidgetBundle: WidgetBundle {
    var body: some Widget {
        LunarCalendarWidget()
    }
}

// MARK: - Preview
struct LunarCalendarWidget_Previews: PreviewProvider {
    static var previews: some View {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: Date())
        
        let sampleEntry = LunarCalendarEntry(
            date: Date(),
            lunarDate: LunarCalendarCalculator.convertSolarToLunar(
                day: components.day!,
                month: components.month!,
                year: components.year!
            ),
            holidays: [],
            auspiciousHours: ["Tý", "Dần", "Mão", "Thìn", "Ngọ", "Tuất"]
        )

        Group {
            LunarCalendarWidgetEntryView(entry: sampleEntry)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("Small - Lunar + Auspicious Hour")

            LunarCalendarWidgetEntryView(entry: sampleEntry)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .previewDisplayName("Medium - Lunar Info")

            LunarCalendarWidgetEntryView(entry: sampleEntry)
                .previewContext(WidgetPreviewContext(family: .systemLarge))
                .previewDisplayName("Large - With Auspicious Hours")
            
            if #available(iOS 16.0, *) {
                LunarCalendarWidgetEntryView(entry: sampleEntry)
                    .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
                    .previewDisplayName("Lock - Rectangular")
                
                LunarCalendarWidgetEntryView(entry: sampleEntry)
                    .previewContext(WidgetPreviewContext(family: .accessoryInline))
                    .previewDisplayName("Lock - Inline")
            }
        }
    }
}
