//
//  ContentView.swift
//  Trips
//
//  Created by Matt Joss on 2/7/26.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        if authManager.isSignedIn {
            NavigationStack {
                HomeView()
            }
        } else {
            LoginView()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthManager.shared)
}
