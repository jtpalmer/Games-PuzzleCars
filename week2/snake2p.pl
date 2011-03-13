#!/usr/bin/env perl
use strict;
use warnings;
use FindBin qw( $Bin );
use lib "$Bin/lib";
use Games::Snake;
use Games::Snake::RemotePlayer;
use Getopt::Long;

my $raddr;
my $rport = 62173;
my $laddr;
my $lport = 62173;

my $result = GetOptions(
    'raddr=s' => \$raddr,
    'rport=i' => \$rport,
    'laddr=s' => \$laddr,
    'lport=i' => \$lport,
);

my $game = Games::Snake->new();

my $p2 = Games::Snake::RemotePlayer->new(
    game  => $game,
    size  => $game->size,
    raddr => $raddr,
    rport => $rport,
    laddr => $laddr,
    lport => $lport,
);

$game->player2($p2);
$game->run($p2);