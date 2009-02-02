package App::TimeTracker;

use 5.010;
use warnings;
use strict;
use version; our $VERSION = version->new('0.20');

=head1 NAME

App::TimeTracker - Track time spend on projects from the commandline

=head1 SYNOPSIS

App::TimeTracker tracks time spend on various projects in a SQLite DB.

see C<perldoc tracker> for a convenient frontend.

=cut

use App::Cmd::Setup -app;
use base qw(Class::Accessor);
use App::TimeTracker::Task;
use App::TimeTracker::Projects;
use App::TimeTracker::Exceptions;
use DateTime;
use DateTime::Format::Strptime;
use File::Spec::Functions qw(splitpath catfile catdir);
use File::HomeDir;
use Getopt::Long;

__PACKAGE__->mk_accessors(qw(opts projects _old_data _schema));

=head1 METHODS

=cut

=head3 new

    my $tracker = App::TimeTracker->new;

Initiate a new tracker object.

Provided by Class::Accessor

=cut

=head2 Helper Methods

=cut

=head3 now

    my $now = $self->now;

Wrapper around DateTime->now that also sets the timezone to local

=cut

sub now {
    my $dt=DateTime->now();
    $dt->set_time_zone('local');
    return $dt;
}

=head3 storage_location

    my $dir = $self->storage_location

Returns the path to the dir containing the stored tasks. Currently hardcoded to File::HomeDir plus F<.TimeTracker>.

=cut

sub storage_location {
    my $self = shift;

    if ($INC{'Test/More.pm'}) {
        return catdir('t/data');
    }
    else {
        return catdir( File::HomeDir->my_home, '.TimeTracker' );
    }
}

=head3 file

    my $path = $self->file( 'path/to/some/file' );
    my $path = $self->file( qw( path to some file) );

Prepends L<storage_location> to the passed file path.

=cut

sub file {
    my $self  = shift;
    return catfile($self->storage_location,@_);
}

=head3 parse_datetime 

    my $dt = $self->parse_datetime("1245");
    my $dt = $self->parse_datetime("0226-1245");

Convert a simple time / datetime into a DateTime object

Input can be a string containing Hour and Minute ("1245"), which will 
use todays date. Or a string containing Month Day followed by Hour & 
Minute (seperated by _ or -)

=cut

sub parse_datetime {
    my ( $self, $datetime ) = @_;
    return $self->now unless $datetime;
    
    my $n=$self->now;

    my $date;
    eval {
        if ( $datetime =~ /^(?<hour>\d\d):?(?<minute>\d\d)$/ ) {
            $date = DateTime->new(
                year=>$n->year,
                month=>$n->month,
                day=>$n->day,
                hour=>$+{hour},
                minute=>$+{minute},
                second=>0,
                time_zone=>'local',
            );
        }
        elsif ($datetime =~ /
            (?<month>\d\d)\.?(?<day>\d\d)
            [-_]
            (?<hour>\d\d):?(?<minute>\d\d)
            /x ) {
            $date = DateTime->new(
                year=>$n->year,
                month=>$+{month},
                day=>$+{day},
                hour=>$+{hour},
                minute=>$+{minute},
                second=>0,
                time_zone=>'local',
            );
        }
    };
    if ($@) {
        X::BadDate->throw("Cannot parse $datetime into a date: $@");
    }
    return $date;
}

=head3 get_from_to 

parse --from and --to, returns strings suitable for L<find_tasks>

=cut

sub get_from_to {
    my ($self, $opt) = @_; 
    
    my ($from, $to);
    if (my $this = $opt->{this}) {
        $from=DateTime->now->truncate(to=>$this);        
        $to=$from->clone->add($this.'s'=>1);
    }
    elsif (my $last = $opt->{last}) {
        $from=DateTime->now->truncate(to=>$last)->subtract($last.'s'=>1);
        $to=$from->clone->add($last.'s'=>1);
    }
    elsif ($opt->{from} && $opt->{to}) {
        $from = DateTime::Format::ISO8601->parse_datetime($opt->{from});
        $to = DateTime::Format::ISO8601->parse_datetime($opt->{to});
    }
    elsif ($opt->{from}) {
        $from = DateTime::Format::ISO8601->parse_datetime($opt->{from});
        $to = $self->app->now;
    }
    elsif ($opt->{to}) {
        $from=$self->app->now->truncate(to=>'year');
        $to = DateTime::Format::ISO8601->parse_datetime($opt->{to});
    }
    else {
        say "You need to specify some date limits!";
        exit;
    }
    return ($from->ymd('').$from->hms(''),$to->ymd('').$to->hms(''));
}

sub find_tasks {
    my ($self,$opt)=@_;
    
    my $project=$opt->{project};
    our ($from_cmp,$to_cmp)=$self->get_from_to($opt);
    
    my @files = File::Find::Rule->file()->name(qr/\.(done|current)$/)->exec(
        sub {
            my ($file) = @_;
            $file=~/(\d{8})-(\d{6})/;
            my $time = $1.$2;
            return 1 if $time >= $from_cmp;
        }
    )->exec(
        sub {
            my ($file) = @_;
            $file=~/(\d{8})-(\d{6})/;
            my $time = $1.$2;
            return 1 if $time <= $to_cmp;
        }
    )->in($self->app->storage_location.'/');
    
    if ($project) {
        @files = grep {/$project/} @files;
    }   

    return \@files;
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
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App::TimeTracker>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::TimeTracker

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App::TimeTracker>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App::TimeTracker>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App::TimeTracker>

=item * Search CPAN

L<http://search.cpan.org/dist/App::TimeTracker>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2008 Thomas Klausner, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
