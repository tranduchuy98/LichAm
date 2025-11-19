import SwiftUI
import StoreKit

struct SettingsView: View {
    @EnvironmentObject var viewModel: CalendarViewModel
    @EnvironmentObject var notificationManager: NotificationManager
    @EnvironmentObject var calendarIntegration: CalendarIntegrationManager
    @Environment(\.dismiss) var dismiss
    
    @State private var showNotificationAlert = false
    @State private var showCalendarAlert = false
    @State private var showAbout = false
    @State private var showTerms = false
    @State private var showPrivacy = false
    
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
                    
                    NavigationLink(destination: HTMLFileView()) {
                        HStack {
                            Image(systemName: "book.fill")
                                .foregroundColor(.blue)
                                .frame(width: 28)
                            
                            Text("Hướng dẫn Widget chi tiết")
                                .foregroundColor(.primary)
                        }
                    }
                    
                    Button(action: {
                        if let scene = UIApplication.shared.connectedScenes
                                 .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                                 SKStoreReviewController.requestReview(in: scene)
                             } else {
                                 SKStoreReviewController.requestReview()
                             }
                    }) {
                                          HStack {
                                              Image(systemName: "star.fill")
                                                  .foregroundColor(.blue)
                                                  .frame(width: 28)
                                              
                                              Text("Đánh giá ứng dụng")
                                                  .foregroundColor(.primary)
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
                        title: "Xem lịch Âm - Dương",
                        description: "• Chạm vào ngày để xem thông tin chi tiết\n• Xem ngày Âm lịch, Can Chi, con giáp\n• Kiểm tra các ngày lễ Tết Việt Nam\n• Xem ngày đặc biệt (Sóc, Vọng)"
                    )
                    
                    FeatureGuideRow(
                        icon: "calendar.badge.clock",
                        iconColor: .orange,
                        title: "Quản lý sự kiện",
                        description: "• Nhấn giữ vào ngày để tạo sự kiện mới\n• Tạo sự kiện theo Âm lịch hoặc Dương lịch\n• Đặt lời nhắc trước 5 phút đến 1 tuần\n• Lặp lại theo ngày/tuần/tháng/năm\n• Tự động đồng bộ với Lịch hệ thống"
                    )
                    
                    FeatureGuideRow(
                        icon: "clock.badge.checkmark",
                        iconColor: .green,
                        title: "Giờ Hoàng Đạo",
                        description: "• Xem 12 giờ trong ngày theo địa chi\n• Phân biệt giờ Hoàng Đạo (tốt) và Hắc Đạo\n• Chọn giờ tốt để làm việc quan trọng\n• Dựa theo hệ thống phong thủy truyền thống"
                    )
                    
                    FeatureGuideRow(
                        icon: "rectangle.fill.on.rectangle.fill",
                        iconColor: .cyan,
                        title: "Widget màn hình",
                        description: "• Hiển thị lịch Âm - Dương ngay màn hình chính\n• Thêm widget vào Lock Screen (iOS 16+)\n• 3 kích thước: Nhỏ, Vừa, Lớn\n• Tự động cập nhật theo ngày\n• Nhấn vào để xem hướng dẫn chi tiết"
                    )
                    
                    FeatureGuideRow(
                        icon: "bell.badge",
                        iconColor: .red,
                        title: "Thông báo thông minh",
                        description: "• Nhắc nhở tự động các ngày lễ, tết\n• Thông báo Sóc (mồng 1) và Vọng (rằm)\n• Nhắc sự kiện theo Âm lịch chính xác\n• Đồng bộ với Calendar và Reminders"
                    )
                    
                    FeatureGuideRow(
                        icon: "calendar.badge.plus",
                        iconColor: .purple,
                        title: "Xuất sang Lịch",
                        description: "• Thêm ngày lễ vào Calendar của Apple\n• Tạo sự kiện lặp lại tự động\n• Đồng bộ trên tất cả thiết bị iCloud\n• Quản lý từ app Lịch gốc"
                    )
                }
                header: {
                    Label("Hướng dẫn sử dụng", systemImage: "lightbulb.fill")
                }
                
                // Legal Section
                Section {
                    Button(action: { showTerms = true }) {
                        HStack {
                            Image(systemName: "doc.text.fill")
                                .foregroundColor(.green)
                                .frame(width: 28)
                            
                            Text("Điều khoản sử dụng")
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button(action: { showPrivacy = true }) {
                        HStack {
                            Image(systemName: "lock.shield.fill")
                                .foregroundColor(.green)
                                .frame(width: 28)
                            
                            Text("Chính sách bảo mật")
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Label("Pháp lý", systemImage: "doc.text")
                } footer: {
                    Text("Bằng việc sử dụng ứng dụng, bạn đồng ý với các điều khoản và chính sách của chúng tôi")
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
            .sheet(isPresented: $showTerms) {
                TermsOfServiceView()
            }
            .sheet(isPresented: $showPrivacy) {
                PrivacyPolicyView()
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

// MARK: - Terms of Service View
struct TermsOfServiceView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.red)
                        
                        Text("Điều khoản sử dụng")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Cập nhật lần cuối: Tháng 11, 2025")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    Divider()
                    
                    // Terms sections
                    TermsSection(
                        title: "1. Chấp nhận điều khoản",
                        content: "Bằng việc tải xuống, cài đặt hoặc sử dụng ứng dụng Lịch Âm Việt Nam, bạn đồng ý tuân thủ và chịu ràng buộc bởi các điều khoản và điều kiện sau đây. Nếu bạn không đồng ý với bất kỳ điều khoản nào, vui lòng không sử dụng ứng dụng."
                    )
                    
                    TermsSection(
                        title: "2. Sử dụng ứng dụng",
                        content: "Ứng dụng Lịch Âm Việt Nam được cung cấp miễn phí cho mục đích cá nhân, phi thương mại. Bạn có quyền:\n\n• Xem thông tin lịch Âm - Dương\n• Tạo và quản lý sự kiện cá nhân\n• Đồng bộ với Calendar của Apple\n• Sử dụng widget và nhận thông báo\n\nBạn không được:\n• Sao chép, sửa đổi hoặc phân phối ứng dụng\n• Sử dụng ứng dụng cho mục đích thương mại\n• Cố gắng truy cập trái phép vào hệ thống"
                    )
                    
                    TermsSection(
                        title: "3. Quyền truy cập",
                        content: "Ứng dụng yêu cầu các quyền sau để hoạt động:\n\n• Calendar: Để tạo và quản lý sự kiện\n• Notifications: Để gửi nhắc nhở về ngày lễ và sự kiện\n• iCloud: Để đồng bộ dữ liệu giữa các thiết bị\n\nBạn có thể quản lý các quyền này trong Cài đặt của thiết bị."
                    )
                    
                    TermsSection(
                        title: "4. Độ chính xác thông tin",
                        content: "Chúng tôi nỗ lực cung cấp thông tin lịch Âm chính xác nhất dựa trên các phương pháp tính toán thiên văn học truyền thống. Tuy nhiên, chúng tôi không đảm bảo tính chính xác tuyệt đối và không chịu trách nhiệm về bất kỳ quyết định nào được đưa ra dựa trên thông tin từ ứng dụng."
                    )
                    
                    TermsSection(
                        title: "5. Thay đổi và cập nhật",
                        content: "Chúng tôi có quyền cập nhật, sửa đổi hoặc thay thế bất kỳ phần nào của các điều khoản này bất cứ lúc nào. Các thay đổi sẽ có hiệu lực ngay khi được đăng trong ứng dụng. Việc tiếp tục sử dụng ứng dụng sau khi có thay đổi đồng nghĩa với việc bạn chấp nhận các điều khoản mới."
                    )
                    
                    TermsSection(
                        title: "6. Giới hạn trách nhiệm",
                        content: "Ứng dụng được cung cấp 'nguyên trạng' không có bất kỳ bảo đảm nào. Chúng tôi không chịu trách nhiệm về:\n\n• Mất mát hoặc thiệt hại dữ liệu\n• Lỗi hoặc gián đoạn dịch vụ\n• Thiệt hại trực tiếp hoặc gián tiếp\n• Xung đột với ứng dụng hoặc dịch vụ khác"
                    )
                    
                    TermsSection(
                        title: "7. Liên hệ",
                        content: "Nếu bạn có bất kỳ câu hỏi nào về các Điều khoản Sử dụng này, vui lòng liên hệ với chúng tôi qua:\n\nEmail: huyduc.dev@gmail.com\n\nChúng tôi sẽ phản hồi trong vòng 2-3 ngày làm việc."
                    )
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 24)
            }
            .navigationTitle("Điều khoản")
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

// MARK: - Privacy Policy View
struct PrivacyPolicyView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        
                        Text("Chính sách bảo mật")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Cập nhật lần cuối: Tháng 11, 2025")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    Divider()
                    
                    // Privacy sections
                    PrivacySection(
                        title: "1. Thu thập thông tin",
                        content: "Ứng dụng Lịch Âm Việt Nam không thu thập, lưu trữ hoặc chia sẻ bất kỳ thông tin cá nhân nào của bạn. Tất cả dữ liệu được lưu trữ cục bộ trên thiết bị của bạn hoặc trong iCloud (nếu bạn bật đồng bộ).\n\nChúng tôi KHÔNG thu thập:\n• Tên, địa chỉ email, số điện thoại\n• Vị trí địa lý\n• Danh bạ hoặc ảnh\n• Thông tin thiết bị\n• Lịch sử sử dụng"
                    )
                    
                    PrivacySection(
                        title: "2. Dữ liệu được lưu trữ",
                        content: "Ứng dụng chỉ lưu trữ:\n\n• Sự kiện và nhắc nhở bạn tạo\n• Tùy chọn cài đặt của bạn\n• Cache lịch Âm để tăng hiệu suất\n\nTất cả dữ liệu này được lưu trữ:\n• Cục bộ trên thiết bị của bạn\n• Trong iCloud của bạn (nếu bật đồng bộ)\n• Không bao giờ được gửi đến máy chủ của chúng tôi"
                    )
                    
                    PrivacySection(
                        title: "3. Quyền truy cập Calendar",
                        content: "Khi bạn cấp quyền truy cập Calendar:\n\n• Ứng dụng chỉ tạo sự kiện bạn yêu cầu\n• Không đọc các sự kiện khác trong lịch\n• Không sửa đổi sự kiện hiện có\n• Không chia sẻ dữ liệu lịch với bên thứ ba\n\nBạn có thể thu hồi quyền này bất cứ lúc nào trong Cài đặt > Lịch Âm > Quyền truy cập"
                    )
                    
                    PrivacySection(
                        title: "4. Thông báo và nhắc nhở",
                        content: "Khi bạn bật thông báo:\n\n• Thông báo được xử lý cục bộ trên thiết bị\n• Không gửi thông tin qua internet\n• Chỉ thông báo về sự kiện bạn tạo\n• Tuân thủ chính sách bảo mật của Apple\n\nBạn có thể tắt thông báo bất cứ lúc nào trong Cài đặt."
                    )
                    
                    PrivacySection(
                        title: "5. iCloud đồng bộ",
                        content: "Nếu bạn bật đồng bộ iCloud:\n\n• Dữ liệu được mã hóa bởi Apple\n• Chỉ bạn có thể truy cập\n• Đồng bộ giữa các thiết bị của bạn\n• Chúng tôi không có quyền truy cập vào iCloud của bạn\n\nĐây là tính năng tùy chọn và bạn có thể tắt bất cứ lúc nào."
                    )
                    
                    PrivacySection(
                        title: "6. Bảo mật",
                        content: "Chúng tôi cam kết bảo vệ dữ liệu của bạn:\n\n• Không kết nối internet trừ khi cần thiết\n• Sử dụng các API bảo mật của Apple\n• Không có quảng cáo hoặc theo dõi\n• Không sử dụng analytics bên thứ ba\n• Mã nguồn tuân thủ tiêu chuẩn bảo mật"
                    )
                    
                    PrivacySection(
                        title: "7. Quyền của bạn",
                        content: "Bạn có toàn quyền kiểm soát dữ liệu của mình:\n\n• Xóa tất cả dữ liệu bằng cách gỡ ứng dụng\n• Xuất dữ liệu sang Calendar\n• Tắt đồng bộ iCloud bất cứ lúc nào\n• Thu hồi quyền truy cập Calendar\n• Yêu cầu giải thích về chính sách bảo mật"
                    )
                    
                    PrivacySection(
                        title: "8. Trẻ em",
                        content: "Ứng dụng không nhắm đến hoặc thu thập thông tin từ trẻ em dưới 13 tuổi. Nếu bạn phát hiện trẻ em đã cung cấp thông tin cá nhân, vui lòng liên hệ với chúng tôi để xóa thông tin đó."
                    )
                    
                    PrivacySection(
                        title: "9. Thay đổi chính sách",
                        content: "Chúng tôi có thể cập nhật Chính sách Bảo mật này theo thời gian. Mọi thay đổi sẽ được thông báo trong ứng dụng và có hiệu lực ngay lập tức. Chúng tôi khuyến khích bạn xem lại chính sách này định kỳ."
                    )
                    
                    PrivacySection(
                        title: "10. Liên hệ",
                        content: "Nếu bạn có câu hỏi về Chính sách Bảo mật này, vui lòng liên hệ:\n\nEmail: huyduc.dev@gmail.com\n\nChúng tôi sẽ phản hồi trong vòng 2-3 ngày làm việc và cam kết giải quyết mọi thắc mắc của bạn."
                    )
                    
                    // Additional info box
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "checkmark.shield.fill")
                                .foregroundColor(.green)
                            Text("Cam kết của chúng tôi")
                                .font(.headline)
                        }
                        
                        Text("Lịch Âm Việt Nam được xây dựng với sự tôn trọng tối đa đối với quyền riêng tư của bạn. Chúng tôi không thu thập, bán hoặc chia sẻ dữ liệu cá nhân của bạn với bất kỳ ai.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.green.opacity(0.1))
                    )
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 24)
            }
            .navigationTitle("Bảo mật")
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

// MARK: - Helper Views
struct TermsSection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.red)
            
            Text(content)
                .font(.body)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct PrivacySection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.green)
            
            Text(content)
                .font(.body)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
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
