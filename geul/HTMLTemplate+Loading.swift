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
        position: relative;
        margin: var(--cursor-spacing-1) 0 1rem;
        border-radius: var(--radius-lg);
        border: 1px solid var(--border);
        background-color: var(--bg-primary);
        overflow: hidden;
        box-shadow: none;
    }

    .mermaid-container .geul-loading {
        padding: 48px 24px;
        background-color: var(--bg-primary);
    }

    .mermaid-container.rendered {
        background-color: var(--bg-primary);
        box-shadow: none;
    }

    .mermaid-container.rendered .geul-loading {
        display: none;
    }

    .mermaid-container.rendered .mermaid {
        display: block !important;
        margin: 0;
        padding: var(--cursor-spacing-1-5);
        background: transparent;
        border: 0;
        overflow: auto;
    }

    .mermaid-container.rendered svg {
        display: block;
        max-width: 100%;
        height: auto;
    }

    .mermaid-error {
        border: 1px solid var(--border);
        background-color: var(--bg-primary);
        padding: var(--cursor-spacing-4);
        border-radius: var(--radius-lg);
        margin: var(--cursor-spacing-1) 0 1rem;
        box-shadow: none;
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
