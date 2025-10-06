//
//  MainTabView.swift
//  Byte
//
//  Created by Nathan Smith on 10/4/25.
//

import SwiftUI

/// Main tab view for the application
struct MainTabView: View {
  // MARK: - Properties

  @EnvironmentObject var appState: AppState

  // MARK: - Body

  var body: some View {
    TabView {
      devicesTab
      filesTab
      photosTab
      settingsTab
    }
    .accessibilityElement(children: .contain)
  }

  // MARK: - Tab Views

  private var devicesTab: some View {
    DevicesView()
      .tabItem {
        Label("Devices", systemImage: "laptopcomputer.and.iphone")
      }
      .accessibilityLabel("Devices tab")
  }

  private var filesTab: some View {
    FilesView()
      .tabItem {
        Label("Files", systemImage: "folder")
      }
      .accessibilityLabel("Files tab")
  }

  private var photosTab: some View {
    PhotosSyncView()
      .tabItem {
        Label("Photos", systemImage: "photo.on.rectangle")
      }
      .accessibilityLabel("Photos tab")
  }

  private var settingsTab: some View {
    SettingsView()
      .tabItem {
        Label("Settings", systemImage: "gear")
      }
      .accessibilityLabel("Settings tab")
  }
}

// MARK: - Preview

#Preview {
  MainTabView()
    .environmentObject(AppState())
}
