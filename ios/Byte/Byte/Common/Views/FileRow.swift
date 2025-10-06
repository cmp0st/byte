//
//  FileRow.swift
//  Byte
//
//  Created by Nathan Smith on 10/5/25.
//

import ByteClient
import SwiftUI

/// Row view for displaying file/directory information
struct FileRow: View {
  // MARK: - Properties

  let entry: Files_V1_FileInfo
  let onTap: () -> Void

  // MARK: - Body

  var body: some View {
    Button(action: onTap) {
      HStack {
        icon
        textContent
        Spacer()
        chevronIfDirectory
      }
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel(accessibilityText)
    .accessibilityHint(accessibilityHint)
  }

  // MARK: - View Components

  private var icon: some View {
    Image(systemName: entry.isDir ? "folder.fill" : "doc.fill")
      .foregroundColor(entry.isDir ? .blue : .gray)
      .accessibilityHidden(true)
  }

  private var textContent: some View {
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
  }

  @ViewBuilder private var chevronIfDirectory: some View {
    if entry.isDir {
      Image(systemName: "chevron.right")
        .foregroundColor(.secondary)
        .accessibilityHidden(true)
    }
  }

  // MARK: - Accessibility

  private var accessibilityText: String {
    if entry.isDir {
      return "Folder: \(entry.name)"
    } else {
      return "File: \(entry.name), size: \(formatBytes(entry.size))"
    }
  }

  private var accessibilityHint: String {
    if entry.isDir {
      return "Double tap to open folder"
    } else {
      return "Double tap to preview file"
    }
  }

  // MARK: - Helper Methods

  private func formatBytes(_ bytes: Int64) -> String {
    let formatter = ByteCountFormatter()
    formatter.countStyle = .file
    return formatter.string(fromByteCount: bytes)
  }
}
