//
//  PhotosSyncView.swift
//  Byte
//
//  Created by Nathan Smith on 10/4/25.
//

import SwiftUI
import Photos
import ByteClient

struct PhotosSyncView: View {
    @EnvironmentObject var appState: AppState
    @State private var photos: [PHAsset] = []
    @State private var selectedPhotos: Set<String> = []
    @State private var isLoading = false
    @State private var uploadProgress: [String: Double] = [:]
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var authorizationStatus: PHAuthorizationStatus = .notDetermined

    var body: some View {
        NavigationView {
            VStack {
                if authorizationStatus == .authorized || authorizationStatus == .limited {
                    if photos.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            Text("No photos found")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        photoGrid

                        if !selectedPhotos.isEmpty {
                            syncButton
                        }
                    }
                } else {
                    photoPermissionView
                }

                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                }

                if let success = successMessage {
                    Text(success)
                        .foregroundColor(.green)
                        .padding()
                }
            }
            .navigationTitle("Photo Sync")
            .toolbar {
                if !selectedPhotos.isEmpty {
                    Button("Clear") {
                        selectedPhotos.removeAll()
                    }
                }
            }
            .onAppear {
                checkPhotoPermission()
            }
        }
    }

    var photoGrid: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10) {
                ForEach(photos, id: \.localIdentifier) { asset in
                    PhotoThumbnail(
                        asset: asset,
                        isSelected: selectedPhotos.contains(asset.localIdentifier),
                        uploadProgress: uploadProgress[asset.localIdentifier]
                    )
                    .onTapGesture {
                        toggleSelection(asset)
                    }
                }
            }
            .padding()
        }
    }

    var syncButton: some View {
        Button(action: {
            Task {
                await syncPhotos()
            }
        }) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
                Text("Sync \(selectedPhotos.count) Photo\(selectedPhotos.count == 1 ? "" : "s")")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .disabled(isLoading)
        .padding()
    }

    var photoPermissionView: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(.orange)

            Text("Photo Access Required")
                .font(.headline)

            Text("Allow access to your photos to sync them to the server")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            Button("Allow Access") {
                requestPhotoPermission()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    func checkPhotoPermission() {
        authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)

        if authorizationStatus == .authorized || authorizationStatus == .limited {
            loadPhotos()
        }
    }

    func requestPhotoPermission() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            DispatchQueue.main.async {
                authorizationStatus = status
                if status == .authorized || status == .limited {
                    loadPhotos()
                }
            }
        }
    }

    func loadPhotos() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = 100

        let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        var loadedPhotos: [PHAsset] = []

        fetchResult.enumerateObjects { asset, _, _ in
            loadedPhotos.append(asset)
        }

        photos = loadedPhotos
    }

    func toggleSelection(_ asset: PHAsset) {
        if selectedPhotos.contains(asset.localIdentifier) {
            selectedPhotos.remove(asset.localIdentifier)
        } else {
            selectedPhotos.insert(asset.localIdentifier)
        }
    }

    func syncPhotos() async {
        guard let client = appState.client else {
            errorMessage = "Client not configured"
            return
        }

        isLoading = true
        errorMessage = nil
        successMessage = nil

        let assetsToSync = photos.filter { selectedPhotos.contains($0.localIdentifier) }
        var successCount = 0

        for asset in assetsToSync {
            do {
                uploadProgress[asset.localIdentifier] = 0.1

                // Get image data
                guard let imageData = await getImageData(for: asset) else {
                    errorMessage = "Failed to load image data"
                    continue
                }

                uploadProgress[asset.localIdentifier] = 0.5

                // Create filename
                let filename = asset.value(forKey: "filename") as? String ?? "photo_\(asset.localIdentifier).jpg"

                // Upload to server using WriteFile RPC
                var request = Files_V1_WriteFileRequest()
                request.path = "/photos/\(filename)"
                request.data = imageData
                request.createParents = true

                _ = await client.files.writeFile(request: request, headers: [:])

                uploadProgress[asset.localIdentifier] = 1.0
                successCount += 1
                selectedPhotos.remove(asset.localIdentifier)
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

    func getImageData(for asset: PHAsset) async -> Data? {
        await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.isSynchronous = false
            options.deliveryMode = .highQualityFormat

            PHImageManager.default().requestImageDataAndOrientation(for: asset, options: options) { data, _, _, _ in
                continuation.resume(returning: data)
            }
        }
    }
}

struct PhotoThumbnail: View {
    let asset: PHAsset
    let isSelected: Bool
    let uploadProgress: Double?
    @State private var image: UIImage?

    var body: some View {
        ZStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .clipped()
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
                    )
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 100, height: 100)
                    .cornerRadius(8)
            }

            if isSelected {
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                            .background(Circle().fill(Color.white))
                            .padding(4)
                    }
                    Spacer()
                }
                .frame(width: 100, height: 100)
            }

            if let progress = uploadProgress, progress > 0 && progress < 1 {
                ProgressView(value: progress)
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
            }
        }
        .onAppear {
            loadThumbnail()
        }
    }

    func loadThumbnail() {
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.isSynchronous = false

        manager.requestImage(
            for: asset,
            targetSize: CGSize(width: 200, height: 200),
            contentMode: .aspectFill,
            options: options
        ) { result, _ in
            if let result = result {
                self.image = result
            }
        }
    }
}

#Preview {
    PhotosSyncView()
        .environmentObject(AppState())
}
