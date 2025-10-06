//
//  DevicesViewModel.swift
//  Byte
//
//  Created by Nathan Smith on 10/5/25.
//

import ByteClient
import Combine
import Connect
import Foundation

/// ViewModel for device management
@MainActor
final class DevicesViewModel: ObservableObject {
  // MARK: - Published Properties

  @Published private(set) var devices: [Devices_V1_ListDevicesResponse.Device] = []
  @Published private(set) var isLoading = false
  @Published private(set) var error: String?

  // MARK: - Public Methods

  /// Load all devices from the server
  /// - Parameter client: The ByteClient instance
  func loadDevices(client: ByteClient) {
    isLoading = true
    error = nil

    Task {
      do {
        let request = Devices_V1_ListDevicesRequest()
        let response = await client.devices.listDevices(request: request, headers: [:])

        if let message = response.message {
          devices = message.devices
        }
        isLoading = false
      } catch {
        self.error = AppError.networkError(error).localizedDescription
        isLoading = false
      }
    }
  }

  /// Create a new device
  /// - Parameter client: The ByteClient instance
  func createDevice(client: ByteClient) {
    Task {
      do {
        let request = Devices_V1_CreateDeviceRequest()
        let response = await client.devices.createDevice(request: request, headers: [:])

        if let message = response.message {
          var newDevice = Devices_V1_ListDevicesResponse.Device()
          newDevice.id = message.id
          devices.append(newDevice)
        }
      } catch {
        self.error = AppError.networkError(error).localizedDescription
      }
    }
  }

  /// Delete a device
  /// - Parameters:
  ///   - device: The device to delete
  ///   - currentDeviceID: The current device ID
  ///   - client: The ByteClient instance
  ///   - onCurrentDeviceDeleted: Callback when current device is deleted
  func deleteDevice(
    _ device: Devices_V1_ListDevicesResponse.Device,
    currentDeviceID: String,
    client: ByteClient,
    onCurrentDeviceDeleted: @escaping () -> Void
  ) {
    let isCurrentDevice = device.id == currentDeviceID

    Task {
      do {
        var request = Devices_V1_DeleteDeviceRequest()
        request.id = device.id
        _ = await client.devices.deleteDevice(request: request, headers: [:])

        devices.removeAll { $0.id == device.id }

        if isCurrentDevice {
          onCurrentDeviceDeleted()
        }
      } catch {
        self.error = AppError.networkError(error).localizedDescription
      }
    }
  }

  /// Check if a device is the current device
  /// - Parameters:
  ///   - device: The device to check
  ///   - currentDeviceID: The current device ID
  /// - Returns: True if this is the current device
  func isCurrentDevice(_ device: Devices_V1_ListDevicesResponse.Device, currentDeviceID: String?) -> Bool {
    device.id == currentDeviceID
  }
}
