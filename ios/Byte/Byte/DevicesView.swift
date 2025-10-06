//
//  DevicesView.swift
//  Byte
//
//  Created by Nathan Smith on 10/4/25.
//

import ByteClient
import Connect
import SwiftUI

struct DevicesView: View {
  @EnvironmentObject var appState: AppState
  @State private var devices: [Devices_V1_ListDevicesResponse.Device] = []
  @State private var isLoading = false
  @State private var error: String?
  @State private var showingCreateDevice = false
  @State private var deviceToDelete: Devices_V1_ListDevicesResponse.Device?
  @State private var showingDeleteConfirmation = false

  var body: some View {
    NavigationView {
      List {
        if isLoading {
          HStack {
            ProgressView()
            Text("Loading devices...")
          }
          .padding()
        } else if devices.isEmpty {
          Text("No devices found")
            .foregroundColor(.secondary)
            .padding()
        } else {
          ForEach(devices, id: \.id) { device in
            DeviceRow(
              device: device,
              isCurrentDevice: device.id == appState.configuration?.deviceID
            ) {
              deviceToDelete = device
              showingDeleteConfirmation = true
            }
          }
        }

        if let error = error {
          Section {
            Text(error)
              .foregroundColor(.red)
              .font(.caption)
          }
        }
      }
      .navigationTitle("Devices")
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Add Device") {
            showingCreateDevice = true
          }
        }

        ToolbarItem(placement: .navigationBarLeading) {
          Button("Refresh") {
            loadDevices()
          }
        }
      }
      .sheet(isPresented: $showingCreateDevice) {
        CreateDeviceView {
          createDevice()
          showingCreateDevice = false
        }
      }
      .onAppear {
        loadDevices()
      }
      .alert("Delete Device", isPresented: $showingDeleteConfirmation) {
        Button("Cancel", role: .cancel) {
          deviceToDelete = nil
        }
        Button("Delete", role: .destructive) {
          if let device = deviceToDelete {
            deleteDevice(device)
          }
          deviceToDelete = nil
        }
      } message: {
        if let device = deviceToDelete, device.id == appState.configuration?.deviceID {
          Text(
            """
            You are about to delete the current device. This will sign you out and \
            require you to set up the app again. Are you sure?
            """
          )
        } else {
          Text("Are you sure you want to delete this device? This action cannot be undone.")
        }
      }
    }
  }

  private func loadDevices() {
    guard let client = appState.client else { return }

    isLoading = true
    error = nil

    Task {
      do {
        let request = Devices_V1_ListDevicesRequest()
        let response = await client.devices.listDevices(request: request, headers: [:])

        await MainActor.run {
          if let message = response.message {
            devices = message.devices
          }
          isLoading = false
        }
      }
    }
  }

  private func createDevice() {
    guard let client = appState.client else { return }

    Task {
      do {
        let request = Devices_V1_CreateDeviceRequest()
        let response = await client.devices.createDevice(request: request, headers: [:])

        await MainActor.run {
          if let message = response.message {
            var newDevice = Devices_V1_ListDevicesResponse.Device()
            newDevice.id = message.id
            devices.append(newDevice)
          }
        }
      } catch {
        await MainActor.run {
          self.error = error.localizedDescription
        }
      }
    }
  }

  private func deleteDevice(_ device: Devices_V1_ListDevicesResponse.Device) {
    guard let client = appState.client else { return }

    let isCurrentDevice = device.id == appState.configuration?.deviceID

    Task {
      do {
        var request = Devices_V1_DeleteDeviceRequest()
        request.id = device.id
        _ = await client.devices.deleteDevice(request: request, headers: [:])

        await MainActor.run {
          devices.removeAll { $0.id == device.id }

          // If we deleted the current device, clear configuration
          if isCurrentDevice {
            appState.clearConfiguration()
          }
        }
      } catch {
        await MainActor.run {
          self.error = error.localizedDescription
        }
      }
    }
  }
}

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
            HStack(spacing: 4) {
              Image(systemName: "checkmark.circle.fill")
                .font(.caption)
              Text("Current Device")
                .font(.caption)
            }
            .foregroundColor(.green)
          }
        }

        if isCurrentDevice {
          Text("This device")
            .font(.caption2)
            .foregroundColor(.secondary)
        }
      }

      Spacer()

      Button {
        onDelete()
      } label: {
        Image(systemName: "trash")
          .foregroundColor(isCurrentDevice ? .orange : .red)
      }
      .buttonStyle(.borderless)
    }
    .padding(.vertical, 4)
  }
}

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
        ToolbarItem(placement: .navigationBarLeading) {
          Button("Cancel") {
            dismiss()
          }
        }

        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Create") {
            onCreate()
            dismiss()
          }
        }
      }
    }
  }
}

#Preview {
  DevicesView()
    .environmentObject(AppState())
}
