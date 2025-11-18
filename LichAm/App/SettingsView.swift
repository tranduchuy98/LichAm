import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var viewModel: CalendarViewModel
    @EnvironmentObject var notificationManager: NotificationManager
    @EnvironmentObject var calendarIntegration: CalendarIntegrationManager
    @Environment(\.dismiss) var dismiss
    
    @State private var showNotificationAlert = false
    @State private var showCalendarAlert = false
    @State private var showAbout = false
    
    var body: some View {
        NavigationView {
            Form {
                // Calendar Integration Section
                Section {
                    HStack {
                        Image(systemName: "calendar.badge.checkmark")
                            .foregroundColor(.blue)
                            .frame(width: 28)
                        
                        Text("Trạng thái quyền")
                        
                        Spacer()
                        
                        if calendarIntegration.hasCalendarAccess {
                            Label("Đã cấp", systemImage: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.subheadline)
                        } else {
                            Label("Chưa cấp", systemImage: "xmark.circle.fill")
                                .foregroundColor(.red)
                                .font(.subheadline)
                        }
                    }
                    
                    if !calendarIntegration.hasCalendarAccess {
                        Button(action: requestCalendarAccess) {
                            HStack {
                                Image(systemName: "arrow.right.circle.fill")
                                    .foregroundColor(.blue)
                                    .frame(width: 28)
                                
                                Text("Cấp quyền truy cập Lịch")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                } header: {
                    Label("Tích hợp Lịch", systemImage: "calendar")
                } footer: {
                    Text("Cho phép ứng dụng thêm các ngày lễ và sự kiện vào Lịch của bạn")
                }
                
                // Notifications Section
                Section {
                    Toggle(isOn: $notificationManager.notificationsEnabled) {
                        HStack {
                            Image(systemName: "bell.fill")
                                .foregroundColor(.orange)
                                .frame(width: 28)
                            
                            Text("Bật thông báo")
                        }
                    }
                    .onChange(of: notificationManager.notificationsEnabled) { newValue in
                        handleNotificationToggle(newValue)
                    }
                    
                    if notificationManager.notificationsEnabled {
                        Button(action: {
                            notificationManager.scheduleHolidayNotifications()
                        }) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                    .foregroundColor(.blue)
                                    .frame(width: 28)
                                
                                Text("Cập nhật thông báo")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                } header: {
                    Label("Thông báo", systemImage: "bell.badge.fill")
                } footer: {
                    Text("Nhận thông báo về các ngày lễ, tết và ngày đặc biệt trong năm")
                }
                
                // App Information Section
                Section {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                            .frame(width: 28)
                        
                        Text("Phiên bản")
                        
                        Spacer()
                        
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Button(action: {
                        showAbout = true
                    }) {
                        HStack {
                            Image(systemName: "doc.text.fill")
                                .foregroundColor(.blue)
                                .frame(width: 28)
                            
                            Text("Giới thiệu")
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Link(destination: URL(string: "https://github.com")!) {
                        HStack {
                            Image(systemName: "link.circle.fill")
                                .foregroundColor(.blue)
                                .frame(width: 28)
                            
                            Text("Mã nguồn")
                            
                            Spacer()
                            
                            Image(systemName: "arrow.up.forward.square")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                } header: {
                    Label("Thông tin", systemImage: "info.circle")
                }
                
                // Features Guide Section
                Section {
                    FeatureGuideRow(
                        icon: "calendar",
                        iconColor: .blue,
                        title: "Xem lịch Âm",
                        description: "Chạm vào ngày bất kỳ để xem thông tin chi tiết"
                    )
                    
                    FeatureGuideRow(
                        icon: "clock.badge.checkmark",
                        iconColor: .green,
                        title: "Giờ Hoàng Đạo",
                        description: "Xem các giờ tốt trong ngày để làm việc quan trọng"
                    )
                    
                    FeatureGuideRow(
                        icon: "calendar.badge.plus",
                        iconColor: .purple,
                        title: "Xuất sang Lịch",
                        description: "Thêm ngày lễ vào ứng dụng Lịch của bạn"
                    )
                    
                    FeatureGuideRow(
                        icon: "bell.badge",
                        iconColor: .orange,
                        title: "Thông báo",
                        description: "Nhận nhắc nhở về các ngày lễ, tết sắp tới"
                    )
                } header: {
                    Label("Hướng dẫn sử dụng", systemImage: "lightbulb.fill")
                }
            }
            .navigationTitle("Cài đặt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Xong") {
                        dismiss()
                    }
                }
            }
            .alert("Cần cấp quyền", isPresented: $showNotificationAlert) {
                Button("Mở Cài đặt") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Đóng", role: .cancel) {}
            } message: {
                Text("Vui lòng vào Cài đặt > Lịch Âm > Thông báo để bật thông báo cho ứng dụng.")
            }
            .sheet(isPresented: $showAbout) {
                AboutView()
            }
        }
    }
    
    private func handleNotificationToggle(_ newValue: Bool) {
        if newValue {
            notificationManager.requestNotificationPermission { granted in
                if granted {
                    notificationManager.scheduleHolidayNotifications()
                } else {
                    showNotificationAlert = true
                }
            }
        } else {
            notificationManager.cancelAllNotifications()
        }
    }
    
    private func requestCalendarAccess() {
        calendarIntegration.requestCalendarAccess { granted, error in
            if !granted {
                showCalendarAlert = true
            }
        }
    }
}

struct FeatureGuideRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(iconColor)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 4)
    }
}

struct AboutView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // App icon
                    Image(systemName: "calendar.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.red)
                        .padding(.top, 40)
                    
                    Text("Lịch Âm Việt Nam")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Phiên bản 1.0.0")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Divider()
                        .padding(.horizontal, 40)
                    
                    // Description
                    VStack(spacing: 16) {
                        Text("Giới thiệu")
                            .font(.headline)
                        
                        Text("Ứng dụng Lịch Âm Việt Nam giúp bạn tra cứu ngày Âm lịch, các ngày lễ tết truyền thống, giờ Hoàng Đạo và thông tin phong thủy hàng ngày.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    
                    // Features
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Tính năng chính")
                            .font(.headline)
                            .padding(.horizontal, 32)
                        
                        VStack(spacing: 12) {
                            AboutFeatureRow(icon: "calendar", title: "Tra cứu Âm lịch chính xác")
                            AboutFeatureRow(icon: "gift", title: "Các ngày lễ và tết Việt Nam")
                            AboutFeatureRow(icon: "clock.badge.checkmark", title: "Giờ Hoàng Đạo hàng ngày")
                            AboutFeatureRow(icon: "star.circle", title: "Thông tin con giáp và Can Chi")
                            AboutFeatureRow(icon: "calendar.badge.plus", title: "Tích hợp với Lịch hệ thống")
                            AboutFeatureRow(icon: "bell.badge", title: "Thông báo ngày lễ")
                        }
                        .padding(.horizontal, 32)
                    }
                    
                    Spacer(minLength: 40)
                    
                    Text("© 2024 Lịch Âm Việt Nam")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 40)
                }
            }
            .navigationTitle("Giới thiệu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Đóng") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct AboutFeatureRow: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            Text(title)
                .font(.body)
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        }
        .padding(.vertical, 4)
    }
}

