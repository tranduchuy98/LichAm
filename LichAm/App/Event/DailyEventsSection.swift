import SwiftUI

// MARK: - Daily Events Section
struct DailyEventsSection: View {
    @EnvironmentObject var eventManager: EventManager
    @EnvironmentObject var viewModel: CalendarViewModel
    
    @State private var showEventDetail: LichAmEvent?
    @State private var showCreateEvent = false
    
    private var todayEvents: [LichAmEvent] {
        eventManager.getEvents(for: viewModel.selectedDate)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with create button
            HStack {
                HStack(spacing: 8) {
                    Text("📅")
                        .font(.title3)
                    
                    Text("Sự kiện hôm nay")
                        .font(.system(size: 18, weight: .bold, design: .serif))
                        .foregroundColor(.red)
                }
                
                Spacer()
                
                Button(action: {
                    showCreateEvent = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundColor(.red)
                }
            }
            
            if todayEvents.isEmpty {
                emptyStateView
            } else {
                eventsListView
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
        .sheet(isPresented: $showCreateEvent) {
            EventCreationView(preselectedDate: viewModel.selectedDate)
                .environmentObject(eventManager)
                .environmentObject(CalendarIntegrationManager())
        }
        .sheet(item: $showEventDetail) { event in
            EventDetailView(event: event)
                .environmentObject(eventManager)
                .environmentObject(CalendarIntegrationManager())
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 40))
                .foregroundColor(.red.opacity(0.3))
            
            Text("Chưa có sự kiện")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button(action: {
                showCreateEvent = true
            }) {
                Text("Tạo sự kiện mới")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.red)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.red.opacity(0.1))
                    )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
    
    private var eventsListView: some View {
        VStack(spacing: 12) {
            ForEach(todayEvents) { event in
                CompactEventCard(event: event) {
                    showEventDetail = event
                }
            }
        }
    }
}

// MARK: - Compact Event Card (for ContentView)
struct CompactEventCard: View {
    let event: LichAmEvent
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Time or All Day indicator
                if event.isAllDay {
                    VStack {
                        Image(systemName: "sun.max.fill")
                            .font(.title3)
                            .foregroundColor(event.color.colorValue)
                        
                        Text("Cả ngày")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                    .frame(width: 60)
                } else {
                    VStack(spacing: 2) {
                        Text(formatTime(event.startDate))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(event.color.colorValue)
                        
                        Text(formatTime(event.endDate))
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    .frame(width: 60)
                }
                
                // Color bar
                RoundedRectangle(cornerRadius: 3)
                    .fill(event.color.colorValue)
                    .frame(width: 4)
                
                // Event info
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(event.color.emoji)
                        
                        Text(event.title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Spacer()
                    }
                    
                    HStack(spacing: 8) {
                        if event.reminderMinutesBefore != nil {
                            HStack(spacing: 3) {
                                Image(systemName: "bell.fill")
                                    .font(.system(size: 9))
                                Text("Nhắc")
                                    .font(.system(size: 10))
                            }
                            .foregroundColor(.blue)
                        }
                        
                        if event.repeatType != .never {
                            HStack(spacing: 3) {
                                Image(systemName: "repeat")
                                    .font(.system(size: 9))
                                Text("Lặp lại")
                                    .font(.system(size: 10))
                            }
                            .foregroundColor(.purple)
                        }
                        
                        if event.isLunarDateBased {
                            HStack(spacing: 3) {
                                Image(systemName: "moon.fill")
                                    .font(.system(size: 9))
                                Text("Âm")
                                    .font(.system(size: 10))
                            }
                            .foregroundColor(.orange)
                        }
                    }
                    
                    if let notes = event.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [
                                event.color.colorValue.opacity(0.08),
                                event.color.colorValue.opacity(0.04)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(event.color.colorValue.opacity(0.2), lineWidth: 1)
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
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - Preview
struct DailyEventsSection_Previews: PreviewProvider {
    static var previews: some View {
        DailyEventsSection()
            .environmentObject(EventManager())
            .environmentObject(CalendarViewModel())
            .padding()
            .background(Color.gray.opacity(0.1))
    }
}
