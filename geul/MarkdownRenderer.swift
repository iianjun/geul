import Foundation
import JavaScriptCore

enum MarkdownRenderer {
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

        // Load KaTeX
        if let url = resourceBundle.url(forResource: "katex.min", withExtension: "js", subdirectory: "Resources"),
           let script = try? String(contentsOf: url, encoding: .utf8) {
            ctx.evaluateScript(script)
        }

        // Configure marked
        ctx.evaluateScript("""
        (function() {
            const renderer = new marked.Renderer();

            renderer.code = function({ text, lang }) {
                if (lang === 'mermaid') {
                    var escaped = text.replace(/&/g, '&amp;')
                                      .replace(/</g, '&lt;')
                                      .replace(/>/g, '&gt;');
                    return '<div class="mermaid-container">' +
                           '<div class="geul-loading">' +
                           '<div class="bar"></div><div class="bar"></div>' +
                           '<div class="bar"></div><div class="bar"></div>' +
                           '</div>' +
                           '<pre class="mermaid" style="display:none;">' +
                           escaped + '</pre></div>';
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

            marked.use({
                renderer: renderer,
                gfm: true,
                breaks: false
            });

            globalThis.renderMarkdown = function(input) {
                return marked.parse(input);
            };

            globalThis.renderKaTeX = function(text) {
                text = text.replace(/\\$\\$([\\s\\S]+?)\\$\\$/g, function(match, math) {
                    try {
                        return katex.renderToString(math.trim(), { displayMode: true, throwOnError: false });
                    } catch(e) { return match; }
                });
                text = text.replace(/(?<!\\$)\\$(?!\\$)(.+?)(?<!\\$)\\$(?!\\$)/g, function(match, math) {
                    try {
                        return katex.renderToString(math.trim(), { displayMode: false, throwOnError: false });
                    } catch(e) { return match; }
                });
                return text;
            };
        })();
        """)

        return ctx
    }()

    static func render(_ markdown: String) -> String {
        context.setObject(markdown, forKeyedSubscript: "_input" as NSString)

        guard let result = context.evaluateScript("renderMarkdown(_input)"),
              !result.isUndefined,
              var html = result.toString() else {
            return "<p>Failed to render markdown</p>"
        }

        // KaTeX post-process
        context.setObject(html, forKeyedSubscript: "_html" as NSString)
        if let katexResult = context.evaluateScript("renderKaTeX(_html)"),
           let katexHTML = katexResult.toString() {
            html = katexHTML
        }

        return html
    }
}
