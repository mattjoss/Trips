//
//  MarkdownTextEditor.swift
//  Trips
//

import SwiftUI
#if os(iOS)
import UIKit

struct MarkdownTextEditor: UIViewRepresentable {
    @Binding var text: String
    @Binding var selection: NSRange

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.backgroundColor = .clear
        textView.textColor = .white
        textView.tintColor = .white
        textView.font = .preferredFont(forTextStyle: .body)
        textView.adjustsFontForContentSizeCategory = true
        textView.keyboardDismissMode = .interactive
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.smartDashesType = .no
        textView.smartQuotesType = .no
        textView.text = text
        DispatchQueue.main.async {
            textView.becomeFirstResponder()
        }
        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        context.coordinator.parent = self
        if textView.text != text { textView.text = text }
        let safeSelection = selection.clamped(toUTF16Length: (text as NSString).length)
        if textView.selectedRange != safeSelection { textView.selectedRange = safeSelection }
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: MarkdownTextEditor

        init(parent: MarkdownTextEditor) { self.parent = parent }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
            parent.selection = textView.selectedRange
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            guard parent.selection != textView.selectedRange else { return }
            parent.selection = textView.selectedRange
        }
    }
}

#else
import AppKit

struct MarkdownTextEditor: NSViewRepresentable {
    @Binding var text: String
    @Binding var selection: NSRange

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView
        textView.delegate = context.coordinator
        textView.backgroundColor = .clear
        scrollView.drawsBackground = false
        textView.drawsBackground = false
        textView.textColor = .white
        textView.insertionPointColor = .white
        textView.font = .systemFont(ofSize: NSFont.systemFontSize)
        textView.isRichText = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.textContainerInset = NSSize(width: 4, height: 4)
        textView.string = text
        DispatchQueue.main.async { textView.window?.makeFirstResponder(textView) }
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        context.coordinator.parent = self
        if textView.string != text { textView.string = text }
        let range = selection.clamped(toUTF16Length: (text as NSString).length)
        if textView.selectedRange() != range { textView.setSelectedRange(range) }
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: MarkdownTextEditor
        init(parent: MarkdownTextEditor) { self.parent = parent }
        func textDidChange(_ notification: Notification) {
            guard let view = notification.object as? NSTextView else { return }
            parent.text = view.string
            parent.selection = view.selectedRange()
        }
        func textViewDidChangeSelection(_ notification: Notification) {
            guard let view = notification.object as? NSTextView else { return }
            if parent.selection != view.selectedRange() { parent.selection = view.selectedRange() }
        }
    }
}
#endif

enum MarkdownCommand {
    case bold
    case italic
    case inlineCode
    case link
    case heading(Int)
    case bulletedList
    case numberedList
    case quote

    func apply(to text: String, selection: NSRange) -> (text: String, selection: NSRange) {
        switch self {
        case .bold: applyInline(marker: "**", to: text, selection: selection)
        case .italic: applyInline(marker: "*", to: text, selection: selection)
        case .inlineCode: applyInline(marker: "`", to: text, selection: selection)
        case .link: applyLink(to: text, selection: selection)
        case .heading(let level):
            applyLinePrefix(String(repeating: "#", count: min(max(level, 1), 6)) + " ", numbered: false, to: text, selection: selection)
        case .bulletedList: applyLinePrefix("- ", numbered: false, to: text, selection: selection)
        case .numberedList: applyLinePrefix("1. ", numbered: true, to: text, selection: selection)
        case .quote: applyLinePrefix("> ", numbered: false, to: text, selection: selection)
        }
    }

