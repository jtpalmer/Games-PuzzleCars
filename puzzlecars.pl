#!/usr/bin/env perl
use strict;
use warnings;
use FindBin qw( $Bin );
use lib "$Bin/lib";
use Games::PuzzleCars;
use Getopt::Long;

my $difficulty = 'normal';
my ( $easy, $hard );
my $result = GetOptions(
    'easy' => \$easy,
    'hard' => \$hard,
);

die "Can't use both --easy and --hard\n" if $easy && $hard;

$difficulty = 'easy' if $easy;
$difficulty = 'hard' if $hard;

Games::PuzzleCars->new( difficulty => $difficulty )->run();
