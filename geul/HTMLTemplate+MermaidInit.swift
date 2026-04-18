import Foundation

extension HTMLTemplate {

    static let mermaidInitScript = """
    function buildMermaidThemeVariables(colors) {
        colors = colors || {};
        return {
            primaryColor: colors['--bg-secondary'],
            primaryTextColor: colors['--text-primary'],
            primaryBorderColor: colors['--border-strong'],
            lineColor: colors['--text-tertiary'],
            secondaryColor: colors['--bg-code'],
            tertiaryColor: colors['--bg-primary'],
            background: colors['--bg-primary']
        };
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

    function updateContent(html) {
        var container = document.getElementById('content');
        if (!container) return;
        container.innerHTML = html;
        try {
            renderMermaidDiagrams(container);
        } catch(e) {
            console.error('[geul] Mermaid render failed:', e);
        }
        renderMath(container);
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

        var content = document.getElementById('content');
        if (content) {
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
