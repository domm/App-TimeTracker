package TimeTracker;

use 5.010;
use warnings;
use strict;
use version; our $VERSION = version->new('0.02');

=head1 NAME

TimeTracker - Track time spend on projects from the commandline

=head1 SYNOPSIS

TimeTracker tracks time spend on various projects in simple flat file.

=cut

use base 'Class::Accessor';
use DateTime;
use File::Spec::Functions qw(splitpath catfile catdir);
use TimeTracker::ConfigData;
use File::HomeDir;
use File::Path;
use Getopt::Long;

use Exception::Class(
    'X',
    'X::BadParams' => { isa => 'X' },
    'X::BadData'   => { isa => 'X' },
    'X::File'      => {
        isa    => 'X',
        fields => [qw(file)],
    },
);

__PACKAGE__->mk_accessors(qw(opts _old_data));

=head1 METHODS

=cut

=head3 new

    my $tracker = TimeTracker->new;

Initiate a new tracker object.

=cut

sub new {
    my $class = shift;

    my $self = bless {}, $class;

    $self->opts(
        {
            file =>
              catfile( File::HomeDir->my_home, '.TimeTracker', 'tracker.db' ),
        }
    );

    return $self;
}

=head3 parse_commandline

    $tracker->parse_commandline;

Parses the commandline opts using Getopt::Long. Options are stored in $self->opts.

Returns $self (for method chaining).

=cut

sub parse_commandline {
    my $self = shift;

    my $opts = $self->opts;
    GetOptions( $opts, 'file=s', );
    return $self;
}

=head3 start

    $tracker->start($project,@tags);

Takes project name and a list of tags and adds a new entry to the task 
DB. It sets the start time to the current time.

=cut

sub start {
    my ( $self, $project, $tags ) = @_;
    X::BadParams->throw("No project specified") unless $project;

    # check if we already know this task
    my %known;
    foreach ( @{ $self->old_data } ) {
        next unless $_->[2];
        $known{ $_->[2] }++;
    }
    unless ( $known{$project} ) {
        say "'$project' is not among the current list of projects:";
        say join( "\t", sort keys %known );
        say "add it? (y|n) ";
        my $prompt = <STDIN>;
        chomp($prompt);
        unless ( $prompt =~ /^y/i ) {
            say "Aborting...";
            exit;
        }
    }

    my $now = DateTime->now;

    # stop last active task
    $self->stop($now);

    # start new task
    open( my $out, '>>', $self->path_to_tracker_db )
      || X::File->throw( file => $self->path_to_tracker_db, message => $! );
    print $out $now->epoch
      . "\tACTIVE\t$project\t"
      . ( $tags ? join( ' ', @$tags ) : '' ) . "\t"
      . $now->strftime("%Y-%m-%d %H:%M:%S") . "\n";
    close $out;
}

=head3 stop

    $self->stop($datetime);

Find the last active task and sets the current time as the stop time

$datetime is optional and defaults to DateTime->now

=cut

sub stop {
    my ( $self, $time ) = @_;

    my $old = $self->old_data;
    my $found_active;

    foreach my $row ( reverse @$old ) {
        if ( $row->[1] && $row->[1] eq 'ACTIVE' ) {
            if ($found_active) {
                X::BadData->throw(
                    "more than one ACTIVE task found in file. Fix manually!");
            }
            $found_active++;

            my $now = $time ? $time->epoch : DateTime->now->epoch;
            $row->[1] = $now;

            my $worked = $row->[1] - $row->[0];
            say "worked "
              . $self->beautify_seconds($worked) . " on "
              . $row->[2]
              . ( $row->[3] ? " (" . $row->[3] . ")" : '' );
        }
    }

    # write data
    open( my $out, '>', $self->path_to_tracker_db )
      || X::File->throw( file => $self->path_to_tracker_db, message => $! );
    print $out join( "\n", map { join( "\t", @$_ ) } @$old );
    print $out "\n";
    close $out;
}

=head2 Helper Methods

=cut

=head3 old_data

    my $data=$self->old_data;

Reads in the data from the pseudo DB. Returns an Array of Arrays.

=cut

sub old_data {
    my $self = shift;

    my $old = $self->_old_data;
    return $old if $old;

    my @lines;
    open( my $in, '<', $self->path_to_tracker_db )
      || X::File->throw( file => $self->path_to_tracker_db, message => $! );

    while ( my $line = <$in> ) {
        chomp($line);
        my @row = split( /\t/, $line );
        push( @lines, \@row );
    }
    close $in;

    $self->_old_data( \@lines );
    return \@lines;
}

=head3 path_to_tracker_db

    my $path = $self->path_to_tracker_db;

Returns the absolute path to the tracker DB file.

If the file does not exists, trys to init it using L<init_tracker_db>

=cut

sub path_to_tracker_db {
    my $self = shift;

    my $file = $self->opts->{file};
    return $file if -e $file;
    $self->init_tracker_db($file);
    return $file;

    return catfile( TimeTracker::ConfigData->config('home'), 'tracker.db' );

}

=head3 init_tracker_db

    $self->init_tracker_db( $path_to_file );

Initiates a new pseudo DB file.

=cut

sub init_tracker_db {
    my ( $self, $file ) = @_;
    $file or X::BadParams->throw("No file path passed to init_tracker_db");
    if ( -e $file ) {
        X::File->throw("$file exists. Will not re-init...");
    }

    # do we have the dir?
    my ( $vol, $dir, $filename ) = splitpath($file);
    unless ( -d $dir ) {
        eval { mkpath($dir) };
        X::File->throw( file => $dir, message => "Cannot make dir: $@" ) if $@;
    }

    open( my $OUT, '>', $file )
      || X::File->throw( file => $file, message => $! );
    print $OUT <<EOINITTRACKER;
# Pseudo-DB for TimeTracker
# Do not edit by hand unless you know what you're doing!

EOINITTRACKER
    close $OUT;
}

=head3 beautify_seconds

    my $nice_message = $self->beautify_seconds($seconds);

Turns an amount of seconds ('271') into a nicer representation ("4 minutes, 31 seconds")

=cut

sub beautify_seconds {
    my ( $self, $s ) = @_;

    if ( $s < 60 ) {
        return "$s second" . ( $s == 1 ? '' : 's' );
    }

    my $m = int( $s / 60 );
    $s = $s - ( $m * 60 );
    if ( $m < 60 ) {
        return
            "$m minute"
          . ( $m == 1 ? '' : 's' )
          . ", $s second"
          . ( $s == 1 ? '' : 's' );
    }

    my $h = int( $m / 60 );
    $m = $m - ( $h * 60 );
    return
        "$h hour"
      . ( $h == 1 ? '' : 's' )
      . ", $m minute"
      . ( $m == 1 ? '' : 's' )
      . ", $s second"
      . ( $s == 1 ? '' : 's' );
}

# 1 is boring
q{ listeing to:
    Fat Freddys Drop: Based on a true story
};

__END__

=head1 AUTHOR

Thomas Klausner, C<< <domm at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-timetracker at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=TimeTracker>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc TimeTracker

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/TimeTracker>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/TimeTracker>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=TimeTracker>

=item * Search CPAN

L<http://search.cpan.org/dist/TimeTracker>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2008 Thomas Klausner, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
