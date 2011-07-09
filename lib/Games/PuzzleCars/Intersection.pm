package Games::PuzzleCars::Intersection;
use Mouse;

extends 'Games::PuzzleCars::Road';

has direction => (
    is      => 'rw',
    isa     => 'Int',
    default => 0,
);

has arrow => (
    is       => 'ro',
    isa      => 'SDLx::Sprite',
    required => 1,
);

sub _direction_count {
    my ($self) = @_;

    return scalar keys %{ $self->directions };
}

sub _next_direction {
    my ( $self, $direction ) = @_;

    return $direction if $self->direction == 2;

    my %next = (
        NORTH => [qw( EAST NORTH WEST SOUTH )],
        EAST  => [qw( SOUTH EAST NORTH WEST )],
        SOUTH => [qw( WEST SOUTH EAST NORTH )],
        WEST  => [qw( NORTH WEST SOUTH EAST )],
    );

    my @dirs
        = grep { defined $self->directions->{$_} } @{ $next{$direction} };

    if ( $self->_direction_count == 4 ) {
        @dirs = grep { $_ ne $direction } @dirs;
    }

    return $dirs[ $self->direction ];
}

sub handle_event {
    my ( $self, $event ) = @_;

    my $e_x = $event->button_x;
    my $e_y = $event->button_y;

    my $x      = ( $self->x + 0.5 ) * $self->map->tile_w;
    my $y      = ( $self->y + 0.5 ) * $self->map->tile_h;
    my $s      = $self->arrow->h;
    my $left   = $x - $s / 2;
    my $right  = $x + $s / 2;
    my $top    = $y - $s / 2;
    my $bottom = $y + $s / 2;

    return
        unless $e_x > $left && $e_x < $right && $e_y > $top && $e_y < $bottom;

    $self->direction(
        ( $self->direction + 1 ) % ( $self->_direction_count - 1 ) );
}

sub draw {
    my ( $self, $surface ) = @_;

    my $arrow = $self->arrow;
    my $x     = ( $self->x + 0.5 ) * $self->map->tile_w;
    my $y     = ( $self->y + 0.5 ) * $self->map->tile_h;
    my $s     = $arrow->h;
    $arrow->clip( [ $self->direction * $s, 0, $s, $s ] );
    $arrow->draw_xy( $surface, $x - $s / 2, $y - $s / 2 );
}

no Mouse;

1;
