import Foundation
import JavaScriptCore

enum MarkdownRenderer {
    private static let queue = DispatchQueue(label: "com.geul.renderer")

    private static let context: JSContext = {
        guard let ctx = JSContext() else { return JSContext() }

        ctx.exceptionHandler = { _, exception in
            if let msg = exception?.toString() {
                print("[JSCore] \(msg)")
            }
        }

        [
            "marked.min.js",
            "highlight.min.js",
            "js/markdown-renderer.js"
        ].forEach { path in
            if let script = AppResource.string(path) {
                ctx.evaluateScript(script)
            }
        }

        return ctx
    }()

    static func render(_ markdown: String) -> String {
        queue.sync {
            context.setObject(markdown, forKeyedSubscript: "_input" as NSString)

            guard let result = context.evaluateScript("renderMarkdown(_input)"),
                  !result.isUndefined,
                  let html = result.toString() else {
                return "<p>Failed to render markdown</p>"
            }

            return html
        }
    }
}
