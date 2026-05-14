import Foundation

enum HTMLTemplate {
    static func compose(
        body: String,
        title: String,
        theme: Theme,
        readerAlignment: ReaderAlignment = .left
    ) -> String {
        let hljsKey = ThemeSanitizer.hljsVariantKey(for: theme)
        let initialHljsPath = highlightStylesheetPath(forHLJSVariantKey: hljsKey)
        let initialHighlightOverride = highlightOverrideCSS(forHLJSVariantKey: hljsKey)
        let cursorDarkHighlightOverrideJSON = ThemeSanitizer.jsStringLiteral(cursorDarkHighlightOverrideCSS)
        let sanitizedColors = ThemeSanitizer.sanitized(theme.colors)
        let colorsJSON = Self.encodeColorsJSON(sanitizedColors)

        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <title>\(title)</title>
            <style id="geul-theme">\(themeCSS(theme))</style>
            <style>\(baseCSS)</style>
            <link id="geul-hljs" rel="stylesheet" href="\(initialHljsPath)">
            <style id="geul-hljs-override">\(initialHighlightOverride)</style>
            <link rel="stylesheet" href="Resources/styles/katex.min.css">
            <link rel="stylesheet" href="\(loadingStylesheetPath)">
        </head>
        <body>
            <article id="content" class="markdown-root markdown-body reader-align-\(readerAlignment.rawValue)">
            \(body)
            </article>
            <script>
            window.__geulCurrentColors = \(colorsJSON);
            window.__geulHljsHref = {
                default: "\(highlightStylesheetPath(forHLJSVariantKey: "default"))",
                dark: "\(highlightStylesheetPath(forHLJSVariantKey: "dark"))"
            };
            window.__geulHljsOverrideCSS = { default: "", dark: \(cursorDarkHighlightOverrideJSON) };
            </script>
            <script src="Resources/scripts/katex.min.js"></script>
            <script src="Resources/scripts/auto-render.min.js"></script>
            <script src="Resources/scripts/mermaid.min.js"></script>
            <script src="\(mermaidInitScriptPath)"></script>
            <script>\(findScript)</script>
        </body>
        </html>
        """
    }

    static func themeCSS(_ theme: Theme) -> String {
        let vars = ThemeSanitizer.sanitized(theme.colors)
            .sorted { $0.key < $1.key }
            .map { "    \($0.key): \($0.value);" }
            .joined(separator: "\n")
        return """
        :root {
        \(vars)
        }
        """
    }

    private static func encodeColorsJSON(_ colors: [String: String]) -> String {
        let data = (try? JSONEncoder().encode(colors)) ?? Data("{}".utf8)
        return String(data: data, encoding: .utf8) ?? "{}"
    }

    static func highlightStylesheetPath(forHLJSVariantKey key: String) -> String {
        key == "dark"
            ? "Resources/styles/github-dark.min.css"
            : "Resources/styles/github.min.css"
    }
}
