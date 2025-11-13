import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: CalendarViewModel
    @StateObject private var calendarIntegration = CalendarIntegrationManager()
    @State private var showHolidaysList = false
    @State private var selectedHoliday: VietnameseHoliday?
    @State private var showCalendarExport = false
    @State private var showDatePicker = false
    
    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    // Traditional Header with lunar date
                    TraditionalHeaderView()
                        .transition(.scale.combined(with: .opacity))
                    
                    // Date Picker Button
                    DatePickerButton(showDatePicker: $showDatePicker)
                    
                    // Traditional Calendar
                    TraditionalCalendarView()
                        .transition(.move(edge: .top).combined(with: .opacity))
                    
                    let specialDay = HolidayManager.isSpecialLunarDay(viewModel.lunarDate)
                
                    if !viewModel.todayHolidays.isEmpty {
                        TraditionalHolidaysSectionView(
                            selectedHoliday: $selectedHoliday,
                            showCalendarExport: $showCalendarExport
                        )
                        .transition(.scale.combined(with: .opacity))
                    } else {
                        if specialDay.isSpecial {
                            Divider()
                            Text("Ngày đặc biệt")
                            Text(specialDay.name)
//                            TraditionalHolidaysSectionView(
//                                selectedHoliday: .constant(VietnameseHoliday(
//                                    name: specialDay.name,
//                                    nameEnglish: "New Year's Day",
//                                    day: 15,
//                                    month: 0,
//                                    isLunar: false,
//                                    description: "Ngày giữa tháng",
//                                    emoji: "🎊"
//                                )),
//                                showCalendarExport: .constant(false)
//                            )
//                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    
                   
                    
                    AuspiciousHoursView(selectedDate: viewModel.selectedDate)
                    
                  
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .background(
                TraditionalBackground()
                    .ignoresSafeArea()
            )
            .navigationTitle("Lịch Âm Việt Nam")
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
                        .foregroundColor(.red)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.showSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.red)
                    }
                }
            }
            .sheet(isPresented: $viewModel.showSettings) {
                SettingsView()
                    .environmentObject(calendarIntegration)
            }
            .sheet(isPresented: $showDatePicker) {
                DatePickerSheet(selectedDate: $viewModel.selectedDate, showDatePicker: $showDatePicker)
            }
        }
        .navigationViewStyle(.stack)
    }
}

// MARK: - Traditional Background
struct TraditionalBackground: View {
    var body: some View {
        ZStack {
            // Base gradient - màu vàng kem truyền thống
            LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.85, blue: 0.7),
                    Color(red: 0.98, green: 0.92, blue: 0.8)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Pattern overlay
            GeometryReader { geometry in
                ForEach(0..<5) { i in
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.red.opacity(0.03), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 200
                            )
                        )
                        .frame(width: 400, height: 400)
                        .offset(
                            x: CGFloat(i % 2 == 0 ? -100 : geometry.size.width - 300),
                            y: CGFloat(i) * 200 - 100
                        )
                }
            }
        }
    }
}


// MARK: - Date Picker Button
struct DatePickerButton: View {
    @Binding var showDatePicker: Bool
    
    var body: some View {
        Button(action: {
            showDatePicker = true
        }) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .font(.title3)
                    .foregroundColor(.red)
                
                Text("Chọn ngày cụ thể")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.red)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.red.opacity(0.6))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: Color.red.opacity(0.15), radius: 8, x: 0, y: 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.red.opacity(0.3), Color.orange.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
            )
        }
    }
}

// MARK: - Date Picker Sheet
struct DatePickerSheet: View {
    @Binding var selectedDate: Date
    @Binding var showDatePicker: Bool
    @State private var tempDate: Date
    
    init(selectedDate: Binding<Date>, showDatePicker: Binding<Bool>) {
        self._selectedDate = selectedDate
        self._showDatePicker = showDatePicker
        self._tempDate = State(initialValue: selectedDate.wrappedValue)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Traditional decoration
                HStack(spacing: 8) {
                    Text("🏮")
                        .font(.title)
                    Text("Chọn Ngày")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.red)
                    Text("🏮")
                        .font(.title)
                }
                .padding(.top, 20)
                
                // Date Picker
                DatePicker(
                    "Chọn ngày",
                    selection: $tempDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .tint(.red)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white)
                        .shadow(color: Color.red.opacity(0.1), radius: 10, x: 0, y: 5)
                )
                
                // Selected date info
                VStack(spacing: 12) {
                    Text("Ngày đã chọn")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(tempDate, style: .date)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.red)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.red.opacity(0.1))
                )
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 16) {
                    Button(action: {
                        showDatePicker = false
                    }) {
                        Text("Hủy")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.gray.opacity(0.1))
                            )
                    }
                    
                    Button(action: {
                        selectedDate = tempDate
                        showDatePicker = false
                    }) {
                        Text("Xác nhận")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.red, Color.orange],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                    }
                }
                .padding(.bottom, 20)
            }
            .padding(.horizontal, 20)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.98, green: 0.92, blue: 0.8),
                        Color(red: 0.95, green: 0.88, blue: 0.75)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Traditional Header View

