(function() {
    const renderer = new marked.Renderer();

    function escapeHTML(text) {
        return String(text == null ? '' : text)
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;');
    }

    function highlightLanguageId(lang) {
        var value = String(lang == null ? '' : lang);
        return /^[A-Za-z0-9_+#.-]+$/.test(value) ? value : '';
    }

    function languageClassToken(language) {
        return language.replace(/[^A-Za-z0-9_-]/g, '-');
    }

    renderer.code = function({ text, lang }) {
        if (lang === 'mermaid') {
            return '<div class="mermaid-container">' +
                   '<div class="geul-loading">' +
                   '<div class="bar"></div><div class="bar"></div>' +
                   '<div class="bar"></div><div class="bar"></div>' +
                   '</div>' +
                   '<pre class="mermaid" style="display:none;">' +
                   escapeHTML(text) + '</pre></div>';
        }
        var language = highlightLanguageId(lang);
        var highlighted;
        if (language && hljs.getLanguage(language)) {
            highlighted = hljs.highlight(text, { language: language }).value;
        } else {
            highlighted = hljs.highlightAuto(text).value;
        }
        var classToken = language ? languageClassToken(language) : '';
        var cls = classToken ? 'hljs language-' + classToken : 'hljs';
        return '<pre><code class="' + cls + '">' + highlighted + '</code></pre>';
    };

    renderer.html = function(token) {
        var raw = token && (token.raw != null ? token.raw : token.text);
        return escapeHTML(raw);
    };

    marked.use({
        renderer: renderer,
        gfm: true,
        breaks: false,
        walkTokens: function(token) {
            if (token && token.type === 'html') {
                var raw = token.raw != null ? token.raw : (token.text || '');
                token.type = 'text';
                token.text = escapeHTML(raw);
                if (token.tokens) token.tokens = undefined;
            }
        }
    });

    globalThis.renderMarkdown = function(input) {
        return marked.parse(input);
    };
})();
