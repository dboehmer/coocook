package Coocook::ActionRole::RequireHttpMethod;

# ABSTRACT: assert that every public controller action is either GET or POST

use Moose::Role;
use MooseX::MarkAsMethods autoclean => 1;

# TODO maybe transform into test to speed up startup?

after BUILD => sub {
    my ( $class, $args ) = @_;

    $args->{attributes}{Private}
      and return;

    $args->{attributes}{AnyMethod}
      and return;    # special keyword indicating any method will be ok

    $args->{attributes}{CaptureArgs}
      and return;    # actions with CaptureArgs are chain elements and automatically private

    $args->{reverse} eq 'end'
      and return;    # Controller::Root->end needs can't be :Private but is ok

    my $methods = $args->{attributes}{Method} || [];

    @$methods == 1    # TODO maybe >= 1?
      or die "Invalid action $args->{reverse}. Should have explicit HTTP method, e.g. GET or POST";
};

1;
