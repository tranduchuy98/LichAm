import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: CalendarViewModel
    @State private var showAuspiciousHours = false
    @State private var showHolidaysList = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header with lunar date
                    HeaderView()
                    
                    // Calendar view
                    CalendarGridView()
                    
                    // Today's information
                    TodayInformationView()
                    
                    // Holidays section
                    if !viewModel.todayHolidays.isEmpty {
                        HolidaysSectionView()
                    }
                }
                .padding()
            }
            .navigationTitle("Lịch Âm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        viewModel.goToToday()
                    }) {
                        Image(systemName: "calendar.circle")
                            .font(.title3)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.showSettings = true
                    }) {
                        Image(systemName: "gearshape")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $viewModel.showSettings) {
                SettingsView()
            }
        }
    }
}

struct HeaderView: View {
    @EnvironmentObject var viewModel: CalendarViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            // Solar date
            Text(viewModel.selectedDate, style: .date)
                .font(.title2)
                .fontWeight(.semibold)
            
            // Lunar date
            VStack(spacing: 4) {
                Text("Ngày \(viewModel.lunarDate.displayString)")
                    .font(.headline)
                    .foregroundColor(.red)
                
                // Zodiac year
                HStack {
                    Text("Năm \(viewModel.canChi)")
                        .font(.subheadline)
                    
                    Text("•")
                        .font(.caption)
                    
                    Text("\(viewModel.zodiacAnimal) (\(viewModel.zodiacAnimalEnglish))")
                        .font(.subheadline)
                }
                .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.red.opacity(0.1))
            )
        }
    }
}

struct CalendarGridView: View {
    @EnvironmentObject var viewModel: CalendarViewModel

    let weekdays = ["CN", "T2", "T3", "T4", "T5", "T6", "T7"]
    let columns = Array(repeating: GridItem(.flexible()), count: 7)

    // We keep a finite sliding window of months to page through (centered on currentMonth)
    @State private var months: [Date] = []
    @State private var selectedPage: Int = 0
    private let pageRange = -12...12 // 25 pages (adjustable)

    var body: some View {
        VStack(spacing: 0) {
            // Month navigation (kept for quick taps)
            HStack {
                Button(action: {
                    goToPage(offset: -1)
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(.primary)
                }

                Spacer()

                Text(viewModel.currentMonth, formatter: monthYearFormatter)
                    .font(.headline)

                Spacer()

                Button(action: {
                    goToPage(offset: 1)
                }) {
                    Image(systemName: "chevron.right")
                        .font(.title3)
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()

            // Weekday headers
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(weekdays, id: \.self) { weekday in
                    Text(weekday)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 8)

            // Paging TabView for months
            TabView(selection: $selectedPage) {
                ForEach(months.indices, id: \.self) { idx in
                    // Each page is a month grid
                    let month = months[idx]
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(getDaysInMonth(for: month), id: \.self) { date in
                            CalendarDayCell(date: date)
                                .contentShape(Rectangle()) // ensure full cell is tappable
                        }
                    }
                    .padding(.horizontal, 4)
                    .tag(idx)
                    .onAppear {
                        // nothing specific
                    }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(minHeight: 350) // keep enough height for grid
            .onChange(of: selectedPage) { newIndex in
                // When user swipes to a page, update viewModel.currentMonth
                guard months.indices.contains(newIndex) else { return }
                withAnimation {
                    viewModel.currentMonth = months[newIndex]
                }
            }
            .onReceive(viewModel.$currentMonth) { newMonth in
                // Recompute months array centered on the new currentMonth and update selectedPage
                rebuildMonths(center: newMonth)
            }
            .onAppear {
                // build initial pages
                rebuildMonths(center: viewModel.currentMonth)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5)
        )
    }

    // MARK: - Helpers

    private var monthYearFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }

    private func rebuildMonths(center: Date) {
        var newMonths: [Date] = []
        let calendar = Calendar.current
        let centerStart = calendar.date(from: calendar.dateComponents([.year, .month], from: center)) ?? center

        for offset in pageRange {
            if let m = calendar.date(byAdding: .month, value: offset, to: centerStart) {
                newMonths.append(m)
            }
        }

        DispatchQueue.main.async {
            self.months = newMonths
            let centerIdx = -pageRange.lowerBound // fixed line ✅
            if newMonths.indices.contains(centerIdx) {
                self.selectedPage = centerIdx
            } else if let idx = newMonths.firstIndex(where: { Calendar.current.isDate($0, equalTo: centerStart, toGranularity: .month) }) {
                self.selectedPage = idx
            } else {
                self.selectedPage = 0
            }
        }
    }


    private func goToPage(offset: Int) {
        let target = selectedPage + offset
        guard months.indices.contains(target) else {
            // if out of range, update center month and rebuild then move
            if offset < 0 {
                viewModel.previousMonth()
            } else {
                viewModel.nextMonth()
            }
            return
        }
        selectedPage = target
        // selectedPage change handler (onChange) will update viewModel.currentMonth
    }

    // Returns array of Date? for the month's grid (leading nils for firstWeekday - 1)
    private func getDaysInMonth(for monthDate: Date) -> [Date?] {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: monthDate)

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

        // ensure full rows (optional): pad to multiple of 7 to keep consistent layout
        while days.count % 7 != 0 {
            days.append(nil)
        }

        return days
    }
}


struct CalendarDayCell: View {
    @EnvironmentObject var viewModel: CalendarViewModel
    let date: Date?
    
    var body: some View {
        if let date = date {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.year, .month, .day], from: date)
            let lunarDate = LunarCalendarCalculator.convertSolarToLunar(
                day: components.day!,
                month: components.month!,
                year: components.year!
            )
            
            Button(action: {
                viewModel.selectDate(date)
            }) {
                VStack(spacing: 2) {
                    Text("\(components.day!)")
                        .font(.system(size: 16, weight: viewModel.isToday(date) ? .bold : .regular))
                        .foregroundColor(getForegroundColor())
                    
                    Text("\(lunarDate.day)")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(getBackgroundColor())
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(viewModel.isSelected(date) ? Color.blue : Color.clear, lineWidth: 2)
                )
            }
        } else {
            Color.clear
                .frame(height: 50)
        }
    }
    
