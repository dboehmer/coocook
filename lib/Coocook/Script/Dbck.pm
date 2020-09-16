package Coocook::Script::Dbck;

# ABSTRACT: script for checking the database integrity just like `fsck` checks filesystems

use feature 'fc';    # Perl 5.16
use open ':locale';
use Moose;
use MooseX::MarkAsMethods autoclean => 1;

use Coocook::Schema;
use Coocook::Util;

with 'Coocook::Script::Role::HasDebug';
with 'Coocook::Script::Role::HasSchema';
with 'MooseX::Getopt';

sub run {
    my $self = shift;

    $self->check_schema();
    $self->check_rows();
    $self->check_values();
}

sub check_schema {
    my $self = shift;

    my $live_schema = $self->_schema;

    $live_schema->storage->sqlt_type eq 'SQLite'
      or die "Only implemented for SQLite!";

    my $code_schema = Coocook::Schema->connect('dbi:SQLite::memory:');
    $code_schema->deploy();

    my $sth = $code_schema->storage->dbh->table_info( undef, undef, undef, 'TABLE' );

    while ( my $table = $sth->fetchrow_hashref ) {
        my $table_name = $table->{TABLE_NAME};
        my $table_type = $table->{TABLE_TYPE};

        $table_type eq 'SYSTEM TABLE'
          and next;

        $self->_debug("Checking schema of table '$table_name' ...");

        my $live_table =
          $live_schema->storage->dbh->table_info( undef, undef, $table_name, $table_type )
          ->fetchrow_hashref;

        if ( not $live_table ) {
            warn "Table missing: '$table_name'\n";
            next;
        }

        my $code_sql = $table->{sqlite_sql};
        my $live_sql = $live_table->{sqlite_sql};

        for ( $code_sql, $live_sql ) {
            s/\s+/ /gms;    # normalize whitespace
            s/["']//g;      # ignore quote chars
        }

        $live_sql eq $code_sql
          and next;

        warn "SQL for table '$table_name' differs:\n";

        s/^/  /gm for $code_sql, $live_sql;

        warn "<" x 7, " code\n";
        warn $code_sql, "\n";
        warn "-" x 7, "\n";
        warn $live_sql, "\n";
        warn ">" x 7, " live\n";
    }
}

sub check_rows {
    my $self = shift;

    my @m_n_tables = (
        { Article          => [qw< me shop_section >] },
        { ArticleTag       => [qw< article tag >] },
        { ArticleUnit      => [qw< article unit >] },
        { Dish             => [qw< meal recipe prepare_at_meal >] },
        { DishIngredient   => [ { dish => 'meal' }, qw< article unit  > ] },
        { DishTag          => [ { dish => 'meal' }, qw< tag  > ] },
        { Item             => [qw< purchase_list unit article  >] },
        { RecipeIngredient => [qw< recipe article unit >] },
        { RecipeTag        => [qw< recipe tag >] },
        { Tag              => [qw< me tag_group >] },
        { Unit             => [qw< me quantity >] },
    );

    for (@m_n_tables) {
        my ( $rs_class, $joins ) = %$_;

        $self->_debug("Checking rows in table '$rs_class' ...");

        @$joins >= 2
          or die "need 2 or more relationships to compare project IDs";

        my $rs = $self->_schema->resultset($rs_class);

        my @pk_cols = $rs->result_source->primary_columns;

        my @tables = map { ref $_ ? values %$_ : $_ } @$joins;

        $rs = $rs->search(
            undef,
            {
                columns => {
                    ( map { $_              => $_ } @pk_cols ),                # e.g. id             => id
                    ( map { $_ . '_project' => $_ . '.project' } @tables ),    # e.g. recipe_project => recipe.project
                },
                join => [ grep { $_ ne 'me' } @$joins ],
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

sub check_values {
    my $self = shift;

    my $schema = $self->_schema;

    if ( $schema->storage->sqlt_type eq 'SQLite' ) {    # only SQLite allows '' for an INTEGER column
        for my $table (qw< DishIngredient RecipeIngredient Item >) {
            my $count = $schema->resultset($table)->search( { value => '' } );

            $count > 0
              and warn "Found $count rows with value of empty string '' in table $table\n";
        }
    }

    {
        my $organizations = $schema->resultset('Organization');
        my $usernames_fc  = $schema->resultset('User')->get_column('name_fc');

        my $duplicates = $organizations->search( { name_fc => { -in => $usernames_fc->as_query } } )->hri;

        while ( my $duplicate = $duplicates->next ) {
            warn sprintf "Duplicate organization/user name '%s'\n", $duplicate->{name};
        }
    }

    my $organizations = $schema->resultset('Organization');

    while ( my $organization = $organizations->next ) {
        $organization->name_fc eq fc( $organization->name )
          or warn sprintf( "Incorrect name_fc for organization '%s': '%s'\n",
            $organization->name, $organization->name_fc );
    }

    my $users = $schema->resultset('User');

    while ( my $user = $users->next ) {
        $user->name_fc eq fc( $user->name )
          or warn sprintf "Incorrect name_fc for user '%s': '%s'\n", $user->name, $user->name_fc;
    }

    my $projects = $schema->resultset('Project');

    while ( my $project = $projects->next ) {
        $project->url_name eq Coocook::Util::url_name( $project->name )
          or warn sprintf "Incorrect url_name for project '%s': '%s'\n", $project->name, $project->url_name;

        $project->url_name_fc eq Coocook::Util::url_name( fc $project->name )
          or warn sprintf "Incorrect url_name_fc for project '%s': '%s'\n", $project->name,
          $project->url_name_fc;
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
