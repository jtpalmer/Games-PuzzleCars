package Games::PuzzleCars::Car;
use Mouse;
use Math::Trig qw( deg2rad );
use Games::PuzzleCars::Sprite;

has [qw( x y rot v_x v_y )] => (
    is       => 'rw',
    isa      => 'Num',
    required => 1,
);

has direction => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);

has turn => (
    is      => 'rw',
    isa     => 'HashRef',
    clearer => '_clear_turn',
);

has turned => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

has map => (
    is       => 'ro',
    isa      => 'Games::PuzzleCars::Map',
    required => 1,
);

has road => (
    is       => 'rw',
    isa      => 'Games::PuzzleCars::Road',
    required => 1,
);

has next_road => (
    is      => 'rw',
    isa     => 'Games::PuzzleCars::Road',
    clearer => '_clear_next_road',
);

has _sprite => (
    is       => 'ro',
    isa      => 'Games::PuzzleCars::Sprite',
    required => 1,
    handles  => [qw( draw )],
);

has color => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

around BUILDARGS => sub {
    my ( $orig, $class, %args ) = @_;

    my $sprite = Games::PuzzleCars::Sprite->new(
        rect    => $args{rect},
        surface => $args{surface},
    );

    return $class->$orig( _sprite => $sprite, %args );
};

before draw => sub {
    my ($self) = @_;

    my $sprite = $self->_sprite;
    my $rect   = $sprite->rect;

    $sprite->x( $self->x - $rect->w / 2 );
    $sprite->y( $self->y - $rect->h / 2 );
    $sprite->rotation( $self->rot );
};

sub move {
    my ( $self, $step, $c, $t ) = @_;

    if ( !$self->turned && ( my $turn = $self->turn ) ) {
        $turn->{angle} += $turn->{delta} * $step;

        my ( $xc, $yc, $r, $angle ) = @$turn{qw( x y r angle )};

        my $delta_dir = $turn->{delta} <=> 0;

        my $x = $xc + cos( deg2rad($angle) ) * $r;
        my $y = $yc - sin( deg2rad($angle) ) * $r;

        $self->x($x);
        $self->y($y);
        $self->rot( $angle + 90 * $delta_dir );

        if ( ( $turn->{angle} <=> $turn->{max_angle} ) == $delta_dir ) {
            my $finish = $turn->{finish};
            $self->x( $finish->{x} );
            $self->y( $finish->{y} );
            $self->rot( $turn->{max_angle} + 90 * $delta_dir );
            $self->v_x( $finish->{v_x} );
            $self->v_y( $finish->{v_y} );
            $self->direction( $finish->{direction} );
            $self->_clear_turn();
            $self->turned(1);
        }
    }
    else {
        $self->x( $self->x + $self->v_x * $step );
        $self->y( $self->y + $self->v_y * $step );
        $self->road->turn($self) unless $self->turned;
    }

    if (   $self->next_road
        && $self->next_road->contains( $self->x, $self->y ) )
    {
        my $road = $self->next_road;
        my $next = $road->next( $self->direction );

        $self->road($road);

        if ($next) {
            $self->next_road($next);
        }
        else {
            $self->_clear_next_road();
        }
        $self->turned(0);
    }
}

no Mouse;

1;
