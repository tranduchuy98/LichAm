import Foundation

class LunarCalendarCalculator {
    
    // MARK: - Julian Day Number Calculation
    
    static func julianDayNumber(day: Int, month: Int, year: Int) -> Int {
        let a = (14 - month) / 12
        let y = year + 4800 - a
        let m = month + 12 * a - 3
        var jd = day + (153 * m + 2) / 5 + 365 * y + y / 4 - y / 100 + y / 400 - 32045
        
        if jd < 2299161 {
            jd = day + (153 * m + 2) / 5 + 365 * y + y / 4 - 32083
        }
        
        return jd
    }
    
    // MARK: - New Moon Calculation
    
    static func newMoon(k: Int) -> Double {
        let kD = Double(k)
        let T = kD / 1236.85
        let T2 = T * T
        let T3 = T2 * T
        let dr = Double.pi / 180.0
        var Jd1 = 2415020.75933 + 29.53058868 * kD + 0.0001178 * T2 - 0.000000155 * T3
        Jd1 += 0.00033 * sin((166.56 + 132.87 * T - 0.009173 * T2) * dr)
        let M = 359.2242 + 29.10535608 * kD - 0.0000333 * T2 - 0.00000347 * T3
        let Mpr = 306.0253 + 385.81691806 * kD + 0.0107306 * T2 + 0.00001236 * T3
        let F = 21.2964 + 390.67050646 * kD - 0.0016528 * T2 - 0.00000239 * T3
        
        var C1 = (0.1734 - 0.000393 * T) * sin(M * dr)
        C1 += 0.0021 * sin(2.0 * M * dr)
        C1 -= 0.4068 * sin(Mpr * dr)
        C1 += 0.0161 * sin(2.0 * Mpr * dr)
        C1 -= 0.0004 * sin(3.0 * Mpr * dr)
        C1 += 0.0104 * sin(2.0 * F * dr)
        C1 -= 0.0051 * sin((M + Mpr) * dr)
        C1 -= 0.0074 * sin((M - Mpr) * dr)
        C1 += 0.0004 * sin((2.0 * F + M) * dr)
        C1 -= 0.0004 * sin((2.0 * F - M) * dr)
        C1 -= 0.0006 * sin((2.0 * F + Mpr) * dr)
        C1 += 0.0010 * sin((2.0 * F - Mpr) * dr)
        C1 += 0.0005 * sin((2.0 * Mpr + M) * dr)
        
        let deltat: Double
        if T < -11 {
            deltat = 0.001 + 0.000839 * T + 0.0002261 * T2 - 0.00000845 * T3 - 0.000000081 * T * T3
        } else {
            deltat = -0.000278 + 0.000265 * T + 0.000262 * T2
        }
        
        let JdNew = Jd1 + C1 - deltat
        return JdNew
    }
    
    // MARK: - Sun Longitude
    
    static func sunLongitude(jdn: Double) -> Int {
        let T = (jdn - 2451545.0) / 36525.0
        let T2 = T * T
        let M = 357.52910 + 35999.05030 * T - 0.0001559 * T2 - 0.00000048 * T * T2
        let L0 = 280.46645 + 36000.76983 * T + 0.0003032 * T2
        var DL = (1.914600 - 0.004817 * T - 0.000014 * T2) * sin(deg2rad(M))
        DL += (0.019993 - 0.000101 * T) * sin(deg2rad(2.0 * M))
        DL += 0.000290 * sin(deg2rad(3.0 * M))
        var L = L0 + DL
        L = L - 360.0 * floor(L / 360.0)
        let index = Int(floor(L / 30.0))
        return index
    }
    
     static func deg2rad(_ deg: Double) -> Double {
        return deg * Double.pi / 180.0
    }
    
    // MARK: - Lunar Month 11
    
    static func getLunarMonth11(yy: Int, timeZone: Double) -> Int {
        let off = Double(julianDayNumber(day: 31, month: 12, year: yy)) - 2415021.0
        let k = Int(floor(off / 29.530588853))
        var nm = newMoon(k: k)
        let sunLong = sunLongitude(jdn: nm)
        
        if sunLong >= 9 {
            nm = newMoon(k: k - 1)
        }
        
        return Int(floor(nm + 0.5 + timeZone / 24.0))
    }
    
    // MARK: - Leap Month
    
    static func getLeapMonthOffset(a11: Int, timeZone: Double) -> Int {
        let k = Int(floor((Double(a11) - 2415021.076998695) / 29.530588853 + 0.5))
        var last = -1
        var i = 1
        var arc = sunLongitude(jdn: newMoon(k: k + i))
        
        repeat {
            last = arc
            i += 1
            arc = sunLongitude(jdn: newMoon(k: k + i))
        } while arc != last && i < 14
        
        return i - 1
    }
    
    // MARK: - Solar to Lunar Conversion
    
