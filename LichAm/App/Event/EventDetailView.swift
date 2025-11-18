import SwiftUI

struct EventDetailView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var eventManager: EventManager
    @EnvironmentObject var calendarIntegration: CalendarIntegrationManager
    
    let eventId: String // Use ID instead of the event itself for proper refresh
    
    // Computed property to get the latest event data
    private var event: LichAmEvent? {
        eventManager.events.first(where: { $0.id == eventId })
    }
    
    @State private var showEditSheet = false
    @State private var showDeleteAlert = false
    @State private var showExportAlert = false
    
    // Convenience initializer that accepts an event
    init(event: LichAmEvent) {
        self.eventId = event.id
    }
    
    var body: some View {
        NavigationView {
            Group {
                if let event = event {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Header with color
                            headerView(event: event)
                            
                            // Main Info Card
                            infoCard(event: event)
                            
                            // Actions
                            actionsSection(event: event)
                            
                            Spacer(minLength: 40)
                        }
                        .padding(16)
                    }
                    .background(
                        TraditionalBackground()
                            .ignoresSafeArea()
                    )
                } else {
                    // Event was deleted
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)
                        
                        Text("Sự kiện không tồn tại")
                            .font(.headline)
                        
                        Button("Đóng") {
                            dismiss()
                        }
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
            }
            .navigationTitle("Chi tiết sự kiện")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Đóng") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showEditSheet) {
                if let event = event {
                    EventCreationView(editingEvent: event)
                        .environmentObject(eventManager)
                        .environmentObject(calendarIntegration)
                }
            }
            .alert("Xóa sự kiện", isPresented: $showDeleteAlert) {
                Button("Hủy", role: .cancel) {}
                Button("Xóa", role: .destructive) {
                    deleteEvent()
                }
            } message: {
                Text("Bạn có chắc chắn muốn xóa sự kiện này?")
            }
            .alert("Xuất sang Lịch", isPresented: $showExportAlert) {
                Button("Hủy", role: .cancel) {}
                Button("Xuất") {
                    exportToCalendar()
                }
            } message: {
                Text("Thêm sự kiện này vào app Lịch của bạn?")
            }
        }
    }
    
    private func headerView(event: LichAmEvent) -> some View {
        VStack(spacing: 16) {
            // Color indicator
            Circle()
                .fill(event.color.colorValue)
                .frame(width: 40, height: 40)
                .overlay(
                    Text(event.color.emoji)
                        .font(.system(size: 20))
                )
                .shadow(color: event.color.colorValue.opacity(0.4), radius: 20, x: 0, y: 10)
            
            // Title
            Text(event.title)
                .font(.system(size: 28, weight: .bold, design: .serif))
                .foregroundColor(.red)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.vertical, 20)
    }
    
    private func infoCard(event: LichAmEvent) -> some View {
        VStack(spacing: 0) {
            // Date & Time
            InfoRow(
                icon: "calendar",
                iconColor: .blue,
                title: "Ngày",
                value: formatDate(event.startDate)
            )
            
            Divider().padding(.leading, 56)
            
            InfoRow(
                icon: event.isAllDay ? "sun.max" : "clock",
                iconColor: .orange,
                title: "Thời gian",
                value: formatTime(event: event)
            )
            
            if event.repeatType != .never {
                Divider().padding(.leading, 56)
                
                InfoRow(
                    icon: "repeat",
                    iconColor: .purple,
                    title: "Lặp lại",
                    value: event.repeatType.displayName
                )
            }
            
            if event.isLunarDateBased {
                Divider().padding(.leading, 56)
                
                InfoRow(
                    icon: "moon.fill",
                    iconColor: .yellow,
                    title: "Âm lịch",
                    value: "Ngày \(event.lunarDay ?? 0)/\(event.lunarMonth ?? 0)"
                )
            }
            
            if let reminder = event.reminderMinutesBefore {
                Divider().padding(.leading, 56)
                
                InfoRow(
                    icon: "bell.fill",
                    iconColor: .red,
                    title: "Nhắc nhở",
                    value: formatReminderTime(reminder)
                )
            }
            
            if let notes = event.notes, !notes.isEmpty {
                Divider().padding(.leading, 56)
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "note.text")
                            .font(.title3)
                            .foregroundColor(.green)
                            .frame(width: 40)
                        
                        Text("Ghi chú")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    
                    Text(notes)
                        .font(.body)
                        .foregroundColor(.primary)
                        .padding(.leading, 56)
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 16)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .red.opacity(0.15), radius: 12, x: 0, y: 4)
        )
    }
    
    private func actionsSection(event: LichAmEvent) -> some View {
        VStack(spacing: 12) {
            // Edit Button
            ActionButton(
                icon: "pencil",
                title: "Chỉnh sửa",
                color: .blue,
                action: {
                    showEditSheet = true
                }
            )
            
            // Export to Calendar - Only show if NOT already in system calendar
            if event.ekEventIdentifier == nil {
                ActionButton(
                    icon: "calendar.badge.plus",
                    title: "Thêm vào Lịch hệ thống",
                    color: .green,
                    action: {
                        showExportAlert = true
                    }
                )
            } else {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Đã có trong Lịch hệ thống")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.green.opacity(0.1))
                )
            }
            
            // Delete Button
            ActionButton(
                icon: "trash",
                title: "Xóa sự kiện",
                color: .red,
                action: {
                    showDeleteAlert = true
                }
            )
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.dateFormat = "EEEE, d MMMM yyyy"
        return formatter.string(from: date)
    }
    
    private func formatTime(event: LichAmEvent) -> String {
        if event.isAllDay {
            return "Cả ngày"
        }
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.dateFormat = "HH:mm"
        
        let start = formatter.string(from: event.startDate)
        let end = formatter.string(from: event.endDate)
        
        return "\(start) - \(end)"
    }
    
    private func formatReminderTime(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes) phút trước"
        } else if minutes < 1440 {
            let hours = minutes / 60
            return "\(hours) giờ trước"
        } else {
            let days = minutes / 1440
            return "\(days) ngày trước"
        }
    }
    
    private func deleteEvent() {
        guard let event = event else { return }
        eventManager.deleteEvent(event)
        dismiss()
    }
    
    private func exportToCalendar() {
        guard let event = event else { return }
        
        // Double-check that it's not already in the calendar
        guard event.ekEventIdentifier == nil else {
            print("Event already in system calendar, skipping export")
            return
        }
        
        calendarIntegration.createEvent(
            title: "\(event.color.emoji) \(event.title)",
            date: event.startDate,
            notes: event.notes,
            isAllDay: event.isAllDay,
            duration: event.endDate.timeIntervalSince(event.startDate)
        ) { success, eventIdentifier, error in
            if success, let identifier = eventIdentifier {
                // Update event with the actual EK identifier
                var updatedEvent = event
                updatedEvent.ekEventIdentifier = identifier
                eventManager.updateEvent(updatedEvent)
                print("Event exported to system calendar with ID: \(identifier)")
            } else if let error = error {
                print("Failed to export to system calendar: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Info Row
struct InfoRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(iconColor)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.body)
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
    }
}

// MARK: - Action Button
struct ActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.headline)
                
                Text(title)
                    .font(.headline)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .foregroundColor(color)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(color.opacity(0.3), lineWidth: 1)
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0.0, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Preview
struct EventDetailView_Previews: PreviewProvider {
    static var previews: some View {
        EventDetailView(
            event: LichAmEvent(
                title: "Sinh nhật mẹ",
                notes: "Chuẩn bị quà và bánh sinh nhật",
                startDate: Date(),
                endDate: Date().addingTimeInterval(3600),
                isAllDay: true,
                reminderMinutesBefore: 1440,
                color: .pink,
                repeatType: .yearly
            )
        )
        .environmentObject(EventManager())
        .environmentObject(CalendarIntegrationManager())
    }
}
