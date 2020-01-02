package Coocook::Schema::ResultSet::BlacklistUsername;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::ResultSet';

__PACKAGE__->load_components('+Coocook::Schema::Component::ResultSet::Blacklist');

=head1 METHODS

=head2 is_username_ok($username)

See L<Coocook::Schema::Component::ResultSet::Blacklist>.

=cut

sub is_username_ok { shift->_is_value_ok( username_fc => @_ ) }

1;
