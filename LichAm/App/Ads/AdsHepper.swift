//
//  AdHelper.swift
//  LichAm
//
//  Helper utilities for integrating ads in SwiftUI
//

import SwiftUI

// MARK: - View Modifiers

struct TrackNavigationModifier: ViewModifier {
    let shouldShowAd: Bool
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                if shouldShowAd {
                    InterstitialAdManager.shared.incrementActionAndShowAd()
                }
            }
    }
}

extension View {
    func trackNavigation(shouldShowAd: Bool = true) -> some View {
        modifier(TrackNavigationModifier(shouldShowAd: shouldShowAd))
    }
}

// MARK: - Ad Trigger Points

enum AdTriggerPoint {
    case afterEventCreation
    case afterEventDeletion
    case afterMonthNavigation
    case afterCalendarExport
    case afterSettingsView
    case afterHolidayDetails
    case afterMultipleSelections
    
    var description: String {
        switch self {
        case .afterEventCreation: return "After creating event"
        case .afterEventDeletion: return "After deleting event"
        case .afterMonthNavigation: return "After navigating months"
        case .afterCalendarExport: return "After exporting calendar"
        case .afterSettingsView: return "After viewing settings"
        case .afterHolidayDetails: return "After viewing holiday details"
        case .afterMultipleSelections: return "After multiple date selections"
        }
    }
    
    func trigger() {
        print("📍 Ad Trigger: \(description)")
        InterstitialAdManager.shared.incrementActionAndShowAd()
    }
    
    func forceShow() {
        print("📍 Ad Trigger (Force): \(description)")
        InterstitialAdManager.shared.incrementActionAndShowAd(force: true)
    }
}

// MARK: - Ad Configuration

struct AdConfiguration {
    static var isAdsEnabled: Bool {
        get { !UserDefaults.standard.bool(forKey: "isPremiumUser") }
    }
    
    static func setPremiumUser(_ isPremium: Bool) {
        UserDefaults.standard.set(isPremium, forKey: "isPremiumUser")
    }
}
