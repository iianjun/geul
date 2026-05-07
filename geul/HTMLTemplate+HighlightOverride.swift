import Foundation

extension HTMLTemplate {

    static let highlightOverrideCSS = """
    pre code.hljs {
        padding: 0;
        background: transparent;
        color: var(--text-primary);
    }

    .hljs-keyword,
    .hljs-literal,
    .hljs-built_in,
    .hljs-type,
    .hljs-selector-tag {
        color: #82D2CE;
    }

    .hljs-meta .hljs-keyword {
        color: #82D2CE;
    }

    .hljs-title,
    .hljs-function,
    .hljs-params,
    .hljs-section,
    .hljs-name {
        color: #efb080;
    }

    .hljs-title.function_,
    .hljs-title.class_ {
        color: #efb080;
    }

    .hljs-string,
    .hljs-meta-string,
    .hljs-template-variable {
        color: #e394dc;
    }

    .hljs-meta .hljs-string {
        color: #e394dc;
    }

    .hljs-number,
    .hljs-symbol,
    .hljs-bullet,
    .hljs-attribute {
        color: #ebc88d;
    }

    .hljs-attr,
    .hljs-variable,
    .hljs-property {
        color: #AAA0FA;
    }

    .hljs-variable.language_ {
        color: #AAA0FA;
    }

    .hljs-comment,
    .hljs-quote {
        color: #E4E4E45E;
        font-style: italic;
    }

    .hljs-meta,
    .hljs-tag {
        color: #d6d6dd;
    }

    .hljs-addition {
        background-color: rgba(63, 162, 102, 0.2);
        color: #70B489;
    }

    .hljs-deletion {
        background-color: rgba(184, 0, 73, 0.2);
        color: #FC6B83;
    }

    .hljs-emphasis {
        font-style: italic;
    }

    .hljs-strong {
        font-weight: bold;
    }
    """
}
