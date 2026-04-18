import Foundation
import JavaScriptCore

enum MarkdownRenderer {
    private static let queue = DispatchQueue(label: "com.geul.renderer")

    private static let resourceBundle: Bundle = {
        #if SWIFT_PACKAGE
        return Bundle.module
        #else
        return Bundle.main
        #endif
    }()

    private static let context: JSContext = {
        guard let ctx = JSContext() else { return JSContext() }

        ctx.exceptionHandler = { _, exception in
            if let msg = exception?.toString() {
                print("[JSCore] \(msg)")
            }
        }

        // Load marked.js
        if let url = resourceBundle.url(forResource: "marked.min", withExtension: "js", subdirectory: "Resources"),
           let script = try? String(contentsOf: url, encoding: .utf8) {
            ctx.evaluateScript(script)
        }

        // Load highlight.js
        if let url = resourceBundle.url(forResource: "highlight.min", withExtension: "js", subdirectory: "Resources"),
           let script = try? String(contentsOf: url, encoding: .utf8) {
            ctx.evaluateScript(script)
        }

        // Configure marked
        ctx.evaluateScript("""
        (function() {
            const renderer = new marked.Renderer();

            function escapeHTML(text) {
                return String(text == null ? '' : text)
                    .replace(/&/g, '&amp;')
                    .replace(/</g, '&lt;')
                    .replace(/>/g, '&gt;');
            }

            renderer.code = function({ text, lang }) {
                if (lang === 'mermaid') {
                    return '<div class="mermaid-container">' +
                           '<div class="geul-loading">' +
                           '<div class="bar"></div><div class="bar"></div>' +
                           '<div class="bar"></div><div class="bar"></div>' +
                           '</div>' +
                           '<pre class="mermaid" style="display:none;">' +
                           escapeHTML(text) + '</pre></div>';
                }
                var highlighted;
                if (lang && hljs.getLanguage(lang)) {
                    highlighted = hljs.highlight(text, { language: lang }).value;
                } else {
                    highlighted = hljs.highlightAuto(text).value;
                }
                var cls = lang ? 'hljs language-' + lang : 'hljs';
                return '<pre><code class="' + cls + '">' + highlighted + '</code></pre>';
            };

            // Prevent raw HTML in markdown from executing inside the WebView.
            // Escape both block-level and inline html tokens so they render as literal text.
            renderer.html = function(token) {
                var raw = token && (token.raw != null ? token.raw : token.text);
                return escapeHTML(raw);
            };

            marked.use({
                renderer: renderer,
                gfm: true,
                breaks: false,
                walkTokens: function(token) {
                    if (token && token.type === 'html') {
                        // Convert html tokens to escaped text so the inline renderer
                        // (which doesn't go through renderer.html) also neutralizes them.
                        var raw = token.raw != null ? token.raw : (token.text || '');
                        token.type = 'text';
                        token.text = escapeHTML(raw);
                        if (token.tokens) token.tokens = undefined;
                    }
                }
            });

            globalThis.renderMarkdown = function(input) {
                return marked.parse(input);
            };
        })();
        """)

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
