$(function() {
    // check 'preorder' when changing preorder details
    $('input[name="preorder_workdays"],input[name="preorder_servings"]').on( 'change click input', function() {
        $('input[name="preorder"').prop('checked', true);
    });

    // check 'shelf life' when changing shelf life period
    $('input[name="shelf_life_days"]').on( 'change click input', function() {
        $('input[name="shelf_life"').prop('checked', true);
    });
});
