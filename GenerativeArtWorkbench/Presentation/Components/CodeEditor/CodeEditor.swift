//
//  CodeEditor.swift
//  GenerativeArtWorkbench
//
//  Created by k2o on 2023/07/23.
//

import SwiftUI
import WebKit

struct CodeEditor: UIViewRepresentable {
    @Binding var code: String
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(code: $code)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let userContentController = WKUserContentController()
        userContentController.add(context.coordinator, name: "callback")
        configuration.userContentController = userContentController
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        //webView.isInspectable = true
        webView.navigationDelegate = context.coordinator
        if let codeEditorURL = Bundle.main.url(forResource: "code_editor", withExtension: "html") {
            webView.loadFileURL(codeEditorURL, allowingReadAccessTo: codeEditorURL)
        }

        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.setCode(code, for: webView)
    }
    
    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        let bindingCode: Binding<String>
        private var storedCode: String {
            didSet { bindingCode.wrappedValue = storedCode }
        }
        private var ignoreCallbackOnce = false

        init(code: Binding<String>) {
            self.storedCode = code.wrappedValue
            self.bindingCode = code
        }

        func setCode(_ code: String, for webView: WKWebView) {
            guard code != storedCode else { return }
            applyCode(code, for: webView)
        }
        
        private func applyCode(_ code: String, for webView: WKWebView) {
            // 改行コードやクォートのエスケープは面倒なのでbase64に変換して渡し、
            // JS側でデコードする
            // https://qiita.com/weal/items/1a2af81138cd8f49937d
            let encodedCode = code.base64Encoded()
            let decodedCode = "decodeURIComponent(escape(atob('\(encodedCode)')))"
            // callbackループをブロック(callbackされた後に解除)
            ignoreCallbackOnce = true
            webView.evaluateJavaScript("editor.session.setValue(\(decodedCode));")
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            applyCode(storedCode, for: webView)
        }
        
        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            switch message.name {
            case "callback":
                if ignoreCallbackOnce {
                    ignoreCallbackOnce = false
                } else if let code = message.body as? String {
                    self.storedCode = code
                }
            default:
                break
            }
        }
    }
}

private extension String {
    func base64Encoded() -> String {
        return data(using: .utf8)?.base64EncodedString() ?? ""
    }
}
