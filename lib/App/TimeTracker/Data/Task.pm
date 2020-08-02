package App::TimeTracker::Data::Task;
use 5.010;

# ABSTRACT: App::TimeTracker Task storage

use Moose;
use App::TimeTracker::Utils qw(now);
use namespace::autoclean;
use App::TimeTracker;
use DateTime::Format::ISO8601;
use DateTime::Format::Duration;
use User::pwent;

use MooseX::Storage;
with Storage(
    format => [ JSONpm => { json_opts => { pretty => 1, canonical => 1 } } ],
    io     => "File",
);

MooseX::Storage::Engine->add_custom_type_handler(
    'DateTime' => (
        expand   => sub { DateTime::Format::ISO8601->parse_datetime(shift) },
        collapse => sub { (shift)->iso8601 } ) );
my $dtf_dur = DateTime::Format::Duration->new( pattern => '%H:%M:%S',
    normalise => 1 );
my $dtf_sec = DateTime::Format::Duration->new( pattern => '%s' );

has 'start' => (
    isa      => 'DateTime',
    is       => 'ro',
    required => 1,
    default  => sub { now() } );
has 'stop' => (
    isa     => 'DateTime',
    is      => 'rw',
    trigger => \&_calc_duration,
);
has 'seconds' => (
    isa        => 'Maybe[Int]',
    is         => 'rw',
    lazy_build => 1,
);

sub _build_seconds {
    my $self  = shift;
    my $delta = now()->subtract_datetime( $self->start );
    my $s     = $dtf_sec->format_duration($delta);
    return undef unless $s > 1;
    return $s;
}
has 'duration' => (
    isa => 'Str',
    is  => 'rw',
);
has 'status' => (
    isa => 'Str',
    is  => 'rw',
);

sub _build_user {
    return @{ getpw($<) }[0];
}
has 'user' => (
    isa        => 'Str',
    is         => 'ro',
    required   => 1,
    lazy_build => 1,
);
has 'project' => (
    isa      => 'Str',
    is       => 'ro',
    required => 1,
);
has 'description' => (
    isa      => 'Maybe[Str]',
    is       => 'ro',
    required => 0,
);
has 'tags' => (
    isa     => 'ArrayRef',
    is      => 'ro',
    default => sub { [] },
    traits  => ['Array'],
    handles => { has_tags => 'count', },
);

sub _filepath {
    my $self  = shift;
    my $start = $self->start;
    my $name  = $self->project;
    $name =~ s/\W/_/g;
    $name =~ s/_+/_/g;
    $name =~ s/^_//;
    $name =~ s/_$//;
    return (
        $start->year,
        sprintf( '%02d', $start->month ),
        $start->strftime("%Y%m%d-%H%M%S") . '_' . $name . '.trc'
    );
}

sub _calc_duration {
    my ( $self, $stop ) = @_;
    $stop ||= $self->stop;
    my $delta = $stop->subtract_datetime( $self->start );
    $self->seconds( $dtf_sec->format_duration($delta) );
    $self->duration( $dtf_dur->format_duration($delta) );
}

sub storage_location {
    my ( $self, $home ) = @_;
    my $file = $home->file( $self->_filepath );
    $file->parent->mkpath;
    return $file;
}

sub description_short {
    my ($self) = @_;
    my $description = $self->description;
    return unless $description;

    $description =~ s/(.{40}[[:alnum:]]*).+$/$1.../;
    $description =~ s/^(.{50}).+$/$1.../;
    $description =~ s/\.{3,}$/.../;
    return $description;
}

sub save {
    my ( $self, $home ) = @_;

    my $file = $self->storage_location($home)->stringify;
    $self->store($file);
    return $file;
}

sub current {
    my ( $class, $home ) = @_;
    $class->_load_from_link( $home, 'current' );
}

sub previous {
    my ( $class, $home ) = @_;
    $class->_load_from_link( $home, 'previous' );
}

sub _load_from_link {
    my ( $class, $home, $link ) = @_;
    my $file = $home->file($link);
    return unless -e $file;
    my $linked_file = $file->slurp( chomp => 1 );
    return unless -e $linked_file;
    return $class->load($linked_file);
}

sub say_project_tags {
    my $self = shift;

    my $tags = $self->tags;
    my $rv   = $self->project;
    $rv .= ' (' . join( ', ', @$tags ) . ')' if @$tags;
    $rv .= ' ' . $self->description if $self->description;
    return $rv;
}

sub do_start {
    my ( $self, $home ) = @_;

    my $saved_to = $self->save($home);

    my $fh = $home->file('current')->openw;
    say $fh $saved_to;
    close $fh;

    say "Started working on "
        . $self->say_project_tags . " at "
        . $self->start->hms;
}

sub rounded_minutes {
    my $self = shift;
    return sprintf "%.0f", $self->seconds/60;
}

sub get_detail {
    my ( $self, $level ) = @_;

    my $detail = {};
    if ( $level eq 'tag' || $level eq 'description' ) {
        $detail->{tags} = $self->tags;
    }
    if ( $level eq 'description' ) {
        $detail->{desc} = $self->description;
    }
    return $detail;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 DESCRIPTION

Rather boring class implementing a Task object. Mainly used for storage etc.

