//
//  PhotosSyncView.swift
//  Byte
//
//  Created by Nathan Smith on 10/4/25.
//

import Photos
import SwiftUI

/// View for syncing photos to the server
struct PhotosSyncView: View {
  // MARK: - Properties

  @EnvironmentObject var appState: AppState
  @StateObject private var viewModel = PhotosSyncViewModel()

  // MARK: - Body

  var body: some View {
    NavigationView {
      VStack {
        contentView
        messagesSection
      }
      .navigationTitle("Photo Sync")
      .toolbar {
        if !viewModel.selectedPhotos.isEmpty {
          clearButton
        }
      }
      .onAppear(perform: viewModel.checkPhotoPermission)
    }
    .accessibilityElement(children: .contain)
    .accessibilityLabel("Photo Sync")
  }

  // MARK: - View Components

  @ViewBuilder private var contentView: some View {
    if viewModel.authorizationStatus == .authorized || viewModel.authorizationStatus == .limited {
      authorizedContent
    } else {
      photoPermissionView
    }
  }

  @ViewBuilder private var authorizedContent: some View {
    if viewModel.photos.isEmpty {
      emptyStateView
    } else {
      VStack {
        photoGrid
        if !viewModel.selectedPhotos.isEmpty {
          syncButton
        }
      }
    }
  }

  private var emptyStateView: some View {
    VStack(spacing: 20) {
      Image(systemName: "photo.on.rectangle.angled")
        .font(.system(size: 60))
        .foregroundColor(.gray)
        .accessibilityHidden(true)
      Text("No photos found")
        .font(.headline)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .accessibilityLabel("No photos available in library")
  }

  private var photoGrid: some View {
    ScrollView {
      LazyVGrid(
        columns: [GridItem(.adaptive(minimum: AppConstants.UserInterface.thumbnailSize))],
        spacing: 10
      ) {
        ForEach(viewModel.photos, id: \.localIdentifier) { asset in
          PhotoThumbnail(
            asset: asset,
            isSelected: viewModel.selectedPhotos.contains(asset.localIdentifier),
            uploadProgress: viewModel.uploadProgress[asset.localIdentifier],
            viewModel: viewModel
          )
          .onTapGesture {
            viewModel.toggleSelection(asset)
          }
        }
      }
      .padding()
    }
    .accessibilityElement(children: .contain)
    .accessibilityLabel("Photo grid")
  }

  private var syncButton: some View {
    Button {
      Task {
        guard let client = appState.client else { return }
        await viewModel.syncPhotos(client: client)
      }
    } label: {
      HStack {
        if viewModel.isLoading {
          ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: .white))
        }
        Text("Sync \(viewModel.selectedPhotos.count) Photo\(viewModel.selectedPhotos.count == 1 ? "" : "s")")
      }
      .frame(maxWidth: .infinity)
      .padding()
      .background(Color.blue)
      .foregroundColor(.white)
      .cornerRadius(AppConstants.UserInterface.cornerRadius)
    }
    .disabled(viewModel.isLoading)
    .padding()
    .accessibilityLabel("Sync \(viewModel.selectedPhotos.count) selected photos")
    .accessibilityHint(viewModel.isLoading ? "Syncing in progress" : "Double tap to start sync")
  }

  private var photoPermissionView: some View {
    VStack(spacing: 20) {
      Image(systemName: "photo.badge.exclamationmark")
        .font(.system(size: 60))
        .foregroundColor(.orange)
        .accessibilityHidden(true)

      Text("Photo Access Required")
        .font(.headline)

      Text("Allow access to your photos to sync them to the server")
        .multilineTextAlignment(.center)
        .foregroundColor(.secondary)
        .padding(.horizontal)

      Button("Allow Access") {
        viewModel.requestPhotoPermission()
      }
      .buttonStyle(.borderedProminent)
      .accessibilityLabel("Allow photo library access")
      .accessibilityHint("Opens system permission dialog")
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  @ViewBuilder private var messagesSection: some View {
    if let error = viewModel.errorMessage {
      Text(error)
        .foregroundColor(.red)
        .padding()
        .accessibilityLabel("Error: \(error)")
    }

    if let success = viewModel.successMessage {
      Text(success)
        .foregroundColor(.green)
        .padding()
        .accessibilityLabel("Success: \(success)")
    }
  }

  private var clearButton: some ToolbarContent {
    ToolbarItem(placement: .navigationBarTrailing) {
      Button("Clear") {
        viewModel.selectedPhotos.removeAll()
      }
      .accessibilityLabel("Clear photo selection")
    }
  }
}

// MARK: - Photo Thumbnail

struct PhotoThumbnail: View {
  let asset: PHAsset
  let isSelected: Bool
  let uploadProgress: Double?
  let viewModel: PhotosSyncViewModel

  @State private var image: UIImage?

  var body: some View {
    ZStack {
      thumbnailImage

      if isSelected {
        selectionBadge
      }

      if let progress = uploadProgress, progress > 0, progress < 1 {
        uploadProgressView(progress: progress)
      }
    }
    .onAppear(perform: loadThumbnail)
    .accessibilityElement(children: .combine)
    .accessibilityLabel(accessibilityLabel)
    .accessibilityAddTraits(isSelected ? .isSelected : [])
  }

  @ViewBuilder private var thumbnailImage: some View {
    if let image = image {
      Image(uiImage: image)
        .resizable()
        .aspectRatio(contentMode: .fill)
        .frame(width: AppConstants.UserInterface.thumbnailSize, height: AppConstants.UserInterface.thumbnailSize)
        .clipped()
        .cornerRadius(AppConstants.UserInterface.cornerRadius)
        .overlay(
          RoundedRectangle(cornerRadius: AppConstants.UserInterface.cornerRadius)
            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: AppConstants.UserInterface.borderWidth)
        )
    } else {
      Rectangle()
        .fill(Color.gray.opacity(0.3))
        .frame(width: AppConstants.UserInterface.thumbnailSize, height: AppConstants.UserInterface.thumbnailSize)
        .cornerRadius(AppConstants.UserInterface.cornerRadius)
    }
  }

  private var selectionBadge: some View {
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
    .frame(width: AppConstants.UserInterface.thumbnailSize, height: AppConstants.UserInterface.thumbnailSize)
    .accessibilityHidden(true)
  }

  private func uploadProgressView(progress: Double) -> some View {
    ProgressView(value: progress)
      .progressViewStyle(CircularProgressViewStyle())
      .scaleEffect(1.5)
      .accessibilityLabel("Uploading: \(Int(progress * 100))%")
  }

  private var accessibilityLabel: String {
    var label = "Photo"
    if isSelected {
      label += ", selected"
    }
    if let progress = uploadProgress, progress > 0, progress < 1 {
      label += ", uploading \(Int(progress * 100))%"
    }
    return label
  }

  private func loadThumbnail() {
    viewModel.getThumbnail(for: asset) { result in
      if let result = result {
        self.image = result
      }
    }
  }
}

// MARK: - Preview

#Preview {
  PhotosSyncView()
    .environmentObject(AppState())
}
