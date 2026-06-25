(function() {
    var state = {
        query: '',
        index: -1,
        total: 0,
        version: 0
    };

    function contentRoot() {
        return document.getElementById('content');
    }

    function result() {
        return {
            query: state.query,
            currentIndex: state.index,
            total: state.total
        };
    }

    function clearSelection() {
        var selection = window.getSelection
            ? window.getSelection()
            : null;
        if (selection) selection.removeAllRanges();
    }

    function setFindStart() {
        var root = contentRoot();
        var selection = window.getSelection
            ? window.getSelection()
            : null;
        if (!root || !selection || typeof document.createRange !== 'function') {
            return;
        }

        var range = document.createRange();
        range.setStart(root, 0);
        range.collapse(true);
        selection.removeAllRanges();
        selection.addRange(range);
    }

    function resetMatches() {
        state.total = 0;
        state.index = -1;
    }

    function isSearchableTextNode(node) {
        if (!node.nodeValue || node.nodeValue.length === 0) return false;

        var parent = node.parentElement;
        if (!parent) return false;

        var blockedTags = ['script', 'style', 'textarea', 'noscript'];
        if (blockedTags.indexOf(parent.tagName.toLowerCase()) !== -1) return false;
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

    function buildRenderedTextIndex(container) {
        var text = '';

        textNodes(container).forEach(function(node) {
            text += node.nodeValue;
        });

        return {
            text: text
        };
    }

    function countTextMatches(text, query) {
        var count = 0;
        var needle = query.toLowerCase();

        if (needle.length === 0) {
            return count;
        }

        for (var i = 0; i <= text.length - query.length; i++) {
            if (text.slice(i, i + query.length).toLowerCase() !== needle) {
                continue;
            }

            count += 1;
            i += query.length - 1;
        }

        return count;
    }

    function countMatches(query) {
        if (!query || query.length === 0) {
            return 0;
        }

        var root = contentRoot();
        if (!root) {
            return 0;
        }

        var index = buildRenderedTextIndex(root);
        return countTextMatches(index.text, query);
    }

    function activate(index) {
        if (state.total === 0) {
            resetMatches();
            return result();
        }

        state.index = ((index % state.total) + state.total) % state.total;

        return result();
    }

    function search(query) {
        state.query = query || '';
        state.version += 1;

        if (state.query.length === 0) {
            resetMatches();
            clearSelection();
            return result();
        }

        state.total = countMatches(state.query);
        if (state.total === 0) {
            state.index = -1;
            clearSelection();
            return result();
        }

        setFindStart();
        return activate(0);
    }

    function prepareForContentUpdate() {
        var snapshot = {
            query: state.query,
            version: state.version
        };
        clearSelection();
        return snapshot;
    }

    function restoreAfterContentUpdate(snapshot) {
        if (!snapshot) {
            return result();
        }

        var query = state.version === snapshot.version
            ? snapshot.query
            : state.query;

        if (query) {
            return search(query);
        }

        resetMatches();
        clearSelection();
        return result();
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
            state.version += 1;
            resetMatches();
            clearSelection();
            return result();
        },
        currentQuery: function() {
            return state.query;
        },
        countMatches: countMatches,
        prepareForContentUpdate: prepareForContentUpdate,
        restoreAfterContentUpdate: restoreAfterContentUpdate,
        currentVersion: function() {
            return state.version;
        }
    };
})();
