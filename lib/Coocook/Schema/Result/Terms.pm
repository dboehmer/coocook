package Coocook::Schema::Result::Terms;

use DateTime;
use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::Result';

__PACKAGE__->table('terms');

__PACKAGE__->add_columns(
    id         => { data_type => 'int', is_auto_increment => 1 },
    valid_from => { data_type => 'date' },
    content_md => { data_type => 'text' },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->add_unique_constraints( ['valid_from'] );

__PACKAGE__->has_many( users => 'Coocook::Schema::Result::User' );

__PACKAGE__->has_many( owned_projects => 'Coocook::Schema::Result::Project', 'owner' );

__PACKAGE__->has_many( projects_users => 'Coocook::Schema::Result::ProjectUser' );
__PACKAGE__->many_to_many( projects => projects_users => 'project' );

__PACKAGE__->meta->make_immutable;

=head2 next($offset?)

Returns next valid terms. C<$offset> is +1 by default.

=cut

sub next { shift->neighbor( shift || 1 ) }

=head2 previous($offset?)

Returns previous valid terms. C<$offset> might be positive or negative and is -1 by default.

=cut

sub previous { shift->neighbor( -1 * abs( shift || 1 ) ) }

=encoding utf8

=head2 neighbor(±$offset)

Returns terms valid C<$offset> elements before/after the current object.
Negative C<$offset> means previous terms.
Positive C<$offset> means next terms.

=cut

sub neighbor {
    my ( $self, $offset ) = @_;

    return $self->result_source->resultset->search(
        {
            valid_from => { ( $offset < 0 ? '<' : '>' ) => $self->get_column('valid_from') },
        },
        {
            order_by => { ( $offset < 0 ? '-DESC' : '-ASC' ) => 'valid_from' },
            offset => abs($offset) - 1,
        }
    )->one_row;
}

1;
