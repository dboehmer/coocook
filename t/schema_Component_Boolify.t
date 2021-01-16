use lib 't/lib';

use TestDB;
use Test::Most;

my $schema = TestDB->new();

my %isa_already_shown;

for my $source ( $schema->sources ) {
    my $rs = $schema->resultset($source);

    my $row = $rs->one_row;

    my $columns_info = $rs->result_source->columns_info;

    while ( my ( $col => $info ) = each %$columns_info ) {
        if ( $info->{data_type} eq 'boolean' ) {
            if ( not $isa_already_shown{$source}++ ) {
                my $class = $rs->result_source->result_class;

                note "mro::get_linear_isa('$class'):";
                note " - $_" for @{ mro::get_linear_isa($class) };
            }

            subtest "$source.$col" => sub {
                $row or plan skip_all => "No row for Result::$source";

                $row->update( { $col => '' } );
                $row->discard_changes();
                is $row->get_column($col) => 0, "'' => 0";

                $row->update( { $col => 42 } );
                $row->discard_changes();
                is $row->get_column($col) => 1, "42 => 1";
            };
        }
    }
}

done_testing();
