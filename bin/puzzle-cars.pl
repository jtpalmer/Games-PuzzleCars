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

=pod

=head1 SYNOPSIS

    $ puzzle-cars.pl

=head1 DESCRIPTION

This will start the game.

=head1 OPTIONS

=over 4

=item B<--easy>

Set the difficulty level to easy.

=item B<--hard>

Set the difficulty level to hard.

=back

=head1 EXAMPLES

    # Normal difficulty
    $ puzzle-cars.pl

    # Easy difficulty
    $ puzzle-cars.pl --easy

=head1 SEE ALSO

=over 4

=item * L<Games::PuzzleCars>

=back

=cut

