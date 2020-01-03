package Coocook::Schema::ResultSet::BlacklistEmail;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::ResultSet';

__PACKAGE__->load_components('+Coocook::Schema::Component::ResultSet::Blacklist');

=head1 METHODS

=head2 add_email($email_address, %other_column_data)

Adds a literal e-mail address to the blacklist.

=cut

sub add_email { shift->_add_value(@_) }

=head2 is_email_ok($email_address)

See L<Coocook::Schema::Component::ResultSet::Blacklist>.

=cut

sub is_email_ok { shift->_is_value_ok(@_) }

sub _blacklist_default_type { 'sha256_b64' }
sub _blacklist_type_column  { 'email_type' }
sub _blacklist_value_column { 'email_fc' }

1;
