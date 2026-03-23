//
//  ScanButton.swift
//  KrishnaGPT
//
//  Created by Saurabh Dave on 2/7/23.
//

import SwiftUI

struct ScanButton: View {

    @Binding var text: String

    var body: some View {
        CameraKeyInputButton(text: $text)
            .frame(width: 30, height: 30)
            .accessibilityLabel("Scan text from camera")
            .accessibilityHint("Opens the camera to scan text and insert it into the message")
    }
}

// MARK: - UIKit bridge for UIAction.captureTextFromCamera

private struct CameraKeyInputButton: UIViewRepresentable {

    @Binding var text: String

    func makeUIView(context: Context) -> UIButton {
        let textFromCamera = UIAction.captureTextFromCamera(
            responder: context.coordinator,
            identifier: nil)
        let button = UIButton(type: .system)
        button.setImage(
            UIImage(systemName: "camera.badge.ellipsis"),
            for: .normal)
        button.menu = UIMenu(children: [textFromCamera])
        button.showsMenuAsPrimaryAction = true
        // Accessibility is handled by the parent SwiftUI view.
        button.isAccessibilityElement = false
        return button
    }

    func updateUIView(_ uiView: UIButton, context: Context) { }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: UIResponder, UIKeyInput {
        let parent: CameraKeyInputButton
        init(_ parent: CameraKeyInputButton) { self.parent = parent }

        var hasText = false
        func insertText(_ text: String) {
            parent.text = text
        }
        func deleteBackward() { }
    }
}

#Preview {
    ScanButton(text: .constant(""))
}
