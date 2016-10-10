package Coocook::Schema::Component::ResultSet::SortByName;

sub sorted_by_column { 'name' }

sub sorted {
    my $self = shift;

    return $self->search(
        undef,
        {
            order_by => $self->me( $self->sorted_by_column ),
        }
    );
}

sub sorted_rs { scalar shift->sorted(@_) }

1;
