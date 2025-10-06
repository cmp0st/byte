//
//  DevicesView.swift
//  Byte
//
//  Created by Nathan Smith on 10/4/25.
//

import ByteClient
import SwiftUI

/// View for managing devices
struct DevicesView: View {
  // MARK: - Properties

  @EnvironmentObject var appState: AppState
  @StateObject private var viewModel = DevicesViewModel()
  @State private var showingCreateDevice = false
  @State private var deviceToDelete: Devices_V1_ListDevicesResponse.Device?
  @State private var showingDeleteConfirmation = false

  // MARK: - Body

  var body: some View {
    NavigationView {
      List {
        contentSection
        errorSection
      }
      .navigationTitle("Devices")
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          addButton
        }
        ToolbarItem(placement: .navigationBarLeading) {
          refreshButton
        }
      }
      .sheet(isPresented: $showingCreateDevice) {
        createDeviceSheet
      }
      .onAppear(perform: handleOnAppear)
      .alert(deleteAlertTitle, isPresented: $showingDeleteConfirmation) {
        deleteAlertButtons
      } message: {
        deleteAlertMessage
      }
    }
    .accessibilityElement(children: .contain)
    .accessibilityLabel("Devices Manager")
  }

  // MARK: - View Components

  @ViewBuilder private var contentSection: some View {
    if viewModel.isLoading {
      loadingView
    } else if viewModel.devices.isEmpty {
      emptyStateView
    } else {
      devicesList
    }
  }

  private var loadingView: some View {
    HStack {
      ProgressView()
      Text("Loading devices...")
    }
    .padding()
    .accessibilityElement(children: .combine)
    .accessibilityLabel("Loading devices")
  }

  private var emptyStateView: some View {
    Text("No devices found")
      .foregroundColor(.secondary)
      .padding()
      .accessibilityLabel("No devices available")
  }

  private var devicesList: some View {
    ForEach(viewModel.devices, id: \.id) { device in
      DeviceRow(
        device: device,
        isCurrentDevice: viewModel.isCurrentDevice(device, currentDeviceID: appState.configuration?.deviceID),
        onDelete: {
          deviceToDelete = device
          showingDeleteConfirmation = true
        }
      )
    }
  }

  @ViewBuilder private var errorSection: some View {
    if let error = viewModel.error {
      Section {
        Text(error)
          .foregroundColor(.red)
          .font(.caption)
      }
      .accessibilityLabel("Error: \(error)")
    }
  }

  private var addButton: some View {
    Button("Add Device") {
      showingCreateDevice = true
    }
    .accessibilityLabel("Add new device")
  }

  private var refreshButton: some View {
    Button("Refresh") {
      handleRefresh()
    }
    .accessibilityLabel("Refresh device list")
  }

  private var createDeviceSheet: some View {
    CreateDeviceView {
      handleCreateDevice()
      showingCreateDevice = false
    }
  }

  private var deleteAlertTitle: String {
    "Delete Device"
  }

  private var deleteAlertButtons: some View {
    Group {
      Button("Cancel", role: .cancel) {
        deviceToDelete = nil
      }
      Button("Delete", role: .destructive) {
        handleDelete()
      }
    }
  }

  @ViewBuilder private var deleteAlertMessage: some View {
    if let device = deviceToDelete {
      Text(deleteMessage(for: device))
    }
  }

  // MARK: - Actions

  private func handleOnAppear() {
    guard let client = appState.client else { return }
    viewModel.loadDevices(client: client)
  }

  private func handleRefresh() {
    guard let client = appState.client else { return }
    viewModel.loadDevices(client: client)
  }

  private func handleCreateDevice() {
    guard let client = appState.client else { return }
    viewModel.createDevice(client: client)
  }

  private func handleDelete() {
    guard let client = appState.client,
      let device = deviceToDelete,
      let currentDeviceID = appState.configuration?.deviceID
    else { return }
    viewModel.deleteDevice(device, currentDeviceID: currentDeviceID, client: client) {
      appState.clearConfiguration()
    }
    deviceToDelete = nil
  }

  private func deleteMessage(for device: Devices_V1_ListDevicesResponse.Device) -> String {
    if viewModel.isCurrentDevice(device, currentDeviceID: appState.configuration?.deviceID) {
      return """
        You are about to delete the current device. This will sign you out and \
        require you to set up the app again. Are you sure?
        """
    } else {
      return "Are you sure you want to delete this device? This action cannot be undone."
    }
  }
}

// MARK: - Device Row

struct DeviceRow: View {
  let device: Devices_V1_ListDevicesResponse.Device
  let isCurrentDevice: Bool
  let onDelete: () -> Void

  var body: some View {
    HStack {
      VStack(alignment: .leading, spacing: 4) {
        HStack {
          Text(device.id)
            .font(.headline)

          if isCurrentDevice {
            currentDeviceBadge
          }
        }

        if isCurrentDevice {
          Text("This device")
            .font(.caption2)
            .foregroundColor(.secondary)
        }
      }

      Spacer()

      deleteButton
    }
    .padding(.vertical, 4)
    .accessibilityElement(children: .contain)
    .accessibilityLabel(accessibilityLabel)
  }

  private var currentDeviceBadge: some View {
    HStack(spacing: 4) {
      Image(systemName: "checkmark.circle.fill")
        .font(.caption)
      Text("Current Device")
        .font(.caption)
    }
    .foregroundColor(.green)
    .accessibilityHidden(true)
  }

  private var deleteButton: some View {
    Button {
      onDelete()
    } label: {
      Image(systemName: "trash")
        .foregroundColor(isCurrentDevice ? .orange : .red)
    }
    .buttonStyle(.borderless)
    .accessibilityLabel("Delete device")
    .accessibilityHint(isCurrentDevice ? "Warning: This is your current device" : "")
  }

  private var accessibilityLabel: String {
    var label = "Device: \(device.id)"
    if isCurrentDevice {
      label += ", Current device"
    }
    return label
  }
}

// MARK: - Create Device View

struct CreateDeviceView: View {
  let onCreate: () -> Void
  @Environment(\.dismiss)
  private var dismiss

  var body: some View {
    NavigationView {
      VStack(spacing: 20) {
        Text("Create New Device")
          .font(.title)
          .padding()

        Text(
          "This will create a new device. The device key will be encrypted with your current device's encryption key."
        )
        .multilineTextAlignment(.center)
        .foregroundColor(.secondary)
        .padding()

        Spacer()
      }
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        leadingToolbarItem
        trailingToolbarItem
      }
    }
    .accessibilityElement(children: .contain)
    .accessibilityLabel("Create new device")
  }

  private var leadingToolbarItem: some ToolbarContent {
    ToolbarItem(placement: .navigationBarLeading) {
      Button("Cancel") {
        dismiss()
      }
      .accessibilityLabel("Cancel device creation")
    }
  }

  private var trailingToolbarItem: some ToolbarContent {
    ToolbarItem(placement: .navigationBarTrailing) {
      Button("Create") {
        onCreate()
        dismiss()
      }
      .accessibilityLabel("Create device")
    }
  }
}

// MARK: - Preview

#Preview {
  DevicesView()
    .environmentObject(AppState())
}
