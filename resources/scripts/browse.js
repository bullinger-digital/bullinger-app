document.addEventListener('DOMContentLoaded', function () {
    pbEvents.subscribe('pb-login', null, function(ev) {
        if (ev.detail.userChanged) {
            pbEvents.emit('pb-search-resubmit', 'search');
        }
    });

    /* Parse the content received from the server */
    pbEvents.subscribe('pb-results-received', 'search', function(ev) {
        const { content } = ev.detail;
        /* Check if the server passed an element containing the current 
           collection in attribute data-root */
        const root = content.querySelector('[data-root]');
        const currentCollection = root ? root.getAttribute('data-root') : "";
        const writable = root ? root.classList.contains('writable') : false;
        
        /* Report the current collection and if it is writable.
           This is relevant for e.g. the pb-upload component */
        pbEvents.emit('pb-collection', 'search', {
            writable,
            collection: currentCollection
        });
        /* hide any element on the page which has attribute can-write */
        document.querySelectorAll('[can-write]').forEach((elem) => {
            elem.disabled = !writable;
        });

        /* Scan for links to collections and handle clicks */
        content.querySelectorAll('[data-collection]').forEach((link) => {
            link.addEventListener('click', (ev) => {
                ev.preventDefault();

                const collection = link.getAttribute('data-collection');
                // write the collection into a hidden input and resubmit the search
                document.querySelector('.options [name=collection]').value = collection;
                pbEvents.emit('pb-search-resubmit', 'search');
            });
        });
    });

    const customForms = document.querySelectorAll('.facets');
    if (customForms) {
        customForms.forEach((customForm) => {
            customForm.addEventListener('pb-custom-form-loaded', function(ev) {
                const elems = ev.detail.querySelectorAll('.facet');
                elems.forEach(facet => {
                    facet.addEventListener('change', () => {
                        const table = facet.closest('table');
                        if (table) {
                            table.querySelectorAll('.nested .facet').forEach(nested => {
                                if (nested != facet) {
                                    nested.checked = false;
                                }
                            });
                        }
                        customForm.submit();
                    });
                });
                ev.detail.querySelectorAll('pb-combo-box').forEach((select) => {
                    select.renderFunction = (data, escape) => {
                        if (data) {
                            return `<div>${escape(data.text)} <span class="freq">${escape(data.freq || '')}</span></div>`;
                        }
                        return '';
                    }
                });
            });
        });
    }

    const tlogs = document.querySelector('.travellogs');
    tlogs.addEventListener('pb-custom-form-loaded', function(ev) {
        const elems = ev.detail.querySelectorAll('paper-checkbox');
        elems.forEach(cb => cb.addEventListener('change', () => {
            pbEvents.emit('pb-search-resubmit', 'search');
        }));
    });

});

document.addEventListener('pb-page-loaded', function() {
    pbEvents.subscribe('pb-combo-box-change', null, function() {
        pbEvents.emit('pb-search-resubmit', 'search');
    });
});