import SwiftUI

struct EventCreationView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var eventManager: EventManager
    @EnvironmentObject var calendarIntegration: CalendarIntegrationManager
    
    @State private var title: String = ""
    @State private var notes: String = ""
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var isAllDay: Bool = false
    @State private var hasReminder: Bool = false
    @State private var reminderMinutes: Int = 30
    @State private var selectedColor: EventColor = .red
    @State private var isLunarDateBased: Bool = false
    @State private var repeatType: EventRepeatType = .never
    @State private var addToSystemCalendar: Bool = true
    
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
    let editingEvent: LichAmEvent?
    let preselectedDate: Date
    
    init(preselectedDate: Date = Date(), editingEvent: LichAmEvent? = nil) {
        self.preselectedDate = preselectedDate
        self.editingEvent = editingEvent
        
        if let event = editingEvent {
            _title = State(initialValue: event.title)
            _notes = State(initialValue: event.notes ?? "")
            _startDate = State(initialValue: event.startDate)
            _endDate = State(initialValue: event.endDate)
            _isAllDay = State(initialValue: event.isAllDay)
            _hasReminder = State(initialValue: event.reminderMinutesBefore != nil)
            _reminderMinutes = State(initialValue: event.reminderMinutesBefore ?? 30)
            _selectedColor = State(initialValue: event.color)
            _isLunarDateBased = State(initialValue: event.isLunarDateBased)
            _repeatType = State(initialValue: event.repeatType)
        } else {
            _startDate = State(initialValue: preselectedDate)
            _endDate = State(initialValue: preselectedDate.addingTimeInterval(3600))
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Basic Info Section
                Section {
                    TextField("Tiêu đề sự kiện", text: $title)
                        .font(.headline)
                    
                    ZStack(alignment: .topLeading) {
                        if notes.isEmpty {
                            Text("Ghi chú (tùy chọn)")
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                        TextEditor(text: $notes)
                            .frame(minHeight: 80)
                            .font(.body)
                    }
                } header: {
                    Label("Thông tin sự kiện", systemImage: "info.circle")
                }
                
                // Date & Time Section
                Section {
                    Toggle("Cả ngày", isOn: $isAllDay)
                        .tint(.red)
                    
                    DatePicker(
                        "Bắt đầu",
                        selection: $startDate,
                        displayedComponents: isAllDay ? [.date] : [.date, .hourAndMinute]
                    )
                    .tint(.red)
                    
                    DatePicker(
                        "Kết thúc",
                        selection: $endDate,
                        displayedComponents: isAllDay ? [.date] : [.date, .hourAndMinute]
                    )
                    .tint(.red)
                    
                    Picker("Lặp lại", selection: $repeatType) {
                        ForEach(EventRepeatType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .tint(.red)
                } header: {
                    Label("Thời gian", systemImage: "calendar")
                }
                
                // Lunar Date Option
                Section {
                    Toggle("Theo Âm lịch", isOn: $isLunarDateBased)
                        .tint(.red)
                    
                    if isLunarDateBased {
                        Text("Sự kiện sẽ lặp lại theo ngày Âm lịch")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Label("Âm lịch", systemImage: "moon.fill")
                }
                
                // Reminder Section
                Section {
                    Toggle("Nhắc nhở", isOn: $hasReminder)
                        .tint(.red)
                    
                    if hasReminder {
                        Picker("Nhắc trước", selection: $reminderMinutes) {
                            Text("5 phút").tag(5)
                            Text("15 phút").tag(15)
                            Text("30 phút").tag(30)
                            Text("1 giờ").tag(60)
                            Text("2 giờ").tag(120)
                            Text("1 ngày").tag(1440)
                            Text("1 tuần").tag(10080)
                        }
                        .tint(.red)
                    }
                } header: {
                    Label("Nhắc nhở", systemImage: "bell.fill")
                }
                
                // Color Selection
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(EventColor.allCases, id: \.self) { color in
                                ColorSelectionButton(
                                    color: color,
                                    isSelected: selectedColor == color,
                                    action: {
                                        withAnimation(.spring(response: 0.3)) {
                                            selectedColor = color
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.vertical, 8)
                    }
                } header: {
                    Label("Màu sắc", systemImage: "paintpalette.fill")
                }
                
                // Calendar Integration
                Section {
                    Toggle("Thêm vào Lịch hệ thống", isOn: $addToSystemCalendar)
                        .tint(.red)
                    
                    if addToSystemCalendar {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Sự kiện sẽ xuất hiện trong app Lịch")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Label("Tích hợp", systemImage: "calendar.badge.plus")
                }
            }
            .navigationTitle(editingEvent == nil ? "Tạo sự kiện" : "Sửa sự kiện")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Hủy") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(editingEvent == nil ? "Tạo" : "Lưu") {
                        saveEvent()
                    }
                    .disabled(title.isEmpty)
                }
            }
            .alert("Thông báo", isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func saveEvent() {
        // Validate dates
        guard endDate >= startDate else {
            alertMessage = "Thời gian kết thúc phải sau thời gian bắt đầu"
            showAlert = true
            return
        }
        
        // Calculate lunar date if needed
        var lunarDay: Int? = nil
        var lunarMonth: Int? = nil
        
        if isLunarDateBased {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.year, .month, .day], from: startDate)
            let lunarDate = LunarCalendarCalculator.convertSolarToLunar(
                day: components.day!,
                month: components.month!,
                year: components.year!
            )
            lunarDay = lunarDate.day
            lunarMonth = lunarDate.month
        }
        
        // Create or update event
        let event = LichAmEvent(
            id: editingEvent?.id ?? UUID().uuidString,
            title: title,
            notes: notes.isEmpty ? nil : notes,
            startDate: startDate,
            endDate: endDate,
            isAllDay: isAllDay,
            reminderMinutesBefore: hasReminder ? reminderMinutes : nil,
            color: selectedColor,
            isLunarDateBased: isLunarDateBased,
            lunarDay: lunarDay,
            lunarMonth: lunarMonth,
            repeatType: repeatType
        )
        
        if editingEvent == nil {
            eventManager.addEvent(event)
        } else {
            eventManager.updateEvent(event)
        }
        
        // Add to system calendar if requested
        if addToSystemCalendar {
            addToSystemCalendarAction(event: event)
        }
        
        dismiss()
    }
    
    private func addToSystemCalendarAction(event: LichAmEvent) {
        calendarIntegration.createEvent(
            title: "\(event.color.emoji) \(event.title)",
            date: event.startDate,
            notes: event.notes,
            isAllDay: event.isAllDay,
            duration: event.endDate.timeIntervalSince(event.startDate)
        ) { success, error in
            if !success {
                print("Failed to add to system calendar: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
}

// MARK: - Color Selection Button
struct ColorSelectionButton: View {
    let color: EventColor
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(color.colorValue)
                        .frame(width: 44, height: 44)
                    
                    if isSelected {
                        Circle()
                            .strokeBorder(Color.white, lineWidth: 3)
                            .frame(width: 44, height: 44)
                        
                        Circle()
                            .strokeBorder(color.colorValue, lineWidth: 2)
                            .frame(width: 52, height: 52)
                        
                        Image(systemName: "checkmark")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }
                
                Text(color.displayName)
                    .font(.caption2)
                    .foregroundColor(isSelected ? color.colorValue : .secondary)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
        }
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Preview
struct EventCreationView_Previews: PreviewProvider {
    static var previews: some View {
        EventCreationView()
            .environmentObject(EventManager())
            .environmentObject(CalendarIntegrationManager())
    }
}
