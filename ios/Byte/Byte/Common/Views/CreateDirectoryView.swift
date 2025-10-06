//
//  CreateDirectoryView.swift
//  Byte
//
//  Created by Nathan Smith on 10/5/25.
//

import SwiftUI

/// View for creating a new directory
struct CreateDirectoryView: View {
  // MARK: - Properties

  let currentPath: String
  let onCreate: (String) -> Void

  @State private var directoryName = ""
  @Environment(\.dismiss)
  private var dismiss

  // MARK: - Body

  var body: some View {
    NavigationView {
      Form {
        directoryInfoSection
      }
      .navigationTitle("Create Directory")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        leadingToolbarItem
        trailingToolbarItem
      }
    }
    .accessibilityElement(children: .contain)
    .accessibilityLabel("Create new directory")
  }

  // MARK: - View Components

  private var directoryInfoSection: some View {
    Section(header: Text("Directory Information")) {
      TextField("Directory Name", text: $directoryName)
        .accessibilityLabel("Directory name input")

      Text(previewPath)
        .font(.caption)
        .foregroundColor(.secondary)
        .accessibilityLabel("Directory will be created at: \(previewPath)")
    }
  }

  private var leadingToolbarItem: some ToolbarContent {
    ToolbarItem(placement: .navigationBarLeading) {
      Button("Cancel") {
        dismiss()
      }
      .accessibilityLabel("Cancel directory creation")
    }
  }

  private var trailingToolbarItem: some ToolbarContent {
    ToolbarItem(placement: .navigationBarTrailing) {
      Button("Create") {
        onCreate(directoryName)
        dismiss()
      }
      .disabled(directoryName.isEmpty)
      .accessibilityLabel("Create directory")
      .accessibilityHint(directoryName.isEmpty ? "Enter a directory name first" : "")
    }
  }

  // MARK: - Helper Properties

  private var previewPath: String {
    let separator = currentPath == AppConstants.Files.rootPath ? "" : "/"
    let name = directoryName.isEmpty ? "<name>" : directoryName
    return "Will be created at: \(currentPath)\(separator)\(name)"
  }
}
