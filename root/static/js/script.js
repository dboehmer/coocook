(() => {

    // reduce options of <select> inputs for unit to units applicable to selected article
    const articleElems = document.getElementsByName('article');
    Array.from(articleElems).forEach(articleElem => {
        const unitElem = articleElem.closest('form').querySelector('select[name=unit]');

        if( unitElem.type == "select-one" ) {
            const unitOptionElems = unitElem.options;

            // event handler
            articleElem.onchange = () => {
                let data_units = articleElem.options[articleElem.selectedIndex].getAttribute('data-units');

                let units = data_units.split(',');
                let units_hash = {};
                units.forEach(function(unit) { units_hash[unit] = true } );

                Array.from(unitOptionElems).forEach(unitOptionElem => {
                    if( Boolean( units_hash[ unitOptionElem.value ] ) ) {
                        unitOptionElem.disabled = false; // if option was disabled, it must be enabled
                        unitOptionElem.style.display = "block";
                        unitOptionElem.selected = true;
                    } else {
                        unitOptionElem.style.display = "none";
                        unitOptionElem.disabled = true; // unable option for selection
                    }
                });
            }
        }
    });

    // show Markdown preview right of <textarea> inputs with class .with-markdown-preview
    document.querySelectorAll("textarea.with-markdown-preview, input[type=text].with-markdown-preview").forEach( elem => {
        let row = elem.parentNode.parentNode;
        let col = document.createElement("div");
        col.className = "col-sm-6";
        let preview = document.createElement("div");
        preview.className = "markdown-preview";

        col.append(preview)
        row.append(col);

        elem.addEventListener("input", e => {
            preview.innerHTML = marked(e.target.value);
        });

        elem.dispatchEvent(new Event("input"));

        if (elem.tagName === "TEXTAREA") {
            let obs = new ResizeObserver(() => {
                let height = elem.clientHeight;
                // Adding 2px to height to prevent infinity loop of resizing
                preview.style.height = `${height + 2}px`;
            });

            obs.observe(elem);

            const syncScrolling = (e, linkedElem) => {
                linkedElem.scrollTop = e.currentTarget.scrollTop;
            }

            elem.addEventListener("scroll", e => syncScrolling(e, preview));
            preview.addEventListener("scroll", e => syncScrolling(e, elem));
        }
    });

})();
