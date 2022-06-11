(() => {
    document.querySelector('input[name="url"]')?.setAttribute('tabindex', -1);

    const MAX_STARS = 5;

    const passwordElem  = document.querySelector('input[name="password"]');
    const password2Elem = document.querySelector('input[name="password2"]');
    const meterElem =  document.getElementById('meter');

    let html = 'strength: ' + '&#x2606;'.repeat( MAX_STARS );
    meterElem.innerHTML = html;

    passwordElem.addEventListener('input', () => {
        let password = passwordElem.value;

        let stars = password == '' ? 0 : ( zxcvbn(password).score + 1 );

        html = 'strength: ';
        html += '&#x2605;'.repeat(             stars );
        html += '&#x2606;'.repeat( MAX_STARS - stars );

        meterElem.innerHTML = html;
        meterElem.setAttribute( 'title', stars + ' of ' + MAX_STARS );
    });

    const comparatorElem = document.getElementById('comparator');

    [passwordElem, password2Elem].forEach(item => {
        item.addEventListener('input', () => {
            let password  = passwordElem.value;
            let password2 = password2Elem.value;

            if( (password.length && password2.length) || (password2.length) ) {
                comparatorElem.innerHTML = password == password2 ? "matches" : "doesn't match";
            }
            else {
                comparatorElem.innerHTML = '';
            }
        });
    });
})();
