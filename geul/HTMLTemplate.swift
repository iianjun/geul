import Foundation

enum AppResource {
    static let bundle: Bundle = {
        #if SWIFT_PACKAGE
        return Bundle.module
        #else
        return Bundle.main
        #endif
    }()

    static var webBaseURL: URL? {
        guard let resourceURL = bundle.resourceURL else { return nil }

        let nestedResources = resourceURL.appendingPathComponent("Resources", isDirectory: true)
        if directoryExists(at: nestedResources) {
            return nestedResources
        }

        return resourceURL
    }

    static func url(_ relativePath: String) -> URL? {
        guard let resourceURL = bundle.resourceURL else { return nil }

        let candidates = [
            resourceURL
                .appendingPathComponent("Resources", isDirectory: true)
                .appendingPathComponent(relativePath),
            resourceURL.appendingPathComponent(relativePath)
        ]

        return candidates.first { FileManager.default.fileExists(atPath: $0.path) }
    }

    static func string(_ relativePath: String) -> String? {
        guard let url = url(relativePath) else { return nil }
        return try? String(contentsOf: url, encoding: .utf8)
    }

    private static func directoryExists(at url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(
            atPath: url.path,
            isDirectory: &isDirectory
        )
        return exists && isDirectory.boolValue
    }
}

enum HTMLTemplate {
    static func compose(
        body: String,
        title: String,
        theme: Theme,
        readerAlignment: ReaderAlignment = .left
    ) -> String {
        let sanitizedColors = ThemeSanitizer.sanitized(theme.colors)
        let hljsKey = ThemeSanitizer.hljsVariantKey(for: theme)
        let configJSON = encodeConfigJSON(
            colors: sanitizedColors,
            hljsTheme: hljsKey,
            readerAlignment: readerAlignment
        )
        let lightDisabledAttribute = disabledAttribute(isDisabled: hljsKey == "dark")
        let darkDisabledAttribute = disabledAttribute(isDisabled: hljsKey != "dark")

        return """
        <!DOCTYPE html>
        <html lang="en" data-hljs-theme="\(hljsKey)">
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <title>\(title)</title>
            <link rel="stylesheet" href="css/globals.css">
            <link rel="stylesheet" href="github.min.css" id="geul-hljs-light"\(lightDisabledAttribute)>
            <link rel="stylesheet" href="github-dark.min.css" id="geul-hljs-dark"\(darkDisabledAttribute)>
            <link rel="stylesheet" href="katex.min.css">
        </head>
        <body>
            <article id="content" class="markdown-root markdown-body reader-align-\(readerAlignment.rawValue)">
            \(body)
            </article>
            <script id="geul-config" type="application/json">
            \(configJSON)
            </script>
            <script src="katex.min.js"></script>
            <script src="auto-render.min.js"></script>
            <script src="mermaid.min.js"></script>
            <script src="js/geul-find.js"></script>
            <script src="js/geul-runtime.js"></script>
        </body>
        </html>
        """
    }

    private static func disabledAttribute(isDisabled: Bool) -> String {
        isDisabled ? " disabled" : ""
    }

    private static func encodeConfigJSON(
        colors: [String: String],
        hljsTheme: String,
        readerAlignment: ReaderAlignment
    ) -> String {
        let config = GeulConfig(
            colors: colors,
            hljsTheme: hljsTheme,
            readerAlignment: readerAlignment.rawValue
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = (try? encoder.encode(config)) ?? Data("{}".utf8)
        return String(data: data, encoding: .utf8) ?? "{}"
    }

    private struct GeulConfig: Encodable {
        let colors: [String: String]
        let hljsTheme: String
        let readerAlignment: String
    }
}
