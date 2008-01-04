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
use File::Spec::Functions qw(splitpath catfile catdir);
use TimeTracker::ConfigData;
use File::HomeDir;
use File::Path;
use Getopt::Long;

use Exception::Class(
    'X',
    'X::BadParams'  => { isa => 'X' },
    'X::BadData'    => { isa => 'X' },
    'X::File' => {
        isa => 'X',
        fields=>[qw(file)],
    },
);

__PACKAGE__->mk_accessors(qw(opts));

=head1 METHODS

=cut

=head3 new

    my $tracker = TimeTracker->new;

Initiate a new tracker object.

=cut

sub new {
    my $class=shift;

    my $self=bless {},$class;

    $self->opts({
        file    => catfile( File::HomeDir->my_home,'.TimeTracker','tracker.db' ),
    });

    return $self;
}

=head3 parse_commandline

    $tracker->parse_commandline;

Parses the commandline opts using Getopt::Long. Options are stored in $self->opts.

Returns $self (for method chaining).

=cut

sub parse_commandline {
    my $self=shift;

    my $opts=$self->opts;
    GetOptions($opts,
        'file=s',
    );
    return $self;
}

=head3 start

    $tracker->start($project,@tags);

Takes project name and a list of tags and adds a new entry to the task 
DB. It sets the start time to the current time.

=cut

sub start {
    my ($self,$project,$tags)=@_;
    X::BadParams->throw("No project specified") unless $project;

    my $now=DateTime->now;
    
    # stop last active task
    $self->stop($now);

    # start new task
    open (my $out, '>>', $self->path_to_tracker_db)
        || X::File->throw(file=>$self->path_to_tracker_db,message=>$!);
    say $out 
        $now->epoch
        ."\tACTIVE\t$project\t"
        .($tags ? join(' ',@$tags) :'')
        ."\t".$now->strftime("%Y-%m-%d %H:%M:%S")
        ;
    close $out;
}

=head3 stop

    $self->stop($datetime);

Find the last active task and sets the current time as the stop time

$datetime is optional and defaults to DateTime->now

=cut

sub stop {
    my ($self,$time)=@_;

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
            
            my $now=$time ? $time->epoch : DateTime->now->epoch;
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

=head2 Helper Methods

=cut

=head3 path_to_tracker_db

    my $path = $self->path_to_tracker_db;

Returns the absolute path to the tracker DB file.

If the file does not exists, trys to init it using L<init_tracker_db>

=cut

sub path_to_tracker_db {
    my $self=shift;

    my $file=$self->opts->{file};
    return $file  if -e $file;
    $self->init_tracker_db($file);
    return $file;

    return catfile(TimeTracker::ConfigData->config( 'home' ),'tracker.db');

}

=head3 init_tracker_db

    $self->init_tracker_db( $path_to_file );

Initiates a new pseudo DB file.

=cut

sub init_tracker_db {
    my ($self,$file)=@_;
    $file or X::BadParams->throw("No file path passed to init_tracker_db");
    if (-e $file) {
        X::File->throw("$file exists. Will not re-init...");
    }

    # do we have the dir?
    my ($vol,$dir,$filename)=splitpath($file);
    unless (-d $dir) {
        eval { mkpath($dir) };
        X::File->throw(file=>$dir,message=>"Cannot make dir: $@") if $@;
    }

    open(my $OUT,'>',$file) || X::File->throw(file=>$file,message=>$!);
    print $OUT <<EOINITTRACKER;
# Pseudo-DB for TimeTracker
# Do not edit by hand unless you know what you're doing!

EOINITTRACKER
    close $OUT;
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
