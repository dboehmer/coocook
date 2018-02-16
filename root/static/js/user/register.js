$( function() {
    let $password  = $('input[name="password"]');
    let $password2 = $('input[name="password2"]');
    let $meter = $( '<span>' );

    $meter.insertAfter($password);
    $meter.before('&nbsp;');

    $password.on( 'change input', function() {
        var result = zxcvbn( $password.val() );

        var html = 'strength: ';
        html += '&#x2605;'.repeat( 1 + result.score );
        html += '&#x2606;'.repeat( 4 - result.score );

        $meter.html( html );
        $meter.attr( 'title', ( 1 + result.score ) + ' of 5' );
    });

    $password.change();

    let $comparator = $('<span>');

    $comparator.insertAfter($password2);
    $comparator.before('&nbsp;');

    $password.add($password2).on('change input', function() {
        let password  = $password .val();
        let password2 = $password2.val();

        if( password.length || password2.length ) {
            $comparator.text( password == password2 ? "matches" : "doesn't match" );
        }
        else {
            $comparator.text('');
        }
    });
} );
