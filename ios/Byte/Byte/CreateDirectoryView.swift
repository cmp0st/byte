//
//  CreateDirectoryView.swift
//  Byte
//
//  Created by Nathan Smith on 10/5/25.
//

import SwiftUI

struct CreateDirectoryView: View {
  let currentPath: String
  @State private var directoryName = ""
  let onCreate: (String) -> Void
  @Environment(\.dismiss)
  private var dismiss

  var body: some View {
    NavigationView {
      Form {
        Section(header: Text("Directory Information")) {
          TextField("Directory Name", text: $directoryName)

          Text(
            """
            Will be created at: \(currentPath == "/" ? "/" : currentPath)/\
            \(directoryName.isEmpty ? "<name>" : directoryName)
            """
          )
          .font(.caption)
          .foregroundColor(.secondary)
        }
      }
      .navigationTitle("Create Directory")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("Cancel") {
            dismiss()
          }
        }

        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Create") {
            onCreate(directoryName)
            dismiss()
          }
          .disabled(directoryName.isEmpty)
        }
      }
    }
  }
}
