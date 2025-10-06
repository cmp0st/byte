//
//  FilesView.swift
//  Byte
//
//  Created by Nathan Smith on 10/4/25.
//

import ByteClient
import SwiftUI

/// Main view for browsing and managing files
struct FilesView: View {
  // MARK: - Properties

  @EnvironmentObject var appState: AppState
  @StateObject private var viewModel = FilesViewModel()
  @State private var showingCreateDirectory = false
  @State private var entryToDelete: Files_V1_FileInfo?
  @State private var showingDeleteConfirmation = false
  @State private var showingFilePicker = false
  @State private var selectedFileToView: Files_V1_FileInfo?
  @State private var showingFileViewer = false

  // MARK: - Body

  var body: some View {
    NavigationView {
      List {
        contentSection
        errorSection
        uploadProgressSection
      }
      .navigationTitle(viewModel.currentPath)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          actionsMenu
        }

        ToolbarItem(placement: .navigationBarLeading) {
          leadingButton
        }
      }
      .sheet(isPresented: $showingCreateDirectory) {
        createDirectorySheet
      }
      .sheet(isPresented: $showingFilePicker) {
        filePickerSheet
      }
      .sheet(isPresented: $showingFileViewer) {
        fileViewerSheet
      }
      .onAppear(perform: handleOnAppear)
      .alert(deleteAlertTitle, isPresented: $showingDeleteConfirmation) {
        deleteAlertButtons
      } message: {
        deleteAlertMessage
      }
    }
    .accessibilityElement(children: .contain)
    .accessibilityLabel("Files Browser")
  }

  // MARK: - View Components

  @ViewBuilder private var contentSection: some View {
    if viewModel.isLoading {
      loadingView
    } else if viewModel.entries.isEmpty {
      emptyStateView
    } else {
      filesList
    }
  }

  private var loadingView: some View {
    HStack {
      ProgressView()
      Text("Loading...")
    }
    .padding()
    .accessibilityElement(children: .combine)
    .accessibilityLabel("Loading directory contents")
  }

  private var emptyStateView: some View {
    Text("Directory is empty")
      .foregroundColor(.secondary)
      .padding()
      .accessibilityLabel("This directory is empty")
  }

  private var filesList: some View {
    ForEach(viewModel.entries, id: \.path) { entry in
      FileRow(entry: entry, onTap: { handleFileTap(entry) })
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
          deleteSwipeAction(for: entry)
        }
    }
  }

  private func deleteSwipeAction(for entry: Files_V1_FileInfo) -> some View {
    Button(role: .destructive) {
      entryToDelete = entry
      showingDeleteConfirmation = true
    } label: {
      Label("Delete", systemImage: "trash")
    }
    .accessibilityLabel("Delete \(entry.name)")
  }

  @ViewBuilder private var errorSection: some View {
    if let error = viewModel.error {
      Section {
        Text(error)
          .foregroundColor(.red)
          .font(.caption)
      }
      .accessibilityLabel("Error: \(error)")
    }
  }

  @ViewBuilder private var uploadProgressSection: some View {
    if viewModel.isUploading {
      Section(header: Text("Uploading")) {
        ForEach(
          viewModel.uploadProgress.sorted(by: { $0.key < $1.key }),
          id: \.key
        ) { filename, progress in
          uploadProgressRow(filename: filename, progress: progress)
        }
      }
    }
  }

  private func uploadProgressRow(filename: String, progress: Double) -> some View {
    HStack {
      Text(filename)
        .font(.caption)
      Spacer()
      ProgressView(value: progress)
        .frame(width: 100)
      Text("\(Int(progress * 100))%")
        .font(.caption2)
        .foregroundColor(.secondary)
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel("Uploading \(filename), \(Int(progress * 100)) percent complete")
  }

  private var actionsMenu: some View {
    Menu {
      Button {
        showingCreateDirectory = true
      } label: {
        Label("New Folder", systemImage: "folder.badge.plus")
      }
      .accessibilityLabel("Create new folder")

      Button {
        showingFilePicker = true
      } label: {
        Label("Upload File", systemImage: "arrow.up.doc")
      }
      .accessibilityLabel("Upload file")
    } label: {
      Image(systemName: "plus.circle")
        .accessibilityLabel("Add files or folders")
    }
  }

  private var leadingButton: some View {
    Group {
      if viewModel.currentPath != AppConstants.Files.rootPath {
        Button("Back", action: handleBackButton)
          .accessibilityLabel("Go back to parent directory")
      } else {
        Button("Refresh", action: handleRefresh)
          .accessibilityLabel("Refresh directory")
      }
    }
  }

  private var createDirectorySheet: some View {
    CreateDirectoryView(currentPath: viewModel.currentPath) { dirName in
      handleCreateDirectory(dirName)
    }
  }

  private var filePickerSheet: some View {
    DocumentPicker(currentPath: viewModel.currentPath) { urls in
      handleFileUpload(urls)
    }
  }

  @ViewBuilder private var fileViewerSheet: some View {
    if let file = selectedFileToView, let data = viewModel.fileData {
      FileViewer(file: file, data: data)
    } else {
      ProgressView("Loading file...")
        .accessibilityLabel("Loading file preview")
    }
  }

  private var deleteAlertTitle: String {
    "Delete \(entryToDelete?.isDir == true ? "Directory" : "File")"
  }

  private var deleteAlertButtons: some View {
    Group {
      Button("Cancel", role: .cancel) {
        entryToDelete = nil
      }
      Button("Delete", role: .destructive, action: handleDelete)
    }
  }

  @ViewBuilder private var deleteAlertMessage: some View {
    if let entry = entryToDelete {
      Text(deleteMessage(for: entry))
    }
  }

  // MARK: - Actions

  private func handleFileTap(_ entry: Files_V1_FileInfo) {
    guard let client = appState.client else { return }

    if entry.isDir {
      viewModel.navigateToDirectory(entry.path, client: client)
    } else {
      selectedFileToView = entry
      showingFileViewer = true
      viewModel.downloadFile(entry, client: client)
    }
  }

  private func handleBackButton() {
    guard let client = appState.client else { return }
    viewModel.navigateUp(client: client)
  }

  private func handleRefresh() {
    guard let client = appState.client else { return }
    viewModel.loadDirectory(client: client)
  }

  private func handleCreateDirectory(_ name: String) {
    guard let client = appState.client else { return }
    viewModel.createDirectory(name: name, client: client)
    showingCreateDirectory = false
  }

  private func handleFileUpload(_ urls: [URL]) {
    guard let client = appState.client else { return }
    viewModel.uploadFiles(urls, client: client)
  }

  private func handleDelete() {
    guard let client = appState.client, let entry = entryToDelete else { return }
    viewModel.deleteEntry(entry, client: client)
    entryToDelete = nil
  }

  private func handleOnAppear() {
    guard let client = appState.client else { return }
    viewModel.loadDirectory(client: client)
  }

  private func deleteMessage(for entry: Files_V1_FileInfo) -> String {
    if entry.isDir {
      return """
        Are you sure you want to delete the directory "\(entry.name)" and all its contents? \
        This action cannot be undone.
        """
    } else {
      return """
        Are you sure you want to delete the file "\(entry.name)"? \
        This action cannot be undone.
        """
    }
  }
}

// MARK: - Preview

#Preview {
  FilesView()
    .environmentObject(AppState())
}
