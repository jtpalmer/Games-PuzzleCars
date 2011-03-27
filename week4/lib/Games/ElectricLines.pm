package Games::ElectricLines;
use Mouse;
use FindBin qw( $Bin );
use File::Spec;
use SDL;
use SDL::Event;
use SDL::Events;
use SDL::Rect;
use SDLx::App;
use SDLx::Sprite::Animated;

has _share_dir => (
    is      => 'ro',
    isa     => 'Str',
    default => sub { File::Spec->catdir( $Bin, 'share' ) },
);

has app => (
    is      => 'ro',
    isa     => 'SDLx::App',
    builder => '_build_app',
    handles => [qw( run )],
);

has sprite => (
    is      => 'ro',
    isa     => 'SDLx::Sprite::Animated',
    lazy    => 1,
    builder => '_build_sprite',
);

has _starting_points => (
    is      => 'ro',
    isa     => 'ArrayRef',
    lazy    => 1,
    builder => '_build_starting_points',
);

has _horizontal_lines => (
    is      => 'ro',
    isa     => 'ArrayRef',
    lazy    => 1,
    builder => '_build_horizontal_lines',
);

has _active_line => (
    is        => 'rw',
    isa       => 'ArrayRef',
    clearer   => '_clear_active_line',
    predicate => '_has_active_line',
);

has _crossing_lines => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub { [] },
);

has _plasma => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub { [] },
);

sub _build_app {
    return SDLx::App->new(
        title => 'Electric Lines',
        w     => 800,
        h     => 600,
        delay => 30,
        eoq   => 1,
    );
}

sub _build_sprite {
    my ($self) = @_;

    my $sprite = SDLx::Sprite::Animated->new(
        rect => SDL::Rect->new( 0, 50, 50, 50 ),
        image => File::Spec->catfile( $self->_share_dir, 'plasma.bmp' ),
        ticks_per_frame => 2,
    );
    $sprite->alpha_key(0x000000);
    $sprite->start();
    return $sprite;
}

sub _build_starting_points {
    my ($self) = @_;

    my $count = 4;

    my $app   = $self->app;
    my $space = $app->h / $count;
    my $x     = 0;

    my @points;

    foreach my $i ( 1 .. $count ) {
        my $y = ( $i - 0.5 ) * $space;
        push @points, [ $x, $y ];
    }

    return \@points;
}

sub _build_horizontal_lines {
    my ($self) = @_;

    my $x = $self->app->w;

    my @lines;
    foreach my $point ( @{ $self->_starting_points } ) {
        push @lines, [ $point, [ $x, $point->[1] ] ];
    }

    return \@lines;
}

sub BUILD {
    my ($self) = @_;

    $self->_add_plasma();

    my $app = $self->app;
    $app->add_event_handler( sub { $self->handle_event(@_) } );
    $app->add_move_handler( sub  { $self->handle_move(@_) } );
    $app->add_show_handler( sub  { $self->handle_show(@_) } );
}

sub handle_event {
    my ( $self, $event, $app ) = @_;

    if ( $event->type == SDL_MOUSEBUTTONDOWN ) {
        return unless $event->button_button == SDL_BUTTON_LEFT;
        my $x = $event->button_x;
        my $y = $event->button_y;
        $self->_active_line( [ [ $x, $y ], [ $x, $y ] ] );
    }
    elsif ( $event->type == SDL_MOUSEMOTION ) {
        return unless $self->_has_active_line();
        my $x = $event->motion_x;
        my $y = $event->motion_y;
        $self->_active_line->[1] = [ $x, $y ];
    }
    elsif ( $event->type == SDL_MOUSEBUTTONUP ) {
        return unless $event->button_button == SDL_BUTTON_LEFT;
        my $x = $event->button_x;
        my $y = $event->button_y;
        $self->_active_line->[1] = [ $x, $y ];
        $self->_store_active_line();
        $self->_clear_active_line();
    }
}

sub _store_active_line {
    my ($self) = @_;
    my $segments = $self->_segment_line( $self->_active_line );
    push @{ $self->_crossing_lines }, @{ $segments->{good} };
}

sub handle_move {
    my ( $self, $step, $app, $t ) = @_;

    foreach my $plasma ( @{ $self->_plasma } ) {
        $self->_move_plasma( $plasma, $step );
    }
}

sub handle_show {
    my ( $self, $delta, $app ) = @_;

    $app->draw_rect( undef, undef );
    foreach my $line ( @{ $self->_horizontal_lines },
        @{ $self->_crossing_lines } )
    {
        $app->draw_line( @$line, 0xFFFFFFFF );
    }
    if ( $self->_has_active_line() ) {
        $self->_draw_active_line( $self->_active_line );
    }
    foreach my $plasma ( @{ $self->_plasma } ) {
        $self->_draw_plasma($plasma);
    }
    $app->update();
}

sub _move_plasma {
    my ( $self, $plasma, $step ) = @_;

    $plasma->{x} += $step;
}

sub _draw_active_line {
    my ( $self, $line ) = @_;

    my $segments = $self->_segment_line($line);

    foreach my $line ( @{ $segments->{good} } ) {
        $self->app->draw_line( @$line, 0x00FF00FF );
    }
    foreach my $line ( @{ $segments->{bad} } ) {
        $self->app->draw_line( @$line, 0xFF0000FF );
    }
}

sub _segment_line {
    my ( $self, $line ) = @_;

    my ( $x0, $y0, $x1, $y1 ) = map {@$_} @$line;

    my @good;
    my @bad;

    my $direction = $y0 <=> $y1;
    if ( $direction == 0 ) {
        push @bad, $line;
    }
    else {
        my @rows = grep {
                   ( $y0 <=> $_->[1] ) == $direction
                && ( $y1 <=> $_->[1] )
                != $direction
        } @{ $self->_starting_points };
        @rows = reverse @rows if $direction == 1;

        if ( @rows < 2 ) {
            push @bad, $line;
        }
        else {
            my @segment = (
                [ $self->_interpolate_x( $line, $rows[0][1] ), $rows[0][1] ],
                [ $self->_interpolate_x( $line, $rows[1][1] ), $rows[1][1] ]
            );
            push @good, \@segment;
            push @bad, [ $line->[0], $segment[0] ],
                [ $segment[1], $line->[1] ];
        }
    }

    return {
        good => \@good,
        bad  => \@bad,
    };
}

sub _interpolate_x {
    my ( $self, $line, $y ) = @_;
    my ( $x0, $y0, $x1, $y1 ) = map {@$_} @$line;
    my $m = ( $y1 - $y0 ) / ( $x1 - $x0 );
    my $b = $y0 - $x0 * $m;
    return ( $y - $b ) / $m;
}

sub _draw_plasma {
    my ( $self, $plasma ) = @_;

    my $sprite = $self->sprite;
    $sprite->x( $plasma->{x} - $sprite->rect->w / 2 );
    $sprite->y( $plasma->{y} - $sprite->rect->h / 2 );
    $sprite->draw( $self->app );
}

sub _add_plasma {
    my ($self) = @_;

    my @points = @{ $self->_starting_points };
    my $i      = int rand @points;
    my @start  = @{ $points[$i] };
    my $line   = $self->_horizontal_lines->[$i];

    my %plasma = (
        x    => $start[0],
        y    => $start[1],
        line => $line,
    );

    push @{ $self->_plasma }, \%plasma;
}

no Mouse;

1;