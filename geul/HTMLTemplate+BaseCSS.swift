import Foundation

extension HTMLTemplate {

    static let baseCSS = """
    :root {
        --radius: 5px;
        --radius-sm: 4px;
        --radius-md: 6px;
        --radius-lg: 8px;
        --cursor-spacing-1: 4px;
        --cursor-spacing-1-5: 6px;
        --cursor-spacing-2: 8px;
        --cursor-spacing-4: 16px;
        --cursor-font-family-mono: "SF Mono", Monaco, Menlo, Consolas,
                                    "Ubuntu Mono", "Liberation Mono",
                                    "DejaVu Sans Mono", "Courier New",
                                    monospace;
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
        min-height: 100vh;
    }

    .markdown-root,
    .markdown-body {
        margin: 0;
        padding: 32px 24px 64px;
    }

    .markdown-root > *:first-child,
    .markdown-body > *:first-child {
        margin-top: 0;
    }

    .markdown-root > *:last-child,
    .markdown-body > *:last-child {
        margin-bottom: 0;
    }

    .markdown-root h1,
    .markdown-root h2,
    .markdown-root h3,
    .markdown-root h4,
    .markdown-root h5,
    .markdown-root h6,
    .markdown-root p,
    .markdown-root ul,
    .markdown-root ol,
    .markdown-root li,
    .markdown-root blockquote,
    .markdown-root pre,
    .markdown-body h1,
    .markdown-body h2,
    .markdown-body h3,
    .markdown-body h4,
    .markdown-body h5,
    .markdown-body h6,
    .markdown-body p,
    .markdown-body ul,
    .markdown-body ol,
    .markdown-body li,
    .markdown-body blockquote,
    .markdown-body pre {
        color: var(--text-primary);
    }

    .markdown-root h1,
    .markdown-root h2,
    .markdown-root h3,
    .markdown-root h4,
    .markdown-root h5,
    .markdown-root h6,
    .markdown-body h1,
    .markdown-body h2,
    .markdown-body h3,
    .markdown-body h4,
    .markdown-body h5,
    .markdown-body h6 {
        color: var(--text-primary);
        font-weight: 600;
        line-height: 1.3;
        letter-spacing: 0;
    }

    .markdown-root h1,
    .markdown-body h1 {
        font-size: 1.6em;
        margin-top: 24px;
        margin-bottom: 12px;
    }

    .markdown-root h2,
    .markdown-body h2 {
        font-size: 1.3em;
        margin-top: 20px;
        margin-bottom: 10px;
    }

    .markdown-root h3,
    .markdown-body h3 {
        font-size: 1.15em;
        margin-top: 18px;
        margin-bottom: 8px;
    }

    .markdown-root h4,
    .markdown-body h4 {
        font-size: 1.05em;
        margin-top: 16px;
        margin-bottom: 8px;
    }

    .markdown-root h5,
    .markdown-root h6,
    .markdown-body h5,
    .markdown-body h6 {
        font-size: 1em;
        margin-top: 14px;
        margin-bottom: 6px;
    }

    .markdown-root h6,
    .markdown-body h6 {
        margin-top: 12px;
        color: var(--text-secondary);
    }

    .markdown-root p,
    .markdown-body p {
        margin: 6px 0;
        word-break: break-word;
    }

    .markdown-root a,
    .markdown-body a {
        color: var(--accent);
        text-decoration: none;
        border-bottom: 0;
    }

    .markdown-root a:hover,
    .markdown-body a:hover {
        text-decoration: underline;
    }

    .markdown-root code,
    .markdown-body code {
        font-family: var(--cursor-font-family-mono);
        font-size: 0.9em;
        line-height: 1.4;
        padding: 1.5px 4px;
        color: var(--text-primary);
        background-color: var(--bg-secondary);
        border-radius: 5px;
        word-break: break-all;
    }

    .markdown-root pre,
    .markdown-body pre {
        position: relative;
        margin: var(--cursor-spacing-1) 0 1rem;
        padding: 0.75rem;
        color: var(--text-primary);
        background-color: var(--bg-code);
        border: 1px solid var(--border);
        border-radius: var(--radius-lg);
        overflow: auto;
        box-shadow: none;
    }

    .markdown-root pre code,
    .markdown-body pre code {
        display: block;
        padding: 0;
        color: var(--text-primary);
        background: transparent;
        border: none;
        border-radius: 0;
        font-size: 0.85em;
        line-height: 1.5;
        tab-size: 4;
        word-break: normal;
    }

    .markdown-root blockquote,
    .markdown-body blockquote {
        margin: 0.5rem 0;
        padding: var(--cursor-spacing-2) 0 var(--cursor-spacing-2)
                 var(--cursor-spacing-4);
        color: var(--text-secondary);
        background: transparent;
        border-left: 3px solid var(--border-strong);
        border-radius: 0;
        word-break: break-word;
    }

    .markdown-root blockquote p:last-child,
    .markdown-body blockquote p:last-child {
        margin-bottom: 0;
    }

    .markdown-root ul,
    .markdown-root ol,
    .markdown-body ul,
    .markdown-body ol {
        display: flex !important;
        flex-direction: column !important;
        gap: var(--cursor-spacing-1-5) !important;
        margin: var(--cursor-spacing-1-5) 0 !important;
        padding-left: 2em;
    }

    .markdown-root li,
    .markdown-body li {
        margin: 0;
        padding: 0;
        word-break: break-word;
    }

    .markdown-root li > p,
    .markdown-body li > p {
        margin: 0;
    }

    .markdown-root li > p + *,
    .markdown-body li > p + * {
        margin-top: var(--cursor-spacing-1);
    }

    .markdown-root table,
    .markdown-body table {
        border-collapse: separate;
        border-spacing: 0;
        width: 100%;
        max-width: 100%;
        margin: 1em 0;
        font-size: 1em;
        border: 1px solid var(--border);
        border-radius: var(--radius-md);
        overflow: hidden;
    }

    .markdown-root th,
    .markdown-body th {
        text-align: left;
        font-weight: 600;
    }

    .markdown-root th,
    .markdown-root td,
    .markdown-body th,
    .markdown-body td {
        padding: 5px 9px;
        text-align: left;
        vertical-align: top;
        border-right: 1px solid var(--border);
        border-bottom: 1px solid var(--border);
    }

    .markdown-root th:last-child,
    .markdown-root td:last-child,
    .markdown-body th:last-child,
    .markdown-body td:last-child {
        border-right: 0;
    }

    .markdown-root tbody tr:last-child td,
    .markdown-body tbody tr:last-child td {
        border-bottom: 0;
    }

    .markdown-root hr,
    .markdown-body hr {
        margin: 16px 0;
        border: 0;
        height: 1px;
        border-top: 1px solid var(--border);
        background: none;
    }

    .markdown-root img,
    .markdown-root video,
    .markdown-body img,
    .markdown-body video {
        max-width: 100%;
        max-height: 100%;
        height: auto;
        border-radius: var(--radius-md);
        margin: 0.5rem 0;
    }

    sub,
    sup {
        line-height: 0;
    }

    .markdown-root del,
    .markdown-body del {
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
