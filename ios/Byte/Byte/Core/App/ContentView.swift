//
//  ContentView.swift
//  Byte
//
//  Created by Nathan Smith on 10/4/25.
//

import SwiftUI

/// Root content view that manages app state
struct ContentView: View {
  @StateObject private var appState = AppState()

  var body: some View {
    Group {
      if appState.isConfigured {
        MainTabView()
      } else {
        SetupView()
      }
    }
    .environmentObject(appState)
    .accessibilityElement(children: .contain)
  }
}

// MARK: - Preview

#Preview {
  ContentView()
}
