import Foundation

class LunarCalendarCalculator {
    
    // Julian Day Number calculation
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
    
    // Calculate new moon day (returns Julian day as Double)
    static func newMoon(k: Int) -> Double {
        let kD = Double(k)
        let T = kD / 1236.85 // Time in Julian centuries from 1900 January 0.5
        let T2 = T * T
        let T3 = T2 * T
        let dr = Double.pi / 180.0
        var Jd1 = 2415020.75933 + 29.53058868 * kD + 0.0001178 * T2 - 0.000000155 * T3
        Jd1 += 0.00033 * sin((166.56 + 132.87 * T - 0.009173 * T2) * dr) // Mean new moon
        let M = 359.2242 + 29.10535608 * kD - 0.0000333 * T2 - 0.00000347 * T3 // Sun's mean anomaly (deg)
        let Mpr = 306.0253 + 385.81691806 * kD + 0.0107306 * T2 + 0.00001236 * T3 // Moon's mean anomaly (deg)
        let F = 21.2964 + 390.67050646 * kD - 0.0016528 * T2 - 0.00000239 * T3 // Moon argument of latitude (deg)
        
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
    
    // Get sun longitude index (0..11) where each bucket = 30 degrees
    static func sunLongitude(jdn: Double) -> Int {
        let T = (jdn - 2451545.0) / 36525.0 // Julian centuries from 2000-01-01 12:00:00 GMT
        let T2 = T * T
        let M = 357.52910 + 35999.05030 * T - 0.0001559 * T2 - 0.00000048 * T * T2 // mean anomaly (deg)
        let L0 = 280.46645 + 36000.76983 * T + 0.0003032 * T2 // mean longitude (deg)
        var DL = (1.914600 - 0.004817 * T - 0.000014 * T2) * sin(deg2rad(M))
        DL += (0.019993 - 0.000101 * T) * sin(deg2rad(2.0 * M))
        DL += 0.000290 * sin(deg2rad(3.0 * M))
        var L = L0 + DL // true longitude in degrees
        L = L - 360.0 * floor(L / 360.0) // normalize to [0,360)
        let index = Int(floor(L / 30.0)) // 0..11
        return index
    }
    
    private static func deg2rad(_ deg: Double) -> Double {
        return deg * Double.pi / 180.0
    }
    
    // Get lunar month 11 (return JDN int)
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
    
    // Check leap month offset
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
    
    // Convert solar date to lunar date
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
    
    // Get zodiac animal (Vietnamese) — safe modulo to avoid negative indexes
    static func getZodiacAnimal(year: Int) -> String {
        let zodiacAnimals = ["Tý", "Sửu", "Dần", "Mão", "Thìn", "Tỵ", "Ngọ", "Mùi", "Thân", "Dậu", "Tuất", "Hợi"]
        let idx = positiveMod(year - 4, 12)
        return zodiacAnimals[idx]
    }
    
    static func getZodiacAnimalEnglish(year: Int) -> String {
        let zodiacAnimals = ["Rat", "Ox", "Tiger", "Cat", "Dragon", "Snake", "Horse", "Goat", "Monkey", "Rooster", "Dog", "Pig"]
        let idx = positiveMod(year - 4, 12)
        return zodiacAnimals[idx]
    }
    
    // Get heavenly stem and earthly branch (Can Chi)
    static func getCanChi(year: Int) -> String {
        let can = ["Giáp","Ất","Bính","Đinh","Mậu","Kỷ","Canh","Tân","Nhâm","Quý"]
        let chi = ["Tý","Sửu","Dần","Mão","Thìn","Tỵ","Ngọ","Mùi","Thân","Dậu","Tuất","Hợi"]
        let canIndex = positiveMod(year + 6, 10)
        let chiIndex = positiveMod(year + 8, 12)
        return "\(can[canIndex]) \(chi[chiIndex])"
    }
    
    private static func positiveMod(_ a: Int, _ m: Int) -> Int {
        let r = a % m
        return r >= 0 ? r : r + m
    }
    
    // Calculate auspicious hours for a given day
    static func getAuspiciousHours(day: Int, month: Int, year: Int) -> [AuspiciousHour] {
        let lunarDate = convertSolarToLunar(day: day, month: month, year: year)
        let dayNumber = positiveMod(lunarDate.day - 1, 12)
        
        // Vietnamese auspicious hours based on traditional almanac
        let hourNames = ["Tý", "Sửu", "Dần", "Mão", "Thìn", "Tỵ", "Ngọ", "Mùi", "Thân", "Dậu", "Tuất", "Hợi"]
        let timeRanges = ["23:00-01:00", "01:00-03:00", "03:00-05:00", "05:00-07:00",
                         "07:00-09:00", "09:00-11:00", "11:00-13:00", "13:00-15:00",
                         "15:00-17:00", "17:00-19:00", "19:00-21:00", "21:00-23:00"]
        
        // Simplified auspicious hours pattern (example)
        let auspiciousPattern = [
            [0, 2, 4, 6, 8, 10],  // Day 1
            [1, 3, 5, 7, 9, 11],  // Day 2
            [0, 2, 4, 6, 8, 10],
            [1, 3, 5, 7, 9, 11],
            [0, 2, 4, 6, 8, 10],
            [1, 3, 5, 7, 9, 11],
            [0, 2, 4, 6, 8, 10],
            [1, 3, 5, 7, 9, 11],
            [0, 2, 4, 6, 8, 10],
            [1, 3, 5, 7, 9, 11],
            [0, 2, 4, 6, 8, 10],
            [1, 3, 5, 7, 9, 11]
        ]
        
        let auspiciousIndices = auspiciousPattern[dayNumber]
        
        var hours: [AuspiciousHour] = []
        for i in 0..<12 {
            hours.append(AuspiciousHour(
                name: hourNames[i],
                timeRange: timeRanges[i],
                isAuspicious: auspiciousIndices.contains(i)
            ))
        }
        
        return hours
    }
}

// Models (unchanged)
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

struct AuspiciousHour: Identifiable {
    let id = UUID()
    let name: String
    let timeRange: String
    let isAuspicious: Bool
}
