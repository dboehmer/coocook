#!/bin/bash

# ABSTRACT: script to migrate data from SQLite to PostgreSQL

set -e

### command line arguments ###

[ $# -eq 1 ] || {
    echo "USAGE: $0 SQLITE_FILENAME" >&2
    exit 1
}

sqlite="$1"

[[ -f "$sqlite" && -r "$sqlite" ]] || {
    echo "Can't read SQLite file: '$sqlite'" >&2
    exit 1
}

### "constants" ###

# tables not to be migrated, delimited by |
EXCLUDED_TABLES='dbix_class_deploymenthandler_versions|sessions'

# freaky hacks
PERL_FILTER=`cat <<'PERL'
if( /^INSERT INTO (dish|recipe)_ingredients\(/ ) {
    # cast boolean columns from 0|1 => FALSE/TRUE
    s/ VALUES\( (?:\d+,){3} \K ([01]) (?=,) / $1 ? 'TRUE' : 'FALSE' /ex
      or die "BOOLEAN cast failed: $_";
}
elsif( /^INSERT INTO items\(/ ) {
    # cast booleans
    s/ ([01]) (?= ,'.*?'\);$ ) / $1 ? 'TRUE' : 'FALSE' /ex
      or die "BOOLEAN cast failed: $_";
}
elsif( /^INSERT INTO projects\(/ ) {
    # cast booleans
    s/ ([01]) (?= ,\d+,'....-..-.....:..:..', (?: '....-..-.....:..:..' | NULL ) \);$ ) / $1 ? 'TRUE' : 'FALSE' /ex
      or die "BOOLEAN cast failed: $_";
}
elsif( /^INSERT INTO units\(/ ) {
    # cast booleans
    s/ ([01]) (?= (?:,'.*?'){2} \);$ ) / $1 ? 'TRUE' : 'FALSE' /ex
      or die "BOOLEAN cast failed: $_";
}

# convert SQLite workaround for newlines to PostgreSQL syntax:
# REPLACE('foo\nbar','\n',char(10)) => E'foo\nbar'
# TODO What does SQLite output if the text actually contains a literal \n?
s/
    replace\(
        ' (.+?) ',    # the actual text
        '\\\\r',
        char\(13\)
    \)
/E'$1'/gx;

s/
    replace\(
        E? ' (.+?) ',    # the actual text, possibly already in E'' syntax
        '\\\\n',
        char\(10\)
    \)
/E'$1'/gx;
PERL
`;

cat <<PGSQL
START TRANSACTION;

SET CONSTRAINTS ALL DEFERRED;
PGSQL

sqlite3 "$sqlite" .tables \
    | xargs -n1 echo \
    | grep -Evx "$EXCLUDED_TABLES" \
    | while read table
    do cat <<SQLITE
.headers on
.mode insert $table
SELECT * FROM $table;
SQLITE
    done \
    | sqlite3 "$sqlite" \
    | perl -pe "$PERL_FILTER"

cat <<PGSQL
COMMIT TRANSACTION;
PGSQL
