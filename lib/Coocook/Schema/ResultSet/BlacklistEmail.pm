package Coocook::Schema::ResultSet::BlacklistEmail;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Coocook::Schema::ResultSet';

__PACKAGE__->load_components('+Coocook::Schema::Component::ResultSet::Blacklist');

=head1 METHODS

=head2 is_email_ok($email_address)

See L<Coocook::Schema::Component::ResultSet::Blacklist>.

=cut

sub is_email_ok { shift->is_value_ok( email => @_ ) }

1;
