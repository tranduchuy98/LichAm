import WidgetKit
import SwiftUI

// MARK: - Widget Timeline Provider
struct LunarCalendarProvider: TimelineProvider {
    func placeholder(in context: Context) -> LunarCalendarEntry {
        LunarCalendarEntry(date: Date(), lunarDate: sampleLunarDate(), holidays: [])
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

        return LunarCalendarEntry(date: date, lunarDate: lunarDate, holidays: holidays)
    }

    private func sampleLunarDate() -> LunarDate {
        return LunarDate(day: 15, month: 8, year: 2024, isLeapMonth: false)
    }
}

// MARK: - Widget Entry
struct LunarCalendarEntry: TimelineEntry {
    let date: Date
    let lunarDate: LunarDate
    let holidays: [VietnameseHoliday]
}

// MARK: - Small Widget View
struct SmallWidgetView: View {
    var entry: LunarCalendarProvider.Entry

    var body: some View {
        VStack(spacing: 4) {
            // Solar date
            Text(entry.date, style: .date)
                .font(.caption)
                .foregroundColor(.secondary)

            // Solar day number
            Text("\(Calendar.current.component(.day, from: entry.date))")
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(.primary)

            // Lunar date
            Text("Ngày \(entry.lunarDate.shortDisplayString)")
                .font(.caption)
                .foregroundColor(.red)
                .fontWeight(.medium)

            // Holiday indicator
            if !entry.holidays.isEmpty {
                Text(entry.holidays[0].emoji)
                    .font(.title3)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

// MARK: - Medium Widget View
struct MediumWidgetView: View {
    var entry: LunarCalendarProvider.Entry

    var body: some View {
        HStack(spacing: 16) {
            // Left side - Date
            VStack(spacing: 4) {
                Text(entry.date, formatter: monthFormatter)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("\(Calendar.current.component(.day, from: entry.date))")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.primary)

                Text(entry.date, formatter: weekdayFormatter)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 80)

            Divider()

            // Right side - Lunar info
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "moon.fill")
                        .foregroundColor(.red)
                    Text("Ngày \(entry.lunarDate.displayString)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                let zodiac = LunarCalendarCalculator.getZodiacAnimal(year: entry.lunarDate.year)
                let canChi = LunarCalendarCalculator.getCanChi(year: entry.lunarDate.year)

                HStack {
                    Image(systemName: "star.circle")
                        .foregroundColor(.blue)
                    Text(zodiac)
                        .font(.caption)
                }

                if !entry.holidays.isEmpty {
                    HStack {
                        Text(entry.holidays[0].emoji)
                        Text(entry.holidays[0].name)
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                }
            }

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private var monthFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter
    }

    private var weekdayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter
    }
}

// MARK: - Large Widget View
struct LargeWidgetView: View {
    var entry: LunarCalendarProvider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text(entry.date, style: .date)
                        .font(.headline)

                    Text("Ngày \(entry.lunarDate.displayString)")
                        .font(.subheadline)
                        .foregroundColor(.red)
                }

                Spacer()

                Text("\(Calendar.current.component(.day, from: entry.date))")
                    .font(.system(size: 48, weight: .bold))
            }

            Divider()

            // Zodiac info
            VStack(alignment: .leading, spacing: 8) {
                let zodiac = LunarCalendarCalculator.getZodiacAnimal(year: entry.lunarDate.year)
                let zodiacEng = LunarCalendarCalculator.getZodiacAnimalEnglish(year: entry.lunarDate.year)
                let canChi = LunarCalendarCalculator.getCanChi(year: entry.lunarDate.year)

                HStack {
                    Image(systemName: "star.circle.fill")
                        .foregroundColor(.yellow)
                    Text("Con giáp: \(zodiac) (\(zodiacEng))")
                        .font(.caption)
                }

                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(.blue)
                    Text("Can Chi: \(canChi)")
                        .font(.caption)
                }
            }

