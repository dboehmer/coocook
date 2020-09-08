package Coocook::Schema::Result::Project;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

use Carp;
use Coocook::Util;
use DateTime;

extends 'Coocook::Schema::Result';

__PACKAGE__->table('projects');

__PACKAGE__->add_columns(
    id          => { data_type => 'int', is_auto_increment => 1 },
    name        => { data_type => 'text' },
    url_name    => { data_type => 'text' },
    url_name_fc => { data_type => 'text' },                          # fold cased
    description => { data_type => 'text' },
    is_public   => { data_type => 'bool', default_value => 1 },
    owner_id    => { data_type => 'int' },
    created  => { data_type => 'datetime', default_value => \'CURRENT_TIMESTAMP', set_on_create => 1 },
    archived => { data_type => 'datetime', is_nullable   => 1 },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->add_unique_constraints( ['name'], ['url_name'], ['url_name_fc'] );

__PACKAGE__->belongs_to( owner => 'Coocook::Schema::Result::User', 'owner_id' );

__PACKAGE__->has_many(
    organizations_projects => 'Coocook::Schema::Result::OrganizationProject',
    'project_id'
);
__PACKAGE__->many_to_many( organizations => organizations_projects => 'organization' );

__PACKAGE__->has_many( projects_users => 'Coocook::Schema::Result::ProjectUser', 'project_id' );
__PACKAGE__->many_to_many( users => projects_users => 'user' );

__PACKAGE__->has_many( articles       => 'Coocook::Schema::Result::Article',      'project_id' );
__PACKAGE__->has_many( meals          => 'Coocook::Schema::Result::Meal',         'project_id' );
__PACKAGE__->has_many( purchase_lists => 'Coocook::Schema::Result::PurchaseList', 'project_id' );
__PACKAGE__->has_many( quantities     => 'Coocook::Schema::Result::Quantity',     'project_id' );
__PACKAGE__->has_many( recipes        => 'Coocook::Schema::Result::Recipe',       'project_id' );
__PACKAGE__->has_many( shop_sections  => 'Coocook::Schema::Result::ShopSection',  'project_id' );
__PACKAGE__->has_many( tags           => 'Coocook::Schema::Result::Tag',          'project_id' );
__PACKAGE__->has_many( tag_groups     => 'Coocook::Schema::Result::TagGroup',     'project_id' );
__PACKAGE__->has_many( units          => 'Coocook::Schema::Result::Unit',         'project_id' );

# trigger for generating url_name[_fc]
before store_column => sub {
    my ( $self, $column, $value ) = @_;

    if ( $column eq 'name' ) {
        $self->set_columns( Coocook::Util::url_names_hashref($value) );
    }
};

__PACKAGE__->meta->make_immutable;

sub archive {
    my $self = shift;

    $self->archived
      and croak "Project already archived";

    $self->update( { archived => DateTime->now() } );
}

sub unarchive {
    my $self = shift;

    $self->archived
      or croak "Project not archived";

    $self->update( { archived => undef } );
}

# pseudo-relationship
sub dishes {
    my $self = shift;

    return $self->result_source->schema->resultset('Dish')->search(
        {
            'meal.project_id' => $self->id,
        },
        {
            join => 'meal',
        }
    );
}

# fetch articles, units and cache their relationships
sub articles_cached_units {
    my $self = shift;

    my $articles = $self->articles;
    my @articles = $articles->sorted->all;

    my @units = $self->units->sorted->all;
    my %units = map { $_->id => $_ } @units;
    my %units_with_articles;

    my %articles_units;

    {
        my $articles_units = $articles->search_related('articles_units');

        while ( my $a_u = $articles_units->next ) {
            my $a = $a_u->article_id;
            my $u = $a_u->unit_id;

            $a_u->related_resultset('unit')->set_cache( [ $units{$u} ] );

            push @{ $articles_units{$a} }, $a_u;

            $units_with_articles{$u}++;
        }
    }

    for my $article (@articles) {
        $article->related_resultset('articles_units')->set_cache( $articles_units{ $article->id } );
    }

    if (wantarray) {

        # this is probably (?) faster than additionally querying the relationship in SQL
        # TODO speed up
        return \@articles, [ grep { exists $units_with_articles{ $_->id } } @units ];
    }
    else {
        return \@articles;
    }
}

=head2 dish_ingredients()

Shortcut.

=cut

sub dish_ingredients { shift->meals->search_related('dishes')->search_related('ingredients') }

=head2 inventory()

Returns a hashref with counts for related object.

=cut

sub inventory {
    my $self = shift;

    my $self_rs = $self->self_rs;

    return $self_rs->search(
        undef,
        {
            columns => {
                articles       => $self_rs->search_related('articles')->count_rs->as_query,
                dishes         => $self_rs->search_related('meals')->search_related('dishes')->count_rs->as_query,
                meals          => $self_rs->search_related('meals')->count_rs->as_query,
                purchase_lists => $self_rs->search_related('purchase_lists')->count_rs->as_query,
                quantities     => $self_rs->search_related('quantities')->count_rs->as_query,
                recipes        => $self_rs->search_related('recipes')->count_rs->as_query,
                shop_sections  => $self_rs->search_related('shop_sections')->count_rs->as_query,
                tags           => $self_rs->search_related('tags')->count_rs->as_query,
                units          => $self_rs->search_related('units')->count_rs->as_query,
                unassigned_items =>
                  $self_rs->search_related('meals')->search_related('dishes')->search_related('ingredients')
                  ->unassigned->count_rs->as_query,
            },
        }
    )->hri->single;
}

=head2 is_stale()

Returns a boolean value indicating whether the whole project is already past.
Indicates if this project can be archived.

=cut

sub is_stale {
    my ( $self, $pivot_date ) = @_;

    return $self->self_rs->stale($pivot_date)->results_exist();
}

=head2 tags_from_names($names)

Returns a resultset with all tags matching names in C<$names>.

TODO: Should probably autocreate tags that do not yet exist.

=cut

sub tags_from_names {
    my ( $self, $names ) = @_;

    return $self->tags->from_names($names);
}

=head2 organizations_without_permission

Returns a resultset with all C<Result::Organization>s without any related C<organizations_projects> record.

=cut

sub organizations_without_permission {
    my $self = shift;

    my $permitted_organizations = $self->organizations_projects->get_column('organization_id');

    return $self->result_source->schema->resultset('Organization')->search(
        {
            id => { -not_in => $permitted_organizations->as_query },
        }
    );
}

=head2 other_projects

Returns a resultset to all projects except itself.

=cut

sub other_projects {
    my $self = shift;

    return $self->result_source->resultset->search( { id => { '!=' => $self->id } } );
}

=head2 users_without_permission

Returns a resultset with all C<Result::User>s without any related C<projects_users> record.

=cut

sub users_without_permission {
    my $self = shift;

    my $permitted_users = $self->projects_users->get_column('user_id');

    return $self->result_source->schema->resultset('User')->search(
        {
            id => { -not_in => $permitted_users->as_query },
        }
    );
}

1;
