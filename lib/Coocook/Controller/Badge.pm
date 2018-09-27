package Coocook::Controller::Badge;

use DateTime;
use Moose;
use MooseX::MarkAsMethods autoclean => 1;

BEGIN { extends 'Coocook::Controller' }

sub dishes_served : GET HEAD Chained('/base') PathPart('badge/dishes_served.svg') Args(0) {
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

    # TODO build SVG instead of redirect to external service
    my $url = 'https://img.shields.io/badge/dishes_served-' . $dishes . '-blue.svg';

    $c->res->headers->header(
        Expires => DateTime->today->add( days => 1 )->strftime("%a, %d %b %Y %H:%M:%S %Z") );

    $c->redirect_detach($url);
}

__PACKAGE__->meta->make_immutable;

1;
