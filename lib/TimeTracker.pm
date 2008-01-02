package TimeTracker;

use 5.010;
use warnings;
use strict;
use version; our $VERSION=version->new('0.01');

=head1 NAME

TimeTracker - Track time spend on projects from the commandline

=head1 SYNOPSIS

TimeTracker tracks time spend on various projects in simple flat file.

=cut

use base 'Class::Accessor';
use DateTime;
use File::Spec::Functions;
use TimeTracker::ConfigData;

use Exception::Class(
    'X',
    'X::BadParams'  => { isa => 'X' },
    'X::BadData'    => { isa => 'X' },
    'X::File' => {
        isa => 'X',
        fields=>[qw(file)],
    },
);

__PACKAGE__->mk_accessors(qw());

=head1 METHODS

=cut

=head3 new

    my $tracker = TimeTracker->new;

Initiate a new tracker object.

=cut

sub new {
    my $class=shift;

    my $self=bless {},$class;

    return $self;
}

=head3 start

    $tracker->start(@tags);

Takes a list of tags and adds a new entry to the task DB. It sets the 
start time to the current time.

=cut

sub start {
    my ($self,$tags)=@_;
    X::BadParams->throw("No tags specified") unless $tags;


    # stop last active task
    $self->stop();

    # start new task
    my $now=DateTime->now->epoch;
    open (my $out, '>>', $self->path_to_tracker_db)
        || X::File->throw(file=>$self->path_to_tracker_db,message=>$!);
    say $out "$now\tACTIVE\t".join(';',@$tags);
    close $out;
}

=head3 stop

    $self->stop();

Find the last active task and sets the current time as the stop time

=cut

sub stop {
    my $self=shift;

    my @new;
    my $found_active;
    open (my $in, '<', $self->path_to_tracker_db)
        || X::File->throw(file=>$self->path_to_tracker_db,message=>$!); 
    my @reversed=reverse <$in>;
    close $in;

    foreach my $line (@reversed) {
        if ($line =~/ACTIVE/) {
            if ($found_active) {
                X::BadData->throw("more than one ACTIVE task found in file. Fix manually!");
            }
            $found_active++;
            my $now=DateTime->now->epoch;
            $line=~s/ACTIVE/$now/;
        }
        push(@new,$line);    
    }

    # write data
    open (my $out, '>', $self->path_to_tracker_db)
        || X::File->throw(file=>$self->path_to_tracker_db,message=>$!);
    print $out reverse @new;
    close $out;
}

=head3 read_tdb

=cut

=head3 add_task

    $tracker->add_task 

=cut

=head2 Helper Methods

=cut

=head3 path_to_tracker_db

    my $path = $self->path_to_tracker_db;

Returns the absolute path to the tracker DB file.

=cut

sub path_to_tracker_db {
    my $self=shift;
    return catfile(TimeTracker::ConfigData->config( 'home' ),'tracker.db');

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
