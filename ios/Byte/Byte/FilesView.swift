//
//  FilesView.swift
//  Byte
//
//  Created by Nathan Smith on 10/4/25.
//

import ByteClient
import Connect
import SwiftUI

struct FilesView: View {
  @EnvironmentObject var appState: AppState
  @State private var entries: [Files_V1_FileInfo] = []
  @State private var currentPath: String = "/"
  @State private var isLoading = false
  @State private var error: String?
  @State private var showingCreateDirectory = false

  var body: some View {
    NavigationView {
      List {
        if isLoading {
          HStack {
            ProgressView()
            Text("Loading...")
          }
          .padding()
        } else if entries.isEmpty {
          Text("Directory is empty")
            .foregroundColor(.secondary)
            .padding()
        } else {
          ForEach(entries, id: \.path) { entry in
            FileRow(entry: entry) {
              if entry.isDir {
                navigateToDirectory(entry.path)
              }
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
      .navigationTitle(currentPath)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("New Folder") {
            showingCreateDirectory = true
          }
        }

        ToolbarItem(placement: .navigationBarLeading) {
          if currentPath != "/" {
            Button("Back") {
              navigateUp()
            }
          } else {
            Button("Refresh") {
              loadDirectory()
            }
          }
        }
      }
      .sheet(isPresented: $showingCreateDirectory) {
        CreateDirectoryView(currentPath: currentPath) { dirName in
          createDirectory(name: dirName)
          showingCreateDirectory = false
        }
      }
      .onAppear {
        loadDirectory()
      }
    }
  }

  private func loadDirectory() {
    guard let client = appState.client else { return }

    isLoading = true
    error = nil

    Task {
      do {
        var request = Files_V1_ListDirectoryRequest()
        request.path = currentPath
        let response = await client.files.listDirectory(request: request, headers: [:])

        await MainActor.run {
          if let message = response.message {
            entries = message.entries
          }
          isLoading = false
        }
      } catch {
        await MainActor.run {
          self.error = error.localizedDescription
          self.isLoading = false
        }
      }
    }
  }

  private func navigateToDirectory(_ path: String) {
    currentPath = path
    loadDirectory()
  }

  private func navigateUp() {
    let components = currentPath.split(separator: "/")
    if components.isEmpty {
      currentPath = "/"
    } else {
      currentPath = "/" + components.dropLast().joined(separator: "/")
      if currentPath.isEmpty {
        currentPath = "/"
      }
    }
    loadDirectory()
  }

  private func createDirectory(name: String) {
    guard let client = appState.client else { return }

    Task {
      do {
        var request = Files_V1_MakeDirectoryRequest()
        let newPath = currentPath == "/" ? "/\(name)" : "\(currentPath)/\(name)"
        request.path = newPath
        request.createParents = false
        _ = await client.files.makeDirectory(request: request, headers: [:])

        await MainActor.run {
          loadDirectory()
        }
      } catch {
        await MainActor.run {
          self.error = error.localizedDescription
        }
      }
    }
  }
}

struct FileRow: View {
  let entry: Files_V1_FileInfo
  let onTap: () -> Void

  var body: some View {
    Button(action: onTap) {
      HStack {
        Image(systemName: entry.isDir ? "folder.fill" : "doc.fill")
          .foregroundColor(entry.isDir ? .blue : .gray)

        VStack(alignment: .leading) {
          Text(entry.name)
            .font(.headline)
            .foregroundColor(.primary)

          if !entry.isDir {
            Text("Size: \(formatBytes(entry.size))")
              .font(.caption)
              .foregroundColor(.secondary)
          }
        }

        Spacer()

        if entry.isDir {
          Image(systemName: "chevron.right")
            .foregroundColor(.secondary)
        }
      }
    }
  }

  private func formatBytes(_ bytes: Int64) -> String {
    let formatter = ByteCountFormatter()
    formatter.countStyle = .file
    return formatter.string(fromByteCount: bytes)
  }
}

struct CreateDirectoryView: View {
  let currentPath: String
  @State private var directoryName = ""
  let onCreate: (String) -> Void
  @Environment(\.dismiss)
  private var dismiss

  var body: some View {
    NavigationView {
      Form {
        Section(header: Text("Directory Information")) {
          TextField("Directory Name", text: $directoryName)

          Text(
            """
            Will be created at: \(currentPath == "/" ? "/" : currentPath)/\
            \(directoryName.isEmpty ? "<name>" : directoryName)
            """
          )
          .font(.caption)
          .foregroundColor(.secondary)
        }
      }
      .navigationTitle("Create Directory")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("Cancel") {
            dismiss()
          }
        }

        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Create") {
            onCreate(directoryName)
            dismiss()
          }
          .disabled(directoryName.isEmpty)
        }
      }
    }
  }
}

#Preview {
  FilesView()
    .environmentObject(AppState())
}
