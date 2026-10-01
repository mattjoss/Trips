//
//  TextEditorView.swift
//  Trips
//

import SwiftUI

struct TextEditorView: View {
    @Binding var text: String
    let onSave: () -> Void
    let onCancel: () -> Void

    @State private var internalText: String

    init(text: Binding<String>, onSave: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self._text = text
        self.onSave = onSave
        self.onCancel = onCancel
        self._internalText = State(initialValue: text.wrappedValue)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hue: 0.58, saturation: 0.06, brightness: 0.09)
                    .ignoresSafeArea()

                TextEditor(text: $internalText)
                    .font(.body)
                    .scrollContentBackground(.hidden)
                    .foregroundStyle(.white)
                    .padding(16)
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(16)
            }
            .navigationTitle("Editor")
            .tripsNavigationTitleStyle(.inline)
            .tripsDarkToolbar()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .foregroundStyle(.white.opacity(0.7))
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Save") {
                        text = internalText
                        onSave()
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                }
            }
        }
    }
}
