(() => {
    document.querySelector('input[name="url"]')?.setAttribute('tabindex', -1);

    const MAX_STARS = 5;

    const passwordElem  = document.querySelector('input[name="password"]');
    const password2Elem = document.querySelector('input[name="password2"]');
    const meterElem =  document.createElement('span');
    passwordElem.parentElement.appendChild(meterElem);

    passwordElem.addEventListener('input', () => {
        const password = passwordElem.value;

        const stars = password == '' ? 0 : ( zxcvbn(password).score + 1 );

        let html = 'strength: ';
        html += '&#x2605;'.repeat(             stars );
        html += '&#x2606;'.repeat( MAX_STARS - stars );

        meterElem.innerHTML = html;
        meterElem.setAttribute( 'title', stars + ' of ' + MAX_STARS );
    });

    const comparatorElem = document.createElement('span');
    password2Elem.parentElement.appendChild(comparatorElem);

    [passwordElem, password2Elem].forEach(item => {
        item.addEventListener('input', () => {
            const password  = passwordElem.value;
            const password2 = password2Elem.value;

            if( password.length || password2.length ) {
                comparatorElem.innerHTML = password == password2 ? "matches" : "doesn't match";
            }
            else {
                comparatorElem.innerHTML = '';
            }
        });
    });
})();
