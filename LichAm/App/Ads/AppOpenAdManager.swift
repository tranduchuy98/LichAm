//
//  AppOpenAdManager.swift
//  LichAm
//
//  App Open Ads Manager - Hiển thị quảng cáo khi mở app
//

import Foundation
import GoogleMobileAds
import SwiftUI

class AppOpenAdManager: NSObject, ObservableObject, FullScreenContentDelegate {
    
    // MARK: - Properties
    
    @Published var isAdLoaded = false
    @Published var isShowingAd = false
    
    private var appOpenAd: AppOpenAd?
    private var loadTime: Date?
    
    // Ad Unit ID - PRODUCTION
    private let adUnitID = "ca-app-pub-9801739600115439/7680328862"
    
    // TEST Ad Unit ID - Dùng khi test
    // private let adUnitID = "ca-app-pub-3940256099942544/5575463023"
    
    // Thời gian ad được coi là đã hết hạn (4 giờ)
    private let adExpirationInterval: TimeInterval = 4 * 60 * 60
    
    // Số lần mở app tối thiểu trước khi hiển thị ad (để không làm phiền user ngay lần đầu)
    private let minimumAppOpensBeforeAd = 2
    private var appOpenCount: Int {
        get { UserDefaults.standard.integer(forKey: "appOpenCount") }
        set { UserDefaults.standard.set(newValue, forKey: "appOpenCount") }
    }
    
    // Thời gian chờ tối thiểu giữa các lần hiển thị ad (30 phút)
    private let minimumTimeBetweenAds: TimeInterval = 30 * 60
    private var lastAdShownTime: Date? {
        get { UserDefaults.standard.object(forKey: "lastAdShownTime") as? Date }
        set { UserDefaults.standard.set(newValue, forKey: "lastAdShownTime") }
    }
    
    // MARK: - Singleton
    
    static let shared = AppOpenAdManager()
    
    private override init() {
        super.init()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Public Methods
    
    /// Load ad - Gọi khi app khởi động
    func loadAd() {
        // Kiểm tra xem ad đã được load và còn hợp lệ không
        if isAdAvailable() {
            print("📱 App Open Ad: Already loaded and valid")
            return
        }
        
        print("📱 App Open Ad: Loading...")
        
        let request = Request()
        AppOpenAd.load(
            with: adUnitID,
            request: request
        ) { [weak self] ad, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ App Open Ad: Failed to load - \(error.localizedDescription)")
                self.isAdLoaded = false
                return
            }
            
            print("✅ App Open Ad: Loaded successfully")
            self.appOpenAd = ad
            self.appOpenAd?.fullScreenContentDelegate = self
            self.loadTime = Date()
            self.isAdLoaded = true
        }
    }
    
    /// Hiển thị ad nếu có
    func showAdIfAvailable() {
        // Tăng số lần mở app
        appOpenCount += 1
        
        // Kiểm tra điều kiện hiển thị
        guard shouldShowAd() else {
            print("📱 App Open Ad: Conditions not met for showing")
            return
        }
        
        guard let ad = appOpenAd, isAdAvailable() else {
            print("📱 App Open Ad: Not available")
            loadAd() // Load ad mới cho lần sau
            return
        }
        
        guard let rootViewController = getRootViewController() else {
            print("❌ App Open Ad: No root view controller")
            return
        }
        
        print("📱 App Open Ad: Showing...")
        isShowingAd = true
        ad.present(from: rootViewController)
    }
    
    // MARK: - Private Methods
    
    /// Kiểm tra xem ad có sẵn sàng hiển thị không
    private func isAdAvailable() -> Bool {
        guard let loadTime = loadTime else {
            return false
        }
        
        // Kiểm tra ad có hết hạn không (4 giờ)
        let now = Date()
        let timeInterval = now.timeIntervalSince(loadTime)
        return timeInterval < adExpirationInterval && appOpenAd != nil
    }
    
    /// Kiểm tra các điều kiện để hiển thị ad
    private func shouldShowAd() -> Bool {
        // 1. Kiểm tra số lần mở app
        guard appOpenCount >= minimumAppOpensBeforeAd else {
            print("📱 App Open Ad: App opened only \(appOpenCount) times, need \(minimumAppOpensBeforeAd)")
            return false
        }
        
        // 2. Kiểm tra thời gian từ lần hiển thị ad cuối
        if let lastShownTime = lastAdShownTime {
            let timeSinceLastAd = Date().timeIntervalSince(lastShownTime)
            if timeSinceLastAd < minimumTimeBetweenAds {
                let remainingMinutes = Int((minimumTimeBetweenAds - timeSinceLastAd) / 60)
                print("📱 App Open Ad: Too soon, wait \(remainingMinutes) more minutes")
                return false
            }
        }
        
        // 3. Kiểm tra xem đang hiển thị ad khác không
        if isShowingAd {
            print("📱 App Open Ad: Already showing another ad")
            return false
        }
        
        return true
    }
    
    private func getRootViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return nil
        }
        return rootViewController
    }
    
    @objc private func appDidBecomeActive() {
        // Tự động hiển thị ad khi app trở về foreground
        showAdIfAvailable()
    }
    
    // MARK: - GADFullScreenContentDelegate
    
    func adDidRecordImpression(_ ad: FullScreenPresentingAd) {
        print("📱 App Open Ad: Did record impression")
    }
    
    func adDidRecordClick(_ ad: FullScreenPresentingAd) {
        print("📱 App Open Ad: Did record click")
    }
    
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("❌ App Open Ad: Failed to present - \(error.localizedDescription)")
        isShowingAd = false
        isAdLoaded = false
        appOpenAd = nil
        loadAd() // Load ad mới
    }
    
    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("📱 App Open Ad: Will present")
        isShowingAd = true
    }
    
    func adWillDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("📱 App Open Ad: Will dismiss")
    }
    
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("📱 App Open Ad: Did dismiss")
        isShowingAd = false
        isAdLoaded = false
        appOpenAd = nil
        lastAdShownTime = Date() // Lưu thời gian hiển thị ad
        
        // Load ad mới cho lần sau
        loadAd()
    }
}
