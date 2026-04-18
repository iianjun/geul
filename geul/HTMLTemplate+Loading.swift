import Foundation

extension HTMLTemplate {

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

    .mermaid-error {
        border-left: 3px solid var(--accent);
        background-color: var(--bg-secondary);
        padding: 16px 20px;
        border-radius: 0 var(--radius) var(--radius) 0;
        margin-bottom: 20px;
        box-shadow: var(--shadow-subtle);
    }

    .mermaid-error-header {
        color: var(--accent);
        font-weight: 600;
        margin-bottom: 8px;
    }

    .mermaid-error-message {
        color: var(--text-secondary);
        font-size: 0.9em;
        margin-bottom: 12px;
        font-family: ui-monospace, "SF Mono", SFMono-Regular,
                     Menlo, Consolas, monospace;
        white-space: pre-wrap;
    }

    .mermaid-error-source {
        font-family: ui-monospace, "SF Mono", SFMono-Regular,
                     Menlo, Consolas, monospace;
        font-size: 0.85em;
        color: var(--text-tertiary);
        background: transparent;
        border: none;
        padding: 0;
        box-shadow: none;
        white-space: pre-wrap;
        margin: 0;
    }
    """
}
