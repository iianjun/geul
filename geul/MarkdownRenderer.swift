import Foundation
import JavaScriptCore

enum MarkdownRenderer {
    private static let context: JSContext = {
        guard let ctx = JSContext() else { return JSContext() }

        // Load marked.js
        if let markedURL = Bundle.main.url(forResource: "marked.min", withExtension: "js", subdirectory: "Resources"),
           let markedJS = try? String(contentsOf: markedURL, encoding: .utf8) {
            ctx.evaluateScript(markedJS)
        }

        // Load highlight.js
        if let hlURL = Bundle.main.url(forResource: "highlight.min", withExtension: "js", subdirectory: "Resources"),
           let hlJS = try? String(contentsOf: hlURL, encoding: .utf8) {
            ctx.evaluateScript(hlJS)
        }

        // Load KaTeX
        if let katexURL = Bundle.main.url(forResource: "katex.min", withExtension: "js", subdirectory: "Resources"),
           let katexJS = try? String(contentsOf: katexURL, encoding: .utf8) {
            ctx.evaluateScript(katexJS)
        }

        // Configure marked with highlight.js integration and mermaid placeholder
        ctx.evaluateScript("""
        (function() {
            const renderer = new marked.Renderer();

            // Mermaid code blocks → loading placeholder (will be rendered in WebView)
            const originalCode = renderer.code;
            renderer.code = function({ text, lang }) {
                if (lang === 'mermaid') {
                    const escaped = text.replace(/&/g, '&amp;')
                                        .replace(/</g, '&lt;')
                                        .replace(/>/g, '&gt;');
                    return '<div class="mermaid-container">' +
                           '<div class="mermaid-loading"><div class="spinner"></div></div>' +
                           '<pre class="mermaid" style="display:none;">' + escaped + '</pre>' +
                           '</div>';
                }
                return false;
            };

            marked.use({
                renderer: renderer,
                gfm: true,
                breaks: false,
                highlight: function(code, lang) {
                    if (lang && hljs.getLanguage(lang)) {
                        return hljs.highlight(code, { language: lang }).value;
                    }
                    return hljs.highlightAuto(code).value;
                }
            });

            // KaTeX inline/block rendering helper
            globalThis.renderKaTeX = function(text) {
                // Block math: $$...$$
                text = text.replace(/\\$\\$([\\s\\S]+?)\\$\\$/g, function(match, math) {
                    try {
                        return katex.renderToString(math.trim(), { displayMode: true, throwOnError: false });
                    } catch(e) { return match; }
                });
                // Inline math: $...$  (not preceded/followed by $)
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
        let escaped = markdown
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "`", with: "\\`")
            .replacingOccurrences(of: "$", with: "\\$")

        // marked.js parse
        guard let markedResult = context.evaluateScript("marked.parse(`\(escaped)`)"),
              var html = markedResult.toString() else {
            return "<p>Failed to render markdown</p>"
        }

        // KaTeX post-process
        let katexEscaped = html
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "`", with: "\\`")
        if let katexResult = context.evaluateScript("renderKaTeX(`\(katexEscaped)`)"),
           let katexHTML = katexResult.toString() {
            html = katexHTML
        }

        return html
    }
}
