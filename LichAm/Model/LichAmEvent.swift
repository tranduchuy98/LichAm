import Foundation
import EventKit

// MARK: - Event Model
struct LichAmEvent: Identifiable, Codable, Equatable {
    var id: String = UUID().uuidString
    var title: String
    var notes: String?
    var startDate: Date
    var endDate: Date
    var isAllDay: Bool
    var reminderMinutesBefore: Int?
    var color: EventColor
    var isLunarDateBased: Bool // Event theo Âm lịch
    var lunarDay: Int?
    var lunarMonth: Int?
    var repeatType: EventRepeatType
    var ekEventIdentifier: String? // ID của event trong Calendar app
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: String = UUID().uuidString,
        title: String,
        notes: String? = nil,
        startDate: Date,
        endDate: Date,
        isAllDay: Bool = false,
        reminderMinutesBefore: Int? = nil,
        color: EventColor = .red,
        isLunarDateBased: Bool = false,
        lunarDay: Int? = nil,
        lunarMonth: Int? = nil,
        repeatType: EventRepeatType = .never,
        ekEventIdentifier: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.startDate = startDate
        self.endDate = endDate
        self.isAllDay = isAllDay
        self.reminderMinutesBefore = reminderMinutesBefore
        self.color = color
        self.isLunarDateBased = isLunarDateBased
        self.lunarDay = lunarDay
        self.lunarMonth = lunarMonth
        self.repeatType = repeatType
        self.ekEventIdentifier = ekEventIdentifier
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    static func == (lhs: LichAmEvent, rhs: LichAmEvent) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Event Color
enum EventColor: String, Codable, CaseIterable {
    case red = "red"
    case blue = "blue"
    case green = "green"
    case orange = "orange"
    case purple = "purple"
    case pink = "pink"
    case yellow = "yellow"
    case teal = "teal"
    
    var displayName: String {
        switch self {
        case .red: return "Đỏ"
        case .blue: return "Xanh dương"
        case .green: return "Xanh lá"
        case .orange: return "Cam"
        case .purple: return "Tím"
        case .pink: return "Hồng"
        case .yellow: return "Vàng"
        case .teal: return "Xanh ngọc"
        }
    }
    
    var colorValue: Color {
        switch self {
        case .red: return .red
        case .blue: return .blue
        case .green: return .green
        case .orange: return .orange
        case .purple: return .purple
        case .pink: return .pink
        case .yellow: return .yellow
        case .teal: return .teal
        }
    }
    
    var emoji: String {
        switch self {
        case .red: return "🔴"
        case .blue: return "🔵"
        case .green: return "🟢"
        case .orange: return "🟠"
        case .purple: return "🟣"
        case .pink: return "🌸"
        case .yellow: return "🟡"
        case .teal: return "💎"
        }
    }
}

// MARK: - Event Repeat Type
enum EventRepeatType: String, Codable, CaseIterable {
    case never = "never"
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case yearly = "yearly"
    case lunarMonthly = "lunar_monthly" // Lặp theo tháng Âm lịch
    case lunarYearly = "lunar_yearly"   // Lặp theo năm Âm lịch
    
    var displayName: String {
        switch self {
        case .never: return "Không lặp lại"
        case .daily: return "Hàng ngày"
        case .weekly: return "Hàng tuần"
        case .monthly: return "Hàng tháng"
        case .yearly: return "Hàng năm"
        case .lunarMonthly: return "Hàng tháng (Âm lịch)"
        case .lunarYearly: return "Hàng năm (Âm lịch)"
        }
    }
    
    var ekRecurrenceRule: EKRecurrenceRule? {
        switch self {
        case .never:
            return nil
        case .daily:
            return EKRecurrenceRule(
                recurrenceWith: .daily,
                interval: 1,
                end: nil
            )
        case .weekly:
            return EKRecurrenceRule(
                recurrenceWith: .weekly,
                interval: 1,
                end: nil
            )
        case .monthly:
            return EKRecurrenceRule(
                recurrenceWith: .monthly,
                interval: 1,
                end: nil
            )
        case .yearly:
            return EKRecurrenceRule(
                recurrenceWith: .yearly,
                interval: 1,
                end: nil
            )
        case .lunarMonthly, .lunarYearly:
            // Âm lịch không có trong EKRecurrenceRule, xử lý riêng
            return nil
        }
    }
}

import SwiftUI
