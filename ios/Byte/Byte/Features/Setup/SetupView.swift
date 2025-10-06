//
//  SetupView.swift
//  Byte
//
//  Created by Nathan Smith on 10/4/25.
//

import SwiftUI

/// Initial setup view for configuring the app
struct SetupView: View {
  // MARK: - Properties

  @EnvironmentObject var appState: AppState
  @State private var serverURL = ""
  @State private var deviceID = ""
  @State private var secret = ""
  @State private var showingSecretField = false
  @State private var showingScanner = false
  @State private var scannedCode: String?
  @State private var localError: String?

  // MARK: - Body

  var body: some View {
    NavigationView {
      Form {
        quickSetupSection
        serverConfigSection
        deviceConfigSection
        authenticationSection
        errorSection
        connectSection
      }
      .navigationTitle("Setup Byte Client")
      .sheet(isPresented: $showingScanner) {
        QRScannerView(scannedCode: $scannedCode)
      }
      .onChange(of: scannedCode) { _, newValue in
        if let code = newValue {
          parseQRCode(code)
        }
      }
    }
    .accessibilityElement(children: .contain)
    .accessibilityLabel("App Setup")
  }

  // MARK: - View Components

  private var quickSetupSection: some View {
    Section(header: Text("Quick Setup")) {
      Button {
        showingScanner = true
      } label: {
        Label("Scan QR Code", systemImage: "qrcode.viewfinder")
      }
      .accessibilityLabel("Scan QR code to configure automatically")
    }
  }

  private var serverConfigSection: some View {
    Section(header: Text("Server Configuration")) {
      TextField("Server URL", text: $serverURL)
        .textContentType(.URL)
        .autocapitalization(.none)
        .disableAutocorrection(true)
        .placeholder(when: serverURL.isEmpty) {
          Text("https://your-server.com")
            .foregroundColor(.secondary)
        }
        .accessibilityLabel("Server URL input")
    }
  }

  private var deviceConfigSection: some View {
    Section(header: Text("Device Configuration")) {
      TextField("Device ID", text: $deviceID)
        .textContentType(.none)
        .autocapitalization(.none)
        .disableAutocorrection(true)
        .accessibilityLabel("Device ID input")

      Text("Device ID must be a valid UUID v4")
        .font(.caption)
        .foregroundColor(.secondary)
        .accessibilityLabel("Note: Device ID must be a valid UUID version 4")
    }
  }

  private var authenticationSection: some View {
    Section(header: Text("Authentication")) {
      HStack {
        if showingSecretField {
          TextField("Secret (Base64)", text: $secret)
            .textContentType(.password)
            .autocapitalization(.none)
            .disableAutocorrection(true)
        } else {
          SecureField("Secret (Base64)", text: $secret)
            .textContentType(.password)
            .autocapitalization(.none)
            .disableAutocorrection(true)
        }

        Button(showingSecretField ? "Hide" : "Show") {
          showingSecretField.toggle()
        }
        .buttonStyle(.bordered)
        .font(.caption)
        .accessibilityLabel(showingSecretField ? "Hide secret" : "Show secret")
      }
      .accessibilityElement(children: .contain)
      .accessibilityLabel("Secret key input")

      Text("Enter your base64-encoded secret key")
        .font(.caption)
        .foregroundColor(.secondary)
        .accessibilityLabel("Note: Enter your base64-encoded secret key")
    }
  }

  @ViewBuilder private var errorSection: some View {
    if let error = localError ?? appState.error {
      Section {
        Text(error)
          .foregroundColor(.red)
          .font(.caption)
      }
      .accessibilityLabel("Error: \(error)")
    }
  }

  private var connectSection: some View {
    Section {
      Button {
        Task {
          await appState.saveConfiguration(
            serverURL: serverURL,
            deviceID: deviceID,
            secret: secret
          )
        }
      } label: {
        if appState.isLoading {
          HStack {
            ProgressView()
              .scaleEffect(0.8)
            Text("Connecting...")
          }
        } else {
          Text("Connect")
        }
      }
      .buttonStyle(.borderedProminent)
      .disabled(isConnectDisabled)
      .accessibilityLabel(appState.isLoading ? "Connecting to server" : "Connect to server")
      .accessibilityHint(isConnectDisabled ? "Fill in all fields to enable connection" : "")
    }
  }

  // MARK: - Helper Properties

  private var isConnectDisabled: Bool {
    serverURL.isEmpty || deviceID.isEmpty || secret.isEmpty || appState.isLoading
  }

  // MARK: - Methods

  private func parseQRCode(_ code: String) {
    guard
      let data = code.data(using: .utf8),
      let json = try? JSONSerialization.jsonObject(with: data) as? [String: String]
    else {
      localError = AppError.invalidQRCode.localizedDescription
      return
    }

    if let serverUrl = json["serverUrl"],
      let deviceId = json["deviceId"],
      let secret = json["secret"]
    {
      self.serverURL = serverUrl
      self.deviceID = deviceId
      self.secret = secret
      localError = nil
    } else {
      localError = AppError.missingQRCodeFields.localizedDescription
    }
  }
}

// MARK: - Helper Extensions

extension View {
  func placeholder<Content: View>(
    when shouldShow: Bool,
    alignment: Alignment = .leading,
    @ViewBuilder placeholder: () -> Content
  ) -> some View {
    ZStack(alignment: alignment) {
      placeholder().opacity(shouldShow ? 1 : 0)
      self
    }
  }
}

// MARK: - Preview

#Preview {
  SetupView()
    .environmentObject(AppState())
}
