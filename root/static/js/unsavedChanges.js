const forms = document.getElementsByClassName('confirmIfUnsavedChanges');
let hasUnsavedChanges = false;

for(const form of forms) {
    const inputs = Array.prototype.slice.apply(form.getElementsByTagName('input'));
    const textareas = Array.prototype.slice.apply(form.getElementsByTagName('textarea'));
    const selects = Array.prototype.slice.apply(form.getElementsByTagName('select'));
    const elements = inputs.concat(textareas).concat(selects);
    console.log(elements)
    for(const elem of elements) {
        elem.addEventListener('input', () => {if(!hasUnsavedChanges) hasUnsavedChanges = true});
    }
    form.addEventListener('submit', () => {if(hasUnsavedChanges) hasUnsavedChanges = false});
}

window.addEventListener('beforeunload', (e) => {
    if (hasUnsavedChanges) {
        (e || window.event).returnValue = '';
        return '';
    }
})