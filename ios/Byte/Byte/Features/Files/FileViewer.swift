//
//  FileViewer.swift
//  Byte
//
//  Created by Nathan Smith on 10/5/25.
//

import ByteClient
import PDFKit
import SwiftUI

/// View for previewing files
struct FileViewer: View {
  // MARK: - Properties

  let file: Files_V1_FileInfo
  let data: Data
  @Environment(\.dismiss)
  private var dismiss

  // MARK: - Body

  var body: some View {
    NavigationView {
      contentView
        .navigationTitle(file.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          leadingToolbarItem
          trailingToolbarItem
        }
    }
    .accessibilityElement(children: .contain)
    .accessibilityLabel("File preview for \(file.name)")
  }

  // MARK: - View Components

  @ViewBuilder private var contentView: some View {
    if isImage {
      imageView
    } else if isPDF {
      PDFViewer(data: data)
    } else {
      unsupportedPreviewView
    }
  }

  @ViewBuilder private var imageView: some View {
    if let uiImage = UIImage(data: data) {
      ScrollView([.horizontal, .vertical]) {
        Image(uiImage: uiImage)
          .resizable()
          .aspectRatio(contentMode: .fit)
      }
      .accessibilityLabel("Image: \(file.name)")
      .accessibilityAddTraits(.isImage)
    } else {
      errorView
    }
  }

  private var errorView: some View {
    Text("Failed to load image")
      .foregroundColor(.red)
      .accessibilityLabel("Error: Failed to load image")
  }

  private var unsupportedPreviewView: some View {
    VStack(spacing: 20) {
      Image(systemName: "doc.text")
        .font(.system(size: 60))
        .foregroundColor(.gray)
        .accessibilityHidden(true)

      Text("Preview not available")
        .font(.headline)

      Text(file.name)
        .font(.caption)
        .foregroundColor(.secondary)

      ShareLink(item: data, preview: SharePreview(file.name)) {
        Label("Share or Save", systemImage: "square.and.arrow.up")
      }
      .buttonStyle(.bordered)
      .accessibilityLabel("Share or save \(file.name)")
    }
    .padding()
  }

  private var leadingToolbarItem: some ToolbarContent {
    ToolbarItem(placement: .navigationBarLeading) {
      Button("Done", action: { dismiss() })
        .accessibilityLabel("Close file preview")
    }
  }

  @ToolbarContentBuilder private var trailingToolbarItem: some ToolbarContent {
    if isImage || isPDF {
      ToolbarItem(placement: .navigationBarTrailing) {
        ShareLink(item: data, preview: SharePreview(file.name)) {
          Image(systemName: "square.and.arrow.up")
        }
        .accessibilityLabel("Share \(file.name)")
      }
    }
  }

  // MARK: - Helper Properties

  private var isImage: Bool {
    let imageExtensions = ["jpg", "jpeg", "png", "gif", "heic", "heif", "bmp", "tiff"]
    let ext = (file.name as NSString).pathExtension.lowercased()
    return imageExtensions.contains(ext)
  }

  private var isPDF: Bool {
    let ext = (file.name as NSString).pathExtension.lowercased()
    return ext == "pdf"
  }
}

// MARK: - PDF Viewer

struct PDFViewer: UIViewRepresentable {
  let data: Data

  func makeUIView(context: Context) -> PDFKitView {
    let view = PDFKitView()
    view.document = PDFDocument(data: data)
    view.autoScales = true
    return view
  }

  func updateUIView(_ uiView: PDFKitView, context: Context) {}
}

final class PDFKitView: PDFView {}
