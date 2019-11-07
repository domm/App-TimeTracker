package App::TimeTracker;
use strict;
use warnings;
use 5.010;

our $VERSION = "3.001";
# ABSTRACT: time tracking for impatient and lazy command line lovers

use App::TimeTracker::Data::Task;

use DateTime;
use Moose;
use Moose::Util::TypeConstraints;
use Path::Class qw();
use Path::Class::Iterator;
use MooseX::Storage::Format::JSONpm;
use JSON::XS;

our $HOUR_RE   = qr/(?<hour>[012]?\d)/;
our $MINUTE_RE = qr/(?<minute>[0-5]?\d)/;
our $DAY_RE    = qr/(?<day>[0123]?\d)/;
our $MONTH_RE  = qr/(?<month>[01]?\d)/;
our $YEAR_RE   = qr/(?<year>2\d{3})/;

with qw(
    MooseX::Getopt
);

subtype 'TT::DateTime' => as class_type('DateTime');
subtype 'TT::RT'       => as 'Int';
subtype 'TT::Duration' => as enum( [qw(day week month year)] );

coerce 'TT::RT' => from 'Str' => via {
    my $raw = $_;
    $raw =~ s/\D//g;
    return $raw;
};

coerce 'TT::DateTime' => from 'Str' => via {
    my $raw = $_;
    my $dt  = DateTime->now;
    $dt->set_time_zone('local');
    $dt->set( second => 0 );

    if ($raw) {
        if ( $raw =~ /^ $HOUR_RE : $MINUTE_RE $/x ) {    # "13:42"
            $dt->set( hour => $+{hour}, minute => $+{minute} );
        }
        elsif ( $raw =~ /^ $YEAR_RE [-.]? $MONTH_RE [-.]? $DAY_RE $/x )
        {                                                # "2010-02-26"
            $dt->set( year => $+{year}, month => $+{month}, day => $+{day} );
            $dt->truncate( to => 'day' );
        }
        elsif ( $raw
            =~ /^ $YEAR_RE [-.]? $MONTH_RE [-.]? $DAY_RE \s+ $HOUR_RE : $MINUTE_RE $/x
            )
        {                                                # "2010-02-26 12:34"
            $dt->set(
                year   => $+{year},
                month  => $+{month},
                day    => $+{day},
                hour   => $+{hour},
                minute => $+{minute} );
        }
        elsif ( $raw =~ /^ $DAY_RE [-.]? $MONTH_RE [-.]? $YEAR_RE $/x )
        {                                                # "26-02-2010"
            $dt->set( year => $+{year}, month => $+{month}, day => $+{day} );
            $dt->truncate( to => 'day' );
        }
        elsif ( $raw
            =~ /^ $DAY_RE [-.]? $MONTH_RE [-.]? $YEAR_RE \s $HOUR_RE : $MINUTE_RE $/x
            )
        {                                                # "26-02-2010 12:34"
            $dt->set(
                year   => $+{year},
                month  => $+{month},
                day    => $+{day},
                hour   => $+{hour},
                minute => $+{minute} );
        }
        else {
            confess "Invalid date format '$raw'";
        }
    }
    return $dt;
};

MooseX::Getopt::OptionTypeMap->add_option_type_to_map( 'TT::DateTime' => '=s',
);
MooseX::Getopt::OptionTypeMap->add_option_type_to_map( 'TT::RT' => '=i', );

no Moose::Util::TypeConstraints;

has 'home' => (
    is       => 'ro',
    isa      => 'Path::Class::Dir',
    traits   => ['NoGetopt'],
    required => 1,
);
has 'config' => (
    is       => 'ro',
    isa      => 'HashRef',
    required => 1,
    traits   => ['NoGetopt'],
);
has '_current_project' => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_current_project',
    traits    => ['NoGetopt'],
);

has 'tags' => (
    isa     => 'ArrayRef',
    is      => 'ro',
    traits  => ['Array'],
    default => sub { [] },
    handles => {
        insert_tag => 'unshift',
        add_tag    => 'push',
    },
    documentation => 'Tags [Multiple]',
);

has '_current_command' => (
    isa    => 'Str',
    is     => 'rw',
    traits => ['NoGetopt'],
);

has '_current_task' => (
    isa    => 'App::TimeTracker::Data::Task',
    is     => 'rw',
    traits => ['NoGetopt'],
);

has '_previous_task' => (
    isa    => 'App::TimeTracker::Data::Task',
    is     => 'rw',
    traits => ['NoGetopt'],
);

sub run {
    my $self = shift;
    my $command = 'cmd_' . ( $self->extra_argv->[0] || 'missing' );

    $self->cmd_commands()
        unless $self->can($command);
    $self->_current_command($command);
    $self->$command;
}

