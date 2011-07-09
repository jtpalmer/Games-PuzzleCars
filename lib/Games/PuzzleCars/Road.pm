package Games::PuzzleCars::Road;
use Mouse;

has map => (
    is       => 'ro',
    isa      => 'Games::PuzzleCars::Map',
    required => 1,
);

has [qw( x y )] => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

has directions => (
    is       => 'ro',
    isa      => 'HashRef',
    required => 1,
);

sub _next_direction {
    my ( $self, $direction ) = @_;

    if ( !defined $self->directions->{$direction} ) {
        my %opposite = (
            WEST  => 'EAST',
            EAST  => 'WEST',
            NORTH => 'SOUTH',
            SOUTH => 'NORTH',
        );

        ($direction) = grep { $_ ne $opposite{$direction} }
            keys %{ $self->directions };
    }

    return $direction;
}

sub next {
    my ( $self, $direction ) = @_;

    $direction = $self->_next_direction($direction);

    my $x = $self->x;
    my $y = $self->y;
    $x -= 1 if $direction eq 'WEST';
    $x += 1 if $direction eq 'EAST';
    $y -= 1 if $direction eq 'NORTH';
    $y += 1 if $direction eq 'SOUTH';

    my $roads = $self->map->roads;
    return undef unless defined $roads->[$x][$y];

    return $roads->[$x][$y];
}

sub turn {
    my ( $self, $car ) = @_;

    my $d  = $car->direction;
    my $nd = $self->_next_direction($d);

    return if $d eq $nd;

    my $x = $car->x;
    my $y = $car->y;

    my $left   = $self->x * $self->map->tile_w + 25;
    my $right  = $self->x * $self->map->tile_w + 75;
    my $top    = $self->y * $self->map->tile_h + 25;
    my $bottom = $self->y * $self->map->tile_h + 75;

    my $r_i     = 12;
    my $r_o     = 38;
    my $delta_i = 4;
    my $delta_o = 2;

    my ( $xc, $yc, $r, $delta, $angle, $max_angle );
    if ( $d eq 'WEST' && $x < $right ) {
        $xc = $right;
        if ( $nd eq 'NORTH' ) {
            $yc        = $top;
            $r         = $r_i;
            $delta     = -$delta_i;
            $angle     = 270;
            $max_angle = 180;
        }
        else {
            $yc        = $bottom;
            $r         = $r_o;
            $delta     = $delta_o;
            $angle     = 90;
            $max_angle = 180;
        }
    }
    elsif ( $d eq 'EAST' && $x > $left ) {
        $xc = $left;
        if ( $nd eq 'NORTH' ) {
            $yc        = $top;
            $r         = $r_o;
            $delta     = $delta_o;
            $angle     = 270;
            $max_angle = 360;
        }
        else {
            $yc        = $bottom;
            $r         = $r_i;
            $delta     = -$delta_i;
            $angle     = 90;
            $max_angle = 0;
        }
    }
    elsif ( $d eq 'NORTH' && $y < $bottom ) {
        if ( $nd eq 'WEST' ) {
            $xc        = $left;
            $r         = $r_o;
            $delta     = $delta_o;
            $angle     = 0;
            $max_angle = 90;
        }
        else {
            $xc        = $right;
            $r         = $r_i;
            $delta     = -$delta_i;
            $angle     = 180;
            $max_angle = 90;
        }
        $yc = $bottom;
    }
    elsif ( $d eq 'SOUTH' && $y > $top ) {
        if ( $nd eq 'WEST' ) {
            $xc        = $left;
            $r         = $r_i;
            $delta     = -$delta_i;
            $angle     = 360;
            $max_angle = 270;
        }
        else {
            $xc        = $right;
            $r         = $r_o;
            $delta     = $delta_o;
            $angle     = 180;
            $max_angle = 270;
        }
        $yc = $top;
    }
    else {
        return;
    }

    my ( $fx, $fy, $fvx, $fvy );
    if ( $nd eq 'WEST' ) {
        $fx  = $left;
        $fy  = $top + 12;
        $fvx = -1;
        $fvy = 0;
    }
    elsif ( $nd eq 'EAST' ) {
        $fx  = $right;
        $fy  = $top + 38;
        $fvx = 1;
        $fvy = 0;
    }
    elsif ( $nd eq 'NORTH' ) {
        $fx  = $left + 38;
        $fy  = $top;
        $fvx = 0;
        $fvy = -1;
    }
    elsif ( $nd eq 'SOUTH' ) {
        $fx  = $left + 12;
        $fy  = $bottom;
        $fvx = 0;
        $fvy = 1;
    }

    $car->next_road( $self->next($d) );
    $car->turn(
        {   x         => $xc,
            y         => $yc,
            r         => $r,
            angle     => $angle,
            max_angle => $max_angle,
            delta     => $delta,
            finish    => {
                x         => $fx,
                y         => $fy,
                v_x       => $fvx,
                v_y       => $fvy,
                direction => $nd,
            },
        }
    );
}

sub contains {
    my ( $self, $x, $y ) = @_;

    my $map = $self->map;
    return
           $x >= $self->x * $map->tile_w
        && $x < ( $self->x + 1 ) * $map->tile_w
        && $y >= $self->y * $map->tile_h
        && $y < ( $self->y + 1 ) * $map->tile_h;
}

no Mouse;

1;
