import Foundation

func check(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

check(OnboardingPolicy.shouldShowAutomatically(hasSeenHelp: false, endpoint: nil, model: nil, keyOrigin: nil),
      "a fresh unconfigured installation opens help")
check(!OnboardingPolicy.shouldShowAutomatically(hasSeenHelp: true, endpoint: nil, model: nil, keyOrigin: nil),
      "closing help or later removing configuration does not repeat onboarding")
check(!OnboardingPolicy.shouldShowAutomatically(hasSeenHelp: false, endpoint: "https://example.invalid/v1/chat/completions", model: "test", keyOrigin: "https://example.invalid"),
      "an existing configured installation remains menu-bar-only without a prior onboarding flag")
for preferences in [("https://example.invalid", nil, nil), (nil, "test", nil), (nil, nil, "https://example.invalid")] as [(String?, String?, String?)] {
    check(!OnboardingPolicy.shouldShowAutomatically(hasSeenHelp: false, endpoint: preferences.0, model: preferences.1, keyOrigin: preferences.2),
          "partial setup is sufficient to keep an existing installation quiet")
}
print("Onboarding: fresh, seen, configured, and partial-setup decisions passed")
