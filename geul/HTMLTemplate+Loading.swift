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

    .mermaid-zoom-button {
        position: absolute;
        top: var(--cursor-spacing-2);
        right: var(--cursor-spacing-2);
        z-index: 2;
        width: 28px;
        height: 28px;
        display: inline-flex;
        align-items: center;
        justify-content: center;
        padding: 0;
        color: var(--text-primary);
        background-color: var(--bg-secondary);
        border: 1px solid var(--border);
        border-radius: var(--radius-md);
        opacity: 0;
        pointer-events: none;
        cursor: pointer;
        box-shadow: none;
        transition: opacity 0.12s ease, border-color 0.12s ease;
    }

    .mermaid-container.rendered:hover .mermaid-zoom-button,
    .mermaid-container.rendered:focus-within .mermaid-zoom-button {
        opacity: 1;
        pointer-events: auto;
    }

    .mermaid-zoom-button:hover {
        border-color: var(--border-strong);
    }

    .mermaid-zoom-button:focus-visible {
        outline: 2px solid var(--accent);
        outline-offset: 2px;
    }

    .mermaid-zoom-button svg {
        width: 15px;
        height: 15px;
        display: block;
        pointer-events: none;
    }

    .mermaid-zoom-overlay {
        position: fixed;
        inset: 0;
        z-index: 2147483647;
        display: flex;
        min-width: 0;
        min-height: 0;
        padding: 24px;
        background-color: color-mix(in srgb, var(--bg-primary) 82%, transparent);
        color: var(--text-primary);
    }

    .mermaid-zoom-dialog {
        position: relative;
        flex: 1;
        min-width: 0;
        min-height: 0;
        overflow: hidden;
        background-color: var(--bg-primary);
        border: 1px solid var(--border);
        border-radius: var(--radius-lg);
        box-shadow: none;
    }

    .mermaid-zoom-stage {
        position: absolute;
        inset: 0;
        overflow: hidden;
        cursor: grab;
        touch-action: none;
        user-select: none;
    }

    .mermaid-zoom-stage.dragging {
        cursor: grabbing;
    }

    .mermaid-zoom-content {
        position: absolute;
        top: 50%;
        left: 50%;
        transform-origin: center center;
        will-change: transform;
    }

    .mermaid-zoom-content svg {
        display: block;
        max-width: none;
        height: auto;
    }

    .mermaid-zoom-toolbar {
        position: absolute;
        top: var(--cursor-spacing-2);
        right: var(--cursor-spacing-2);
        z-index: 3;
        display: flex;
        align-items: center;
        gap: var(--cursor-spacing-1);
        padding: var(--cursor-spacing-1);
        color: var(--text-primary);
        background-color: var(--bg-secondary);
        border: 1px solid var(--border);
        border-radius: var(--radius-md);
        box-shadow: none;
    }

    .mermaid-zoom-control {
        width: 28px;
        height: 28px;
        display: inline-flex;
        align-items: center;
        justify-content: center;
        padding: 0;
        color: var(--text-primary);
        background-color: var(--bg-primary);
        border: 1px solid var(--border);
        border-radius: var(--radius-sm);
        font: inherit;
        font-size: 12px;
        line-height: 1;
        cursor: pointer;
    }

    .mermaid-zoom-control:hover {
        border-color: var(--border-strong);
    }

    .mermaid-zoom-control:focus-visible {
        outline: 2px solid var(--accent);
        outline-offset: 2px;
    }

    .mermaid-zoom-fit {
        width: 34px;
        font-size: 11px;
    }

    .mermaid-zoom-percent {
        min-width: 44px;
        color: var(--text-secondary);
        font-size: 11px;
        font-variant-numeric: tabular-nums;
        text-align: center;
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
