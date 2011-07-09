#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;
use Imager;

sub main {
    my ( $i_file, $o_file, $bg_color, $num ) = @_;

    die "Need an input file\n"  unless $i_file;
    die "Need an output file\n" unless $o_file;

    $bg_color //= '#1D1D1D';

    $num //= 360 / 5;
    my $deg = 360 / $num;

    my $input = Imager->new;
    $input->read( file => $i_file )
        or die "Could not read: $i_file: " . $input->errstr;

    my $size = size( $input->getwidth, $input->getheight );

    my $output
        = Imager->new( xsize => $size * $num, ysize => $size, channels => 4 );
    $output->box(
        xmin   => 0,
        ymin   => 0,
        xmax   => $size * $num,
        ymax   => $size,
        filled => 1,
        color  => $bg_color,
    );

    foreach my $i ( 0 .. $num - 1 ) {
        my $rot = $input->rotate( degrees => -$i * $deg, back => $bg_color );
        my $left = $i * $size + ( $size - $rot->getwidth ) / 2;
        my $top = ( $size - $rot->getheight ) / 2;
        $output->paste( src => $rot, left => $left, top => $top );
    }

    $output->write( file => $o_file )
        or die "Cannot save $o_file: ", $output->errstr;

    exit;
}

sub size {
    my ( $w, $h ) = @_;
    return int( sqrt( $w * $w + $h * $h ) ) + 1;
}

main(@ARGV);
