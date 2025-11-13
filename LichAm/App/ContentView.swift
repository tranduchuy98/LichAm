import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: CalendarViewModel
    @StateObject private var calendarIntegration = CalendarIntegrationManager()
    @State private var showAuspiciousHours = false
    @State private var showHolidaysList = false
    @State private var selectedHoliday: VietnameseHoliday?
    @State private var showCalendarExport = false
    
    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    // Modern Header with lunar date
                    ModernHeaderView()
                        .transition(.scale.combined(with: .opacity))
                    
                    // Smooth Scrolling Calendar
                    ModernCalendarView()
                        .transition(.move(edge: .top).combined(with: .opacity))
                    
                    // Today's Information Card
                    ModernTodayInfoCard()
                        .transition(.move(edge: .leading).combined(with: .opacity))
                    
                    
                    // Holidays Section
                    if !viewModel.todayHolidays.isEmpty {
                        ModernHolidaysSectionView(
                            selectedHoliday: $selectedHoliday,
                            showCalendarExport: $showCalendarExport
                        )
                        .transition(.scale.combined(with: .opacity))
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .background(
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color(.systemBackground).opacity(0.95)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Lịch Âm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        viewModel.goToToday()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar.circle.fill")
                            Text("Hôm nay")
                                .font(.subheadline)
                        }
                        .foregroundColor(.blue)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.showSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $viewModel.showSettings) {
                SettingsView()
                    .environmentObject(calendarIntegration)
            }
        }
        .navigationViewStyle(.stack)
    }
}

// MARK: - Modern Header View

struct ModernHeaderView: View {
    @EnvironmentObject var viewModel: CalendarViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            // Solar date with animation
            Text(viewModel.selectedDate, style: .date)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .id(viewModel.selectedDate)
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .scale.combined(with: .opacity)
                ))
            
            // Lunar date card with gradient
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "moon.stars.fill")
                        .font(.title2)
                        .foregroundColor(.yellow)
                    
                    Text("Ngày \(viewModel.lunarDate.displayString)")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                Divider()
                    .background(Color.white.opacity(0.3))
                
                HStack(spacing: 20) {
                    VStack(spacing: 4) {
                        Text("Năm")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        Text(viewModel.canChi)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    }
                    
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 1, height: 30)
                    
                    VStack(spacing: 4) {
                        Text("Con giáp")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        Text("\(viewModel.zodiacAnimal)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    }
                    
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 1, height: 30)
                    
                    VStack(spacing: 4) {
                        Text("English")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        Text(viewModel.zodiacAnimalEnglish)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [Color.red.opacity(0.8), Color.orange.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .red.opacity(0.3), radius: 10, x: 0, y: 5)
            )
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.selectedDate)
    }
}

// MARK: - Modern Calendar View with Smooth Scrolling

struct ModernCalendarView: View {
    @EnvironmentObject var viewModel: CalendarViewModel
    @State private var scrollOffset: CGFloat = 0
    @State private var months: [Date] = []
    @State private var currentMonthIndex: Int = 12
    
    let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)
    let weekdays = ["CN", "T2", "T3", "T4", "T5", "T6", "T7"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Month navigation header
            HStack {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        viewModel.previousMonth()
                    }
                }) {
                    Image(systemName: "chevron.left.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                Text(viewModel.currentMonth, formatter: monthYearFormatter)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .id(viewModel.currentMonth)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                
                Spacer()
                
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        viewModel.nextMonth()
                    }
                }) {
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 16)
            
            // Weekday headers
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(weekdays, id: \.self) { weekday in
                    Text(weekday)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 12)
            
            // Calendar grid
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(viewModel.getDaysInMonth(), id: \.self) { date in
                    ModernCalendarDayCell(date: date)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 4)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.currentMonth)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
    }
    
    private var monthYearFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale(identifier: "vi_VN")
        return formatter
    }
}

// MARK: - Modern Calendar Day Cell

struct ModernCalendarDayCell: View {
    @EnvironmentObject var viewModel: CalendarViewModel
    let date: Date?
    @State private var isPressed = false
    
