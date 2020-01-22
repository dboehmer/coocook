package Coocook::Model::Badge;

# ABSTRACT: generator for SVG images of badges inspired by img.shields.io

use strict;
use warnings;

use SVG;

sub create_badge {
    my ( $class, $text_left_content, $text_right_content, $other_color ) = @_;

    my $text_right_width = 7 * length($text_right_content) + 10;

    # create an SVG object
    my $badge = SVG->new( width => 85 + $text_right_width, height => 20 );

    # Group with the rounded rectangle in the background, that has two colors
    my $grey_rectangle = $badge->group(
        id    => 'group_grey_rectangle',
        style => {
            stroke => 'none',
            fill   => '#555'
        },
    );

    my $grey_rounded_rect = $grey_rectangle->rectangle(
        x      => 0,
        y      => 0,
        width  => 20,
        height => 20,
        rx     => 5,
        ry     => 5,
        id     => 'grey_rounded_rect'
    );

    my $grey_sharp_rect = $grey_rectangle->rectangle(
        x      => 10,
        y      => 0,
        width  => 75,
        height => 20,
        rx     => 0,
        ry     => 0,
        id     => 'grey_sharp_rect'
    );

    my $other_color_rectangle = $badge->group(
        id    => 'group_other_colorrectangle',
        style => {
            stroke => 'none',
            fill   => $other_color,
        },
    );

    my $other_color_sharp_rect = $other_color_rectangle->rectangle(
        x      => 85,
        y      => 0,
        width  => 8,
        height => 20,
        rx     => 0,
        ry     => 0,
        id     => 'other_color_sharp_rect'
    );

    my $other_color_rounded_rect = $other_color_rectangle->rectangle(
        x      => 85,
        y      => 0,
        width  => $text_right_width,
        height => 20,
        rx     => 5,
        ry     => 5,
        id     => 'other_color_rounded_rect'
    );

    my $badge_text = $badge->group(
        id            => 'group_badge_text',
        'text-anchor' => 'middle',
        'font-size'   => '110',
        'font-family' => 'DejaVu Sans,Verdana,Geneva,sans-serif',
        fill          => 'white',
        stroke        => 'none',
    );

    my $text_left_shadow = $badge_text->text(
        id             => 'text_left_shadow',
        x              => 435,
        y              => 150,
        fill           => '#010101',
        'fill-opacity' => 0.3,
        'text-length'  => 750,
        -cdata         => $text_left_content,
        transform      => 'scale(0.1)',
    );

    my $text_right_shadow = $badge_text->text(
        id             => 'text_right_shadow',
        x              => 85 * 10 + ( $text_right_width * 5 ),
        y              => 150,
        fill           => '#010101',
        'fill-opacity' => 0.3,
        'text-length'  => 210,
        -cdata         => $text_right_content,
        transform      => 'scale(0.1)',
    );

    my $text_left = $badge_text->text(
        id            => 'text_left',
        x             => 435,
        y             => 140,
        'text-length' => 750,
        -cdata        => $text_left_content,
        transform     => 'scale(0.1)',
    );

    my $text_right = $badge_text->text(
        id            => 'text_right',
        x             => 85 * 10 + ( $text_right_width * 5 ),
        y             => 140,
        'text-length' => 210,
        -cdata        => $text_right_content,
        transform     => 'scale(0.1)',
    );

    my $badge_shadow_gradient = $badge->gradient(
        -type => 'linear',
        id    => 'badge_shadow',
        x1    => '0%',
        x2    => '0%',
        y1    => '0%',
        y2    => '100%',
    );

    my $badge_shadow_gradient_stop_transparent = $badge_shadow_gradient->stop(
        id             => 'badge_shadow_stop_transparent',
        offset         => '0%',
        'stop-color'   => '#bbb',
        'stop-opacity' => 0.1,
    );

    my $badge_shadow_gradient_stop_black = $badge_shadow_gradient->stop(
        id             => 'badge_shadow_stop_black',
        offset         => '100%',
        'stop-color'   => '#000',
        'stop-opacity' => 0.1,
    );

    my $badge_shadow_rectangle = $badge->rectangle(
        x      => 0,
        y      => 0,
        r      => 5,
        width  => 85 + $text_right_width,
        height => 20,
        fill   => 'url(#badge_shadow)'
    );

    return $badge->xmlify;
}

1;
