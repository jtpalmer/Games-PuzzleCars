package Games::PuzzleCars;
use Mouse;
use FindBin qw( $Bin );
use File::Spec;
use SDL;
use SDLx::App;
use SDLx::Surface;
use SDLx::Text;
use Games::PuzzleCars::Map;
use Games::PuzzleCars::Car;

has share_dir => (
    is      => 'ro',
    isa     => 'Str',
    default => sub { File::Spec->catdir( $Bin, 'share' ) },
);

has app => (
    is      => 'ro',
    isa     => 'SDLx::App',
    lazy    => 1,
    builder => '_build_app',
    handles => [qw( run )],
);

has difficulty => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has map => (
    is      => 'rw',
    isa     => 'Games::PuzzleCars::Map',
    lazy    => 1,
    builder => '_build_map',
);

has cars => (
    is      => 'ro',
    isa     => 'ArrayRef[Games::PuzzleCars::Car]',
    default => sub { [] },
);

has car_frequency => (
    is      => 'ro',
    isa     => 'Num',
    default => 3,
);

has _last_car_time => (
    is      => 'rw',
    isa     => 'Num',
    default => 0,
);

has _car_colors => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    default => sub { [qw( r g y )] },
);

has points => (
    is      => 'rw',
    isa     => 'Int',
    default => 0,
);

has _label => (
    is      => 'ro',
    isa     => 'SDLx::Text',
    default => sub {
        SDLx::Text->new( x => 10, y => 10, size => 32, color => [ 0, 0, 0 ] );
    },
);

has _surfaces => (
    is      => 'ro',
    isa     => 'HashRef[SDLx::Surface]',
    default => sub { [] },
    lazy    => 1,
    builder => '_build_surfaces',
);

sub _build_app {
    return SDLx::App->new(
        w     => 800,
        h     => 600,
        dt    => 0.02,
        eoq   => 1,
        delay => 20,
        title => 'Puzzle Cars',
    );
}

sub _build_map {
    my $self = shift;
    return Games::PuzzleCars::Map->new(
        w    => $self->app->w,
        h    => $self->app->h,
        file => File::Spec->catfile(
            $self->share_dir, 'maps', $self->{difficulty} . '.txt'
        ),
        intersection => {
            w     => 40,
            h     => 40,
            image => File::Spec->catfile( $self->share_dir, 'arrows.bmp' ),

        },
        roads => {
            w       => 50,
            h       => 50,
            image   => File::Spec->catfile( $self->share_dir, 'roads.bmp' ),
            mapping => [
                [   [ [ 6, 0 ] ],
                    [ [ 2, 0 ], [ 2, 1 ] ],
                    [ [ 4, 0 ], [ 5, 0 ] ],
                    [ [ 0, 0 ] ],
                    [ [ 8, 0 ], [ 8, 1 ], [ 9, 0 ], [ 9, 1 ] ],
                ],
                [   [ [ 7, 0 ] ],
                    [ [ 3, 0 ], [ 3, 1 ] ],
                    [ [ 4, 0 ], [ 5, 0 ] ],
                    [ [ 1, 0 ] ],
                    [ [ 8, 0 ], [ 8, 1 ], [ 9, 0 ], [ 9, 1 ] ],
                ],
                [   [ [ 6, 1 ] ],
                    [ [ 2, 0 ], [ 2, 1 ] ],
                    [ [ 4, 1 ], [ 5, 1 ] ],
                    [ [ 0, 1 ] ],
                    [ [ 8, 0 ], [ 8, 1 ], [ 9, 0 ], [ 9, 1 ] ],
                ],
                [   [ [ 7, 1 ] ],
                    [ [ 3, 0 ], [ 3, 1 ] ],
                    [ [ 4, 1 ], [ 5, 1 ] ],
                    [ [ 1, 1 ] ],
                    [ [ 8, 0 ], [ 8, 1 ], [ 9, 0 ], [ 9, 1 ] ],
                ],
            ],
        },
    );
}

