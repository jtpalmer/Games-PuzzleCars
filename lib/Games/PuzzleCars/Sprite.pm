package Games::PuzzleCars::Sprite;
use Mouse;
use SDLx::Sprite::Animated;

has _sprite => (
    is       => 'ro',
    isa      => 'SDLx::Sprite::Animated',
    required => 1,
    handles  => [qw( x y h w rect clip draw draw_xy alpha_key )],
);

has increment => (
    is      => 'ro',
    isa     => 'Int',
    lazy    => 1,
    default => sub { 360 / ( $_[0]->rows * $_[0]->cols ) },
);

has rows => (
    is      => 'ro',
    isa     => 'Int',
    lazy    => 1,
    default => sub { $_[0]->h / $_[0]->rect->h },
);

has cols => (
    is      => 'ro',
    isa     => 'Int',
    lazy    => 1,
    default => sub { $_[0]->w / $_[0]->rect->w },
);

around BUILDARGS => sub {
    my ( $orig, $class, %args ) = @_;

    my $animated = SDLx::Sprite::Animated->new(
        rect    => $args{rect},
        surface => $args{surface},
    );
    $animated->alpha_key(0x1D1D1D);

    return $class->$orig( _sprite => $animated );
};

sub rotation {
    my ( $self, $rot ) = @_;

    while ( $rot >= 360 ) { $rot -= 360 }
    while ( $rot < 0 ) { $rot += 360 }

    my $frame = int( $rot / $self->increment );

    my $clip = $self->clip;
    $clip->x( ( $frame % $self->cols ) * $self->rect->h );
    $clip->y( int( $frame / $self->cols ) * $self->rect->w );
}

no Mouse;

1;
