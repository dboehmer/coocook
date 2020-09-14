// properties comes from root/templates/project/import.tt

for ( var property of properties ) {
    if( property.depends_on.length || property.dependency_of.length ) {
        let depends_on    = property.depends_on   .map(function(key) { return document.getElementById('property_' + key) });
        let dependency_of = property.dependency_of.map(function(key) { return document.getElementById('property_' + key) });

        let prop = document.getElementById('property_' + property.key);

        prop.addEventListener( 'change', function() {
            if( this.checked ) {
                depends_on.forEach(function(dep) { dep.checked = true; dep.dispatchEvent(new Event('change')) });
            }
            else {
                dependency_of.forEach(function(dep) { dep.checked = false; dep.dispatchEvent(new Event('change')) });
            }
        });
    }
}

// JavaScript worked until here -> remove warning
document.getElementById('jsWarning').remove();
