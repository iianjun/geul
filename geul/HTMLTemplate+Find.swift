import Foundation

extension HTMLTemplate {

    static let findCSS = #"""
    mark.geul-find-match {
        padding: 0 2px;
        border-radius: 3px;
        background: color-mix(in srgb, var(--accent) 28%, transparent);
        color: inherit;
    }

    mark.geul-find-match.geul-find-active {
        background: var(--accent);
        color: #ffffff;
        box-shadow: 0 0 0 2px color-mix(in srgb, var(--accent) 28%, transparent);
    }
    """#

    static let findScript = #"""
    (function() {
        var state = {
            query: '',
            marks: [],
            index: -1
        };

        function contentRoot() {
            return document.getElementById('content');
        }

        function result() {
            return {
                query: state.query,
                currentIndex: state.index,
                total: state.marks.length
            };
        }

        function removeMarks() {
            state.marks.forEach(function(mark) {
                var parent = mark.parentNode;
                if (!parent) return;

                while (mark.firstChild) {
                    parent.insertBefore(mark.firstChild, mark);
                }

                parent.removeChild(mark);
                parent.normalize();
            });

            state.marks = [];
            state.index = -1;
        }

        function isSearchableTextNode(node) {
            if (!node.nodeValue || node.nodeValue.length === 0) return false;

            var parent = node.parentElement;
            if (!parent) return false;

            var blockedTags = ['script', 'style', 'textarea', 'noscript'];
            if (blockedTags.indexOf(parent.tagName.toLowerCase()) !== -1) return false;
            if (parent.closest('mark.geul-find-match')) return false;
            if (parent.closest('svg')) return false;

            return true;
        }

        function textNodes(container) {
            var nodes = [];
            var walker = document.createTreeWalker(
                container,
                NodeFilter.SHOW_TEXT,
                {
                    acceptNode: function(node) {
                        return isSearchableTextNode(node)
                            ? NodeFilter.FILTER_ACCEPT
                            : NodeFilter.FILTER_REJECT;
                    }
                }
            );

            while (walker.nextNode()) {
                nodes.push(walker.currentNode);
            }

            return nodes;
        }

        function collectMatches(node, query) {
            var matches = [];
            var text = node.nodeValue;
            var needle = query.toLowerCase();

            if (needle.length === 0) {
                return matches;
            }

            for (var i = 0; i <= text.length - query.length; i++) {
                if (text.slice(i, i + query.length).toLowerCase() !== needle) {
                    continue;
                }

                matches.push({
                    node: node,
                    start: i,
                    length: query.length
                });

                i += query.length - 1;
            }

            return matches;
        }

        function applyMatches(matches) {
            for (var i = matches.length - 1; i >= 0; i--) {
                var match = matches[i];
                var node = match.node;
                var selected = node.splitText(match.start);
                selected.splitText(match.length);

                var mark = document.createElement('mark');
                mark.className = 'geul-find-match';
                mark.textContent = selected.nodeValue;
                selected.parentNode.replaceChild(mark, selected);
            }

            state.marks = Array.prototype.slice.call(
                document.querySelectorAll('article#content mark.geul-find-match')
            );
        }

        function activate(index) {
            state.marks.forEach(function(mark) {
                mark.classList.remove('geul-find-active');
            });

            if (state.marks.length === 0) {
                state.index = -1;
                return result();
            }

            state.index = ((index % state.marks.length) + state.marks.length)
                % state.marks.length;

            var active = state.marks[state.index];
            active.classList.add('geul-find-active');
            active.scrollIntoView({
                block: 'center',
                inline: 'nearest',
                behavior: 'smooth'
            });

            return result();
        }

        function search(query) {
            removeMarks();
            state.query = query || '';

            if (state.query.length === 0) {
                return result();
            }

            var root = contentRoot();
            if (!root) {
                return result();
            }

            var matches = [];
            textNodes(root).forEach(function(node) {
                matches = matches.concat(collectMatches(node, state.query));
            });

            applyMatches(matches);
            return activate(0);
        }

        window.geulFind = {
            search: search,
            next: function() {
                return activate(state.index + 1);
            },
            previous: function() {
                return activate(state.index - 1);
            },
            clear: function() {
                state.query = '';
                removeMarks();
                return result();
            },
            currentQuery: function() {
                return state.query;
            }
        };
    })();
    """#
}
