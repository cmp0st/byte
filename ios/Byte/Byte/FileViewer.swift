//
//  FileViewer.swift
//  Byte
//
//  Created by Nathan Smith on 10/5/25.
//

import ByteClient
import PDFKit
import SwiftUI

struct FileViewer: View {
  let file: Files_V1_FileInfo
  let data: Data
  @Environment(\.dismiss)
  private var dismiss

  var body: some View {
    NavigationView {
      VStack {
        if isImage {
          if let uiImage = UIImage(data: data) {
            ScrollView([.horizontal, .vertical]) {
              Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
            }
          } else {
            Text("Failed to load image")
              .foregroundColor(.red)
          }
        } else if isPDF {
          PDFViewer(data: data)
        } else {
          VStack(spacing: 20) {
            Image(systemName: "doc.text")
              .font(.system(size: 60))
              .foregroundColor(.gray)

            Text("Preview not available")
              .font(.headline)

            Text(file.name)
              .font(.caption)
              .foregroundColor(.secondary)

            ShareLink(item: data, preview: SharePreview(file.name)) {
              Label("Share or Save", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(.bordered)
          }
          .padding()
        }
      }
      .navigationTitle(file.name)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("Done") {
            dismiss()
          }
        }

        if isImage || isPDF {
          ToolbarItem(placement: .navigationBarTrailing) {
            ShareLink(item: data, preview: SharePreview(file.name)) {
              Image(systemName: "square.and.arrow.up")
            }
          }
        }
      }
    }
  }

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

class PDFKitView: PDFView {}
