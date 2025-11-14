//
//  TraditionalCalendarView.swift
//  LichAm
//
//  Created by Huy Tran on 14/11/25.
//

import Foundation
import SwiftUI

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
                        .foregroundColor((lunarDate.day == 1 || lunarDate.day == 15 ) ? .red : getForegroundColor())
                    
                    Text("\(lunarDate.day)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor((lunarDate.day == 1 || lunarDate.day == 15 ) ? .red.opacity(0.7) : getForegroundColor().opacity(0.7))
                    
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
                            .fill((lunarDate.day == 1 || lunarDate.day == 15 ) ? .red.opacity(0.15) : getBackgroundColor())
                        
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
