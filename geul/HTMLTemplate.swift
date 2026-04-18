import Foundation

enum HTMLTemplate {
    static func compose(body: String, title: String, theme: Theme) -> String {
        let highlightLightCSS = loadResource("github.min", ext: "css") ?? ""
        let highlightDarkCSS = loadResource("github-dark.min", ext: "css") ?? ""
        let katexCSS = loadResource("katex.min", ext: "css")
        let katexJS = loadResource("katex.min", ext: "js")
        let autoRenderJS = loadResource("auto-render.min", ext: "js")
        let mermaidJS = loadResource("mermaid.min", ext: "js")
        let hljsLightJSON = ThemeSanitizer.jsStringLiteral(highlightLightCSS)
        let hljsDarkJSON = ThemeSanitizer.jsStringLiteral(highlightDarkCSS)
        let hljsKey = ThemeSanitizer.hljsVariantKey(for: theme)
        let initialHljs = hljsKey == "dark" ? highlightDarkCSS : highlightLightCSS
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
            <style id="geul-hljs">\(initialHljs)</style>
            <style>\(highlightOverrideCSS)</style>
            <style>\(katexCSS ?? "")</style>
            <style>\(loadingCSS)</style>
        </head>
        <body>
            <article id="content" class="markdown-body">
            \(body)
            </article>
            <script>
            window.__geulCurrentColors = \(colorsJSON);
            window.__geulHljsCSS = { default: \(hljsLightJSON), dark: \(hljsDarkJSON) };
            </script>
            <script>\(katexJS ?? "")</script>
            <script>\(autoRenderJS ?? "")</script>
            <script>\(mermaidJS ?? "")</script>
            <script>\(mermaidInitScript)</script>
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

    private static let resourceBundle: Bundle = {
        #if SWIFT_PACKAGE
        return Bundle.module
        #else
        return Bundle.main
        #endif
    }()

    private static func loadResource(_ name: String, ext: String) -> String? {
        guard let url = resourceBundle.url(
            forResource: name,
            withExtension: ext,
            subdirectory: "Resources"
        ),
              let content = try? String(contentsOf: url, encoding: .utf8)
        else {
            return nil
        }
        return content
    }
}
