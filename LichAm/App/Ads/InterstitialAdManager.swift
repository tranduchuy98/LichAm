//
//  InterstitialAdManager.swift
//  LichAm
//
//  Interstitial Ads Manager - Quảng cáo toàn màn hình giữa các màn hình
//

import Foundation
import GoogleMobileAds
import SwiftUI

class InterstitialAdManager: NSObject, ObservableObject, FullScreenContentDelegate {
    
    // MARK: - Properties
    
    @Published var isAdLoaded = false
    @Published var isShowingAd = false
    
    private var interstitialAd: InterstitialAd?
    
    // Ad Unit ID - PRODUCTION
    private let adUnitID = "ca-app-pub-9801739600115439/8510302600"
    
    // TEST Ad Unit ID - Dùng khi test
    // private let adUnitID = "ca-app-pub-3940256099942544/4411468910"
    
    // Số lần action tối thiểu trước khi hiển thị ad
    private let actionsBeforeAd = 3
    private var actionCount: Int = 0
    
    // Thời gian chờ tối thiểu giữa các lần hiển thị (5 phút)
    private let minimumTimeBetweenAds: TimeInterval = 5 * 60
    private var lastAdShownTime: Date?
    
    // MARK: - Singleton
    
    static let shared = InterstitialAdManager()
    
    private override init() {
        super.init()
        loadAd()
    }
    
    // MARK: - Public Methods
    
    /// Load ad
    func loadAd() {
        if isAdLoaded {
            print("🎬 Interstitial Ad: Already loaded")
            return
        }
        
        print("🎬 Interstitial Ad: Loading...")
        
        let request = Request()
        InterstitialAd.load(
            with: adUnitID,
            request: request
        ) { [weak self] ad, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ Interstitial Ad: Failed to load - \(error.localizedDescription)")
                self.isAdLoaded = false
                return
            }
            
            print("✅ Interstitial Ad: Loaded successfully")
            self.interstitialAd = ad
            self.interstitialAd?.fullScreenContentDelegate = self
            self.isAdLoaded = true
        }
    }
    
    /// Tăng số lần action và có thể hiển thị ad
    /// - Parameter force: Bắt buộc hiển thị ad ngay lập tức (bỏ qua kiểm tra action count)
    func incrementActionAndShowAd(force: Bool = false) {
        actionCount += 1
        
        print("🎬 Interstitial Ad: Action count = \(actionCount)/\(actionsBeforeAd)")
        
        if force || actionCount >= actionsBeforeAd {
            showAdIfAvailable()
            actionCount = 0 // Reset counter
        }
    }
    
    /// Hiển thị ad nếu có
    func showAdIfAvailable() {
        // Kiểm tra điều kiện thời gian
        if let lastShownTime = lastAdShownTime {
            let timeSinceLastAd = Date().timeIntervalSince(lastShownTime)
            if timeSinceLastAd < minimumTimeBetweenAds {
                let remainingMinutes = Int((minimumTimeBetweenAds - timeSinceLastAd) / 60)
                print("🎬 Interstitial Ad: Too soon, wait \(remainingMinutes) more minutes")
                return
            }
        }
        
        guard let ad = interstitialAd, isAdLoaded else {
            print("🎬 Interstitial Ad: Not available")
            loadAd() // Load ad mới
            return
        }
        
        guard !isShowingAd else {
            print("🎬 Interstitial Ad: Already showing")
            return
        }
        
        guard let rootViewController = getRootViewController() else {
            print("❌ Interstitial Ad: No root view controller")
            return
        }
        
        print("🎬 Interstitial Ad: Showing...")
        ad.present(from: rootViewController)
    }
    
    /// Reset action counter (gọi khi muốn reset đếm)
    func resetActionCount() {
        actionCount = 0
        print("🎬 Interstitial Ad: Action count reset")
    }
    
    // MARK: - Private Methods
    
    private func getRootViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return nil
        }
        return rootViewController
    }
    
    // MARK: - GADFullScreenContentDelegate
    
    func adDidRecordImpression(_ ad: FullScreenPresentingAd) {
        print("🎬 Interstitial Ad: Did record impression")
    }
    
    func adDidRecordClick(_ ad: FullScreenPresentingAd) {
        print("🎬 Interstitial Ad: Did record click")
    }
    
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("❌ Interstitial Ad: Failed to present - \(error.localizedDescription)")
        isShowingAd = false
        isAdLoaded = false
        interstitialAd = nil
        loadAd() // Load ad mới
    }
    
    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("🎬 Interstitial Ad: Will present")
        isShowingAd = true
    }
    
    func adWillDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("🎬 Interstitial Ad: Will dismiss")
    }
    
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("🎬 Interstitial Ad: Did dismiss")
        isShowingAd = false
        isAdLoaded = false
        interstitialAd = nil
        lastAdShownTime = Date()
        
        // Load ad mới cho lần sau
        loadAd()
    }
}

// MARK: - SwiftUI Helper

/// Extension để dễ dàng gọi ad từ SwiftUI
extension View {
    /// Track action và có thể hiển thị interstitial ad
    func trackAdAction() -> some View {
        self.onAppear {
            InterstitialAdManager.shared.incrementActionAndShowAd()
        }
    }
    
    /// Hiển thị interstitial ad ngay lập tức
    func showInterstitialAd() {
        InterstitialAdManager.shared.showAdIfAvailable()
    }
}
