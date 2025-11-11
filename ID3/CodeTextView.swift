import SwiftUI
import AppKit

struct CodeTextView: NSViewRepresentable {
    @Binding var text: String
    var language: ProgrammingLanguage
    var theme: EditorTheme
    var onTextChange: (String) -> Void = { _ in }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeNSView(context: Context) -> NSView {
        let container = NSView()

        let scrollView = NSScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.backgroundColor = .clear

        let textView = CodeNSTextView()
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainerInset = NSSize(width: 16, height: 18)
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.lineFragmentPadding = 0
        configure(textView: textView, coordinator: context.coordinator)

        scrollView.documentView = textView
        container.addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: container.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        context.coordinator.textView = textView
        context.coordinator.applyHighlight()

        return container
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        guard let textView = context.coordinator.textView else { return }

        if textView.string != text {
            context.coordinator.isUpdatingText = true
            textView.string = text
            context.coordinator.isUpdatingText = false
        }

        configure(textView: textView, coordinator: context.coordinator)
        context.coordinator.parent = self
        context.coordinator.applyHighlight()
    }

    private func configure(textView: NSTextView, coordinator: Coordinator) {
        textView.delegate = coordinator
        textView.isEditable = true
        textView.isSelectable = true
        textView.isRichText = false
        textView.usesFindPanel = true
        textView.allowsUndo = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDataDetectionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.smartInsertDeleteEnabled = false
        textView.font = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        textView.backgroundColor = theme.nsBackgroundColor
        textView.textColor = theme.nsPrimaryTextColor
        textView.insertionPointColor = theme.nsPrimaryTextColor
        textView.drawsBackground = true
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        weak var textView: NSTextView?
        var parent: CodeTextView
        var isUpdatingText = false

        init(parent: CodeTextView) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard !isUpdatingText, let textView = notification.object as? NSTextView else { return }
            let string = textView.string
            parent.text = string
            parent.onTextChange(string)
            applyHighlight()
        }

        func applyHighlight() {
            guard let storage = textView?.textStorage else { return }
            SyntaxHighlighter.highlight(textStorage: storage, language: parent.language, theme: parent.theme)
        }
    }
}

private final class CodeNSTextView: NSTextView {
    override var acceptsFirstResponder: Bool { true }
}