    private func getForegroundColor() -> Color {
        if viewModel.isToday(date) {
            return .white
        } else if viewModel.hasHoliday(date) {
            return .red
        } else {
            return .primary
        }
    }
    
    private func getBackgroundColor() -> Color {
        if viewModel.isToday(date) {
            return .blue
        } else if viewModel.hasHoliday(date) {
            return .red.opacity(0.1)
        } else {
            return Color(.systemGray6)
        }
    }
}

struct TodayInformationView: View {
    @EnvironmentObject var viewModel: CalendarViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Thông tin ngày")
                .font(.headline)
            
            VStack(spacing: 8) {
                InfoRow(
                    icon: "calendar",
                    title: "Âm lịch",
                    value: viewModel.lunarDate.displayString
                )
                
                InfoRow(
                    icon: "sparkles",
                    title: "Can Chi",
                    value: viewModel.canChi
                )
                
                InfoRow(
                    icon: "star.circle",
                    title: "Con giáp",
                    value: "\(viewModel.zodiacAnimal) (\(viewModel.zodiacAnimalEnglish))"
                )
                
                let specialDay = HolidayManager.isSpecialLunarDay(viewModel.lunarDate)
                if specialDay.isSpecial {
                    InfoRow(
                        icon: "moon.stars.fill",
                        title: "Ngày đặc biệt",
                        value: specialDay.name
                    )
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5)
        )
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            Text(title)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .fontWeight(.medium)
        }
        .font(.subheadline)
    }
}

struct HolidaysSectionView: View {
    @EnvironmentObject var viewModel: CalendarViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Lễ hội & Ngày lễ")
                .font(.headline)
            
            VStack(spacing: 12) {
                ForEach(viewModel.todayHolidays) { holiday in
                    HolidayCard(holiday: holiday)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5)
        )
    }
}

struct HolidayCard: View {
    let holiday: VietnameseHoliday
    
    var body: some View {
        HStack(spacing: 12) {
            Text(holiday.emoji)
                .font(.largeTitle)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(holiday.name)
                    .font(.headline)
                
                Text(holiday.nameEnglish)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(holiday.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.red.opacity(0.1))
        )
    }
}
