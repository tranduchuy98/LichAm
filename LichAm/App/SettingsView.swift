import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var viewModel: CalendarViewModel
    @EnvironmentObject var notificationManager: NotificationManager
    @Environment(\.dismiss) var dismiss
    @State private var showNotificationAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Hiển thị")) {
                    Toggle("Chế độ tối", isOn: Binding(
                        get: { viewModel.isDarkMode },
                        set: { _ in
                            viewModel.toggleDarkMode()
                            dismiss()
                        }
                    ))
                }
                
                Section(header: Text("Thông báo"),
                        footer: Text("Nhận thông báo về các ngày lễ, tết và ngày đặc biệt trong năm")) {
                    Toggle("Bật thông báo", isOn: $notificationManager.notificationsEnabled)
                        .onChange(of: notificationManager.notificationsEnabled) { newValue in
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
                    
                    if notificationManager.notificationsEnabled {
                        Button("Cập nhật thông báo") {
                            notificationManager.scheduleHolidayNotifications()
                        }
                    }
                }
                
                Section(header: Text("Thông tin")) {
                    HStack {
                        Text("Phiên bản")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Link(destination: URL(string: "https://github.com")!) {
                        HStack {
                            Text("Mã nguồn")
                            Spacer()
                            Image(systemName: "arrow.up.forward.square")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                Section(header: Text("Giới thiệu")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Lịch Âm Việt Nam")
                            .font(.headline)
                        
                        Text("Ứng dụng lịch Âm Việt Nam giúp bạn tra cứu ngày Âm lịch, các ngày lễ tết truyền thống, giờ Hoàng Đạo và thông tin phong thủy hàng ngày.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                
                Section(header: Text("Hướng dẫn sử dụng")) {
                    VStack(alignment: .leading, spacing: 12) {
                        FeatureRow(
                            icon: "calendar",
                            title: "Xem lịch Âm",
                            description: "Chạm vào ngày bất kỳ để xem thông tin chi tiết"
                        )
                        
                        Divider()
                        
                        FeatureRow(
                            icon: "clock.badge.checkmark",
                            title: "Giờ Hoàng Đạo",
                            description: "Xem các giờ tốt trong ngày để làm việc quan trọng"
                        )
                        
                        Divider()
                        
                        FeatureRow(
                            icon: "bell.badge",
                            title: "Thông báo",
                            description: "Nhận nhắc nhở về các ngày lễ, tết sắp tới"
                        )
                        
                        Divider()
                        
                        FeatureRow(
                            icon: "square.grid.2x2",
                            title: "Widget",
                            description: "Thêm widget vào màn hình chính để xem nhanh"
                        )
                    }
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
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 30)
            
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
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(CalendarViewModel())
            .environmentObject(NotificationManager())
    }
}