struct TraditionalHeaderView: View {
    @EnvironmentObject var viewModel: CalendarViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            // Solar date with traditional styling
            Text(viewModel.selectedDate, style: .date)
                .font(.system(size: 26, weight: .bold, design: .serif))
                .foregroundColor(.red)
                .id(viewModel.selectedDate)
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .scale.combined(with: .opacity)
                ))
            
            // Lunar date card with traditional red/gold theme
            VStack(spacing: 14) {
                HStack {
                    Image(systemName: "moon.stars.fill")
                        .font(.title2)
                        .foregroundColor(.yellow)
                    
                    Text("Ngày \(viewModel.lunarDate.displayString)")
                        .font(.system(size: 20, weight: .bold, design: .serif))
                        .foregroundColor(.white)
                }
                
                // Decorative divider
                HStack {
                    Rectangle()
                        .fill(Color.yellow.opacity(0.6))
                        .frame(height: 2)
                    Text("☯️")
                        .font(.caption)
                    Rectangle()
                        .fill(Color.yellow.opacity(0.6))
                        .frame(height: 2)
                }
                
                HStack(spacing: 20) {
                    VStack(spacing: 6) {
                        Text("Năm")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.yellow.opacity(0.9))
                        Text(viewModel.canChi)
                            .font(.system(size: 15, weight: .bold, design: .serif))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.red.opacity(0.3))
                    )
                    
                    VStack(spacing: 6) {
                        Text("Ngày")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.yellow.opacity(0.9))
                        Text(LunarCalendarCalculator.getDayCanChi(
                            day: Calendar.current.component(.day, from: viewModel.selectedDate),
                            month: Calendar.current.component(.month, from: viewModel.selectedDate),
                            year: Calendar.current.component(.year, from: viewModel.selectedDate)
                        ))
                            .font(.system(size: 15, weight: .bold, design: .serif))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.red.opacity(0.3))
                    )
                    
                    VStack(spacing: 6) {
                        Text("Con giáp")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.yellow.opacity(0.9))
                        Text("\(viewModel.zodiacAnimal)")
                            .font(.system(size: 15, weight: .bold, design: .serif))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.red.opacity(0.3))
                    )
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(
                ZStack {
                    // Main red background
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.8, green: 0.1, blue: 0.1),
                                    Color(red: 0.6, green: 0.05, blue: 0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    // Gold border
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.yellow.opacity(0.8), Color.orange.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                }
                .shadow(color: .red.opacity(0.4), radius: 15, x: 0, y: 8)
            )
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.selectedDate)
    }
}

// MARK: - Traditional Calendar View

struct TraditionalCalendarView: View {
    @EnvironmentObject var viewModel: CalendarViewModel
    
    let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)
    let weekdays = ["CN", "T2", "T3", "T4", "T5", "T6", "T7"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Month navigation header with traditional styling
            HStack {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        viewModel.previousMonth()
                    }
                }) {
                    Image(systemName: "chevron.left.circle.fill")
                        .font(.title2)
                        .foregroundColor(.red)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    Text(viewModel.currentMonth, formatter: monthYearFormatter)
                        .font(.system(size: 20, weight: .bold, design: .serif))
                        .foregroundColor(.red)
                }
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
                        .foregroundColor(.red)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 16)
            
            // Weekday headers
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(weekdays, id: \.self) { weekday in
                    Text(weekday)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.red.opacity(0.1))
                        )
                }
            }
            .padding(.bottom, 12)
            
            // Calendar grid
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(viewModel.getDaysInMonth(), id: \.self) { date in
                    TraditionalCalendarDayCell(date: date)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 4)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.currentMonth)
        }
        .padding(20)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white)
                
                RoundedRectangle(cornerRadius: 24)
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.red.opacity(0.3), Color.orange.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            }
            .shadow(color: .red.opacity(0.15), radius: 12, x: 0, y: 4)
        )
    }
    
    private var monthYearFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale(identifier: "vi_VN")
        return formatter
    }
}

// MARK: - Traditional Calendar Day Cell

struct TraditionalCalendarDayCell: View {
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
                        Text("🏮")
                            .font(.system(size: 8))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 64)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(getBackgroundColor())
                        
                        if viewModel.isSelected(date) {
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [Color.red, Color.orange],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 3
                                )
                        }
                    }
                    .shadow(color: getShadowColor(), radius: isPressed ? 2 : 4, x: 0, y: isPressed ? 1 : 2)
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
            return Color.red
        } else if viewModel.isSelected(date) {
            return Color.red.opacity(0.15)
        } else if viewModel.hasHoliday(date) {
            return Color.red.opacity(0.1)
        } else {
            return Color(.systemBackground)
        }
    }
    
    private func getShadowColor() -> Color {
        if viewModel.isToday(date) {
            return Color.red.opacity(0.4)
        } else if viewModel.isSelected(date) {
            return Color.red.opacity(0.3)
        } else {
            return Color.black.opacity(0.05)
        }
    }
}

// MARK: - Traditional Holidays Section

struct TraditionalHolidaysSectionView: View {
    @EnvironmentObject var viewModel: CalendarViewModel
    @Binding var selectedHoliday: VietnameseHoliday?
    @Binding var showCalendarExport: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("🎊")
                    .font(.title3)
                
                Text("Lễ hội & Ngày lễ")
                    .font(.system(size: 18, weight: .bold, design: .serif))
                    .foregroundColor(.red)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                ForEach(viewModel.todayHolidays) { holiday in
                    TraditionalHolidayCard(
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
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.red.opacity(0.3), Color.orange.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            }
            .shadow(color: .red.opacity(0.15), radius: 12, x: 0, y: 4)
        )
    }
}

struct TraditionalHolidayCard: View {
    let holiday: VietnameseHoliday
    let onExport: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        HStack(spacing: 16) {
            Text(holiday.emoji)
                .font(.system(size: 50))
            
            VStack(alignment: .leading, spacing: 6) {
                Text(holiday.name)
                    .font(.system(size: 16, weight: .bold, design: .serif))
                    .foregroundColor(.red)
                
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
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.red, Color.orange],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .shadow(color: .red.opacity(0.3), radius: 4, x: 0, y: 2)
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
                .fill(
                    LinearGradient(
                        colors: [
                            Color.red.opacity(0.08),
                            Color.orange.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.red.opacity(0.2), lineWidth: 1)
                )
        )
    }
}
