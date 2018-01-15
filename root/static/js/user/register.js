$( function() {
    let $password  = $('input[name="password"]');
    let $password2 = $('input[name="password2"]');
    let $meter = $( '<span>' );

    $meter.insertAfter($password);
    $meter.before('&nbsp;');

    $password.on( 'change input', function() {
        var result = zxcvbn( $password.val() );

        $meter.text( 'strength: ' + result.score + ' of 4' );
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