    static func convertSolarToLunar(day: Int, month: Int, year: Int, timeZone: Double = 7.0) -> LunarDate {
        let dayNumber = julianDayNumber(day: day, month: month, year: year)
        let k = Int(floor((Double(dayNumber) - 2415021.076998695) / 29.530588853))
        var monthStart = Int(floor(newMoon(k: k + 1) + 0.5 + timeZone / 24.0))
        
        if monthStart > dayNumber {
            monthStart = Int(floor(newMoon(k: k) + 0.5 + timeZone / 24.0))
        }
        
        var a11 = getLunarMonth11(yy: year, timeZone: timeZone)
        var b11 = a11
        var lunarYear: Int
        
        if a11 >= monthStart {
            lunarYear = year
            a11 = getLunarMonth11(yy: year - 1, timeZone: timeZone)
        } else {
            lunarYear = year + 1
            b11 = getLunarMonth11(yy: year + 1, timeZone: timeZone)
        }
        
        let lunarDay = dayNumber - monthStart + 1
        let diff = Int(floor(Double(monthStart - a11) / 29.0))
        var lunarLeap = false
        var lunarMonth = diff + 11
        
        if b11 - a11 > 365 {
            let leapMonthDiff = getLeapMonthOffset(a11: a11, timeZone: timeZone)
            if diff >= leapMonthDiff {
                lunarMonth = diff + 10
                if diff == leapMonthDiff {
                    lunarLeap = true
                }
            }
        }
        
        if lunarMonth > 12 {
            lunarMonth -= 12
        }
        if lunarMonth >= 11 && diff < 4 {
            lunarYear -= 1
        }
        
        return LunarDate(
            day: lunarDay,
            month: lunarMonth,
            year: lunarYear,
            isLeapMonth: lunarLeap
        )
    }
    
    // MARK: - Zodiac Animals
    
    static func getZodiacAnimal(year: Int) -> String {
        let zodiacAnimals = ["Tý", "Sửu", "Dần", "Mão", "Thìn", "Tỵ", "Ngọ", "Mùi", "Thân", "Dậu", "Tuất", "Hợi"]
        let idx = positiveMod(year - 4, 12)
        return zodiacAnimals[idx]
    }
    
    static func getZodiacAnimalViet(year: Int) -> String {
        let zodiacAnimals = ["Rắn", "Trâu", "Hổ", "Mèo", "Rồng", "Rắn", "Ngựa", "Dê", "Khỉ", "Gà", "Chó", "Heo/Lợn"]
        let idx = positiveMod(year - 4, 12)
        return zodiacAnimals[idx]
    }
    
    static func getZodiacAnimalEnglish(year: Int) -> String {
        let zodiacAnimals = ["Rat", "Ox", "Tiger", "Cat", "Dragon", "Snake", "Horse", "Goat", "Monkey", "Rooster", "Dog", "Pig"]
        let idx = positiveMod(year - 4, 12)
        return zodiacAnimals[idx]
    }
    
    // MARK: - Can Chi (Heavenly Stems and Earthly Branches)
    
    static func getCanChi(year: Int) -> String {
        let can = ["Giáp","Ất","Bính","Đinh","Mậu","Kỷ","Canh","Tân","Nhâm","Quý"]
        let chi = ["Tý","Sửu","Dần","Mão","Thìn","Tỵ","Ngọ","Mùi","Thân","Dậu","Tuất","Hợi"]
        let canIndex = positiveMod(year + 6, 10)
        let chiIndex = positiveMod(year + 8, 12)
        return "\(can[canIndex]) \(chi[chiIndex])"
    }
    
    static func getDayCanChi(day: Int, month: Int, year: Int) -> String {
        let jdn = julianDayNumber(day: day, month: month, year: year)
        let can = ["Giáp","Ất","Bính","Đinh","Mậu","Kỷ","Canh","Tân","Nhâm","Quý"]
        let chi = ["Tý","Sửu","Dần","Mão","Thìn","Tỵ","Ngọ","Mùi","Thân","Dậu","Tuất","Hợi"]
        let canIndex = positiveMod(jdn + 9, 10)
        let chiIndex = positiveMod(jdn + 1, 12)
        return "\(can[canIndex]) \(chi[chiIndex])"
    }
    
     static func positiveMod(_ a: Int, _ m: Int) -> Int {
        let r = a % m
        return r >= 0 ? r : r + m
    }
    
    // MARK: - Enhanced Auspicious Hours Calculation

     static func calculateAuspiciousness(dayBranchIndex: Int, hourBranchIndex: Int, lunarDay: Int) -> Bool {
        // Traditional Hoàng Đạo (Yellow Path) calculation
        // Based on the "Jianchu" system and day's earthly branch
        
        let auspiciousPatterns: [[Int]] = [
            [0, 2, 4, 7, 9, 11],  // Tý day
            [1, 3, 5, 8, 10, 0],  // Sửu day
            [2, 4, 6, 9, 11, 1],  // Dần day
            [3, 5, 7, 10, 0, 2],  // Mão day
            [4, 6, 8, 11, 1, 3],  // Thìn day
            [5, 7, 9, 0, 2, 4],   // Tỵ day
            [6, 8, 10, 1, 3, 5],  // Ngọ day
            [7, 9, 11, 2, 4, 6],  // Mùi day
            [8, 10, 0, 3, 5, 7],  // Thân day
            [9, 11, 1, 4, 6, 8],  // Dậu day
            [10, 0, 2, 5, 7, 9],  // Tuất day
            [11, 1, 3, 6, 8, 10]  // Hợi day
        ]
        
        let pattern = auspiciousPatterns[dayBranchIndex]
        return pattern.contains(hourBranchIndex)
    }
}

// MARK: - Models

struct LunarDate: Codable, Equatable {
    let day: Int
    let month: Int
    let year: Int
    let isLeapMonth: Bool
    
    var displayString: String {
        let leapPrefix = isLeapMonth ? "Nhuận " : ""
        return "\(leapPrefix)\(day)/\(month)/\(year)"
    }
    
    var shortDisplayString: String {
        return "\(day)/\(month)"
    }
}
