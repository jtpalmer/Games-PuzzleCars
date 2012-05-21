#!perl
use strict;
use warnings;

BEGIN {
    if ( $^O eq 'darwin' && $^X ne 'SDLPerl' ) {
        exec 'SDLPerl', $0, @ARGV or die "Failed to exec SDLPerl: $!";
    }
}

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

exit;