sub now {
    my $dt = DateTime->now();
    $dt->set_time_zone('local');
    return $dt;
}

sub beautify_seconds {
    my ( $self, $s ) = @_;
    return '0' unless $s;
    my ( $m, $h ) = ( 0, 0 );

    if ( $s >= 60 ) {
        $m = int( $s / 60 );
        $s = $s - ( $m * 60 );
    }
    if ( $m && $m >= 60 ) {
        $h = int( $m / 60 );
        $m = $m - ( $h * 60 );
    }
    return sprintf( "%02d:%02d:%02d", $h, $m, $s );
}

sub find_task_files {
    my ( $self, $args ) = @_;

    my $root = $self->home;
    my ( $cmp_from, $cmp_to );

    if ( my $from = $args->{from} ) {
        my $to = $args->{to} || $self->now;
        $to->set( hour => 23, minute => 59, second => 59 ) unless $to->hour;
        $cmp_from = $from->strftime("%Y%m%d%H%M%S");
        $cmp_to   = $to->strftime("%Y%m%d%H%M%S");

        if ( $from->year == $to->year ) {
            $root = $root->subdir( $from->year );
            if ( $from->month == $to->month ) {
                $root = $root->subdir( $from->strftime("%m") );
            }
        }
    }

    my $projects;
    if ( $args->{projects} ) {
        $projects = join( '|', map { s/-/./g; $_ } @{ $args->{projects} } );
    }

    my $children;
    if ($args->{parent}) {
        my @kids = $args->{parent};
        $self->all_childs_of($args->{parent},\@kids);
        $children = join( '|', map { s/-/./g; $_ } @kids );
    }

    my $tags;
    if ( $args->{tags} ) {
        $tags = join( '|', @{ $args->{tags} } );
    }

    my @found;
    my $iterator = Path::Class::Iterator->new( root => $root, );
    until ( !$iterator || $iterator->done ) {
        my $file = $iterator->next;

        next unless -f $file;
        my $name = $file->basename;
        next unless $name =~ /\.trc$/;

        if ($cmp_from) {
            $file =~ /(\d{8})-(\d{6})/;
            my $time = $1 . $2;
            next if $time < $cmp_from;
            next if $time > $cmp_to;
        }

        if ($projects) {
            next unless ( $name =~ m/$projects/i );
        }

        if ($children) {
            next unless ( $name =~ m/$children/i );
        }

        if ($tags) {
            my $raw_content = $file->slurp;
            next unless $raw_content =~ /$tags/i;
        }

        push( @found, $file );
    }
    return sort @found;
}

sub project_tree {
    my $self = shift;
    my $file = $self->home->file('projects.json');
    return unless -e $file && -s $file;
    my $decoder  = JSON::XS->new->utf8->pretty->relaxed;
    my $projects = $decoder->decode( scalar $file->slurp );

    my %tree;
    my $depth;
    while ( my ( $project, $location ) = each %$projects ) {
        $tree{$project} //= { parent => undef, children => {} };
        # check config file for parent
        if ( -e $location ) {
            my $this_config = $decoder->decode(
                scalar Path::Class::file($location)->slurp );
            if ( my $parent = $this_config->{parent} ) {
                $tree{$project}->{parent} = $parent;
                $tree{$parent}->{children}{$project} = 1;
                next;
            }
        }
        # check path for parent
        my @parts = Path::Class::file($location)->parent->parent->dir_list;
        foreach my $dir (@parts) {
            if ( $project ne $dir and my $parent = $projects->{$dir} ) {
                $tree{$project}->{parent} = $dir;
                $tree{$dir}->{children}{$project} = 1;
            }
        }
    }

    return \%tree;
}

sub all_childs_of {
    my ($self, $parent, $collector) = @_;

    my $tree = $self->project_tree;
    my $this = $tree->{$parent};

    my @kids = keys %{$this->{children}};

    if (@kids) {
        push(@$collector, @kids);
        foreach my $kid (@kids) {
            $self->all_childs_of($kid, $collector);
        }
    }
}

1;

__END__

=head1 SYNOPSIS

Backend for the C<tracker> command. See L<tracker> and/or C<perldoc tracker> for details.

=head1 CONTRIBUTORS

Maros Kollar, Klaus Ita, Yanick Champoux, Lukas Rampa, David Schmidt, Michael Kröll, Thomas Sibley, Nelo Onyiah, Jozef Kutej, Roland Lammel, Ruslan Zakirov, Kartik Thakore, Tokuhiro Matsuno, Paul Cochrane, David Provost, Mohammad S Anwar, Håkon Hægland