    private func applyInline(marker: String, to text: String, selection: NSRange) -> (String, NSRange) {
        let source = text as NSString
        let range = selection.clamped(toUTF16Length: source.length)
        let markerLength = (marker as NSString).length

        let markersAreUnambiguous = marker != "*" || (
            (range.location < 2 || source.substring(with: NSRange(location: range.location - 2, length: 1)) != "*") &&
            (NSMaxRange(range) + 1 >= source.length || source.substring(with: NSRange(location: NSMaxRange(range) + 1, length: 1)) != "*")
        )

        if markersAreUnambiguous,
           range.location >= markerLength,
           NSMaxRange(range) + markerLength <= source.length,
           source.substring(with: NSRange(location: range.location - markerLength, length: markerLength)) == marker,
           source.substring(with: NSRange(location: NSMaxRange(range), length: markerLength)) == marker {
            let expanded = NSRange(location: range.location - markerLength, length: range.length + markerLength * 2)
            let mutable = NSMutableString(string: text)
            mutable.replaceCharacters(in: expanded, with: source.substring(with: range))
            return (mutable as String, NSRange(location: range.location - markerLength, length: range.length))
        }

        let selectedText = source.substring(with: range)
        let mutable = NSMutableString(string: text)
        mutable.replaceCharacters(in: range, with: marker + selectedText + marker)
        return (mutable as String, NSRange(location: range.location + markerLength, length: range.length))
    }

    private func applyLink(to text: String, selection: NSRange) -> (String, NSRange) {
        let source = text as NSString
        let range = selection.clamped(toUTF16Length: source.length)
        let label = range.length == 0 ? "link text" : source.substring(with: range)
        let replacement = "[\(label)](https://)"
        let mutable = NSMutableString(string: text)
        mutable.replaceCharacters(in: range, with: replacement)
        if range.length == 0 {
            return (mutable as String, NSRange(location: range.location + 1, length: (label as NSString).length))
        }
        return (mutable as String, NSRange(location: range.location + (replacement as NSString).length - 9, length: 8))
    }

    private func applyLinePrefix(_ prefix: String, numbered: Bool, to text: String, selection: NSRange) -> (String, NSRange) {
        let source = text as NSString
        let range = selection.clamped(toUTF16Length: source.length)
        let lineRange = source.lineRange(for: range)
        let selectedLines = source.substring(with: lineRange)
        let keepsTrailingNewline = selectedLines.hasSuffix("\n")
        var lines = selectedLines.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        if keepsTrailingNewline, lines.last == "" { lines.removeLast() }

        let allHavePrefix = !lines.isEmpty && lines.allSatisfy { line in
            numbered ? line.range(of: #"^\d+\. "#, options: .regularExpression) != nil : line.hasPrefix(prefix)
        }
        var changedBy = 0
        for index in lines.indices {
            let originalLength = (lines[index] as NSString).length
            if allHavePrefix {
                if numbered, let match = lines[index].range(of: #"^\d+\. "#, options: .regularExpression) {
                    lines[index].removeSubrange(match)
                } else if lines[index].hasPrefix(prefix) {
                    lines[index].removeFirst(prefix.count)
                }
            } else {
                lines[index] = normalizedLine(lines[index], for: prefix, numbered: numbered, lineNumber: index + 1)
            }
            changedBy += (lines[index] as NSString).length - originalLength
        }

        var replacement = lines.joined(separator: "\n")
        if keepsTrailingNewline { replacement += "\n" }
        let mutable = NSMutableString(string: text)
        mutable.replaceCharacters(in: lineRange, with: replacement)
        return (mutable as String, NSRange(location: lineRange.location, length: max(0, lineRange.length + changedBy)))
    }

    private func normalizedLine(_ line: String, for prefix: String, numbered: Bool, lineNumber: Int) -> String {
        var content = line
        if prefix.hasPrefix("#"), let match = content.range(of: #"^#{1,6} "#, options: .regularExpression) {
            content.removeSubrange(match)
        } else if numbered, let match = content.range(of: #"^\d+\. "#, options: .regularExpression) {
            content.removeSubrange(match)
        }
        return numbered ? "\(lineNumber). \(content)" : prefix + content
    }
}

private extension NSRange {
    func clamped(toUTF16Length length: Int) -> NSRange {
        let safeLocation = min(max(location, 0), length)
        return NSRange(location: safeLocation, length: min(max(self.length, 0), length - safeLocation))
    }
}
