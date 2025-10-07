//
//  SettingsView.swift
//  Byte
//
//  Created by Nathan Smith on 10/5/25.
//

import ByteClient
import SwiftUI

/// View for app settings
struct SettingsView: View {
  // MARK: - Properties

  @EnvironmentObject var appState: AppState
  @State private var showingResetAlert = false

  // MARK: - Body

  var body: some View {
    NavigationView {
      List {
        configurationSection
        photoSyncSection
        actionsSection
      }
      .navigationTitle("Settings")
      .alert("Reset Configuration", isPresented: $showingResetAlert) {
        alertButtons
      } message: {
        alertMessage
      }
    }
    .accessibilityElement(children: .contain)
    .accessibilityLabel("Settings")
  }

  // MARK: - View Components

  @ViewBuilder private var configurationSection: some View {
    if let config = appState.configuration {
      Section(header: Text("Configuration")) {
        configurationRow(title: "Server URL", value: config.serverURL)
        configurationRow(title: "Device ID", value: config.deviceID, isMonospaced: true)
      }
    }
  }

  private func configurationRow(title: String, value: String, isMonospaced: Bool = false) -> some View {
    HStack {
      Text(title)
      Spacer()
      Text(value)
        .foregroundColor(.secondary)
        .font(isMonospaced ? .caption.monospaced() : .caption)
        .lineLimit(1)
        .truncationMode(.middle)
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(title): \(value)")
  }

  private var photoSyncSection: some View {
    Section(header: Text("Photo Sync")) {
      Toggle("Auto-Sync Photos", isOn: Binding(
        get: { PhotoSyncService.shared.autoSyncEnabled },
        set: { PhotoSyncService.shared.autoSyncEnabled = $0 }
      ))
      .accessibilityLabel("Auto-sync photos")
      .accessibilityHint("Automatically upload new photos when they are added to your library")

      if let lastSync = PhotoSyncService.shared.lastSyncTime {
        HStack {
          Text("Last Sync")
          Spacer()
          Text(lastSync, style: .relative)
            .foregroundColor(.secondary)
            .font(.caption)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Last sync: \(lastSync, style: .relative)")
      }

      Button("Clear Sync History") {
        PhotoSyncService.shared.clearSyncState()
      }
      .accessibilityLabel("Clear sync history")
      .accessibilityHint("Removes record of previously synced photos")
    }
  }

  private var actionsSection: some View {
    Section {
      Button("Reset Configuration") {
        showingResetAlert = true
      }
      .foregroundColor(.red)
      .accessibilityLabel("Reset configuration")
      .accessibilityHint("Warning: This will remove all stored settings")
    }
  }

  private var alertButtons: some View {
    Group {
      Button("Cancel", role: .cancel) {}
      Button("Reset", role: .destructive) {
        appState.clearConfiguration()
      }
    }
  }

  private var alertMessage: some View {
    Text("This will remove all stored configuration data. You'll need to set up the client again.")
  }
}

// MARK: - Preview

#Preview {
  SettingsView()
    .environmentObject(AppState())
}
