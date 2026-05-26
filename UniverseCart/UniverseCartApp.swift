//
//  UniverseCartApp.swift
//  UniverseCart
//

import SwiftUI

@main
struct UniverseCartApp: App {
    @State private var auth = AuthSession()
    @State private var showOnboarding = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(auth)
                .onOpenURL { url in
                    Task { await auth.handleOpenURL(url) }
                }
                .onAppear {
                    presentOnboardingIfNeeded()
                }
                .onChange(of: auth.isAuthenticated) { _, _ in
                    presentOnboardingIfNeeded()
                }
                .fullScreenCover(isPresented: $showOnboarding) {
                    OnboardingFlowView {
                        showOnboarding = false
                    }
                }
        }
    }

    private func presentOnboardingIfNeeded() {
        showOnboarding = auth.isAuthenticated && !OnboardingPreferences.hasCompleted
    }
}
