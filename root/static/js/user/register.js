$( function() {
    $('input[name="url"]').attr('tabindex', -1);

    var MAX_STARS = 5;

    let $password  = $('input[name="password"]');
    let $password2 = $('input[name="password2"]');
    let $meter = $( '<span>' );

    $meter.insertAfter($password);
    $meter.before('&nbsp;');

    $password.on( 'change input', function() {
        let password = $password.val();

        let stars = password == '' ? 0 : ( zxcvbn(password).score + 1 );

        let html = 'strength: ';
        html += '&#x2605;'.repeat(             stars );
        html += '&#x2606;'.repeat( MAX_STARS - stars );

        $meter.html( html );
        $meter.attr( 'title', stars + ' of ' + MAX_STARS );
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
