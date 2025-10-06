//
//  FileRow.swift
//  Byte
//
//  Created by Nathan Smith on 10/5/25.
//

import ByteClient
import SwiftUI

struct FileRow: View {
  let entry: Files_V1_FileInfo
  let onTap: () -> Void

  var body: some View {
    Button(action: onTap) {
      HStack {
        Image(systemName: entry.isDir ? "folder.fill" : "doc.fill")
          .foregroundColor(entry.isDir ? .blue : .gray)

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

        Spacer()

        if entry.isDir {
          Image(systemName: "chevron.right")
            .foregroundColor(.secondary)
        }
      }
    }
  }

  private func formatBytes(_ bytes: Int64) -> String {
    let formatter = ByteCountFormatter()
    formatter.countStyle = .file
    return formatter.string(fromByteCount: bytes)
  }
}
