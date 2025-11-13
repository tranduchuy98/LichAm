//
//  AuspiciousHoursView.swift
//  LichAm
//
//  FIXED VERSION - Xcode 16.4 Compatible
//

import SwiftUI

// MARK: - Auspicious Hours View
struct AuspiciousHoursView: View {
    
   let selectedDate: Date
    
    private var dayChiIndex: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        let jdn = julianDayNumber(
            day: components.day ?? 1,
            month: components.month ?? 1,
            year: components.year ?? 2025
        )
        return positiveMod(jdn + 1, 12)
    }
    
    private var dayChi: String {
        let chiOrder = ["Tý","Sửu","Dần","Mão","Thìn","Tỵ","Ngọ","Mùi","Thân","Dậu","Tuất","Hợi"]
        return chiOrder[dayChiIndex]
    }
    
    private var auspiciousHours: [String] {
        AuspiciousHoursManager.gioHoangDaoMapping[dayChi] ?? []
    }
    
    private var allHourChis: [String] {
        ["Tý","Sửu","Dần","Mão","Thìn","Tỵ","Ngọ","Mùi","Thân","Dậu","Tuất","Hợi"]
    }
    
    var body: some View {
        VStack(spacing: 20) {
            legendView
            hoursListView
            Spacer(minLength: 40)
        }
        .padding(.horizontal)
    }
    
    // MARK: - View Components
    
    
    private var legendView: some View {
        HStack(spacing: 16) {
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.green.opacity(0.8))
                    .frame(width: 12, height: 12)
                Text("Giờ Hoàng Đạo")
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.gray.opacity(0.5))
                    .frame(width: 12, height: 12)
                Text("Giờ Hắc Đạo")
                    .font(.caption)
                    .foregroundColor(.primary)
            }
        }
        .padding(.horizontal)
    }
    
    private var hoursListView: some View {
        VStack(spacing: 12) {
            ForEach(allHourChis, id: \.self) { chi in
                let isAuspicious = auspiciousHours.contains(chi)
                AuspiciousHourCard(
                    chi: chi,
                    timeRange: AuspiciousHoursManager.chiHourRanges[chi] ?? "",
                    isAuspicious: isAuspicious
                )
            }
        }
        .padding(.horizontal)
    }

    
    // MARK: - Helper Functions
    
    private func julianDayNumber(day: Int, month: Int, year: Int) -> Int {
        let a = (14 - month) / 12
        let y = year + 4800 - a
        let m = month + 12 * a - 3
        var jd = day + (153 * m + 2) / 5 + 365 * y + y / 4 - y / 100 + y / 400 - 32045
        
        if jd < 2299161 {
            jd = day + (153 * m + 2) / 5 + 365 * y + y / 4 - 32083
        }
        
        return jd
    }
    
    private func positiveMod(_ a: Int, _ m: Int) -> Int {
        let r = a % m
        return r >= 0 ? r : r + m
    }
}

// MARK: - Auspicious Hour Card
struct AuspiciousHourCard: View {
    let chi: String
    let timeRange: String
    let isAuspicious: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Chi symbol
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: isAuspicious ?
                                [Color.green.opacity(0.8), Color.green.opacity(0.6)] :
                                [Color.gray.opacity(0.5), Color.gray.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                    .shadow(color: .primary.opacity(0.3), radius: 4, x: 0, y: 2)
                
                Text(chi)
                    .font(.system(size: 20, weight: .bold, design: .serif))
                    .foregroundColor(.primary)
            }
            
            // Time info
            VStack(alignment: .leading, spacing: 4) {
                Text(timeRange)
                    .font(.system(size: 18, weight: .semibold, design: .monospaced))
                    .foregroundColor(.primary)
                
                Text(isAuspicious ? "✨ Giờ Hoàng Đạo" : "⚫️ Giờ Hắc Đạo")
                    .font(.caption)
                    .foregroundColor(isAuspicious ? .yellow : .primary.opacity(0.6))
                    .fontWeight(isAuspicious ? .semibold : .regular)
            }
            
            Spacer()
            
            // Status indicator
            if isAuspicious {
                VStack(spacing: 2) {
                    Image(systemName: "star.fill")
                        .font(.title3)
                        .foregroundColor(.yellow)
                    Text("Tốt")
                        .font(.caption2)
                        .foregroundColor(.yellow)
                        .fontWeight(.semibold)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    isAuspicious ?
                        Color.green.opacity(0.15) :
                        Color.primary.opacity(0.08)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            isAuspicious ?
                                Color.green.opacity(0.4) :
                                Color.primary.opacity(0.2),
                            lineWidth: isAuspicious ? 2 : 1
                        )
                )
        )
        .shadow(
            color: isAuspicious ? Color.green.opacity(0.3) : Color.primary.opacity(0.2),
            radius: isAuspicious ? 8 : 4,
            x: 0,
            y: isAuspicious ? 4 : 2
        )
    }
}

// MARK: - Auspicious Hours Manager
struct AuspiciousHoursManager {
    static let gioHoangDaoMapping: [String: [String]] = [
        "Tý":  ["Dần","Thân","Tý","Ngọ","Sửu","Mùi"],
        "Sửu": ["Dần","Mão","Tỵ","Thân","Tuất","Hợi"],
        "Dần": ["Tý","Sửu","Thìn","Tỵ","Mùi","Tuất"],
        "Mão": ["Tý","Dần","Mão","Ngọ","Mùi","Dậu"],
        "Thìn":["Dần","Thìn","Tỵ","Thân","Dậu","Hợi"],
        "Tỵ":  ["Sửu","Thìn","Ngọ","Mùi","Tuất","Hợi"],
        "Ngọ": ["Tý","Dần","Mão","Ngọ","Mùi","Dậu"],
        "Mùi": ["Dần","Mão","Tỵ","Thân","Tuất","Hợi"],
        "Thân":["Tý","Sửu","Thìn","Tỵ","Mùi","Tuất"],
        "Dậu": ["Tý","Dần","Mão","Ngọ","Mùi","Dậu"],
        "Tuất":["Dần","Thìn","Tỵ","Thân","Dậu","Hợi"],
        "Hợi": ["Sửu","Thìn","Ngọ","Mùi","Tuất","Hợi"]
    ]
    
    static let chiHourRanges: [String: String] = [
        "Tý":"23:00 - 01:00", "Sửu":"01:00 - 03:00", "Dần":"03:00 - 05:00", "Mão":"05:00 - 07:00",
        "Thìn":"07:00 - 09:00", "Tỵ":"09:00 - 11:00", "Ngọ":"11:00 - 13:00", "Mùi":"13:00 - 15:00",
        "Thân":"15:00 - 17:00", "Dậu":"17:00 - 19:00", "Tuất":"19:00 - 21:00", "Hợi":"21:00 - 23:00"
    ]
}