    var body: some View {
        if let date = date {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.year, .month, .day], from: date)
            let lunarDate = viewModel.getLunarDateForDate(date)
            
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    viewModel.selectDate(date)
                }
            }) {
                VStack(spacing: 4) {
                    Text("\(components.day!)")
                        .font(.system(size: 16, weight: viewModel.isToday(date) ? .bold : .semibold))
                        .foregroundColor(getForegroundColor())
                    
                    Text("\(lunarDate.day)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(getForegroundColor().opacity(0.7))
                    
                    if viewModel.hasHoliday(date) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 4, height: 4)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 64)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(getBackgroundColor())
                        .shadow(color: getShadowColor(), radius: isPressed ? 2 : 4, x: 0, y: isPressed ? 1 : 2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(getBorderColor(), lineWidth: viewModel.isSelected(date) ? 2.5 : 0)
                )
                .scaleEffect(isPressed ? 0.95 : 1.0)
            }
            .buttonStyle(PlainButtonStyle())
            .onLongPressGesture(minimumDuration: 0.0, pressing: { pressing in
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = pressing
                }
            }, perform: {})
        } else {
            Color.clear
                .frame(height: 64)
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
            return Color.blue
        } else if viewModel.isSelected(date) {
            return Color.blue.opacity(0.15)
        } else if viewModel.hasHoliday(date) {
            return Color.red.opacity(0.08)
        } else {
            return Color(.tertiarySystemBackground)
        }
    }
    
    private func getBorderColor() -> Color {
        return viewModel.isSelected(date) ? Color.blue : Color.clear
    }
    
    private func getShadowColor() -> Color {
        if viewModel.isToday(date) {
            return Color.blue.opacity(0.3)
        } else if viewModel.isSelected(date) {
            return Color.blue.opacity(0.2)
        } else {
            return Color.black.opacity(0.05)
        }
    }
}

// MARK: - Modern Today Info Card

struct ModernTodayInfoCard: View {
    @EnvironmentObject var viewModel: CalendarViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .font(.title3)
                    .foregroundColor(.blue)
                
                Text("Thông tin ngày")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            VStack(spacing: 14) {
                ModernInfoRow(
                    icon: "calendar",
                    iconColor: .blue,
                    title: "Âm lịch",
                    value: viewModel.lunarDate.displayString
                )
                
                Divider()
                
                ModernInfoRow(
                    icon: "sparkles",
                    iconColor: .purple,
                    title: "Can Chi",
                    value: LunarCalendarCalculator.getDayCanChi(
                        day: Calendar.current.component(.day, from: viewModel.selectedDate),
                        month: Calendar.current.component(.month, from: viewModel.selectedDate),
                        year: Calendar.current.component(.year, from: viewModel.selectedDate)
                    )
                )
                
                Divider()
                
                ModernInfoRow(
                    icon: "star.circle.fill",
                    iconColor: .yellow,
                    title: "Con giáp năm",
                    value: "\(viewModel.zodiacAnimal) (\(viewModel.zodiacAnimalEnglish))"
                )
                
                let specialDay = HolidayManager.isSpecialLunarDay(viewModel.lunarDate)
                if specialDay.isSpecial {
                    Divider()
                    
                    ModernInfoRow(
                        icon: "moon.stars.fill",
                        iconColor: .orange,
                        title: "Ngày đặc biệt",
                        value: specialDay.name
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
    }
}

struct ModernInfoRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(iconColor)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
    }
}




// MARK: - Modern Holidays Section

struct ModernHolidaysSectionView: View {
    @EnvironmentObject var viewModel: CalendarViewModel
    @Binding var selectedHoliday: VietnameseHoliday?
    @Binding var showCalendarExport: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "gift.fill")
                    .font(.title3)
                    .foregroundColor(.red)
                
                Text("Lễ hội & Ngày lễ")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                ForEach(viewModel.todayHolidays) { holiday in
                    ModernHolidayCard(
                        holiday: holiday,
                        onExport: {
                            selectedHoliday = holiday
                            showCalendarExport = true
                        }
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
    }
}

struct ModernHolidayCard: View {
    let holiday: VietnameseHoliday
    let onExport: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        HStack(spacing: 16) {
            Text(holiday.emoji)
                .font(.system(size: 50))
            
            VStack(alignment: .leading, spacing: 6) {
                Text(holiday.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(holiday.nameEnglish)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(holiday.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            Button(action: onExport) {
                Image(systemName: "calendar.badge.plus")
                    .font(.title3)
                    .foregroundColor(.blue)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(Color.blue.opacity(0.15))
                    )
            }
            .scaleEffect(isPressed ? 0.9 : 1.0)
            .onLongPressGesture(minimumDuration: 0.0, pressing: { pressing in
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = pressing
                }
            }, perform: {})
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.red.opacity(0.08))
        )
    }
}
