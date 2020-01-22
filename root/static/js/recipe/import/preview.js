$( function() {
    $('form#import table td.article select').change(function() {
        let $this = $(this);

        let $selectedOption = $this.find('option:selected');

        let $unit = $this.closest('tr').find('td.unit select');
        let $units = $unit.find('option');

        if( !$selectedOption.val() ) {
            $units.show();
            return;
        }

        let unitIds = $selectedOption.attr('data-units').split(',');

        // if select unit is not applicable to article, reset unit selector
        if( unitIds.indexOf( $unit.val() ) == -1 ) {
            $unit.val('');
        }

        // show only applicable units
        $units.each( function() {
            let $u = $(this);
            let unitId = $u.val();

            $u.toggle( unitId == '' || unitIds.indexOf(unitId) > -1 );
        });
    }).trigger('change');

    // check uniqueness of recipe name
    $('form#import input[name="name"]').on('change input', function() {
        let name = this.value;

        this.setCustomValidity( existingRecipeNames.indexOf(name) == -1 ? '' : "This recipe name already exists in this project" );
    }).trigger('input');

    // skip checkboxes
    $('form#import table td.import input[type="checkbox"]').on( 'change', function() {
        let skip = !this.checked;
        let $tr = $(this).closest('tr');

        $tr.toggleClass( 'skip', skip );

        $tr.find('input,select').not(this).prop( 'disabled', skip );
    }).trigger('change');
} );
