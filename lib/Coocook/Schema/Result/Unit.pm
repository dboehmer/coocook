package Coocook::Schema::Result::Unit;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::Result';

__PACKAGE__->table("units");

__PACKAGE__->add_columns(
    id                  => { data_type => "int",  is_auto_increment => 1 },
    quantity            => { data_type => "int",  is_nullable       => 1 },
    to_quantity_default => { data_type => "real", is_nullable       => 1 },
    short_name          => { data_type => "text" },
    long_name           => { data_type => "text" },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->add_unique_constraints( ['short_name'], ['long_name'], );

__PACKAGE__->belongs_to( quantity => 'Coocook::Schema::Result::Quantity' );

__PACKAGE__->has_many(
    articles_units => 'Coocook::Schema::Result::ArticleUnit' );

__PACKAGE__->many_to_many( articles => articles_units => 'article' );

__PACKAGE__->meta->make_immutable;

sub can_be_quantity_default {
    my $self = shift;

    $self->get_column('quantity')  or return;
    $self->get_to_quantity_default or return;

    return 1;
}

sub is_quantity_default {
    my $self = shift;

    my $quantity = $self->quantity or return;

    return ( $self->id == $quantity->get_column('default_unit') );
}

# marks this unit as its quantity's default and adjusts conversion factors of all units
sub make_quantity_default {
    my $self = shift;

    my $quantity = $self->quantity            or die "No quantity";
    my $factor   = $self->to_quantity_default or die "No to_quantity_default";
    my $orig     = $quantity->default_unit;

    if ( not $orig ) {    # no previous default->just select this unit
        return $quantity->update( { default_unit => $self->id } );
    }

    $orig->id == $self->id and return 1;    # already default

    # collect convertable units of this quantity except $self and $orig
    my @others = $quantity->units->search(
        {
            id                  => { -not_in => [ $self->id, $orig->id ] },
            to_quantity_default => { '!='    => undef },     # IS NOT NULL
        }
    );

    $self->result_source->schema->txn_do(
        sub {
            for my $unit (@others) {
                $unit->update(
                    {
                        to_quantity_default => $unit->to_quantity_default /
                          $factor
                    }
                );
            }

            $orig->update( { to_quantity_default => 1 / $factor } );
            $self->update( { to_quantity_default => undef } );

            $quantity->update( { default_unit => $self->id } );
        }
    );

    return 1;
}

1;
