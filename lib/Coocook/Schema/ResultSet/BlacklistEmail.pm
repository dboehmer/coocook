package Coocook::Schema::ResultSet::BlacklistEmail;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::ResultSet';

__PACKAGE__->load_components('+Coocook::Schema::Component::ResultSet::Blacklist::Hashed');

=head1 METHODS

=head2 add_email($email_address, %other_column_data)

Adds a literal e-mail address to the blacklist.

=cut

sub add_email { shift->_add_value( email_fc => @_ ) }

=head2 is_email_ok($email_address)

See L<Coocook::Schema::Component::ResultSet::Blacklist>.

=cut

sub is_email_ok { shift->_is_value_ok( email_fc => @_ ) }

1;
