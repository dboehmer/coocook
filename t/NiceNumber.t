use Test2::V0;

use Coocook::Filter::NiceNumber;
use Test::Builder;
use Test2::API qw(context);

plan(15);

ok my $filter = Coocook::Filter::NiceNumber->new();

isa_ok $filter, 'Template::Plugin::Filter';

like dies { $filter->filter("foo") }, qr/isn't numeric/, "exception for non-numeric string";

t( undef() => undef, "undef" );
t( ""      => "",    "empty string" );

# 3 significant digits
t( 123        => "123" );
t( 1.23       => "1.23" );
t( 1.234567   => "1.23" );
t( 12345.6789 => "12300" );
t( 1 / 3      => "0.333" );
t( 0.999999   => "1" );
t( 123456789  => "123000000" );
t( 0.0101     => "0.0101" );
t( 0.000001   => "0.000001" );

todo 'sprintf("%f") cuts digits off this string--how to fix that?' => sub {
    t( 0.0000012345 => "0.00000123" );
};

sub t {
    my ( $input, $expected, $name ) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $output = $filter->filter($input);

    is $output => $expected, $name || "$input = '$expected'";
}
