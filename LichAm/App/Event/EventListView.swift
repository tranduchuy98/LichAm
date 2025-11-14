import SwiftUI

struct EventListView: View {
    @EnvironmentObject var eventManager: EventManager
    @EnvironmentObject var calendarIntegration: CalendarIntegrationManager
    @EnvironmentObject var viewModel: CalendarViewModel
    
    @State private var showCreateEvent = false
    @State private var selectedEvent: LichAmEvent?
    @State private var showEventDetail = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                TraditionalBackground()
                    .ignoresSafeArea()
                
                if eventManager.events.isEmpty {
                    emptyStateView
                } else {
                    eventsList
                }
            }
            .navigationTitle("Sự kiện của tôi")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showCreateEvent = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.red)
                    }
                }
            }
            .sheet(isPresented: $showCreateEvent) {
                EventCreationView(preselectedDate: viewModel.selectedDate)
                    .environmentObject(eventManager)
                    .environmentObject(calendarIntegration)
            }
            .sheet(item: $selectedEvent) { event in
                EventDetailView(event: event)
                    .environmentObject(eventManager)
                    .environmentObject(calendarIntegration)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 64))
                .foregroundColor(.red.opacity(0.3))
            
            Text("Chưa có sự kiện nào")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.red)
            
            Text("Tạo sự kiện đầu tiên của bạn")
                .font(.body)
                .foregroundColor(.secondary)
            
            Button(action: {
                showCreateEvent = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Tạo sự kiện")
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
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
                .foregroundColor(.white)
            }
            .padding(.top, 8)
        }
    }
    
    private var eventsList: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Upcoming Events
                if !eventManager.getUpcomingEvents().isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Sắp diễn ra")
                            .font(.headline)
                            .foregroundColor(.red)
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                        
                        ForEach(eventManager.getUpcomingEvents()) { event in
                            EventCard(event: event) {
                                selectedEvent = event
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                }
                
                // All Events
                VStack(alignment: .leading, spacing: 12) {
                    Text("Tất cả sự kiện")
                        .font(.headline)
                        .foregroundColor(.red)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                    
                    ForEach(eventManager.events.sorted(by: { $0.startDate > $1.startDate })) { event in
                        EventCard(event: event) {
                            selectedEvent = event
                        }
                        .padding(.horizontal, 16)
                    }
                }
                
                Spacer(minLength: 40)
            }
            .padding(.vertical, 16)
        }
    }
}

// MARK: - Event Card
struct EventCard: View {
    let event: LichAmEvent
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Color indicator
                RoundedRectangle(cornerRadius: 4)
                    .fill(event.color.colorValue)
                    .frame(width: 6)
                
                VStack(alignment: .leading, spacing: 8) {
                    // Title
                    HStack {
                        Text(event.color.emoji)
                            .font(.title3)
                        
                        Text(event.title)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if event.repeatType != .never {
                            Image(systemName: "repeat")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Date and time
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: event.isAllDay ? "calendar" : "clock")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(formatDate(event.startDate, isAllDay: event.isAllDay))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        if event.isLunarDateBased {
                            HStack(spacing: 4) {
                                Image(systemName: "moon.fill")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                
                                Text("Âm lịch")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.orange.opacity(0.1))
                            )
                        }
                    }
                    
                    // Notes preview
                    if let notes = event.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    // Tags
                    HStack(spacing: 8) {
                        if event.reminderMinutesBefore != nil {
                            TagView(icon: "bell.fill", text: "Nhắc nhở", color: .blue)
                        }
                        
                        if event.ekEventIdentifier != nil {
                            TagView(icon: "calendar", text: "Trong Lịch", color: .green)
                        }
                    }
                }
                .padding(.vertical, 4)
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                    
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            event.color.colorValue.opacity(0.3),
                            lineWidth: 1
                        )
                }
                .shadow(color: event.color.colorValue.opacity(0.15), radius: 8, x: 0, y: 4)
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
    
    private func formatDate(_ date: Date, isAllDay: Bool) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        
        if isAllDay {
            formatter.dateFormat = "EEEE, d MMMM yyyy"
        } else {
            formatter.dateFormat = "HH:mm, EEEE, d MMM"
        }
        
        return formatter.string(from: date)
    }
}

// MARK: - Tag View
struct TagView: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
            
            Text(text)
                .font(.system(size: 11))
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - Preview
struct EventListView_Previews: PreviewProvider {
    static var previews: some View {
        EventListView()
            .environmentObject(EventManager())
            .environmentObject(CalendarViewModel())
            .environmentObject(CalendarIntegrationManager())
    }
}
