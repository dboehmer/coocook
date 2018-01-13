package Coocook::Controller::Print;

use DateTime;
use Moose;
use MooseX::MarkAsMethods autoclean => 1;
use utf8;

BEGIN { extends 'Coocook::Controller' }

=head1 NAME

Coocook::Controller::Print - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 index

=cut

sub auto : Private {
    my ( $self, $c ) = @_;

    push @{ $c->stash->{css} }, 'lib/print.css';
}

sub index : GET Chained('/project/base') PathPart('print') Args(0) {
    my ( $self, $c ) = @_;

    # TODO find a way to exclude this method when adding 'lib/print.css' (5 lines above)
    my $css = $c->stash->{css};
    @$css = grep { $_ ne 'lib/print.css' } @$css;    # remove 'lib/print.css' again :-/

    my $project = $c->stash->{project} || die;

    my @days;
    {
        # can't use get_column(date) here because only $meal->date() inflates DateTime object
        my @dates =
          map { $_->date } $project->meals->search( undef, { columns => 'date', distinct => 1 } )->all;

        for my $date (@dates) {
            push @days,
              {
                date => $date,
                url  => $c->project_uri( '/print/day', $date->year, $date->month, $date->day ),
              };
        }
    }

    my @lists;
    {
        my $lists = $project->purchase_lists->search( undef, { order_by => 'date' } );

        while ( my $list = $lists->next ) {
            push @lists,
              {
                date => $list->date,
                name => $list->name,
                url  => $c->project_uri( '/print/purchase_list', $list->id ),
              };
        }
    }

    my @projects = $c->model('DB::Project')->all;

    $c->stash(
        days        => \@days,
        lists       => \@lists,
        projects    => \@projects,
        project_url => $c->project_uri('/print/project'),
        title       => "Printing",
    );
}

sub day : GET Chained('/project/base') PathPart('print/day') Args(3) {
    my ( $self, $c, $year, $month, $day ) = @_;

    my $dt = DateTime->new(
        year  => $year,
        month => $month,
        day   => $day,
    );

    my $meals = $c->model('Plan')->day( $c->project, $dt );

    for my $meal (@$meals) {
        for my $dish ( @{ $meal->{dishes} } ) {
            $dish->{url} = $c->project_uri( '/dish/edit', $dish->{id} );

            if ( my $prep_meal = $dish->{prepare_at_meal} ) {
                $prep_meal->{url} =
                  $c->project_uri( '/print/day', map { $prep_meal->{date}->$_ } qw< year month day > );
            }
        }

        for my $dish ( @{ $meal->{prepared_dishes} } ) {
            my $meal = $dish->{meal};

            $meal->{url} ||= $c->project_uri( '/print/day', map { $meal->{date}->$_ } qw< year month day > );
        }
    }

    $c->stash(
        day        => $dt,
        meals      => $meals,
        title      => "Print " . $dt->strftime( $c->stash->{date_format_short} ),
        html_title => "Print " . $dt->strftime( $c->stash->{date_format_long} ),
    );
}

sub project : GET Chained('/project/base') PathPart('print/project') Args(0) {
    my ( $self, $c, $id ) = @_;

    my @extra_columns = grep { defined and length } $c->req->params->get_all('extra_column');

    $c->stash(
        days          => $c->model('Plan')->project( $c->project ),
        extra_columns => \@extra_columns,
        title         => "Print overview",
    );
}

sub purchase_list : GET Chained('/project/base') PathPart('print/purchase_list') Args(1) {
    my ( $self, $c, $id ) = @_;

    my $list = $c->stash->{list} = $c->project->purchase_lists->find($id);

    my $model_list = $c->model('PurchaseList')->new( list => $c->stash->{list} );

    $c->stash(
        sections => $model_list->shop_sections,
        units    => $model_list->units,
    );

    $c->escape_title( "Purchase list" => $list->name );
}

__PACKAGE__->meta->make_immutable;

1;
