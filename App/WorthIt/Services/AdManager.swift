import Foundation
import UIKit
import GoogleMobileAds
import AppTrackingTransparency

/// Wraps Google Mobile Ads. The ONLY networked component in the app — product
/// analysis stays fully on-device. An interstitial is shown after every check
/// unless the user is premium.
///
/// NOTE: the IDs below are Google's official **test** IDs. Replace
/// `interstitialUnitID` and the `GADApplicationIdentifier` in Info.plist with
/// your real AdMob IDs before shipping.
@MainActor
final class AdManager: NSObject, GADFullScreenContentDelegate {

    static let shared = AdManager()

    static let testInterstitialUnitID = "ca-app-pub-3940256099942544/4411468910"
    var interstitialUnitID = AdManager.testInterstitialUnitID

    private var interstitial: GADInterstitialAd?
    private var onDismiss: (() -> Void)?

    func start() {
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        loadInterstitial()
    }

    /// Must be called after the app is active (Apple requirement). Ad serving
    /// still works if the user denies tracking — it just becomes non-personalized.
    func requestTrackingAuthorizationIfNeeded() {
        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined
        else { return }
        ATTrackingManager.requestTrackingAuthorization { _ in }
    }

    func loadInterstitial() {
        let request = GADRequest()
        GADInterstitialAd.load(withAdUnitID: interstitialUnitID,
                               request: request) { [weak self] ad, error in
            guard let self else { return }
            if let error {
                print("Interstitial failed to load: \(error.localizedDescription)")
                self.interstitial = nil
                return
            }
            self.interstitial = ad
            self.interstitial?.fullScreenContentDelegate = self
        }
    }

    /// Shows an interstitial (if available and not premium), then calls
    /// `completion`. Always calls `completion` exactly once so navigation never
    /// gets stuck.
    func maybeShowInterstitial(isPremium: Bool, completion: @escaping () -> Void) {
        guard !isPremium, let interstitial,
              let root = Self.topViewController() else {
            completion()
            loadInterstitial()
            return
        }
        onDismiss = completion
        interstitial.present(fromRootViewController: root)
    }

    // MARK: GADFullScreenContentDelegate

    func adDidDismissFullScreenContent(_ ad: GADFullScreenContentAd) {
        finish()
    }

    func ad(_ ad: GADFullScreenContentAd,
            didFailToPresentFullScreenContentWithError error: Error) {
        finish()
    }

    private func finish() {
        let cb = onDismiss
        onDismiss = nil
        interstitial = nil
        loadInterstitial()
        cb?()
    }

    private static func topViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        var top = scene?.windows.first { $0.isKeyWindow }?.rootViewController
        while let presented = top?.presentedViewController { top = presented }
        return top
    }
}
