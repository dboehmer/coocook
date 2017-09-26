package Coocook::Schema::Component::Result::ResultsetRelationships;

# ABSTRACT: add accessor methods for table relationships to Resultset classes

use strict;
use warnings;

use base 'DBIx::Class';
use mro;    # provides next::method

use Carp;
use Sub::Name;

our @CARP_NOT;

sub has_many {
    my $class = shift;
    my ( $accessor_name, $related_class, $their_fk_column, $attrs ) = @_;

    if ( defined $their_fk_column and ref $their_fk_column eq '' ) {
        $related_class =~ s/^Coocook::Schema::Result:://;

        my $resultset_class = _resultset_class($class);

        _add_sub(
            "${resultset_class}::${accessor_name}" => sub {
                my $self = shift;

                my $ids = $self->get_column('id')->as_query;

                return $self->result_source->schema->resultset($related_class)
                  ->search( { $self->me($their_fk_column) => { -in => $ids } }, $attrs );
            }
        );
    }
    else {
        local @CARP_NOT = ('DBIx::Class::Relationship::BelongsTo');

        carp "Can't create resultset relationship for ${class}->$accessor_name"
          . " because only scalar with PK column supported\n";
    }

    return $class->next::method(@_);
}

sub many_to_many_TODO {    # TODO introspect reverse relationship data in anon sub
    my $class = shift;
    my ( $accessor_name, $link_rel_name, $foreign_rel_name, $attrs ) = @_;

    my $resultset_class = _resultset_class($class);

    _add_sub(
        "${resultset_class}::${accessor_name}" => sub {
            my $self = shift;

            my $ids = $self->get_column('id')->as_query;

            return $self->result_source->schema->resultset('Tag')
              ->search( { 'articles_tags.article' => { -in => $ids } }, { join => 'articles_tags' } );
        }
    );

    return $class->next::method(@_);
}

sub _resultset_class {
    my ($class) = shift;

    ( my $resultset_class = $class ) =~ s/::Result::/::ResultSet::/;

    # make sure class is loaded
    local $@;
    $class->ensure_class_loaded($resultset_class);

    if ($@) {
        if ( $@ =~ m/^Can't locate / ) {    # define most basic resultset class
            warn "Autogenerating class $resultset_class\n";
            no strict 'refs';
            @{"${resultset_class}::ISA"} = ('Coocook::Schema::ResultSet');
        }
        else {
            die $@;                         # raise unexpected error
        }
    }

    return $resultset_class;
}

sub _add_sub {
    my ( $subname, $coderef ) = @_;

    no strict 'refs';
    *$subname = subname $subname => $coderef;

    warn "Created $subname\n";
}

1;
