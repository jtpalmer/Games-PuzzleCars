package Games::PuzzleCars::Map;
use Mouse;
use List::Util qw( max );
use SDL::Rect;
use SDL::Event;
use SDL::Events;
use SDLx::Surface;
use SDLx::Sprite;
use Games::PuzzleCars::Road;
use Games::PuzzleCars::Intersection;

has _data => (
    is       => 'ro',
    isa      => 'HashRef',
    required => 1,
);

has background => (
    is      => 'ro',
    isa     => 'SDLx::Surface',
    lazy    => 1,
    builder => '_build_background',
);

has roads => (
    is      => 'ro',
    isa     => 'ArrayRef[ArrayRef]',
    lazy    => 1,
    builder => '_build_roads',
);

has intersections => (
    is      => 'ro',
    isa     => 'ArrayRef[Games::PuzzleCars::Intersection]',
    lazy    => 1,
    builder => '_build_intersections',
);

has borders => (
    is      => 'ro',
    isa     => 'ArrayRef[Games::PuzzleCars::Road]',
    lazy    => 1,
    builder => '_build_borders',
);

has exits => (
    is      => 'ro',
    isa     => 'ArrayRef[ArrayRef]',
    lazy    => 1,
    builder => '_build_exits',
);

has exit_colors => (
    is      => 'ro',
    isa     => 'HashRef[Int]',
    default => sub { { r => 0x920A0AFF, g => 0x479932FF, y => 0xB9C043FF, } },
);

has [qw( w h tile_w tile_h )] => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

sub _build_background {
    my ($self) = @_;

    my $bg = SDLx::Surface->new(
        w     => $self->w * $self->tile_w,
        h     => $self->h * $self->tile_h,
        color => 0x000000FF,
    );

    my $data = $self->_data;

    my $road_sprite = SDLx::Sprite->new( image => $data->{roads}{image} );

    my $road_w       = $data->{roads}{w};
    my $road_h       = $data->{roads}{h};
    my $road_mapping = $data->{roads}{mapping};

    my $grid  = $data->{grid};
    my $exits = $data->{exits};

    my %horizontal = ( 0 => 'WEST',  1 => 'EAST' );
    my %vertical   = ( 0 => 'NORTH', 1 => 'SOUTH' );

    foreach my $col_id ( 0 .. $self->w - 1 ) {
        foreach my $row_id ( 0 .. $self->h - 1 ) {
            while ( my ( $y_i, $y_dir ) = each(%vertical) ) {
                while ( my ( $x_i, $x_dir ) = each(%horizontal) ) {

                    my $index = 0;
                    if ( my %directions = %{ $grid->[$col_id][$row_id] } ) {
                        $index += 1 if defined $directions{$y_dir};
                        $index += 2 if defined $directions{$x_dir};
                    }
                    else {
                        $index = 4;
                    }

                    my @tiles = @{ $road_mapping->[ 2 * $y_i + $x_i ] };

                    my @tile_group = @{ $tiles[$index] };
                    my @tile       = @{ $tile_group[ int rand @tile_group ] };
                    my $x          = $tile[0];
                    my $y          = $tile[1];

                    $road_sprite->clip(
                        [ $x * $road_w, $y * $road_h, $road_w, $road_h ] );
                    $road_sprite->draw_xy(
                        $bg,
                        ( 2 * $col_id + $x_i ) * $road_w,
                        ( 2 * $row_id + $y_i ) * $road_h
                    );
                }
            }
            if ( my $color = $exits->[$col_id][$row_id] ) {
                $bg->draw_circle_filled(
                    [   ( $col_id + 0.5 ) * $self->tile_w,
                        ( $row_id + 0.5 ) * $self->tile_h
                    ],
                    $road_h / 4,
                    $self->exit_colors->{$color}
                );
            }
        }
    }

    return $bg;
}

