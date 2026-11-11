import AuthenticationServices

/// Sign in with Apple. Needs the capability turned on in Xcode (see README); without it `start` reports failure.
@MainActor
final class AppleSignIn: NSObject, ASAuthorizationControllerDelegate {
    static let shared = AppleSignIn()
    private var done: ((Bool) -> Void)?

    func start(_ completion: @escaping (Bool) -> Void) {
        done = completion
        let r = ASAuthorizationAppleIDProvider().createRequest()
        r.requestedScopes = [.fullName]
        let c = ASAuthorizationController(authorizationRequests: [r])
        c.delegate = self
        c.performRequests()
    }

    nonisolated func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization a: ASAuthorization) {
        MainActor.assumeIsolated { done?(true); done = nil }
    }

    nonisolated func authorizationController(controller: ASAuthorizationController, didCompleteWithError e: Error) {
        MainActor.assumeIsolated { done?(false); done = nil }
    }
}
