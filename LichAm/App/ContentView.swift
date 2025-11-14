import SwiftUI


struct ContentView: View {
    @EnvironmentObject var viewModel: CalendarViewModel
    @EnvironmentObject var eventManager: EventManager
    @StateObject private var calendarIntegration = CalendarIntegrationManager()
    @State private var showHolidaysList = false
    @State private var selectedHoliday: VietnameseHoliday?
    @State private var showCalendarExport = false
    @State private var showDatePicker = false
    @State private var showEventsList = false
    
    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    // Traditional Header with lunar date
                    TraditionalHeaderView()
                        .transition(.scale.combined(with: .opacity))
                    
                    // Date Picker Button - IMPROVED WITH LUNAR DATE
                    DatePickerButton(showDatePicker: $showDatePicker)
                    
                    // Traditional Calendar
                    TraditionalCalendarView()
                        .transition(.move(edge: .top).combined(with: .opacity))
                    
                    // Events Section
                    if eventManager.hasEvents(for: viewModel.selectedDate) {
                        DailyEventsSection()
                            .id(viewModel.selectedDate)
                            .transition(.scale.combined(with: .opacity))
                    }
                    
                    let specialDay = HolidayManager.isSpecialLunarDay(viewModel.lunarDate)
                    if specialDay.isSpecial {
                        VStack(alignment: .leading, spacing: 12) {

                            HStack(spacing: 8) {
                                Image(systemName: "sparkles")
                                    .foregroundColor(.yellow)
                                    .font(.title3)

                                Text("Ngày đặc biệt")
                                    .font(.system(size: 18, weight: .bold, design: .serif))
                                    .foregroundColor(.red)
                                Spacer()
                            }

                            Text(specialDay.name)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.red.opacity(0.8))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.red.opacity(0.08))
                                )

                        }
                        .padding(20)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white)
                                .shadow(color: Color.red.opacity(0.1), radius: 8, x: 0, y: 5)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(
                                            LinearGradient(
                                                colors: [
                                                    Color.red.opacity(0.4),
                                                    Color.orange.opacity(0.3)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 2
                                        )
                                )
                        )
                        .transition(.scale.combined(with: .opacity))
                    }
                    if !viewModel.todayHolidays.isEmpty {
                        TraditionalHolidaysSectionView(
                            selectedHoliday: $selectedHoliday,
                            showCalendarExport: $showCalendarExport
                        )
                        .transition(.scale.combined(with: .opacity))
                    }
                    AuspiciousHoursView(selectedDate: viewModel.selectedDate, showInauspicious: false)
                        .id(viewModel.selectedDate)
                    
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
                    HStack(spacing: 12) {
                        // Events button with badge
                        Button(action: {
                            showEventsList = true
                        }) {
                            ZStack(alignment: .topTrailing) {
                                Image(systemName: "calendar.badge.clock")
                                    .font(.title3)
                                    .foregroundColor(.red)
                                
                                if eventManager.getTotalEventsCount() > 0 {
                                    Circle()
                                        .fill(Color.orange)
                                        .frame(width: 8, height: 8)
                                        .offset(x: 4, y: -4)
                                }
                            }
                        }
                        
                        Button(action: {
                            viewModel.showSettings = true
                        }) {
                            Image(systemName: "gearshape.fill")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .sheet(isPresented: $viewModel.showSettings) {
                SettingsView()
                    .environmentObject(calendarIntegration)
            }
            .sheet(isPresented: $showDatePicker) {
                    DatePickerSheet(showDatePicker: $showDatePicker)
                        .environmentObject(viewModel)
            }
            .sheet(isPresented: $showEventsList) {
                EventListView()
                    .environmentObject(eventManager)
                    .environmentObject(calendarIntegration)
                    .environmentObject(viewModel)
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

// MARK: - Date Picker Button - IMPROVED WITH LUNAR DATE
struct DatePickerButton: View {
    @EnvironmentObject var viewModel: CalendarViewModel
    @Binding var showDatePicker: Bool
    
    var body: some View {
        Button(action: {
            showDatePicker = true
        }) {
            HStack(spacing: 16) {
                Image(systemName: "calendar.badge.clock")
                    .font(.title2)
                    .foregroundColor(.red)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Chọn ngày cụ thể")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.red)
                    
                    HStack(spacing: 12) {
                        // Solar date
                        HStack(spacing: 4) {
                            Image(systemName: "sun.max.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.orange.opacity(0.8))
                            Text(formatSolarDate(viewModel.selectedDate))
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.primary.opacity(0.8))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.orange.opacity(0.1))
                        )
                        
                        // Lunar date
                        HStack(spacing: 4) {
                            Image(systemName: "moon.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.red.opacity(0.8))
                            Text("\(viewModel.lunarDate.day)/\(viewModel.lunarDate.month)")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.red)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.red.opacity(0.1))
                        )
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right.circle.fill")
                    .font(.title3)
                    .foregroundColor(.red.opacity(0.7))
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
    
    private func formatSolarDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Date Picker Sheet
struct DatePickerSheet: View {
    @EnvironmentObject var viewModel: CalendarViewModel
    @Binding var showDatePicker: Bool
    @State private var tempDate: Date = Date()
    
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
                
                // Selected date info - ENHANCED WITH LUNAR DATE
                VStack(spacing: 16) {
                    Text("Ngày đã chọn")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Solar date
                    Text(formatVietnameseDate(tempDate))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.red)
                    
                    // Lunar date display
                    let calendar = Calendar.current
                    let components = calendar.dateComponents([.year, .month, .day], from: tempDate)
                    let lunarDate = LunarCalendarCalculator.convertSolarToLunar(
                        day: components.day!,
                        month: components.month!,
                        year: components.year!
                    )
                    
                    HStack(spacing: 16) {
                        VStack(spacing: 6) {
                            HStack(spacing: 6) {
                                Image(systemName: "moon.fill")
                                    .font(.caption)
                                    .foregroundColor(.red)
                                Text("Âm lịch")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Text("\(lunarDate.day)/\(lunarDate.month)/\(lunarDate.year)")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.red)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.red.opacity(0.1))
                        )
                        
                        VStack(spacing: 6) {
                            HStack(spacing: 6) {
                                Image(systemName: "star.circle")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                Text("Can Chi")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Text(LunarCalendarCalculator.getDayCanChi(
                                day: components.day!,
                                month: components.month!,
                                year: components.year!
                            ))
                            .font(.system(size: 14, weight: .bold, design: .serif))
                            .foregroundColor(.primary)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.orange.opacity(0.1))
                        )
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.red.opacity(0.05))
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
                        viewModel.selectDate(tempDate)
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
            .onAppear {
                tempDate = viewModel.selectedDate
            }
            .navigationBarHidden(true)
        }
    }
    
    private func formatVietnameseDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMMM yyyy"
        formatter.locale = Locale(identifier: "vi_VN")
        return formatter.string(from: date)
    }
}

// MARK: - Traditional Header View
struct TraditionalHeaderView: View {
    @EnvironmentObject var viewModel: CalendarViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            // Solar date with traditional styling
            Text(formatVietnameseDate(viewModel.selectedDate))
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
    
    private func formatVietnameseDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMMM yyyy"
        formatter.locale = Locale(identifier: "vi_VN")
        return formatter.string(from: date)
    }
}
