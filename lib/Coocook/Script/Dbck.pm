package Coocook::Script::Dbck;

# ABSTRACT: script for checking the database integrity just like `fsck` checks filesystems

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

use Coocook::Schema;

with 'MooseX::Getopt';

has debug => (
    is            => 'rw',
    isa           => 'Bool',
    documentation => "enable debugging output",
);

has dsn => (
    is            => 'rw',
    isa           => 'Str',
    default       => 'development',
    documentation => "key in dbic.yaml or DBI DSN string",
);

has _schema => (
    is      => 'rw',
    isa     => 'Coocook::Schema',
    lazy    => 1,
    builder => '_build__schema',
);

sub _build__schema {
    my $self = shift;

    return Coocook::Schema->connect( $self->dsn );
}

sub run {
    my $self = shift;

    my @m_n_tables = (
        { ArticleTag       => [qw< article tag >] },
        { ArticleUnit      => [qw< article unit >] },
        { Dish             => [qw< meal recipe prepare_at_meal >] },
        { DishIngredient   => [ { dish => 'meal' }, qw< article unit  > ] },
        { DishTag          => [ { dish => 'meal' }, qw< tag  > ] },
        { Item             => [qw< purchase_list unit article  >] },
        { RecipeIngredient => [qw< recipe article unit >] },
        { RecipeTag        => [qw< recipe tag >] },
    );

    for (@m_n_tables) {
        my ( $rs_class, $joins ) = %$_;

        $self->_debug("Checking table '$rs_class' ...");

        @$joins >= 2
          or die "need 2 or more relationships to compare project IDs";

        my $rs = $self->_schema->resultset($rs_class);

        my @pk_cols = $rs->result_source->primary_columns;

        my @tables = map { ref $_ ? values %$_ : $_ } @$joins;

        $rs = $rs->search(
            undef,
            {
                columns => {
                    ( map { $_ => $_ } @pk_cols ),    # e.g. id             => id
                    ( map { $_ . '_project' => $_ . '.project' } @tables ),    # e.g. recipe_project => recipe.project
                },
                join => [@$joins],
            }
        )->hri;

      ROW: while ( my $row = $rs->next ) {

            # TODO optimize: hardcode which 'project' col IS NOT NULL->no need to search
            my ($master_rel) = grep { defined $row->{ $_ . '_project' } } @tables
              or die "this shouldn't happen";

            my $project_id = $row->{ $master_rel . '_project' }
              or die;

            for my $rel (@tables) {
                $rel eq $master_rel
                  and next;

                my $val = $row->{ $rel . '_project' } // next;

                if ( $val != $project_id ) {
                    printf STDERR "Project IDs differ for %s row (%s): %s\n", $rs_class,
                      join( ", ", map { "$_ = " . $row->{$_} } @pk_cols ),
                      join( ", ", map { $_ . ".project = " . ( $row->{ $_ . '_project' } // "undef" ) } @tables );

                    next ROW;
                }
            }
        }
    }
}

sub _debug {
    my $self = shift;

    $self->debug
      or return;

    local $| = 1;

    print @_, "\n";
}

__PACKAGE__->meta->make_immutable;

1;
