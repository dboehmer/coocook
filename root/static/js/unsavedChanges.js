"use strict";

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
