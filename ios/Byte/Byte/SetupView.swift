//
//  SetupView.swift
//  Byte
//
//  Created by Nathan Smith on 10/4/25.
//

import SwiftUI

struct SetupView: View {
  @EnvironmentObject var appState: AppState
  @State private var serverURL = ""
  @State private var deviceID = ""
  @State private var secret = ""
  @State private var showingSecretField = false
  @State private var showingScanner = false
  @State private var scannedCode: String?

  var body: some View {
    NavigationView {
      Form {
        Section(header: Text("Quick Setup")) {
          Button {
            showingScanner = true
          } label: {
            Label("Scan QR Code", systemImage: "qrcode.viewfinder")
          }
        }

        Section(header: Text("Server Configuration")) {
          TextField("Server URL", text: $serverURL)
            .textContentType(.URL)
            .autocapitalization(.none)
            .disableAutocorrection(true)
            .placeholder(when: serverURL.isEmpty) {
              Text("https://your-server.com")
                .foregroundColor(.secondary)
            }
        }

        Section(header: Text("Device Configuration")) {
          TextField("Device ID", text: $deviceID)
            .textContentType(.none)
            .autocapitalization(.none)
            .disableAutocorrection(true)

          Text("Device ID must be a valid UUID v4")
            .font(.caption)
            .foregroundColor(.secondary)
        }

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
          }

          Text("Enter your base64-encoded secret key")
            .font(.caption)
            .foregroundColor(.secondary)
        }

        if let error = appState.error {
          Section {
            Text(error)
              .foregroundColor(.red)
              .font(.caption)
          }
        }

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
          .disabled(serverURL.isEmpty || deviceID.isEmpty || secret.isEmpty || appState.isLoading)
        }
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
  }

  private func parseQRCode(_ code: String) {
    guard let data = code.data(using: .utf8),
      let json = try? JSONSerialization.jsonObject(with: data) as? [String: String]
    else {
      appState.error = "Invalid QR code format"
      return
    }

    if let serverUrl = json["serverUrl"], let deviceId = json["deviceId"], let secret = json["secret"] {
      self.serverURL = serverUrl
      self.deviceID = deviceId
      self.secret = secret
    } else {
      appState.error = "QR code missing required fields"
    }
  }
}

// Helper extension for placeholder text
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

#Preview {
  SetupView()
    .environmentObject(AppState())
}
