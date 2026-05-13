import Foundation

extension HTMLTemplate {

    static let mermaidInitScript = """
    function buildMermaidThemeVariables(colors) {
        colors = colors || {};
        return {
            background: colors['--bg-primary'],
            mainBkg: colors['--bg-primary'],
            primaryColor: colors['--bg-primary'],
            primaryTextColor: colors['--text-primary'],
            secondaryTextColor: colors['--text-primary'],
            tertiaryTextColor: colors['--text-secondary'],
            primaryBorderColor: colors['--border-strong'],
            nodeBorder: colors['--border-strong'],
            lineColor: colors['--border-strong'],
            secondaryColor: colors['--bg-code'],
            clusterBkg: colors['--bg-secondary'],
            clusterBorder: colors['--border'],
            edgeLabelBackground: colors['--bg-primary'],
            tertiaryColor: colors['--bg-primary'],
            textColor: colors['--text-primary']
        };
    }

    var geulMermaidZoomActiveOverlay = null;
    var geulMermaidZoomLastOpener = null;
    var geulMermaidZoomOptions = {
        minScale: 0.25,
        maxScale: 6,
        zoomStep: 1.2,
        fitPadding: 56
    };

    function clampMermaidZoomScale(scale) {
        return Math.min(
            geulMermaidZoomOptions.maxScale,
            Math.max(geulMermaidZoomOptions.minScale, scale)
        );
    }

    function closeMermaidZoomOverlay() {
        if (!geulMermaidZoomActiveOverlay) return;

        var overlay = geulMermaidZoomActiveOverlay;
        var opener = geulMermaidZoomLastOpener;
        geulMermaidZoomActiveOverlay = null;
        geulMermaidZoomLastOpener = null;

        if (typeof overlay.geulCleanup === 'function') {
            overlay.geulCleanup();
        }
        overlay.remove();

        if (opener && document.contains(opener)) {
            opener.focus();
        }
    }

    function installMermaidZoomControls(container) {
        if (!container || container.classList.contains('mermaid-error')) return;

        var svg = container.querySelector('.mermaid svg');
        if (!svg) return;

        var existing = container.querySelector('.mermaid-zoom-button');
        if (existing) existing.remove();

        var button = document.createElement('button');
        button.type = 'button';
        button.className = 'mermaid-zoom-button';
        button.title = 'Open diagram zoom viewer';
        button.setAttribute('aria-label', 'Open diagram zoom viewer');
        button.innerHTML =
            '<svg viewBox="0 0 16 16" aria-hidden="true" focusable="false">' +
            '<path fill="currentColor" d="M2 6V2h4v1.4H4.4l3.1 3.1-1 1L3.4 4.4V6H2z"/>' +
            '<path fill="currentColor" d="M10 2h4v4h-1.4V4.4L9.5 7.5l-1-1 3.1-3.1H10V2z"/>' +
            '<path fill="currentColor" d="M6.5 8.5l1 1-3.1 3.1H6V14H2v-4h1.4v1.6l3.1-3.1z"/>' +
            '<path fill="currentColor" d="M9.5 8.5l3.1 3.1V10H14v4h-4v-1.4h1.6L8.5 9.5l1-1z"/>' +
            '</svg>';
        button.addEventListener('click', function(event) {
            event.preventDefault();
            event.stopPropagation();
            openMermaidZoomOverlay(container, button);
        });

        container.appendChild(button);
    }

    function mermaidZoomSourceSize(sourceSvg) {
        var viewBox = sourceSvg.viewBox && sourceSvg.viewBox.baseVal;
        if (viewBox && viewBox.width > 0 && viewBox.height > 0) {
            return { width: viewBox.width, height: viewBox.height };
        }

        var rect = sourceSvg.getBoundingClientRect();
        if (rect.width > 0 && rect.height > 0) {
            return { width: rect.width, height: rect.height };
        }

        return null;
    }

    function updateMermaidZoomTransform(state) {
        state.content.style.transform =
            'translate(-50%, -50%) translate(' + state.x + 'px, ' + state.y + 'px) ' +
            'scale(' + state.scale + ')';
        state.percent.textContent = Math.round(state.scale * 100) + '%';
    }

    function fitMermaidZoomToStage(state) {
        var stageRect = state.stage.getBoundingClientRect();
        var availableWidth = Math.max(1, stageRect.width - geulMermaidZoomOptions.fitPadding);
        var availableHeight = Math.max(1, stageRect.height - geulMermaidZoomOptions.fitPadding);
        var fitScale = Math.min(
            availableWidth / state.sourceSize.width,
            availableHeight / state.sourceSize.height
        );

        state.scale = clampMermaidZoomScale(fitScale);
        state.x = 0;
        state.y = 0;
        updateMermaidZoomTransform(state);
    }

    function zoomMermaidOverlayTo(state, nextScale, anchorX, anchorY) {
        var clampedScale = clampMermaidZoomScale(nextScale);
        var stageRect = state.stage.getBoundingClientRect();
        var centerX = stageRect.left + (stageRect.width / 2) + state.x;
        var centerY = stageRect.top + (stageRect.height / 2) + state.y;
        var targetX = anchorX == null ? stageRect.left + (stageRect.width / 2) : anchorX;
        var targetY = anchorY == null ? stageRect.top + (stageRect.height / 2) : anchorY;
        var contentX = (targetX - centerX) / state.scale;
        var contentY = (targetY - centerY) / state.scale;

        state.scale = clampedScale;
        state.x = targetX - (stageRect.left + (stageRect.width / 2)) - (contentX * state.scale);
        state.y = targetY - (stageRect.top + (stageRect.height / 2)) - (contentY * state.scale);
        updateMermaidZoomTransform(state);
    }

    function makeMermaidZoomButton(className, label, text) {
        var button = document.createElement('button');
        button.type = 'button';
        button.className = className;
        button.setAttribute('aria-label', label);
        button.title = label;
        button.textContent = text;
        return button;
    }

    function openMermaidZoomOverlay(container, opener) {
        var sourceSvg = container ? container.querySelector('.mermaid svg') : null;
        if (!sourceSvg) {
            console.warn('[geul] Mermaid zoom requested without a rendered SVG');
            return;
        }

        var sourceSize = mermaidZoomSourceSize(sourceSvg);
        if (!sourceSize) {
            console.warn('[geul] Mermaid zoom requested before SVG dimensions were available');
            return;
        }

        closeMermaidZoomOverlay();
        geulMermaidZoomLastOpener = opener || null;

        var overlay = document.createElement('div');
        overlay.className = 'mermaid-zoom-overlay';
        overlay.setAttribute('role', 'dialog');
        overlay.setAttribute('aria-modal', 'true');
        overlay.setAttribute('aria-label', 'Mermaid diagram zoom viewer');

        var dialog = document.createElement('div');
        dialog.className = 'mermaid-zoom-dialog';

        var stage = document.createElement('div');
        stage.className = 'mermaid-zoom-stage';

        var content = document.createElement('div');
        content.className = 'mermaid-zoom-content';

        var clone = sourceSvg.cloneNode(true);
        clone.removeAttribute('style');
        clone.setAttribute('width', sourceSize.width);
        clone.setAttribute('height', sourceSize.height);
        clone.setAttribute('aria-hidden', 'true');
        content.appendChild(clone);
        stage.appendChild(content);

        var toolbar = document.createElement('div');
        toolbar.className = 'mermaid-zoom-toolbar';

        var zoomOut = makeMermaidZoomButton('mermaid-zoom-control', 'Zoom out', '-');
        var percent = document.createElement('span');
        percent.className = 'mermaid-zoom-percent';
        percent.textContent = '100%';
        var zoomIn = makeMermaidZoomButton('mermaid-zoom-control', 'Zoom in', '+');
        var fit = makeMermaidZoomButton('mermaid-zoom-control mermaid-zoom-fit', 'Fit diagram', 'Fit');
        var close = makeMermaidZoomButton('mermaid-zoom-control', 'Close diagram zoom viewer', 'x');

        toolbar.appendChild(zoomOut);
        toolbar.appendChild(percent);
        toolbar.appendChild(zoomIn);
        toolbar.appendChild(fit);
        toolbar.appendChild(close);

        dialog.appendChild(stage);
        dialog.appendChild(toolbar);
        overlay.appendChild(dialog);
        document.body.appendChild(overlay);

        var state = {
            overlay: overlay,
            stage: stage,
            content: content,
            percent: percent,
            sourceSize: sourceSize,
            scale: 1,
            x: 0,
            y: 0
        };

        var dragging = null;

        function onKeyDown(event) {
            if (event.key === 'Escape') {
                event.preventDefault();
                closeMermaidZoomOverlay();
            }
        }

        function onPointerMove(event) {
            if (!dragging) return;
            state.x = dragging.startX + event.clientX - dragging.pointerX;
            state.y = dragging.startY + event.clientY - dragging.pointerY;
            updateMermaidZoomTransform(state);
        }

        function onPointerUp(event) {
            if (!dragging) return;
            dragging = null;
            stage.classList.remove('dragging');
            try {
                stage.releasePointerCapture(event.pointerId);
            } catch(e) {
                // Pointer capture may already be released by WebKit.
            }
        }

        overlay.geulCleanup = function() {
            document.removeEventListener('keydown', onKeyDown);
            stage.removeEventListener('pointermove', onPointerMove);
            stage.removeEventListener('pointerup', onPointerUp);
            stage.removeEventListener('pointercancel', onPointerUp);
        };

        overlay.addEventListener('click', function(event) {
            if (event.target === overlay) {
                closeMermaidZoomOverlay();
            }
        });

        close.addEventListener('click', closeMermaidZoomOverlay);
        fit.addEventListener('click', function() {
            fitMermaidZoomToStage(state);
        });
        zoomIn.addEventListener('click', function() {
            zoomMermaidOverlayTo(state, state.scale * geulMermaidZoomOptions.zoomStep);
        });
        zoomOut.addEventListener('click', function() {
            zoomMermaidOverlayTo(state, state.scale / geulMermaidZoomOptions.zoomStep);
        });

        stage.addEventListener('wheel', function(event) {
            event.preventDefault();
            var direction = event.deltaY < 0 ? geulMermaidZoomOptions.zoomStep : 1 / geulMermaidZoomOptions.zoomStep;
            zoomMermaidOverlayTo(state, state.scale * direction, event.clientX, event.clientY);
        }, { passive: false });

        stage.addEventListener('pointerdown', function(event) {
            if (event.button !== 0) return;
            event.preventDefault();
            dragging = {
                pointerX: event.clientX,
                pointerY: event.clientY,
                startX: state.x,
                startY: state.y
            };
            stage.classList.add('dragging');
            stage.setPointerCapture(event.pointerId);
        });
        stage.addEventListener('pointermove', onPointerMove);
        stage.addEventListener('pointerup', onPointerUp);
        stage.addEventListener('pointercancel', onPointerUp);
        document.addEventListener('keydown', onKeyDown);

        geulMermaidZoomActiveOverlay = overlay;
        fitMermaidZoomToStage(state);
        close.focus();
    }

    function initMermaid() {
        if (typeof mermaid === 'undefined') return;
        mermaid.initialize({
            startOnLoad: false,
            theme: 'base',
            themeVariables: buildMermaidThemeVariables(window.__geulCurrentColors),
            securityLevel: 'loose'
        });
    }

    async function renderMermaidDiagrams(root) {
        var containers = root.querySelectorAll('.mermaid-container');
        if (containers.length === 0) return;

        if (typeof mermaid === 'undefined') {
            containers.forEach(function(c) {
                showMermaidError(c, new Error('Mermaid library not loaded'));
            });
            return;
        }

        mermaid.initialize({
            startOnLoad: false,
            theme: 'base',
            themeVariables: buildMermaidThemeVariables(window.__geulCurrentColors),
            securityLevel: 'loose'
        });

        var prefix = 'mermaid-' + Date.now() + '-';
        for (var i = 0; i < containers.length; i++) {
            var container = containers[i];
            var pre = container.querySelector('.mermaid');
            if (!pre) continue;

            try {
                if (!container.dataset.mermaidSource) {
                    container.dataset.mermaidSource = pre.textContent;
                }
                var source = container.dataset.mermaidSource;
                await mermaid.parse(source);
                var result = await mermaid.render(prefix + i, source);
                pre.innerHTML = result.svg;
                container.classList.add('rendered');
                installMermaidZoomControls(container);
            } catch(e) {
                showMermaidError(container, e);
            }
        }
    }

    function showMermaidError(container, error) {
        var source = container.dataset.mermaidSource || '';
        var message = '';
        if (error) {
            message = error.str
                   || error.message
                   || (error.hash && error.hash.text)
                   || String(error);
        } else {
            message = String(error);
        }
        container.innerHTML = '';
        container.classList.remove('rendered');
        container.classList.add('mermaid-error');

        var header = document.createElement('div');
        header.className = 'mermaid-error-header';
        header.textContent = 'Mermaid rendering failed';

        var msg = document.createElement('div');
        msg.className = 'mermaid-error-message';
        msg.textContent = message;

        var pre = document.createElement('pre');
        pre.className = 'mermaid-error-source';
        pre.textContent = source;

        container.appendChild(header);
        container.appendChild(msg);
        container.appendChild(pre);
    }

    function renderMath(root) {
        if (!root || typeof renderMathInElement !== 'function') return;
        renderMathInElement(root, {
            delimiters: [
                { left: '$$', right: '$$', display: true },
                { left: '$',  right: '$',  display: false }
            ],
            throwOnError: false,
            errorColor: 'var(--accent)',
            ignoredTags: ['script','noscript','style','textarea','pre','code','option']
        });
    }

    async function updateContent(html) {
        var findSnapshot = window.geulFind
            ? window.geulFind.prepareForContentUpdate()
            : null;
        var container = document.getElementById('content');
        if (!container) return null;

        closeMermaidZoomOverlay();
        container.innerHTML = html;
        try {
            await renderMermaidDiagrams(container);
        } catch(e) {
            console.error('[geul] Mermaid render failed:', e);
        }
        renderMath(container);

        if (window.geulFind) {
            return window.geulFind.restoreAfterContentUpdate(findSnapshot);
        }

        return null;
    }

    function setTheme(colors, hljsKey) {
        window.__geulCurrentColors = colors;

        var lines = Object.keys(colors).sort().map(function(k) {
            return '    ' + k + ': ' + colors[k] + ';';
        }).join('\\n');
        var css = ':root {\\n' + lines + '\\n}';
        var styleEl = document.getElementById('geul-theme');
        if (styleEl) styleEl.textContent = css;

        var hljs = document.getElementById('geul-hljs');
        if (hljs && window.__geulHljsCSS) {
            hljs.textContent = window.__geulHljsCSS[hljsKey] || window.__geulHljsCSS.default;
        }

        var hljsOverride = document.getElementById('geul-hljs-override');
        if (hljsOverride) {
            var overrides = window.__geulHljsOverrideCSS || {};
            hljsOverride.textContent = overrides[hljsKey] || overrides.default || '';
        }

        var content = document.getElementById('content');
        if (content) {
            closeMermaidZoomOverlay();
            var containers = content.querySelectorAll('.mermaid-container');
            containers.forEach(function(c) {
                c.classList.remove('rendered');
                c.classList.remove('mermaid-error');
                if (c.dataset.mermaidSource) {
                    c.innerHTML =
                        '<div class="geul-loading">' +
                        '<div class="bar"></div><div class="bar"></div>' +
                        '<div class="bar"></div><div class="bar"></div>' +
                        '</div>' +
                        '<pre class="mermaid" style="display:none;">' +
                        c.dataset.mermaidSource.replace(/&/g, '&amp;')
                                              .replace(/</g, '&lt;')
                                              .replace(/>/g, '&gt;') +
                        '</pre>';
                }
            });
            renderMermaidDiagrams(content);
        }
    }

    document.addEventListener('DOMContentLoaded', function() {
        try {
            initMermaid();
            renderMermaidDiagrams(document.getElementById('content'));
        } catch(e) {
            console.error('[geul] Mermaid init failed:', e);
        }
        renderMath(document.getElementById('content'));
    });
    """
}
