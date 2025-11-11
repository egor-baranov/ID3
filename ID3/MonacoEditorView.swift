import SwiftUI
import WebKit

struct MonacoEditorView: NSViewRepresentable {
    typealias NSViewType = WKWebView

    var text: Binding<String>
    var language: ProgrammingLanguage
    var theme: EditorTheme
    var onTextChange: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let controller = WKUserContentController()
        controller.add(context.coordinator, name: "monacoBridge")
        config.userContentController = controller

        let webView = WKWebView(frame: .zero, configuration: config)
        context.coordinator.webView = webView
        webView.loadHTMLString(Self.htmlTemplate, baseURL: nil)
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        context.coordinator.parent = self
        context.coordinator.pushState()
    }

    final class Coordinator: NSObject, WKScriptMessageHandler {
        var parent: MonacoEditorView
        weak var webView: WKWebView?
        private var isReady = false

        init(parent: MonacoEditorView) {
            self.parent = parent
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "monacoBridge" else { return }
            guard let dict = message.body as? [String: Any], let type = dict["type"] as? String else { return }

            switch type {
            case "ready":
                isReady = true
                pushState()
            case "change":
                guard let value = dict["value"] as? String else { return }
                if parent.text.wrappedValue != value {
                    parent.text.wrappedValue = value
                    parent.onTextChange(value)
                }
            default:
                break
            }
        }

        func pushState() {
            guard isReady, let webView else { return }
            let value = parent.text.wrappedValue.javascriptEscaped()
            let language = parent.language.monacoIdentifier
            let theme = parent.theme == .dark ? "vs-dark" : "vs"
            let js = "window.__setEditorState({value: '\(value)', language: '\(language)', theme: '\(theme)'});"
            webView.evaluateJavaScript(js, completionHandler: nil)
        }
    }

    private static let htmlTemplate: String = {
        """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset=\"utf-8\" />
            <style>
                html, body, #container { height: 100%; width: 100%; margin: 0; padding: 0; overflow: hidden; background: #1e1e1e; }
            </style>
            <script src=\"https://cdnjs.cloudflare.com/ajax/libs/monaco-editor/0.49.0/min/vs/loader.min.js\"></script>
        </head>
        <body>
            <div id=\"container\"></div>
            <script>
                window.__pendingState = null;
                window.__setEditorState = function(state) {
                    if (window.editor) {
                        const model = window.editor.getModel();
                        if (state.value !== undefined && state.value !== window.editor.getValue()) {
                            const selection = window.editor.getSelection();
                            window.editor.setValue(state.value);
                            if (selection) {
                                window.editor.setSelection(selection);
                            }
                        }
                        if (state.language && window.monaco) {
                            monaco.editor.setModelLanguage(model, state.language);
                        }
                        if (state.theme && window.monaco) {
                            monaco.editor.setTheme(state.theme);
                        }
                    } else {
                        window.__pendingState = state;
                    }
                }

                const requireConfig = {
                    paths: { 'vs': 'https://cdnjs.cloudflare.com/ajax/libs/monaco-editor/0.49.0/min/vs' }
                };
                require.config(requireConfig);
                require(['vs/editor/editor.main'], function() {
                    window.monacoReady = true;
                    window.editor = monaco.editor.create(document.getElementById('container'), {
                        value: '',
                        language: 'plaintext',
                        theme: 'vs',
                        automaticLayout: true,
                        fontSize: 14,
                        minimap: { enabled: false },
                        scrollBeyondLastLine: false,
                        renderWhitespace: 'none'
                    });
                    if (window.__pendingState) {
                        window.__setEditorState(window.__pendingState);
                        window.__pendingState = null;
                    }
                    editor.onDidChangeModelContent(function() {
                        window.webkit?.messageHandlers?.monacoBridge?.postMessage({
                            type: 'change',
                            value: editor.getValue()
                        });
                    });
                    window.webkit?.messageHandlers?.monacoBridge?.postMessage({ type: 'ready' });
                });
            </script>
        </body>
        </html>
        """
    }()
}

private extension ProgrammingLanguage {
    var monacoIdentifier: String {
        switch kind {
        case .swift: return "swift"
        case .javascript, .jsx: return "javascript"
        case .typescript, .tsx: return "typescript"
        case .json: return "json"
        case .css: return "css"
        case .html: return "html"
        case .shell: return "shell"
        case .python: return "python"
        case .ruby: return "ruby"
        case .go: return "go"
        case .csharp: return "csharp"
        case .kotlin: return "kotlin"
        case .java: return "java"
        case .markdown: return "markdown"
        default: return "plaintext"
        }
    }
}

private extension String {
    func javascriptEscaped() -> String {
        replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "")
    }
}
