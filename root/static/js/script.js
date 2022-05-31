"use strict";

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
    $('textarea.with-markdown-preview, input[type="text"].with-markdown-preview').each(function() {
        let $input   = $(this);
        let $row     = $('<div>', {class: 'row'}).insertBefore($input);
        let $preview = $('<div>', {class: 'markdown-preview'}).appendTo($row);

        $input.detach().prependTo($row);

        $input.addClass('col');
        $preview.addClass('col');

        $input.on('change input', function() {
            $preview.html( marked( $input.val() ) );
        }).change();
    });

});

const forms = document.getElementsByClassName('confirmIfUnsavedChanges');
let hasUnsavedChanges = false;

for( const form of forms ) {
    const inputs =      Array.prototype.slice.apply(form.getElementsByTagName('input'));
    const textareas =   Array.prototype.slice.apply(form.getElementsByTagName('textarea'));
    const selects =     Array.prototype.slice.apply(form.getElementsByTagName('select'));
    const elements =    inputs.concat(textareas).concat(selects);

    for( const elem of elements ) {
        elem.addEventListener('input', () => { if( !hasUnsavedChanges ) hasUnsavedChanges = true });
    }

    form.addEventListener('submit', () => { if( hasUnsavedChanges ) hasUnsavedChanges = false });
}

// See documentation about 'beforeunload' event on https://developer.mozilla.org/en-US/docs/Web/API/Window/beforeunload_event
window.addEventListener('beforeunload', (e) => {
    if( hasUnsavedChanges ) e.preventDefault(); //
});
