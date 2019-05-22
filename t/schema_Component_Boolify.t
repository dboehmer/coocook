use strict;
use warnings;

use Test::Most;

{
    ## no critic (RequireFilenameMatchesPackage)
    package MySchema::Result::A;

    use parent 'DBIx::Class::Core';

    __PACKAGE__->load_components('+Coocook::Schema::Component::Result::Boolify');

    __PACKAGE__->table('a');

    __PACKAGE__->add_columns(
        id   => { data_type => 'INT' },
        flag => { data_type => 'BOOL' },
        str  => { data_type => 'TEXT' },
    );

    __PACKAGE__->set_primary_key('id');

    package MySchema;

    use parent 'DBIx::Class::Schema';

    __PACKAGE__->load_classes( { 'MySchema::Result' => ['A'] } );
}

my $schema = MySchema->connect('dbi:SQLite::memory:');

$schema->deploy();

$schema->resultset('A')->create( { id => 1, flag => 'true', str => 'value' } );

my $row = $schema->resultset('A')->find(1);

is $row->flag => 1,       "bool column stored 1";
is $row->str  => 'value', "text column stored text";

$row->update( { flag => '' } );

$row->discard_changes();

is $row->flag => 0, "bool column stored 0";

done_testing();
