package Coocook::Schema::Result::Project;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::Result';

use feature 'fc';    # Perl v5.16

__PACKAGE__->table("projects");

__PACKAGE__->add_columns(
    id          => { data_type => 'int', is_auto_increment => 1 },
    name        => { data_type => 'text' },
    url_name    => { data_type => 'text' },
    url_name_fc => { data_type => 'text' }, # fold cased
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->add_unique_constraints( ['name'], ['url_name'], ['url_name_fc'] );

__PACKAGE__->has_many( articles => 'Coocook::Schema::Result::Article', 'project' );
__PACKAGE__->has_many( meals    => 'Coocook::Schema::Result::Meal',    'project' );
__PACKAGE__->has_many( purchase_lists => 'Coocook::Schema::Result::PurchaseList' );
__PACKAGE__->has_many( quantities     => 'Coocook::Schema::Result::Quantity' );
__PACKAGE__->has_many( recipes        => 'Coocook::Schema::Result::Recipe' );
__PACKAGE__->has_many( shop_sections  => 'Coocook::Schema::Result::ShopSection' );
__PACKAGE__->has_many( tags           => 'Coocook::Schema::Result::Tag' );
__PACKAGE__->has_many( tag_groups     => 'Coocook::Schema::Result::TagGroup' );
__PACKAGE__->has_many( units          => 'Coocook::Schema::Result::Unit' );

before delete => sub {    # TODO solve workaround
    my $self = shift;

    $self->purchase_lists->items->delete;
    $self->purchase_lists->delete;
    $self->articles->article_tags->delete;
    $self->articles->articles_units->delete;
    $self->meals->dishes->ingredients->delete;
    $self->meals->dishes->delete;
    $self->meals->delete;
    $self->recipes->ingredients->delete;
    $self->recipes->recipe_tags->delete;
    $self->recipes->delete;
    $self->articles->delete;
    $self->shop_sections->delete;
    $self->quantities->update( { default_unit => undef } );    # to pass FK constraint
    $self->units->delete;
    $self->quantities->delete;
    $self->tags->delete;
    $self->tag_groups->delete;
};

# trigger for generating url_name[_fc]
before store_column => sub {
    my ( $self, $column, $value ) = @_;

    if ( $column eq 'name' ) {
        ( my $url_name = $value ) =~ s/\W+/-/g;

        $self->set_columns(
            {
                url_name    => $url_name,
                url_name_fc => fc $url_name,
            }
        );
    }
};

__PACKAGE__->meta->make_immutable;

# pseudo-relationship
sub dishes {
    my $self = shift;

    return $self->result_source->schema->resultset('Dish')->search(
        {
            'meal.project' => $self->id,
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

    my %articles_units;

    {
        my $articles_units = $articles->articles_units;

        while ( my $a_u = $articles_units->next ) {
            my $a = $a_u->get_column('article');
            my $u = $a_u->get_column('unit');

            $a_u->related_resultset('unit')->set_cache( [ $units{$u} ] );

            push @{ $articles_units{$a} }, $a_u;
        }
    }

    for my $article (@articles) {
        $article->related_resultset('articles_units')->set_cache( $articles_units{ $article->id } );
    }

    return \@articles, \@units;
}

=head2 other_projects

Returns a resultset to all projects except itself.

=cut

sub other_projects {
    my $self = shift;

    return $self->result_source->resultset->search( { id => { '!=' => $self->id } } );
}

1;
