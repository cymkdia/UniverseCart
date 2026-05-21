//
//  UniverseCartApp.swift
//  UniverseCart
//

import SwiftUI

@main
struct UniverseCartApp: App {
    @State private var auth = AuthSession()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(auth)
        }
    }
}
