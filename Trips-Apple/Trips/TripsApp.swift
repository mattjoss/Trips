//
//  TripsApp.swift
//  Trips
//
//  Created by Matt Joss on 2/7/26.
//

import SwiftUI
import FirebaseCore
import GoogleSignIn

@main
struct TripsApp: App {
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(AuthManager.shared)
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
                #if os(macOS)
                .frame(minWidth: 600, minHeight: 500)
                .preferredColorScheme(.dark)
                #endif
        }
    }
}
