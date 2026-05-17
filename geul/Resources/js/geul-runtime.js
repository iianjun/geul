(function() {
    var currentColors = {};
    var currentHljsTheme = 'default';
    var themeCSSVariables = [
        '--bg-primary',
        '--bg-secondary',
        '--bg-code',
        '--bg-code-border',
        '--text-primary',
        '--text-secondary',
        '--text-tertiary',
        '--accent',
        '--accent-soft',
        '--border',
        '--border-strong',
        '--shadow-subtle'
    ];

    function readConfig() {
        var el = document.getElementById('geul-config');
        if (!el) return {};

        try {
            return JSON.parse(el.textContent || '{}');
        } catch(e) {
            console.error('[geul] config parse failed:', e);
            return {};
        }
    }

    function applyThemeVariables(colors) {
        colors = colors || {};
        themeCSSVariables.forEach(function(key) {
            document.documentElement.style.removeProperty(key);
        });
        Object.keys(colors).sort().forEach(function(key) {
            document.documentElement.style.setProperty(key, colors[key]);
        });
    }

    function setHighlightTheme(hljsKey) {
        currentHljsTheme = hljsKey === 'dark' ? 'dark' : 'default';
        document.documentElement.setAttribute('data-hljs-theme', currentHljsTheme);

        var lightLink = document.getElementById('geul-hljs-light');
        var darkLink = document.getElementById('geul-hljs-dark');
        if (lightLink) lightLink.disabled = currentHljsTheme === 'dark';
        if (darkLink) darkLink.disabled = currentHljsTheme !== 'dark';
    }

    function escapeHTML(text) {
        return String(text == null ? '' : text)
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;');
    }

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

    function initMermaid() {
        if (typeof mermaid === 'undefined') return;
        mermaid.initialize({
            startOnLoad: false,
            theme: 'base',
            themeVariables: buildMermaidThemeVariables(currentColors),
            securityLevel: 'loose'
        });
    }

    async function renderMermaidDiagrams(root) {
        if (!root) return;

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
            themeVariables: buildMermaidThemeVariables(currentColors),
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

    async function updateContent(html) {
        var findSnapshot = window.geulFind
            ? window.geulFind.prepareForContentUpdate()
            : null;
        var container = document.getElementById('content');
        if (!container) return null;

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
        currentColors = colors || {};
        applyThemeVariables(currentColors);
        setHighlightTheme(hljsKey);

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
                        escapeHTML(c.dataset.mermaidSource) +
                        '</pre>';
                }
            });
            renderMermaidDiagrams(content);
        }
    }

    function setReaderAlignment(alignment) {
        var allowed = ['left', 'center', 'right'];
        var value = allowed.indexOf(alignment) === -1 ? 'left' : alignment;
        var content = document.getElementById('content');
        if (!content) return;

        content.classList.remove(
            'reader-align-left',
            'reader-align-center',
            'reader-align-right'
        );
        content.classList.add('reader-align-' + value);
    }

    var config = readConfig();
    currentColors = config.colors || {};
    applyThemeVariables(currentColors);
    setHighlightTheme(config.hljsTheme);
    setReaderAlignment(config.readerAlignment || 'left');

    window.geul = {
        updateContent: updateContent,
        setTheme: setTheme,
        setReaderAlignment: setReaderAlignment
    };

    window.updateContent = updateContent;
    window.setTheme = setTheme;
    window.setReaderAlignment = setReaderAlignment;

    document.addEventListener('DOMContentLoaded', function() {
        try {
            initMermaid();
            renderMermaidDiagrams(document.getElementById('content'));
        } catch(e) {
            console.error('[geul] Mermaid init failed:', e);
        }
        renderMath(document.getElementById('content'));
    });
})();
