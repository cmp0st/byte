//
//  FilesViewModel.swift
//  Byte
//
//  Created by Nathan Smith on 10/5/25.
//

import ByteClient
import Combine
import Connect
import Foundation

@MainActor
class FilesViewModel: ObservableObject {
  @Published var entries: [Files_V1_FileInfo] = []
  @Published var currentPath: String = "/"
  @Published var isLoading = false
  @Published var error: String?
  @Published var uploadProgress: [String: Double] = [:]
  @Published var isUploading = false
  @Published var fileData: Data?
  @Published var isDownloading = false

  func loadDirectory(client: ByteClient, clearError: Bool = true) {
    isLoading = true
    if clearError {
      error = nil
    }

    Task {
      do {
        var request = Files_V1_ListDirectoryRequest()
        request.path = currentPath
        let response = await client.files.listDirectory(request: request, headers: [:])

        if let message = response.message {
          entries = message.entries
        }
        isLoading = false
      } catch {
        self.error = error.localizedDescription
        self.isLoading = false
      }
    }
  }

  func navigateToDirectory(_ path: String, client: ByteClient) {
    currentPath = path
    loadDirectory(client: client)
  }

  func navigateUp(client: ByteClient) {
    let components = currentPath.split(separator: "/")
    if components.isEmpty {
      currentPath = "/"
    } else {
      currentPath = "/" + components.dropLast().joined(separator: "/")
      if currentPath.isEmpty {
        currentPath = "/"
      }
    }
    loadDirectory(client: client)
  }

  func createDirectory(name: String, client: ByteClient) {
    Task {
      do {
        var request = Files_V1_MakeDirectoryRequest()
        let newPath = currentPath == "/" ? "/\(name)" : "\(currentPath)/\(name)"
        request.path = newPath
        request.createParents = false
        _ = await client.files.makeDirectory(request: request, headers: [:])

        loadDirectory(client: client)
      } catch {
        self.error = error.localizedDescription
      }
    }
  }

  func deleteEntry(_ entry: Files_V1_FileInfo, client: ByteClient) {
    Task {
      do {
        var request = Files_V1_DeleteFileRequest()
        request.path = entry.path
        request.recursive = entry.isDir

        _ = await client.files.deleteFile(request: request, headers: [:])

        entries.removeAll { $0.path == entry.path }
      } catch {
        self.error = error.localizedDescription
      }
    }
  }

  func downloadFile(_ file: Files_V1_FileInfo, client: ByteClient) {
    isDownloading = true
    fileData = nil
    error = nil

    Task {
      do {
        var request = Files_V1_ReadFileRequest()
        request.path = file.path
        let response = await client.files.readFile(request: request, headers: [:])

        if let error = response.error {
          throw error
        }

        if let message = response.message {
          fileData = message.data
        }
        isDownloading = false
      } catch {
        self.error = "Failed to download \(file.name): \(error.localizedDescription)"
        self.isDownloading = false
      }
    }
  }

  func uploadFiles(_ urls: [URL], client: ByteClient) {
    isUploading = true
    error = nil

    Task {
      for url in urls {
        await uploadSingleFile(url, client: client)
      }

      isUploading = false
      loadDirectory(client: client, clearError: false)
    }
  }

  private func uploadSingleFile(_ url: URL, client: ByteClient) async {
    let filename = url.lastPathComponent

    do {
      // Since asCopy: true, files are already copied to temporary location
      // No need for security-scoped resource access
      let fileData = try Data(contentsOf: url)

      uploadProgress[filename] = 0.1

      // Upload to server
      var request = Files_V1_WriteFileRequest()
      let uploadPath = currentPath == "/" ? "/\(filename)" : "\(currentPath)/\(filename)"
      request.path = uploadPath
      request.data = fileData
      request.createParents = false

      uploadProgress[filename] = 0.5

      let response = await client.files.writeFile(request: request, headers: [:])

      // Check for errors
      if let error = response.error {
        throw error
      }

      uploadProgress[filename] = 1.0

      // Small delay to show completion
      try await Task.sleep(nanoseconds: 500_000_000)

      uploadProgress.removeValue(forKey: filename)
    } catch {
      self.error = "Failed to upload \(filename): \(error.localizedDescription)"
      uploadProgress.removeValue(forKey: filename)
    }
  }
}