sub _build_surfaces {
    my ($self) = @_;

    my %surfaces;
    foreach my $color ( @{ $self->_car_colors } ) {
        $surfaces{ $color . '_car' }
            = SDLx::Surface->load(
            File::Spec->catfile( $self->share_dir, 'cars', $color . '.bmp' )
            );
    }

    return \%surfaces;
}

sub BUILD {
    my ($self) = @_;

    $self->_add_car();

    my $app = $self->app;
    $app->add_event_handler( sub { $self->handle_event(@_) } );
    $app->add_move_handler( sub  { $self->handle_move(@_) } );
    $app->add_show_handler( sub  { $self->handle_show(@_) } );
}

sub handle_event {
    my ( $self, $event, $app ) = @_;
    $self->map->handle_event($event);
}

sub handle_move {
    my ( $self, $step, $app, $t ) = @_;

    if ( $t > $self->_last_car_time + $self->car_frequency ) {
        $self->_last_car_time($t);
        $self->_add_car();
    }

    my $map  = $self->map;
    my @cars = @{ $self->cars };
    foreach my $car (@cars) {
        $car->move( $step, $app, $t );

        if (   $car->x < 0
            || $car->x > $map->w * $map->tile_w
            || $car->y < 0
            || $car->y > $map->h * $map->tile_h )
        {

            my $road = $car->road;
            if ( my $exit = $map->exits->[ $road->x ][ $road->y ] ) {
                if ( $car->color eq $exit ) {
                    $self->points( $self->points + 10 );
                }
                else {
                    $self->points( $self->points - 10 );
                }
            }

            @{ $self->cars } = grep { $_ ne $car } @{ $self->cars };
        }
    }
}

sub handle_show {
    my ( $self, $delta, $app ) = @_;

    $self->map->draw($app);
    $_->draw($app) foreach @{ $self->cars };
    $self->_label->write_to( $app, 'Score: ' . $self->points );
    $app->update();
}

sub _add_car {
    my ($self) = @_;

    my $left  = 37;
    my $right = 63;

    my $map     = $self->map;
    my $borders = $map->borders;
    my $border  = $borders->[ int rand @$borders ];

    my $colors = $self->_car_colors;
    my $color  = $colors->[ int rand @$colors ];

    my ( $x, $y, $rot, $v_x, $v_y, $direction );
    if ( $border->x == 0 && defined $border->directions->{WEST} ) {
        $x         = 0;
        $y         = $border->y * $map->tile_h + $right;
        $rot       = 0;
        $v_x       = 1;
        $v_y       = 0;
        $direction = 'EAST';
    }
    elsif ( $border->y == 0 && defined $border->directions->{NORTH} ) {
        $x         = $border->x * $map->tile_w + $left;
        $y         = 0;
        $rot       = 270;
        $v_x       = 0;
        $v_y       = 1;
        $direction = 'SOUTH';
    }
    elsif ( $border->x == $map->w - 1 && defined $border->directions->{EAST} )
    {
        $x         = $map->w * $map->tile_w;
        $y         = $border->y * $map->tile_h + $left;
        $rot       = 180;
        $v_x       = -1;
        $v_y       = 0;
        $direction = 'WEST';
    }
    elsif ( $border->y == $map->h - 1
        && defined $border->directions->{SOUTH} )
    {
        $x         = $border->x * $map->tile_w + $right;
        $y         = $map->h * $map->tile_h;
        $rot       = 90;
        $v_x       = 0;
        $v_y       = -1;
        $direction = 'NORTH';
    }

    die unless defined $x;

    my $car = Games::PuzzleCars::Car->new(
        color     => $color,
        rect      => SDL::Rect->new( 0, 0, 34, 34 ),
        surface   => $self->_surfaces->{ $color . '_car' },
        map       => $self->map,
        road      => $border,
        next_road => $border->next($direction),
        direction => $direction,
        x         => $x,
        y         => $y,
        rot       => $rot,
        v_x       => $v_x,
        v_y       => $v_y,
    );

    push @{ $self->cars }, $car;
}

no Mouse;

1;
