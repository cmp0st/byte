//
//  ContentView.swift
//  Byte
//
//  Created by Nathan Smith on 10/4/25.
//

import SwiftUI

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
  }
}

#Preview {
  ContentView()
}
