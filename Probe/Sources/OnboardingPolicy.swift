import Foundation

/// Decide first-use presentation from nonsecret preferences, without reading credentials.
enum OnboardingPolicy {
    static let seenKey = "onboarding.hasSeenHelp"

    /// Show once only when no setup preference exists. Partial setup also preserves quiet upgrades.
    static func shouldShowAutomatically(hasSeenHelp: Bool, endpoint: String?, model: String?, keyOrigin: String?) -> Bool {
        !hasSeenHelp && [endpoint, model, keyOrigin].allSatisfy {
            ($0 ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
}
