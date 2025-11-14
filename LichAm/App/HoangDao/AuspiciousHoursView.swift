//
//  AuspiciousHoursView.swift
//  LichAm
//
//  OPTIMIZED FOR PERFORMANCE - Lightweight cells + option to hide inauspicious hours
//

import SwiftUI

struct AuspiciousHoursView: View {
    let selectedDate: Date
    let showInauspicious: Bool // nếu false => chỉ hiển thị giờ hoàng đạo

    // Cached computed values
    private let dayChiIndex: Int
    private let dayChi: String
    private let auspiciousHours: [String]
    private let allHourChis: [String] = ["Tý","Sửu","Dần","Mão","Thìn","Tỵ","Ngọ","Mùi","Thân","Dậu","Tuất","Hợi"]

    init(selectedDate: Date, showInauspicious: Bool = true) {
        self.selectedDate = selectedDate
        self.showInauspicious = showInauspicious

        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        let jdn = Self.julianDayNumber(
            day: components.day ?? 1,
            month: components.month ?? 1,
            year: components.year ?? 2025
        )

        self.dayChiIndex = Self.positiveMod(jdn + 1, 12)

        let chiOrder = ["Tý","Sửu","Dần","Mão","Thìn","Tỵ","Ngọ","Mùi","Thân","Dậu","Tuất","Hợi"]
        self.dayChi = chiOrder[dayChiIndex]

        self.auspiciousHours = AuspiciousHoursManager.gioHoangDaoMapping[dayChi] ?? []
    }

    var body: some View {
        VStack(spacing: 14) {
            headerView

            // Only show legend when inauspicious is shown
            if showInauspicious {
                legendView
            }

            // Light-weight list: LazyVStack inside parent ScrollView is enough
            LazyVStack(spacing: 10, pinnedViews: []) {
                ForEach(filteredHourList(), id: \.self) { chi in
                    AuspiciousHourRow(chi: chi,
                                     timeRange: AuspiciousHoursManager.chiHourRanges[chi] ?? "",
                                     isAuspicious: auspiciousHours.contains(chi))
                        .id(chi) // stable id to help diffing
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.98))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }

    private func filteredHourList() -> [String] {
        if showInauspicious {
            return allHourChis
        } else {
            // only show auspicious hours, in original order
            return allHourChis.filter { auspiciousHours.contains($0) }
        }
    }

    // MARK: - Header & Legend

    private var headerView: some View {
        HStack {
            Text("⏰")
                .font(.headline)
            VStack(alignment: .leading, spacing: 2) {
                Text("Giờ Hoàng Đạo")
                    .font(.system(size: 16, weight: .semibold))
                Text("Ngày: \(dayChi)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
    }

    private var legendView: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Circle().frame(width: 10, height: 10).foregroundColor(.red)
                Text("Hoàng Đạo").font(.caption).foregroundColor(.primary)
            }
            HStack(spacing: 8) {
                Circle().frame(width: 10, height: 10).foregroundColor(.gray)
                Text("Hắc Đạo").font(.caption).foregroundColor(.secondary)
            }
            Spacer()
        }
    }

    // MARK: - Helpers

    private static func julianDayNumber(day: Int, month: Int, year: Int) -> Int {
        let a = (14 - month) / 12
        let y = year + 4800 - a
        let m = month + 12 * a - 3
        var jd = day + (153 * m + 2) / 5 + 365 * y + y / 4 - y / 100 + y / 400 - 32045

        if jd < 2299161 {
            jd = day + (153 * m + 2) / 5 + 365 * y + y / 4 - 32083
        }

        return jd
    }

    private static func positiveMod(_ a: Int, _ m: Int) -> Int {
        let r = a % m
        return r >= 0 ? r : r + m
    }
}

// MARK: - Lightweight Row (no heavy gradients / minimal layering)
private struct AuspiciousHourRow: View {
    let chi: String
    let timeRange: String
    let isAuspicious: Bool

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .frame(width: 44, height: 44)
                    .foregroundColor(isAuspicious ? Color.red.opacity(0.9) : Color.gray.opacity(0.2))
                Text(chi)
                    .font(.system(size: 18, weight: .bold, design: .serif))
                    .foregroundColor(isAuspicious ? .white : .primary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(timeRange)
                    .font(.system(size: 15, weight: .semibold, design: .monospaced))
                    .foregroundColor(isAuspicious ? .red : .primary)
                Text(isAuspicious ? "Giờ Hoàng Đạo" : "Giờ Hắc Đạo")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if isAuspicious {
                Text("Tốt")
                    .font(.caption2)
                    .bold()
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(RoundedRectangle(cornerRadius: 10).foregroundColor(Color.red.opacity(0.12)))
            } else {
                // minimal icon for inauspicious
                Image(systemName: "moon.fill")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white))
        .contentShape(Rectangle())
    }
}

// MARK: - AuspiciousHoursManager (kept minimal)
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
