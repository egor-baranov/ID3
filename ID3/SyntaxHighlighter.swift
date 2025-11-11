import Foundation
import AppKit

struct ProgrammingLanguage: Equatable {
    enum Kind {
        case swift, javascript, typescript, jsx, tsx, json, css, html, shell, python, ruby, go, csharp, kotlin, java, markdown, plain
    }

    let kind: Kind

    init(fileURL: URL?) {
        guard let ext = fileURL?.pathExtension.lowercased() else {
            kind = .plain
            return
        }

        switch ext {
        case "swift": kind = .swift
        case "js": kind = .javascript
        case "ts": kind = .typescript
        case "jsx": kind = .jsx
        case "tsx": kind = .tsx
        case "json": kind = .json
        case "css": kind = .css
        case "html", "htm": kind = .html
        case "sh", "bash", "zsh": kind = .shell
        case "py": kind = .python
        case "rb": kind = .ruby
        case "go": kind = .go
        case "cs": kind = .csharp
        case "kt", "kts": kind = .kotlin
        case "java": kind = .java
        case "md": kind = .markdown
        default: kind = .plain
        }
    }

    var keywords: [String] {
        switch kind {
        case .swift:
            return ["class", "struct", "enum", "func", "let", "var", "if", "else", "guard", "for", "while", "return", "import", "switch", "case", "protocol", "extension", "init", "where"]
        case .javascript, .typescript, .jsx, .tsx:
            return ["const", "let", "var", "function", "return", "if", "else", "import", "from", "export", "class", "extends", "new", "switch", "case", "break", "continue", "await", "async", "yield"]
        case .css:
            return ["var", "@media", "@import", "@keyframes"]
        case .shell:
            return ["if", "then", "fi", "else", "elif", "do", "done", "case", "esac", "function"]
        case .python:
            return ["def", "class", "return", "import", "from", "if", "elif", "else", "for", "while", "try", "except", "with", "as", "pass", "break", "continue", "lambda", "yield"]
        case .ruby:
            return ["def", "class", "module", "if", "elsif", "else", "end", "do", "while", "until", "yield", "return", "require", "include"]
        case .go:
            return ["func", "var", "const", "type", "struct", "interface", "if", "else", "for", "range", "return", "import", "package", "switch", "case", "go", "defer"]
        case .csharp:
            return ["class", "struct", "namespace", "using", "public", "private", "protected", "if", "else", "switch", "case", "return", "void", "new", "var", "static"]
        case .kotlin:
            return ["fun", "val", "var", "class", "object", "interface", "if", "else", "when", "return", "import", "package", "sealed", "data", "suspend"]
        case .java:
            return ["class", "interface", "extends", "implements", "public", "private", "protected", "if", "else", "switch", "case", "return", "import", "package", "new", "final", "static"]
        case .html, .json, .markdown, .plain:
            return []
        }
    }

    var singleLineCommentToken: String? {
        switch kind {
        case .swift, .javascript, .typescript, .jsx, .tsx, .java, .csharp, .go:
            return "//"
        case .shell, .python, .ruby:
            return "#"
        default:
            return nil
        }
    }

    var multiLineCommentTokens: (start: String, end: String)? {
        switch kind {
        case .swift, .javascript, .typescript, .jsx, .tsx, .css, .java, .csharp, .go:
            return ("/*", "*/")
        default:
            return nil
        }
    }

    var stringDelimiters: [String] {
        switch kind {
        case .shell:
            return ["\"", "'", "`"]
        case .markdown:
            return ["`"]
        default:
            return ["\"", "'"]
        }
    }
}

enum SyntaxHighlighter {
    static func highlight(textStorage: NSTextStorage, language: ProgrammingLanguage, theme: EditorTheme) {
        let range = NSRange(location: 0, length: textStorage.length)
        let baseAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 14, weight: .regular),
            .foregroundColor: theme.nsPrimaryTextColor
        ]

        textStorage.beginEditing()
        textStorage.setAttributes(baseAttributes, range: range)

        applyStrings(in: textStorage, delimiters: language.stringDelimiters, color: theme.stringColor)
        applyComments(in: textStorage, language: language, color: theme.commentColor)
        applyNumbers(in: textStorage, color: theme.numberColor)
        applyKeywords(in: textStorage, keywords: language.keywords, color: theme.keywordColor)

        textStorage.endEditing()
    }

    private static func applyKeywords(in textStorage: NSTextStorage, keywords: [String], color: NSColor) {
        guard !keywords.isEmpty else { return }
        let escaped = keywords.map { NSRegularExpression.escapedPattern(for: $0) }
        let pattern = "\\b(\(escaped.joined(separator: "|")))\\b"
        applyRegex(pattern, on: textStorage, attributes: [.foregroundColor: color])
    }

    private static func applyComments(in textStorage: NSTextStorage, language: ProgrammingLanguage, color: NSColor) {
        if let token = language.singleLineCommentToken {
            let escaped = NSRegularExpression.escapedPattern(for: token)
            let pattern = "\(escaped).*"
            applyRegex(pattern, on: textStorage, attributes: [.foregroundColor: color])
        }

        if let multi = language.multiLineCommentTokens {
            let start = NSRegularExpression.escapedPattern(for: multi.start)
            let end = NSRegularExpression.escapedPattern(for: multi.end)
            let pattern = "\(start)(.|\\n|\\r)*?\(end)"
            applyRegex(pattern, on: textStorage, attributes: [.foregroundColor: color])
        }
    }

    private static func applyStrings(in textStorage: NSTextStorage, delimiters: [String], color: NSColor) {
        for delimiter in delimiters {
            let escaped = NSRegularExpression.escapedPattern(for: delimiter)
            let pattern = "\(escaped)(?:\\\\.|[^\(escaped)])*?\(escaped)"
            applyRegex(pattern, on: textStorage, attributes: [.foregroundColor: color])
        }
    }

    private static func applyNumbers(in textStorage: NSTextStorage, color: NSColor) {
        let pattern = "\\b\\d+(?:\\.\\d+)?\\b"
        applyRegex(pattern, on: textStorage, attributes: [.foregroundColor: color])
    }

    private static func applyRegex(_ pattern: String, on textStorage: NSTextStorage, attributes: [NSAttributedString.Key: Any]) {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines]) else { return }
        let string = textStorage.string
        let range = NSRange(location: 0, length: (string as NSString).length)
        regex.enumerateMatches(in: string, options: [], range: range) { match, _, _ in
            guard let match = match else { return }
            textStorage.addAttributes(attributes, range: match.range)
        }
    }
}
