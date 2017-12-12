$(function() {

    $('select[name=article]').each(function() {
        let $article = $(this);
        let $unit    = $article.closest('form').find('select[name=unit]');

        if( $unit.length == 1 ) {
            let $units = $unit.find('option');

            $article.change(function() {
                var units = $article.find('option:selected').attr('data-units').split(',');

                var units_hash = {};
                units.forEach(function(unit) { units_hash[unit] = true } );

                $units.each(function() {
                    var $unit = $(this);
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
            .change();
        }
    });

});
