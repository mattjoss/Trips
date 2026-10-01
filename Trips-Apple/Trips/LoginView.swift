import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var errorMessage: String?
    @State private var isLoading: Bool = false

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(hue: 0.58, saturation: 0.6, brightness: 0.3),
                         Color(hue: 0.58, saturation: 0.8, brightness: 0.15)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // App icon / title area
                VStack(spacing: 16) {
                    Image(systemName: "airplane.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.white.opacity(0.9))

                    Text("Trips")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("Sign in to access your travels")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()

                // Sign-In Button
                VStack(spacing: 16) {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(1.3)
                    } else {
                        GoogleSignInButton {
                            signIn()
                        }
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                .padding(.bottom, 60)
            }
            .padding(.horizontal, 32)
        }
    }

    private func signIn() {
        #if os(macOS)
        guard let presenter = NSApp.keyWindow ?? NSApp.mainWindow else {
            errorMessage = "Unable to find the sign-in window."
            return
        }
        #else
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            errorMessage = "Unable to get presenting view controller."
            return
        }

        let presenter = rootVC
        #endif

        isLoading = true
        errorMessage = nil

        Task {
            do {
                try await authManager.signInWithGoogle(presenting: presenter)
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

// MARK: - Google Sign-In Button

struct GoogleSignInButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "g.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)

                Text("Sign in with Google")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 28)
            .background(.white)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthManager.shared)
}
