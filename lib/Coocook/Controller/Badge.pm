package Coocook::Controller::Badge;

use DateTime;
use Moose;
use MooseX::MarkAsMethods autoclean => 1;

BEGIN { extends 'Coocook::Controller' }

sub dishes_served : GET HEAD Chained('/base') PathPart('badge/dishes_served.svg') Args(0) Public {
    my ( $self, $c ) = @_;

    my $dishes = $c->model('DB::Dish')->in_past_or_today->sum_servings;

    my $suffix;
    my @suffixes = qw< k m b >;

    while ( $dishes >= 999.5 and @suffixes ) {
        $dishes /= 1000;
        $suffix = shift @suffixes;
    }

    if ($suffix) {
        my $format = $dishes < 10 ? "%.1f$suffix" : "%.0f$suffix";
        $dishes = sprintf $format, $dishes;
    }

    my $badge = $c->model('Badge')->create_badge( "dishes served", $dishes, "#007ec6" );

    $c->response->content_type('image/svg+xml');
    $c->response->body($badge);
    return;
}

__PACKAGE__->meta->make_immutable;

1;
