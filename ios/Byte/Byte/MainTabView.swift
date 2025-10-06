//
//  MainTabView.swift
//  Byte
//
//  Created by Nathan Smith on 10/4/25.
//

import ByteClient
import SwiftUI

struct MainTabView: View {
  @EnvironmentObject var appState: AppState

  var body: some View {
    TabView {
      DevicesView()
        .tabItem {
          Image(systemName: "laptopcomputer.and.iphone")
          Text("Devices")
        }

      FilesView()
        .tabItem {
          Image(systemName: "folder")
          Text("Files")
        }

      PhotosSyncView()
        .tabItem {
          Image(systemName: "photo.on.rectangle")
          Text("Photos")
        }

      SettingsView()
        .tabItem {
          Image(systemName: "gear")
          Text("Settings")
        }
    }
  }
}

struct SettingsView: View {
  @EnvironmentObject var appState: AppState
  @State private var showingResetAlert = false

  var body: some View {
    NavigationView {
      List {
        if let config = appState.configuration {
          Section(header: Text("Configuration")) {
            HStack {
              Text("Server URL")
              Spacer()
              Text(config.serverURL)
                .foregroundColor(.secondary)
            }

            HStack {
              Text("Device ID")
              Spacer()
              Text(config.deviceID)
                .foregroundColor(.secondary)
                .font(.caption)
            }
          }
        }

        Section {
          Button("Reset Configuration") {
            showingResetAlert = true
          }
          .foregroundColor(.red)
        }
      }
      .navigationTitle("Settings")
      .alert("Reset Configuration", isPresented: $showingResetAlert) {
        Button("Cancel", role: .cancel) {}
        Button("Reset", role: .destructive) {
          appState.clearConfiguration()
        }
      } message: {
        Text("This will remove all stored configuration data. You'll need to set up the client again.")
      }
    }
  }
}

#Preview {
  MainTabView()
    .environmentObject(AppState())
}