sub _build_roads {
    my ($self) = @_;

    my @roads;

    my $data = $self->_data;

    my $grid = $data->{grid};

    my $arrow = SDLx::Sprite->new( image => $data->{intersection}{image} );
    $arrow->alpha_key(0x000000);

    foreach my $col_id ( 0 .. $self->w - 1 ) {
        foreach my $row_id ( 0 .. $self->h - 1 ) {
            if ( my %directions = %{ $grid->[$col_id][$row_id] } ) {
                if ( keys %directions > 2 ) {
                    $roads[$col_id][$row_id]
                        = Games::PuzzleCars::Intersection->new(
                        map        => $self,
                        x          => $col_id,
                        y          => $row_id,
                        arrow      => $arrow,
                        directions => \%directions,
                        );
                }
                else {
                    $roads[$col_id][$row_id] = Games::PuzzleCars::Road->new(
                        map        => $self,
                        x          => $col_id,
                        y          => $row_id,
                        directions => \%directions,
                    );
                }
            }
        }
    }

    return \@roads;
}

sub _build_intersections {
    my ($self) = @_;

    return [
        grep { $_ && $_->isa('Games::PuzzleCars::Intersection') }
        map {@$_} @{ $self->roads }
    ];
}

sub _build_borders {
    my ($self) = @_;

    return [
        grep {
            $_
                && ( $_->x == 0
                || $_->x == $self->w - 1
                || $_->y == 0
                || $_->y == $self->h - 1 )
            } map {@$_} @{ $self->roads }
    ];
}

sub _build_exits {
    my ($self) = @_;
    return $self->_data->{exits};
}

around BUILDARGS => sub {
    my ( $orig, $class, %args ) = @_;

    open my $map_file, '<', $args{file};
    my @map = map { chomp; [ split //, $_ ] } <$map_file>;

    my @grid;
    my @exits;

    my $h = $#map;
    my $w = max map { $#{$_} } @map;

    foreach my $row_id ( 0 .. $h ) {
        foreach my $col_id ( 0 .. $w ) {

            my ( $prev_row, $next_row ) = ( $row_id - 1, $row_id + 1 );
            $prev_row = $row_id + 1 if $row_id == 0;
            $next_row = $row_id - 1 if $row_id == $h;
            my @v = ( $map[$prev_row][$col_id], $map[$next_row][$col_id] );

            my ( $prev_col, $next_col ) = ( $col_id - 1, $col_id + 1 );
            $prev_col = $col_id + 1 if $col_id == 0;
            $next_col = $col_id - 1 if $col_id == $w;
            my @h = ( $map[$row_id][$prev_col], $map[$row_id][$next_col] );

            my $cell = $map[$row_id][$col_id];

            if ( $cell =~ /[Rrgy]/ ) {
                my %directions;
                $directions{WEST}  = 1 if $h[0] =~ /[Rrgy]/;
                $directions{EAST}  = 1 if $h[1] =~ /[Rrgy]/;
                $directions{NORTH} = 1 if $v[0] =~ /[Rrgy]/;
                $directions{SOUTH} = 1 if $v[1] =~ /[Rrgy]/;

                $grid[$col_id][$row_id] = \%directions;
                $exits[$col_id][$row_id] = $cell if $cell =~ /[rgy]/;
            }
            else {
                $grid[$col_id][$row_id] = {};
            }
        }
    }

    return $class->$orig(
        _data => {
            grid         => \@grid,
            exits        => \@exits,
            roads        => $args{roads},
            intersection => $args{intersection},
        },
        w      => $w + 1,
        h      => $h + 1,
        tile_w => $args{roads}{w} * 2,
        tile_h => $args{roads}{h} * 2,
    );
};

sub handle_event {
    my ( $self, $event ) = @_;

    return unless $event->type == SDL_MOUSEBUTTONDOWN;

    $_->handle_event($event) foreach @{ $self->intersections };
}

sub draw {
    my ( $self, $surface ) = @_;

    $self->background->blit($surface);
    $_->draw($surface) foreach @{ $self->intersections };
}

no Mouse;

1;
