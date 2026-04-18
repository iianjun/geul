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
                var result = await mermaid.render(prefix + i, source);
                pre.innerHTML = result.svg;
                container.classList.add('rendered');
            } catch(e) {
                pre.textContent = 'Mermaid rendering error: ' + e.message;
                pre.style.display = 'block';
                pre.style.color = 'var(--text-secondary)';
                var loading = container.querySelector('.geul-loading');
                if (loading) loading.style.display = 'none';
            }
        }
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
        renderMermaidDiagrams(container);
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
                var pre = c.querySelector('.mermaid');
                if (pre && c.dataset.mermaidSource) {
                    pre.textContent = c.dataset.mermaidSource;
                    pre.style.display = 'none';
                }
            });
            renderMermaidDiagrams(content);
        }
    }

    document.addEventListener('DOMContentLoaded', function() {
        initMermaid();
        renderMermaidDiagrams(document.getElementById('content'));
        renderMath(document.getElementById('content'));
    });
    """
}
