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

/// ViewModel for file browsing and management
@MainActor
final class FilesViewModel: ObservableObject {
  // MARK: - Published Properties

  @Published private(set) var entries: [Files_V1_FileInfo] = []
  @Published private(set) var currentPath: String = AppConstants.Files.rootPath
  @Published private(set) var isLoading = false
  @Published private(set) var error: String?
  @Published private(set) var uploadProgress: [String: Double] = [:]
  @Published private(set) var isUploading = false
  @Published private(set) var fileData: Data?
  @Published private(set) var isDownloading = false

  // MARK: - Public Methods

  /// Load directory contents
  /// - Parameters:
  ///   - client: The ByteClient instance
  ///   - clearError: Whether to clear existing errors
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

  /// Navigate to a specific directory
  /// - Parameters:
  ///   - path: The path to navigate to
  ///   - client: The ByteClient instance
  func navigateToDirectory(_ path: String, client: ByteClient) {
    currentPath = path
    loadDirectory(client: client)
  }

  /// Navigate up one directory level
  /// - Parameter client: The ByteClient instance
  func navigateUp(client: ByteClient) {
    let components = currentPath.split(separator: "/")
    if components.isEmpty {
      currentPath = AppConstants.Files.rootPath
    } else {
      currentPath = "/" + components.dropLast().joined(separator: "/")
      if currentPath.isEmpty {
        currentPath = AppConstants.Files.rootPath
      }
    }
    loadDirectory(client: client)
  }

  /// Create a new directory
  /// - Parameters:
  ///   - name: The directory name
  ///   - client: The ByteClient instance
  func createDirectory(name: String, client: ByteClient) {
    Task {
      do {
        var request = Files_V1_MakeDirectoryRequest()
        let newPath = buildPath(for: name)
        request.path = newPath
        request.createParents = false
        _ = await client.files.makeDirectory(request: request, headers: [:])

        loadDirectory(client: client)
      } catch {
        self.error = AppError.fileOperationFailed("create directory").localizedDescription
      }
    }
  }

  /// Delete a file or directory
  /// - Parameters:
  ///   - entry: The file info to delete
  ///   - client: The ByteClient instance
  func deleteEntry(_ entry: Files_V1_FileInfo, client: ByteClient) {
    Task {
      do {
        var request = Files_V1_DeleteFileRequest()
        request.path = entry.path
        request.recursive = entry.isDir

        _ = await client.files.deleteFile(request: request, headers: [:])

        entries.removeAll { $0.path == entry.path }
      } catch {
        self.error = AppError.fileOperationFailed("delete").localizedDescription
      }
    }
  }

  /// Download a file
  /// - Parameters:
  ///   - file: The file to download
  ///   - client: The ByteClient instance
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

  /// Upload multiple files
  /// - Parameters:
  ///   - urls: The file URLs to upload
  ///   - client: The ByteClient instance
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

  // MARK: - Private Methods

  private func uploadSingleFile(_ url: URL, client: ByteClient) async {
    let filename = url.lastPathComponent

    do {
      let fileData = try Data(contentsOf: url)

      uploadProgress[filename] = 0.1

      var request = Files_V1_WriteFileRequest()
      let uploadPath = buildPath(for: filename)
      request.path = uploadPath
      request.data = fileData
      request.createParents = false

      uploadProgress[filename] = 0.5

      let response = await client.files.writeFile(request: request, headers: [:])

      if let error = response.error {
        throw error
      }

      uploadProgress[filename] = 1.0

      try await Task.sleep(nanoseconds: AppConstants.Animation.uploadCompletionDelay)

      uploadProgress.removeValue(forKey: filename)
    } catch {
      self.error = "Failed to upload \(filename): \(error.localizedDescription)"
      uploadProgress.removeValue(forKey: filename)
    }
  }

  private func buildPath(for filename: String) -> String {
    if currentPath == AppConstants.Files.rootPath {
      return "/\(filename)"
    } else {
      return "\(currentPath)/\(filename)"
    }
  }
}
