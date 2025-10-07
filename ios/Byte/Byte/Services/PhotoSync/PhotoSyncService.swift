//
//  PhotoSyncService.swift
//  Byte
//
//  Created by Nathan Smith on 10/5/25.
//

import ByteClient
import Combine
import Foundation
import Photos

/// Service for managing automatic photo synchronization
@MainActor
final class PhotoSyncService: NSObject, ObservableObject {
  // MARK: - Properties

  static let shared = PhotoSyncService()

  @Published var autoSyncEnabled: Bool {
    didSet {
      UserDefaults.standard.set(autoSyncEnabled, forKey: UserDefaultsKeys.autoSyncEnabled)
      if autoSyncEnabled {
        startObservingPhotoLibrary()
      } else {
        stopObservingPhotoLibrary()
      }
    }
  }

  @Published private(set) var lastSyncTime: Date? {
    didSet {
      if let lastSyncTime = lastSyncTime {
        UserDefaults.standard.set(lastSyncTime, forKey: UserDefaultsKeys.lastSyncTime)
      }
    }
  }

  @Published private(set) var isSyncing = false

  private var syncedPhotoIdentifiers: Set<String> {
    get {
      let array = UserDefaults.standard.stringArray(forKey: UserDefaultsKeys.syncedPhotoIdentifiers) ?? []
      return Set(array)
    }
    set {
      UserDefaults.standard.set(Array(newValue), forKey: UserDefaultsKeys.syncedPhotoIdentifiers)
    }
  }

  private var isObservingPhotoLibrary = false
  private weak var client: ByteClient?

  // MARK: - UserDefaults Keys

  private enum UserDefaultsKeys {
    static let autoSyncEnabled = "photoSync.autoSyncEnabled"
    static let syncedPhotoIdentifiers = "photoSync.syncedPhotoIdentifiers"
    static let lastSyncTime = "photoSync.lastSyncTime"
  }

  // MARK: - Initialization

  override init() {
    self.autoSyncEnabled = UserDefaults.standard.bool(forKey: UserDefaultsKeys.autoSyncEnabled)
    self.lastSyncTime = UserDefaults.standard.object(forKey: UserDefaultsKeys.lastSyncTime) as? Date
    super.init()

    if autoSyncEnabled {
      startObservingPhotoLibrary()
    }
  }

  // MARK: - Public Methods

  /// Set the ByteClient instance for uploads
  func setClient(_ client: ByteClient?) {
    self.client = client
  }

  /// Mark a photo as synced
  func markPhotoAsSynced(_ identifier: String) {
    var identifiers = syncedPhotoIdentifiers
    identifiers.insert(identifier)
    syncedPhotoIdentifiers = identifiers
  }

  /// Check if a photo has been synced
  func isPhotoSynced(_ identifier: String) -> Bool {
    syncedPhotoIdentifiers.contains(identifier)
  }

  /// Sync new photos that haven't been uploaded yet
  func syncNewPhotos() async {
    guard let client = client else { return }
    guard !isSyncing else { return }

    isSyncing = true
    defer { isSyncing = false }

    // Fetch all photos
    let fetchOptions = PHFetchOptions()
    fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

    let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
    var newPhotos: [PHAsset] = []

    fetchResult.enumerateObjects { [weak self] asset, _, _ in
      guard let self = self else { return }
      if !self.isPhotoSynced(asset.localIdentifier) {
        newPhotos.append(asset)
      }
    }

    // Upload new photos
    for asset in newPhotos {
      do {
        guard let imageData = await getImageData(for: asset) else {
          continue
        }

        let filename =
          asset.value(forKey: "filename") as? String
          ?? "\(AppConstants.Photos.defaultFilename)_\(asset.localIdentifier).jpg"

        var request = Files_V1_WriteFileRequest()
        request.path = "\(AppConstants.Photos.uploadDirectory)\(filename)"
        request.data = imageData
        request.createParents = true

        _ = await client.files.writeFile(request: request, headers: [:])

        markPhotoAsSynced(asset.localIdentifier)
      } catch {
        // Continue with next photo on error
        continue
      }
    }

    if !newPhotos.isEmpty {
      lastSyncTime = Date()
    }
  }

  /// Clear all sync state
  func clearSyncState() {
    syncedPhotoIdentifiers = []
    lastSyncTime = nil
  }

  // MARK: - Private Methods

  private func startObservingPhotoLibrary() {
    guard !isObservingPhotoLibrary else { return }
    PHPhotoLibrary.shared().register(self)
    isObservingPhotoLibrary = true
  }

  private func stopObservingPhotoLibrary() {
    guard isObservingPhotoLibrary else { return }
    PHPhotoLibrary.shared().unregisterChangeObserver(self)
    isObservingPhotoLibrary = false
  }

  private func getImageData(for asset: PHAsset) async -> Data? {
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
}

// MARK: - PHPhotoLibraryChangeObserver

extension PhotoSyncService: PHPhotoLibraryChangeObserver {
  nonisolated func photoLibraryDidChange(_ changeInstance: PHChange) {
    Task { @MainActor in
      // Only sync if auto-sync is enabled
      guard autoSyncEnabled else { return }

      // Trigger sync on photo library changes
      await syncNewPhotos()
    }
  }
}
