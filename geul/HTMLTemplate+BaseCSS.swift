import Foundation

extension HTMLTemplate {

    static let baseCSS = """
    :root {
        --radius: 8px;
        --radius-lg: 12px;
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
