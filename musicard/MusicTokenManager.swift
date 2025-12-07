import Foundation
import MusicKit
import StoreKit

final class MusicTokenManager {
    static let shared = MusicTokenManager()

    private let userDefaults = UserDefaults.standard
    private let userTokenKey = "MusicKitUserToken"

    private var cachedDeveloperToken: String?
    private var cachedUserToken: String?
    private var isConfiguring = false

    private init() {}

    func ensureTokens() async throws -> Tokens {
        if isConfiguring {
            while isConfiguring {
                try await Task.sleep(nanoseconds: 50_000_000)
            }
        }

        isConfiguring = true
        defer { isConfiguring = false }

        if cachedDeveloperToken == nil {
            cachedDeveloperToken = try loadDeveloperToken()
        }

        if cachedUserToken == nil, let developerToken = cachedDeveloperToken {
            cachedUserToken = try await ensureUserToken(developerToken: developerToken)
        }

        guard let developer = cachedDeveloperToken else {
            throw TokenError.missingDeveloperToken
        }

        guard let user = cachedUserToken else {
            throw TokenError.failedToFetchUserToken
        }

        return Tokens(developerToken: developer, userToken: user)
    }

    private func loadDeveloperToken() throws -> String {
        if let token = cachedDeveloperToken, !token.isEmpty {
            return token
        }
        guard let token = Bundle.main.object(forInfoDictionaryKey: "MusicKitDeveloperToken") as? String,
              !token.isEmpty else {
            throw TokenError.missingDeveloperToken
        }
        cachedDeveloperToken = token
        return token
    }

    private func ensureUserToken(developerToken: String) async throws -> String {
        if let token = cachedUserToken, !token.isEmpty {
            return token
        }

        if let stored = userDefaults.string(forKey: userTokenKey), !stored.isEmpty {
            cachedUserToken = stored
            return stored
        }

        try await ensureCloudServiceAuthorization()

        let controller = SKCloudServiceController()
        let token: String = try await withCheckedThrowingContinuation { continuation in
            controller.requestUserToken(forDeveloperToken: developerToken) { token, error in
                if let token, !token.isEmpty {
                    continuation.resume(returning: token)
                } else if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(throwing: TokenError.failedToFetchUserToken)
                }
            }
        }

        cachedUserToken = token
        userDefaults.set(token, forKey: userTokenKey)
        return token
    }

    private func ensureCloudServiceAuthorization() async throws {
        let status = SKCloudServiceController.authorizationStatus()
        switch status {
        case .authorized:
            return
        case .notDetermined:
            let newStatus: SKCloudServiceAuthorizationStatus = await withCheckedContinuation { continuation in
                SKCloudServiceController.requestAuthorization { status in
                    continuation.resume(returning: status)
                }
            }
            guard newStatus == .authorized else {
                throw TokenError.userAccessDenied
            }
        default:
            throw TokenError.userAccessDenied
        }
    }

    struct Tokens {
        let developerToken: String
        let userToken: String
    }
}
extension MusicTokenManager {
    enum TokenError: LocalizedError {
        case missingDeveloperToken
        case failedToFetchUserToken
        case userAccessDenied

        var errorDescription: String? {
            switch self {
            case .missingDeveloperToken:
                return "Voeg je MusicKit developer token toe aan Info.plist."
            case .failedToFetchUserToken:
                return "Kon geen Apple Music-gebruikerstoken ophalen."
            case .userAccessDenied:
                return "Apple Music-toegang is geweigerd."
            }
        }
    }
}
