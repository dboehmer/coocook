package Coocook::Schema::ResultSet::BlacklistUsername;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::ResultSet';

__PACKAGE__->load_components('+Coocook::Schema::Component::ResultSet::Blacklist');

=head1 METHODS

=head2 add_username($username, %additional_column_data)

=cut

sub add_username { shift->_add_value(@_) }

=head2 is_username_ok($username)

See L<Coocook::Schema::Component::ResultSet::Blacklist>.

=cut

sub is_username_ok { shift->_is_value_ok(@_) }

sub _blacklist_type_column  { 'username_type' }
sub _blacklist_value_column { 'username_fc' }

1;
