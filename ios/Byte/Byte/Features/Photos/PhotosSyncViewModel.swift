//
//  PhotosSyncViewModel.swift
//  Byte
//
//  Created by Nathan Smith on 10/5/25.
//

import ByteClient
import Combine
import Foundation
import Photos
import UIKit

/// ViewModel for photo synchronization
@MainActor
final class PhotosSyncViewModel: ObservableObject {
  // MARK: - Published Properties

  @Published private(set) var photos: [PHAsset] = []
  @Published var selectedPhotos: Set<String> = []
  @Published private(set) var isLoading = false
  @Published private(set) var uploadProgress: [String: Double] = [:]
  @Published private(set) var errorMessage: String?
  @Published private(set) var successMessage: String?
  @Published private(set) var authorizationStatus: PHAuthorizationStatus = .notDetermined

  // MARK: - Public Methods

  /// Check photo library permission status
  func checkPhotoPermission() {
    authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)

    if authorizationStatus == .authorized || authorizationStatus == .limited {
      loadPhotos()
    }
  }

  /// Request photo library permission
  func requestPhotoPermission() {
    PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
      Task { @MainActor in
        self?.authorizationStatus = status
        if status == .authorized || status == .limited {
          self?.loadPhotos()
        }
      }
    }
  }

  /// Load photos from the library
  func loadPhotos() {
    let fetchOptions = PHFetchOptions()
    fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
    fetchOptions.fetchLimit = AppConstants.Photos.defaultFetchLimit

    let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
    var loadedPhotos: [PHAsset] = []

    fetchResult.enumerateObjects { asset, _, _ in
      loadedPhotos.append(asset)
    }

    photos = loadedPhotos
  }

  /// Toggle photo selection
  /// - Parameter asset: The photo asset to toggle
  func toggleSelection(_ asset: PHAsset) {
    if selectedPhotos.contains(asset.localIdentifier) {
      selectedPhotos.remove(asset.localIdentifier)
    } else {
      selectedPhotos.insert(asset.localIdentifier)
    }
  }

  /// Sync selected photos to the server
  /// - Parameter client: The ByteClient instance
  func syncPhotos(client: ByteClient) async {
    isLoading = true
    errorMessage = nil
    successMessage = nil

    let assetsToSync = photos.filter { selectedPhotos.contains($0.localIdentifier) }
    var successCount = 0

    for asset in assetsToSync {
      do {
        uploadProgress[asset.localIdentifier] = 0.1

        guard let imageData = await getImageData(for: asset) else {
          errorMessage = AppError.photoLoadFailed(asset.localIdentifier).localizedDescription
          continue
        }

        uploadProgress[asset.localIdentifier] = 0.5

        let filename =
          asset.value(forKey: "filename") as? String
          ?? "\(AppConstants.Photos.defaultFilename)_\(asset.localIdentifier).jpg"

        var request = Files_V1_WriteFileRequest()
        request.path = "\(AppConstants.Photos.uploadDirectory)\(filename)"
        request.data = imageData
        request.createParents = true

        _ = await client.files.writeFile(request: request, headers: [:])

        uploadProgress[asset.localIdentifier] = 1.0
        successCount += 1
        selectedPhotos.remove(asset.localIdentifier)

        // Mark photo as synced in the service
        PhotoSyncService.shared.markPhotoAsSynced(asset.localIdentifier)
      } catch {
        errorMessage = "Failed to sync photo: \(error.localizedDescription)"
      }
    }

    if successCount > 0 {
      successMessage = "Successfully synced \(successCount) photo\(successCount == 1 ? "" : "s")"
    }

    isLoading = false
    uploadProgress.removeAll()
  }

  /// Get image data for a photo asset
  /// - Parameter asset: The photo asset
  /// - Returns: Image data or nil
  func getImageData(for asset: PHAsset) async -> Data? {
    await withCheckedContinuation { continuation in
      let options = PHImageRequestOptions()
      options.isSynchronous = false
      options.deliveryMode = .highQualityFormat

      PHImageManager.default().requestImageDataAndOrientation(
        for: asset,
        options: options
      ) { data, _, _, _ in
        continuation.resume(returning: data)
      }
    }
  }

  /// Get thumbnail image for a photo asset
  /// - Parameters:
  ///   - asset: The photo asset
  ///   - completion: Completion handler with the image
  func getThumbnail(for asset: PHAsset, completion: @escaping (UIImage?) -> Void) {
    let manager = PHImageManager.default()
    let options = PHImageRequestOptions()
    options.isSynchronous = false

    manager.requestImage(
      for: asset,
      targetSize: AppConstants.Photos.thumbnailSize,
      contentMode: .aspectFill,
      options: options
    ) { result, _ in
      completion(result)
    }
  }
}
