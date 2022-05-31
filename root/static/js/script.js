$(function() {

    // reduce options of <select> inputs for unit to units applicable to selected article
    $('select[name=article]').each(function() {
        let $article = $(this);
        let $unit    = $article.closest('form').find('select[name=unit]');

        if( $unit.length == 1 ) {
            let $units = $unit.find('option');

            // event handler
            $article.change(function() {
                let data_units = $article.find('option:selected').attr('data-units');

                if( ! data_units ) {    // no 'data-units' attribute, e.g. for "choose article" placeholder
                    $units.show();
                    return;
                }

                let units = data_units.split(',');
                let units_hash = {};
                units.forEach(function(unit) { units_hash[unit] = true } );

                $units.each(function() {
                    let $unit = $(this);
                    $unit.toggle( Boolean( units_hash[ $unit.attr('value') ] ) );
                });

                $units.prop('selected', false);

                // select first visible option ( :visible does not work properly for select options)
                $units.each(function () {
                    if ($(this).css('display') != 'none') {
                        $(this).prop('selected', true);
                        return false;
                    }
                });
            })
            .change();    // trigger on page load
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

});
