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
    """
}
