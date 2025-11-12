import Foundation

struct VietnameseHoliday: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let nameEnglish: String
    let day: Int
    let month: Int
    let isLunar: Bool
    let description: String
    let emoji: String
    
    static func == (lhs: VietnameseHoliday, rhs: VietnameseHoliday) -> Bool {
        return lhs.day == rhs.day && lhs.month == rhs.month && lhs.isLunar == rhs.isLunar
    }
}

class HolidayManager {
    
    // Solar (Gregorian) holidays
    static let solarHolidays: [VietnameseHoliday] = [
        VietnameseHoliday(
            name: "Tết Dương Lịch",
            nameEnglish: "New Year's Day",
            day: 1,
            month: 1,
            isLunar: false,
            description: "Năm mới Dương lịch",
            emoji: "🎊"
        ),
        VietnameseHoliday(
            name: "Ngày Thành lập Đảng",
            nameEnglish: "Vietnamese Communist Party Founding Day",
            day: 3,
            month: 2,
            isLunar: false,
            description: "Kỷ niệm ngày thành lập Đảng Cộng sản Việt Nam",
            emoji: "🇻🇳"
        ),
        VietnameseHoliday(
            name: "Giỗ Tổ Hùng Vương",
            nameEnglish: "Hung Kings' Temple Festival",
            day: 10,
            month: 3,
            isLunar: true,
            description: "Lễ hội tưởng nhớ các vua Hùng",
            emoji: "🏛️"
        ),
        VietnameseHoliday(
            name: "Ngày Giải phóng Miền Nam",
            nameEnglish: "Reunification Day",
            day: 30,
            month: 4,
            isLunar: false,
            description: "Kỷ niệm ngày thống nhất đất nước",
            emoji: "🎆"
        ),
        VietnameseHoliday(
            name: "Quốc tế Lao động",
            nameEnglish: "International Labor Day",
            day: 1,
            month: 5,
            isLunar: false,
            description: "Ngày Quốc tế Lao động",
            emoji: "👷"
        ),
        VietnameseHoliday(
            name: "Quốc khánh",
            nameEnglish: "National Day",
            day: 2,
            month: 9,
            isLunar: false,
            description: "Ngày Quốc khánh nước Cộng hòa Xã hội Chủ nghĩa Việt Nam",
            emoji: "🇻🇳"
        )
    ]
    
    // Lunar holidays
    static let lunarHolidays: [VietnameseHoliday] = [
        VietnameseHoliday(
            name: "Tết Nguyên Đán",
            nameEnglish: "Lunar New Year",
            day: 1,
            month: 1,
            isLunar: true,
            description: "Tết Nguyên Đán - Năm mới Âm lịch",
            emoji: "🧧"
        ),
        VietnameseHoliday(
            name: "Mùng 2 Tết",
            nameEnglish: "Second Day of Tet",
            day: 2,
            month: 1,
            isLunar: true,
            description: "Ngày thứ hai của Tết",
            emoji: "🧧"
        ),
        VietnameseHoliday(
            name: "Mùng 3 Tết",
            nameEnglish: "Third Day of Tet",
            day: 3,
            month: 1,
            isLunar: true,
            description: "Ngày thứ ba của Tết",
            emoji: "🧧"
        ),
        VietnameseHoliday(
            name: "Tết Nguyên Tiêu",
            nameEnglish: "Lantern Festival",
            day: 15,
            month: 1,
            isLunar: true,
            description: "Rằm tháng Giêng",
            emoji: "🏮"
        ),
        VietnameseHoliday(
            name: "Tết Hàn Thực",
            nameEnglish: "Cold Food Festival",
            day: 3,
            month: 3,
            isLunar: true,
            description: "Tết Hàn Thực",
            emoji: "🍚"
        ),
        VietnameseHoliday(
            name: "Lễ Phật Đản",
            nameEnglish: "Buddha's Birthday",
            day: 15,
            month: 4,
            isLunar: true,
            description: "Phật Đản sinh - Đại lễ Phật giáo",
            emoji: "☸️"
        ),
        VietnameseHoliday(
            name: "Tết Đoan Ngọ",
            nameEnglish: "Dragon Boat Festival",
            day: 5,
            month: 5,
            isLunar: true,
            description: "Tết Đoan Ngọ - Tết diệt sâu bọ",
            emoji: "🐉"
        ),
        VietnameseHoliday(
            name: "Vu Lan",
            nameEnglish: "Vu Lan Festival",
            day: 15,
            month: 7,
            isLunar: true,
            description: "Lễ Vu Lan - Ngày Cha Mẹ Việt Nam",
            emoji: "🌹"
        ),
        VietnameseHoliday(
            name: "Tết Trung Thu",
            nameEnglish: "Mid-Autumn Festival",
            day: 15,
            month: 8,
            isLunar: true,
            description: "Tết Trung Thu - Tết Thiếu nhi",
            emoji: "🥮"
        ),
        VietnameseHoliday(
            name: "Tết Trùng Cửu",
            nameEnglish: "Double Ninth Festival",
            day: 9,
            month: 9,
            isLunar: true,
            description: "Tết Trùng Cửu",
            emoji: "🍁"
        ),
        VietnameseHoliday(
            name: "Tết Hạ Nguyên",
            nameEnglish: "Lower Yuan Festival",
            day: 15,
            month: 10,
            isLunar: true,
            description: "Tết Hạ Nguyên",
            emoji: "🕯️"
        ),
        VietnameseHoliday(
            name: "Ông Công - Ông Táo",
            nameEnglish: "Kitchen God Festival",
            day: 23,
            month: 12,
            isLunar: true,
            description: "Tiễn ông Táo về trời",
            emoji: "🍪"
        ),
        VietnameseHoliday(
            name: "Giao Thừa",
            nameEnglish: "New Year's Eve",
            day: 30,
            month: 12,
            isLunar: true,
            description: "Đêm Giao Thừa",
            emoji: "🎆"
        )
    ]
    
    // Special lunar days (first and full moon)
    static func isSpecialLunarDay(_ lunarDate: LunarDate) -> (isSpecial: Bool, name: String) {
        if lunarDate.day == 1 {
            return (true, "Mồng 1 - Sóc")
        } else if lunarDate.day == 15 {
            return (true, "Rằm - Vọng")
        }
        return (false, "")
    }
    
    // Get holidays for a specific solar date
    static func getHolidaysForSolarDate(day: Int, month: Int, year: Int) -> [VietnameseHoliday] {
        var holidays: [VietnameseHoliday] = []
        
        // Check solar holidays
        for holiday in solarHolidays where !holiday.isLunar {
            if holiday.day == day && holiday.month == month {
                holidays.append(holiday)
            }
        }
        
        // Check lunar holidays
        let lunarDate = LunarCalendarCalculator.convertSolarToLunar(day: day, month: month, year: year)
        for holiday in lunarHolidays where holiday.isLunar {
            if holiday.day == lunarDate.day && holiday.month == lunarDate.month {
                holidays.append(holiday)
            }
        }
        
        // Check Hung Kings' Day (10/3 lunar calendar - but also check solar conversion)
        for holiday in solarHolidays where holiday.isLunar {
            if holiday.day == lunarDate.day && holiday.month == lunarDate.month {
                holidays.append(holiday)
            }
        }
        
        return holidays
    }
    
    // Get all holidays for a specific month
    static func getHolidaysForMonth(month: Int, year: Int, isLunar: Bool) -> [VietnameseHoliday] {
        if isLunar {
            return lunarHolidays.filter { $0.month == month && $0.isLunar }
        } else {
            return solarHolidays.filter { $0.month == month && !$0.isLunar }
        }
    }
}
