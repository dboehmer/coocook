(() => {
    // check 'preorder' when changing preorder details
    const preorderInputElem = document.getElementById('preorder');
    const preorderWorkdaysInputElem = document.getElementById('preorder_workdays');
    const preorderServingsInputElem = document.getElementById('preorder_servings');
    [preorderWorkdaysInputElem, preorderServingsInputElem].forEach(elem => {
        elem.addEventListener('input', () => preorderInputElem.checked = true);
    });

    // check 'shelf life' when changing shelf life period
    const shelfLifeInputElem = document.getElementById('shelf_life');
    const shelfLifeDaysInputElem = document.getElementById('shelf_life_days');
    shelfLifeDaysInputElem.addEventListener('input', () => shelfLifeInputElem.checked = true);
})();
