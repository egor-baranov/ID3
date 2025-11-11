import SwiftUI
import WebKit

struct WorkbenchWebView: NSViewRepresentable {
    typealias NSViewType = WKWebView

    let configuration: WorkbenchConfiguration
    unowned let appModel: AppModel

    func makeCoordinator() -> Coordinator {
        Coordinator(configuration: configuration, appModel: appModel)
    }

    func makeNSView(context: Context) -> WKWebView {
        let webConfig = context.coordinator.makeWebConfiguration()
        let webView = WKWebView(frame: .zero, configuration: webConfig)
        webView.navigationDelegate = context.coordinator
        context.coordinator.loadWorkbench(in: webView)
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        context.coordinator.configuration = configuration
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var configuration: WorkbenchConfiguration
        unowned let appModel: AppModel
        private weak var webView: WKWebView?

        init(configuration: WorkbenchConfiguration, appModel: AppModel) {
            self.configuration = configuration
            self.appModel = appModel
        }

        func makeWebConfiguration() -> WKWebViewConfiguration {
            let config = WKWebViewConfiguration()
            config.preferences.setValue(true, forKey: "developerExtrasEnabled")

            let controller = WKUserContentController()
            controller.add(self, name: "ideNative")
            controller.addUserScript(
                WKUserScript(
                    source: bootstrapScript(),
                    injectionTime: .atDocumentStart,
                    forMainFrameOnly: true
                )
            )
            config.userContentController = controller
            return config
        }

        private func bootstrapScript() -> String {
            let workspacePath = configuration.workspaceURL?.path ?? ""
            let escaped = workspacePath.javascriptEscaped()
            return """
                window.IDENativeBridge = {
                    workspacePath: '\(escaped)',
                    emit(type, payload) {
                        window.webkit?.messageHandlers?.ideNative?.postMessage({ type, payload });
                    }
                };
            """
        }

        func loadWorkbench(in webView: WKWebView) {
            self.webView = webView
            let entry = configuration.entrypoint
            guard FileManager.default.fileExists(atPath: entry.path) else {
                appModel.state = .error("Missing workbench entry at \(entry.path)")
                return
            }

            webView.loadFileURL(entry, allowingReadAccessTo: configuration.workbenchRoot)
            appModel.state = .loading
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "ideNative" else { return }

            if let payload = message.body as? [String: Any],
               let type = payload["type"] as? String,
               type == "ready" {
                appModel.state = .ready
                pushWorkspacePath()
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            appModel.state = .ready
            pushWorkspacePath()
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            appModel.state = .error(error.localizedDescription)
        }

        private func pushWorkspacePath() {
            guard let workspacePath = configuration.workspaceURL?.path else { return }
            let escaped = workspacePath.javascriptEscaped()
            let js = """
                window.postMessage({
                    type: 'ide.setWorkspace',
                    path: '\(escaped)'
                }, '*');
            """
            webView?.evaluateJavaScript(js, completionHandler: nil)
        }
    }
}

private extension String {
    func javascriptEscaped() -> String {
        replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
    }
}
