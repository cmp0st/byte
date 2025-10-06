//
//  FilesView.swift
//  Byte
//
//  Created by Nathan Smith on 10/4/25.
//

import ByteClient
import Connect
import PDFKit
import SwiftUI
import UniformTypeIdentifiers

struct FilesView: View {
  @EnvironmentObject var appState: AppState
  @StateObject private var viewModel = FilesViewModel()
  @State private var showingCreateDirectory = false
  @State private var entryToDelete: Files_V1_FileInfo?
  @State private var showingDeleteConfirmation = false
  @State private var showingFilePicker = false
  @State private var selectedFileToView: Files_V1_FileInfo?
  @State private var showingFileViewer = false

  var body: some View {
    NavigationView {
      List {
        if viewModel.isLoading {
          HStack {
            ProgressView()
            Text("Loading...")
          }
          .padding()
        } else if viewModel.entries.isEmpty {
          Text("Directory is empty")
            .foregroundColor(.secondary)
            .padding()
        } else {
          ForEach(viewModel.entries, id: \.path) { entry in
            FileRow(entry: entry) {
              handleFileTap(entry)
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
              Button(role: .destructive) {
                entryToDelete = entry
                showingDeleteConfirmation = true
              } label: {
                Label("Delete", systemImage: "trash")
              }
            }
          }
        }

        if let error = viewModel.error {
          Section {
            Text(error)
              .foregroundColor(.red)
              .font(.caption)
          }
        }

        if viewModel.isUploading {
          Section(header: Text("Uploading")) {
            ForEach(viewModel.uploadProgress.sorted(by: { $0.key < $1.key }), id: \.key) { filename, progress in
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
            }
          }
        }
      }
      .navigationTitle(viewModel.currentPath)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Menu {
            Button {
              showingCreateDirectory = true
            } label: {
              Label("New Folder", systemImage: "folder.badge.plus")
            }

            Button {
              showingFilePicker = true
            } label: {
              Label("Upload File", systemImage: "arrow.up.doc")
            }
          } label: {
            Image(systemName: "plus.circle")
          }
        }

        ToolbarItem(placement: .navigationBarLeading) {
          if viewModel.currentPath != "/" {
            Button("Back") {
              handleBackButton()
            }
          } else {
            Button("Refresh") {
              handleRefresh()
            }
          }
        }
      }
      .sheet(isPresented: $showingCreateDirectory) {
        CreateDirectoryView(currentPath: viewModel.currentPath) { dirName in
          handleCreateDirectory(dirName)
        }
      }
      .sheet(isPresented: $showingFilePicker) {
        DocumentPicker(currentPath: viewModel.currentPath) { urls in
          handleFileUpload(urls)
        }
      }
      .sheet(isPresented: $showingFileViewer) {
        if let file = selectedFileToView, let data = viewModel.fileData {
          FileViewer(file: file, data: data)
        } else {
          ProgressView("Loading file...")
        }
      }
      .onAppear {
        handleOnAppear()
      }
      .alert(
        "Delete \(entryToDelete?.isDir == true ? "Directory" : "File")",
        isPresented: $showingDeleteConfirmation
      ) {
        Button("Cancel", role: .cancel) {
          entryToDelete = nil
        }
        Button("Delete", role: .destructive) {
          handleDelete()
        }
      } message: {
        if let entry = entryToDelete {
          Text(deleteMessage(for: entry))
        }
      }
    }
  }

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

#Preview {
  FilesView()
    .environmentObject(AppState())
}
