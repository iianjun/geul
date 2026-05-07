import Foundation

extension HTMLTemplate {

    static let baseCSS = """
    :root {
        --radius: 3px;
        --radius-lg: 3px;
    }

    * {
        box-sizing: border-box;
    }

    html,
    body {
        margin: 0;
        font-family: -apple-system, BlinkMacSystemFont, "Segoe WPC",
                     "Segoe UI", system-ui, "Ubuntu", "Droid Sans",
                     sans-serif;
        font-size: 14px;
        line-height: 22px;
        color: var(--text-primary);
        background-color: var(--bg-primary);
        word-wrap: break-word;
        -webkit-font-smoothing: antialiased;
        -moz-osx-font-smoothing: grayscale;
    }

    body {
        padding-top: 1em;
    }

    .markdown-body {
        padding: 0 26px 96px;
    }

    h1, h2, h3, h4, h5, h6,
    p, ol, ul, pre {
        margin-top: 0;
    }

    h1, h2, h3, h4, h5, h6 {
        color: var(--text-primary);
        font-weight: 600;
        margin-top: 24px;
        margin-bottom: 16px;
        line-height: 1.25;
        letter-spacing: 0;
    }

    h1 {
        font-size: 2em;
        margin-top: 0;
        padding-bottom: 0.3em;
        border-bottom: 1px solid var(--border);
    }

    h2 {
        font-size: 1.5em;
        padding-bottom: 0.3em;
        border-bottom: 1px solid var(--border);
    }

    h3 { font-size: 1.25em; }
    h4 { font-size: 1em; }
    h5 { font-size: 0.875em; }
    h6 { font-size: 0.85em; color: var(--text-secondary); }

    p {
        margin-bottom: 16px;
    }

    a {
        color: var(--accent);
        text-decoration: none;
        border-bottom: 0;
    }

    a:hover {
        text-decoration: underline;
    }

    code {
        font-family: var(--vscode-editor-font-family, "SF Mono", Monaco,
                     Menlo, Consolas, "Ubuntu Mono", "Liberation Mono",
                     "DejaVu Sans Mono", "Courier New", monospace);
        font-size: 1em;
        line-height: 1.357em;
        padding: 0.15em 0.4em;
        color: var(--text-primary);
        background-color: var(--bg-secondary);
        border-radius: var(--radius);
    }

    pre {
        margin-bottom: 0.7em;
        padding: 16px;
        color: var(--text-primary);
        background-color: var(--bg-code);
        border: 1px solid var(--bg-code-border);
        border-radius: var(--radius);
        overflow: auto;
        box-shadow: var(--shadow-subtle);
    }

    pre code {
        display: inline-block;
        padding: 0;
        color: var(--text-primary);
        background: none;
        border: none;
        border-radius: 0;
        tab-size: 4;
    }

    blockquote {
        margin: 0 0 0.7em;
        padding: 0 16px 0 10px;
        color: var(--text-tertiary);
        background: transparent;
        border-left: 5px solid var(--text-tertiary);
        border-radius: 2px;
    }

    blockquote p:last-child {
        margin-bottom: 0;
    }

    ul,
    ol {
        margin-bottom: 0.7em;
        padding-left: 2em;
    }

    li {
        margin-bottom: 0;
    }

    li p {
        margin-bottom: 0.7em;
    }

    table {
        border-collapse: collapse;
        margin-bottom: 0.7em;
        font-size: 1em;
    }

    th {
        text-align: left;
        font-weight: 600;
        border-bottom: 1px solid var(--border-strong);
    }

    th,
    td {
        padding: 5px 10px;
    }

    table > tbody > tr + tr > td {
        border-top: 1px solid var(--border);
    }

    hr {
        margin: 0 0 0.7em;
        border: 0;
        height: 1px;
        border-bottom: 1px solid var(--border);
        background: none;
    }

    img,
    video {
        max-width: 100%;
        max-height: 100%;
        height: auto;
        border-radius: var(--radius-lg);
        margin: 0 0 0.7em;
    }

    sub,
    sup {
        line-height: 0;
    }

    del {
        color: var(--text-tertiary);
    }

    ::selection {
        background-color: rgba(228, 228, 228, 0.19);
        color: var(--text-primary);
    }

    ::-webkit-scrollbar {
        width: 10px;
        height: 10px;
    }

    ::-webkit-scrollbar-track {
        background: transparent;
    }

    ::-webkit-scrollbar-thumb {
        background: rgba(228, 228, 228, 0.07);
        border-radius: 5px;
    }

    ::-webkit-scrollbar-thumb:hover {
        background: rgba(228, 228, 228, 0.12);
    }
    """
}
