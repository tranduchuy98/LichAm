//
//  AuspiciousHoursView.swift
//  LichAm
//
//  TRADITIONAL STYLE VERSION - Xcode 16.4 Compatible
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
            headerView
            legendView
            hoursListView
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
    
    // MARK: - View Components
    
    private var headerView: some View {
        HStack {
            Text("⏰")
                .font(.title2)
            
            Text("Giờ Hoàng Đạo")
                .font(.system(size: 18, weight: .bold, design: .serif))
                .foregroundColor(.red)
            
            Spacer()
            
            Text("🕐")
                .font(.title2)
        }
    }
    
    private var legendView: some View {
        HStack(spacing: 20) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.red.opacity(0.8), Color.red.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 16, height: 16)
                    
                    Image(systemName: "star.fill")
                        .font(.system(size: 8))
                        .foregroundColor(.yellow)
                }
                
                Text("Giờ Hoàng Đạo")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.red)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.red.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.red.opacity(0.3), lineWidth: 1)
                    )
            )
            
            HStack(spacing: 8) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.gray.opacity(0.6), Color.gray.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 16, height: 16)
                
                Text("Giờ Hắc Đạo")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }
    
    private var hoursListView: some View {
        VStack(spacing: 12) {
            ForEach(Array(allHourChis.enumerated()), id: \.element) { index, chi in
                let isAuspicious = auspiciousHours.contains(chi)
                TraditionalAuspiciousHourCard(
                    chi: chi,
                    timeRange: AuspiciousHoursManager.chiHourRanges[chi] ?? "",
                    isAuspicious: isAuspicious
                )
            }
        }
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

// MARK: - Traditional Auspicious Hour Card
struct TraditionalAuspiciousHourCard: View {
    let chi: String
    let timeRange: String
    let isAuspicious: Bool
    @State private var isPressed = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Chi symbol with traditional styling
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: isAuspicious ?
                                [Color.red.opacity(0.9), Color.red.opacity(0.7)] :
                                [Color.gray.opacity(0.6), Color.gray.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                
                // Gold border for auspicious hours
                if isAuspicious {
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.yellow.opacity(0.8), Color.orange.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 56, height: 56)
                }
                
                Text(chi)
                    .font(.system(size: 22, weight: .bold, design: .serif))
                    .foregroundColor(isAuspicious ? .white : .primary.opacity(0.7))
            }
            .shadow(
                color: isAuspicious ? Color.red.opacity(0.4) : Color.black.opacity(0.2),
                radius: isAuspicious ? 6 : 3,
                x: 0,
                y: 2
            )
            
            // Time info with traditional styling
            VStack(alignment: .leading, spacing: 6) {
                Text(timeRange)
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(isAuspicious ? .red : .primary)
                
                HStack(spacing: 4) {
                    if isAuspicious {
                        Text("✨")
                            .font(.caption)
                        Text("Giờ Hoàng Đạo")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.red)
                    } else {
                        Text("⚫️")
                            .font(.caption)
                        Text("Giờ Hắc Đạo")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Status indicator
            if isAuspicious {
                VStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.yellow.opacity(0.3), Color.orange.opacity(0.2)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "star.fill")
                            .font(.title3)
                            .foregroundColor(.yellow)
                    }
                    
                    Text("Tốt")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.red)
                }
            } else {
                Image(systemName: "moon.fill")
                    .font(.title3)
                    .foregroundColor(.gray.opacity(0.5))
            }
        }
        .padding(16)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        isAuspicious ?
                            LinearGradient(
                                colors: [
                                    Color.red.opacity(0.08),
                                    Color.orange.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [
                                    Color.gray.opacity(0.05),
                                    Color.gray.opacity(0.03)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
                
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        isAuspicious ?
                            LinearGradient(
                                colors: [Color.red.opacity(0.4), Color.orange.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                        lineWidth: isAuspicious ? 2 : 1
                    )
            }
        )
        .shadow(
            color: isAuspicious ? Color.red.opacity(0.2) : Color.black.opacity(0.08),
            radius: isAuspicious ? 10 : 4,
            x: 0,
            y: isAuspicious ? 4 : 2
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
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
    
    // Traditional descriptions for each Chi hour
    static let chiDescriptions: [String: String] = [
        "Tý": "Đầu ngày mới, thời điểm yên tĩnh",
        "Sửu": "Lúc trâu cày, chăm chỉ làm việc",
        "Dần": "Lúc hổ gầm, khởi đầu mạnh mẽ",
        "Mão": "Lúc mèo rửa mặt, sự thanh khiết",
        "Thìn": "Lúc rồng bay, sức mạnh thần thánh",
        "Tỵ": "Lúc rắn ẩn, sự khôn ngoan",
        "Ngọ": "Giữa trưa, ánh sáng rực rỡ",
        "Mùi": "Lúc dê gặm cỏ, sự bình yên",
        "Thân": "Lúc khỉ leo trèo, nhanh nhẹn",
        "Dậu": "Lúc gà về chuồng, sum họp",
        "Tuất": "Lúc chó canh nhà, bảo vệ",
        "Hợi": "Cuối ngày, nghỉ ngơi thư giãn"
    ]
}