            // Holidays
            if !entry.holidays.isEmpty {
                Divider()

                VStack(alignment: .leading, spacing: 6) {
                    ForEach(entry.holidays.prefix(2)) { holiday in
                        HStack {
                            Text(holiday.emoji)
                            VStack(alignment: .leading) {
                                Text(holiday.name)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                Text(holiday.nameEnglish)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

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
        // --- Lock Screen accessory families
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

// MARK: - Accessory Views for Lock Screen (very small / lightweight)
@available(iOS 16.0, *)
private struct AccessoryCircularView: View {
    var entry: LunarCalendarProvider.Entry
    var body: some View {
        // circular: tiny, often used for single glyph/emoji or short number
        ZStack {
            // show lunar day number or holiday emoji
            if !entry.holidays.isEmpty {
                Text(entry.holidays[0].emoji)
                    .font(.headline)
            } else {
                Text("\(Calendar.current.component(.day, from: entry.date))")
                    .font(.headline)
            }
        }
    }
}

@available(iOS 16.0, *)
private struct AccessoryRectangularView: View {
    var entry: LunarCalendarProvider.Entry
    var body: some View {
        // rectangular: slightly larger, good for 1–2 lines
        HStack(spacing: 6) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(Calendar.current.component(.day, from: entry.date))")
                    .font(.headline)
                Text("Ngày \(entry.lunarDate.shortDisplayString)")
                    .font(.caption2)
                    .foregroundColor(.red)
            }
            Spacer()
            if !entry.holidays.isEmpty {
                Text(entry.holidays[0].emoji)
            }
        }
        .padding(.horizontal, 6)
    }
}

@available(iOS 16.0, *)
private struct AccessoryInlineView: View {
    var entry: LunarCalendarProvider.Entry
    var body: some View {
        // inline: single-line text shown beside the time
        HStack(spacing: 4) {
            if !entry.holidays.isEmpty {
                Text(entry.holidays[0].emoji)
            }
            Text("Ngày \(entry.lunarDate.shortDisplayString)")
                .font(.caption2)
        }
    }
}

// MARK: - Widget Configuration (include accessory families)
struct LunarCalendarWidget: Widget {
    let kind: String = "LunarCalendarWidget"

    var body: some WidgetConfiguration {
        if #available(iOS 16.0, *) {
            StaticConfiguration(kind: kind, provider: LunarCalendarProvider()) { entry in
                LunarCalendarWidgetEntryView(entry: entry)
            }
            .configurationDisplayName("Lịch Âm")
            .description("Hiển thị ngày Âm lịch và các ngày lễ Việt Nam")
            .supportedFamilies([.systemSmall, .systemMedium, .systemLarge,
                                .accessoryCircular, .accessoryRectangular, .accessoryInline])
        } else {
            StaticConfiguration(kind: kind, provider: LunarCalendarProvider()) { entry in
                LunarCalendarWidgetEntryView(entry: entry)
            }
            .configurationDisplayName("Lịch Âm")
            .description("Hiển thị ngày Âm lịch và các ngày lễ Việt Nam")
            .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
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
        let sampleEntry = LunarCalendarEntry(
            date: Date(),
            lunarDate: LunarDate(day: 15, month: 8, year: 2024, isLeapMonth: false),
            holidays: [
                VietnameseHoliday(
                    name: "Tết Trung Thu",
                    nameEnglish: "Mid-Autumn Festival",
                    day: 15,
                    month: 8,
                    isLunar: true,
                    description: "Tết Thiếu nhi",
                    emoji: "🥮"
                )
            ]
        )

        Group {
            LunarCalendarWidgetEntryView(entry: sampleEntry)
                .previewContext(WidgetPreviewContext(family: .systemSmall))

            LunarCalendarWidgetEntryView(entry: sampleEntry)
                .previewContext(WidgetPreviewContext(family: .systemMedium))

            LunarCalendarWidgetEntryView(entry: sampleEntry)
                .previewContext(WidgetPreviewContext(family: .systemLarge))
        }
    }
}
