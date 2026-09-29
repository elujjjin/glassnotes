import SwiftUI
import UIKit

/// A `UITextView`-backed editor that publishes its selection.
///
/// SwiftUI's `TextEditor` gives no way to read the caret or the current
/// selection, which makes a formatting toolbar impossible: every insertion has
/// to go to the end of the document. Wrapping `UITextView` exposes both, so
/// `FormattingBar` can act on what the user actually selected.
struct MarkdownTextEditor: UIViewRepresentable {
    @Binding var text: String
    @Binding var selection: NSRange

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.delegate = context.coordinator
        view.backgroundColor = .clear
        view.font = .systemFont(ofSize: 16)
        view.textColor = .white
        view.tintColor = .white
        view.keyboardDismissMode = .interactive
        view.textContainerInset = UIEdgeInsets(top: 8, left: 4, bottom: 8, right: 4)
        view.adjustsFontForContentSizeCategory = true
        view.isScrollEnabled = false
        // Markdown punctuation should not be auto-corrected or "smart"-quoted.
        view.autocorrectionType = .no
        view.smartQuotesType = .no
        view.smartDashesType = .no
        view.smartInsertDeleteType = .no
        view.accessibilityLabel = "Note body"
        view.text = text
        return view
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.textColor = .white
        uiView.tintColor = .white
        uiView.backgroundColor = .clear

        let length = text.utf16.count

        // Apply a text change first, since it can invalidate the stored range.
        if uiView.text != text {
            let caret = uiView.selectedRange.location
            uiView.text = text
            uiView.selectedRange = NSRange(location: min(caret, length), length: 0)
        }

        // Then honour a selection that came from the formatting bar.
        let wantedLocation = min(max(0, selection.location), length)
        let wanted = NSRange(
            location: wantedLocation,
            length: min(max(0, selection.length), length - wantedLocation)
        )
        if uiView.selectedRange != wanted {
            uiView.selectedRange = wanted
        }
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        private let parent: MarkdownTextEditor

        init(_ parent: MarkdownTextEditor) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            guard textView.text != parent.text else { return }
            parent.text = textView.text
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            guard parent.selection != textView.selectedRange else { return }
            parent.selection = textView.selectedRange
        }
    }
}
