import Foundation

enum HTMLTemplate {
    static func compose(body: String, title: String) -> String {
        let highlightCSS = loadResource("github.min", ext: "css")
        let katexCSS = loadResource("katex.min", ext: "css")
        let mermaidJS = loadResource("mermaid.min", ext: "js")

        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <title>\(title)</title>
            <style>\(baseCSS)</style>
            <style>\(highlightCSS ?? "")</style>
            <style>\(katexCSS ?? "")</style>
            <style>\(loadingCSS)</style>
        </head>
        <body>
            <article class="markdown-body">
            \(body)
            </article>
            <script>\(mermaidJS ?? "")</script>
            <script>\(mermaidInitScript)</script>
        </body>
        </html>
        """
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

// MARK: - Stone Theme CSS

private extension HTMLTemplate {

    static let baseCSS = """
    :root {
        --bg-primary: #fafaf9;
        --bg-secondary: #f5f5f4;
        --bg-code: #f5f5f4;
        --bg-code-border: #0d9488;
        --text-primary: #1c1917;
        --text-secondary: #78716c;
        --text-tertiary: #a8a29e;
        --accent: #0d9488;
        --accent-soft: rgba(13, 148, 136, 0.08);
        --border: #e7e5e4;
        --border-strong: #d6d3d1;
        --shadow-subtle: 0 1px 2px rgba(28, 25, 23, 0.04);
        --radius: 8px;
        --radius-lg: 12px;
    }

    @media (prefers-color-scheme: dark) {
        :root {
            --bg-primary: #1c1917;
            --bg-secondary: #292524;
            --bg-code: #292524;
            --bg-code-border: #2dd4bf;
            --text-primary: #fafaf9;
            --text-secondary: #a8a29e;
            --text-tertiary: #78716c;
            --accent: #2dd4bf;
            --accent-soft: rgba(45, 212, 191, 0.08);
            --border: #44403c;
            --border-strong: #57534e;
            --shadow-subtle: 0 1px 2px rgba(0, 0, 0, 0.2);
        }
    }

    * {
        margin: 0;
        padding: 0;
        box-sizing: border-box;
    }

    html {
        font-size: 16px;
        -webkit-font-smoothing: antialiased;
        -moz-osx-font-smoothing: grayscale;
        text-rendering: optimizeLegibility;
    }

    body {
        font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text",
                     "Helvetica Neue", Arial, sans-serif;
        line-height: 1.7;
        color: var(--text-primary);
        background-color: var(--bg-primary);
    }

    .markdown-body {
        padding: 48px 32px 96px;
    }

    /* Headings */
    h1, h2, h3, h4, h5, h6 {
        font-family: -apple-system, BlinkMacSystemFont, "SF Pro Display",
                     "Helvetica Neue", Arial, sans-serif;
        color: var(--text-primary);
        font-weight: 650;
        line-height: 1.25;
        letter-spacing: -0.015em;
    }

    h1 {
        font-size: 2em;
        font-weight: 700;
        letter-spacing: -0.025em;
        margin-top: 0;
        margin-bottom: 20px;
    }

    .markdown-body > h1:first-child { margin-top: 0; }

    h2 {
        font-size: 1.5em;
        margin-top: 48px;
        margin-bottom: 16px;
        padding-top: 24px;
        border-top: 1px solid var(--border);
    }

    h3 {
        font-size: 1.2em;
        margin-top: 36px;
        margin-bottom: 12px;
    }

    h4 {
        font-size: 1em;
        margin-top: 28px;
        margin-bottom: 8px;
        color: var(--text-secondary);
        text-transform: uppercase;
        letter-spacing: 0.04em;
        font-weight: 600;
    }

    h5 {
        font-size: 0.875em;
        margin-top: 24px;
        margin-bottom: 8px;
        color: var(--text-secondary);
    }

    h6 {
        font-size: 0.8em;
        margin-top: 24px;
        margin-bottom: 8px;
        color: var(--text-tertiary);
    }

    /* Paragraph */
    p { margin-bottom: 16px; }

    /* Links */
    a {
        color: var(--accent);
        text-decoration: none;
        border-bottom: 1px solid transparent;
        transition: border-color 0.15s ease;
    }
    a:hover { border-bottom-color: var(--accent); }

    /* Inline code */
    code {
        font-family: ui-monospace, "SF Mono", SFMono-Regular,
                     Menlo, Consolas, monospace;
        font-size: 0.875em;
        padding: 0.15em 0.4em;
        background-color: var(--bg-secondary);
        border: 1px solid var(--border);
        border-radius: 5px;
        color: var(--text-primary);
    }

    /* Code block */
    pre {
        margin-bottom: 20px;
        padding: 20px 24px;
        background-color: var(--bg-code);
        border-left: 3px solid var(--bg-code-border);
        border-radius: var(--radius);
        overflow-x: auto;
        box-shadow: var(--shadow-subtle);
    }

    pre code {
        padding: 0;
        background: none;
        border: none;
        border-radius: 0;
        font-size: 0.85em;
        line-height: 1.6;
    }

    /* Blockquote */
    blockquote {
        margin-bottom: 20px;
        padding: 16px 20px;
        background-color: var(--accent-soft);
        border-left: 3px solid var(--accent);
        border-radius: 0 var(--radius) var(--radius) 0;
        color: var(--text-secondary);
    }
    blockquote p:last-child { margin-bottom: 0; }

    /* Lists */
    ul, ol {
        margin-bottom: 16px;
        padding-left: 1.75em;
    }
    li { margin-bottom: 4px; }
    li > p { margin-bottom: 6px; }
    li::marker { color: var(--text-tertiary); }

    /* Tables — minimal, no outer border */
    table {
        width: 100%;
        margin-bottom: 20px;
        border-collapse: collapse;
        font-size: 0.9em;
    }

    thead th {
        text-align: left;
        padding: 10px 16px;
        font-weight: 600;
        font-size: 0.8em;
        text-transform: uppercase;
        letter-spacing: 0.05em;
        color: var(--text-secondary);
        border-bottom: 2px solid var(--border-strong);
    }

    tbody td {
        padding: 10px 16px;
        border-bottom: 1px solid var(--border);
    }
    tbody tr:last-child td { border-bottom: none; }

    /* Horizontal rule */
    hr {
        margin: 40px 0;
        border: none;
        height: 1px;
        background: linear-gradient(
            to right,
            transparent,
            var(--border-strong) 20%,
            var(--border-strong) 80%,
            transparent
        );
    }

    /* Images */
    img {
        max-width: 100%;
        height: auto;
        border-radius: var(--radius-lg);
        margin: 8px 0 20px;
    }

    /* Strikethrough */
    del { color: var(--text-tertiary); }

    /* Selection */
    ::selection {
        background-color: var(--accent);
        color: #ffffff;
    }

    /* Scrollbar */
    ::-webkit-scrollbar { width: 6px; height: 6px; }
    ::-webkit-scrollbar-track { background: transparent; }
    ::-webkit-scrollbar-thumb {
        background: var(--border-strong);
        border-radius: 3px;
    }
    ::-webkit-scrollbar-thumb:hover { background: var(--text-tertiary); }
    """
}

// MARK: - Loading UI (shared 4-bar equalizer)

private extension HTMLTemplate {

    static let loadingCSS = """
    .geul-loading {
        display: flex;
        align-items: center;
        justify-content: center;
        gap: 6px;
    }

    .geul-loading .bar {
        width: 3px;
        height: 16px;
        background-color: var(--accent);
        border-radius: 2px;
        animation: bar-pulse 0.9s ease-in-out infinite;
    }

    .geul-loading .bar:nth-child(2) { animation-delay: 0.1s; }
    .geul-loading .bar:nth-child(3) { animation-delay: 0.2s; }
    .geul-loading .bar:nth-child(4) { animation-delay: 0.3s; }

    @keyframes bar-pulse {
        0%, 100% { transform: scaleY(0.6); opacity: 0.3; }
        50% { transform: scaleY(1); opacity: 1; }
    }

    .mermaid-container {
        margin-bottom: 20px;
        border-radius: var(--radius-lg);
        background-color: var(--bg-secondary);
        overflow: hidden;
        box-shadow: var(--shadow-subtle);
    }

    .mermaid-container .geul-loading {
        padding: 48px 24px;
    }

    .mermaid-container.rendered {
        background-color: transparent;
        box-shadow: none;
    }

    .mermaid-container.rendered .geul-loading {
        display: none;
    }

    .mermaid-container.rendered .mermaid {
        display: block !important;
    }
    """
}

// MARK: - Mermaid Init Script

private extension HTMLTemplate {

    static let mermaidInitScript = """
    document.addEventListener('DOMContentLoaded', function() {
        const containers = document.querySelectorAll('.mermaid-container');
        if (containers.length === 0) return;

        mermaid.initialize({
            startOnLoad: false,
            theme: 'default',
            securityLevel: 'loose'
        });

        containers.forEach(async function(container, i) {
            const pre = container.querySelector('.mermaid');
            if (!pre) return;

            try {
                const { svg } = await mermaid.render(
                    'mermaid-' + i, pre.textContent
                );
                pre.innerHTML = svg;
                container.classList.add('rendered');
            } catch(e) {
                pre.textContent =
                    'Mermaid rendering error: ' + e.message;
                pre.style.display = 'block';
                pre.style.color = 'var(--text-secondary)';
                var loading =
                    container.querySelector('.geul-loading');
                if (loading) loading.style.display = 'none';
            }
        });
    });
    """
}
