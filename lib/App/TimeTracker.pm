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

use base qw(Class::Accessor App::Cmd);
use App::TimeTracker::Schema;
use DateTime;
use DateTime::Format::Strptime;
use File::Spec::Functions qw(splitpath catfile catdir);
use File::HomeDir;
use File::Path;
use Getopt::Long;


use Exception::Class(
    'X',
    'X::BadParams' => { isa => 'X' },
    'X::BadData'   => { isa => 'X' },
    'X::BadDate'    => {isa=>'X'},
    'X::File'      => {
        isa    => 'X',
        fields => [qw(file)],
    },
    'X::DB' => {isa=>'X'},
);

__PACKAGE__->mk_accessors(qw(opts _old_data _schema));

=head1 METHODS

=cut

=head3 global_opts

Defines the global option definition

=cut

sub global_opts {
    return (
        [ "start=s",  "start time"],
        [ "stop=s",   "stop time"],
        [ 'file|f=s' => "data file", 
            {default=>catfile( File::HomeDir->my_home, '.TimeTracker', 'timetracker.db' ),} ],
    );
}

=head3 global_validate

Global input validation

=cut

sub global_validate {
    my ($self, $opt, $args) = @_;
    
    if (!-e $opt->{file}) {
        $self->init_tracker_db($opt->{file});
    }

    foreach (qw(start stop)) {
        if (my $manual=$opt->{$_}) {
            $opt->{$_}=$self->parse_datetime($manual);
        }
        else {
            $opt->{$_}=$self->now;
        }
    }
    $self->opts($opt);

}

=head3 new

    my $tracker = App::TimeTracker->new;

Initiate a new tracker object.

Providev by Class::Accessor

=cut

=head3 stop

    $self->stop($datetime);

Find the last active task and sets the current time as the stop time

$datetime is optional and defaults to DateTime->now

=cut

sub stop {
    my ( $self, $time ) = @_;

    my $schema=$self->schema;
    $time ||= $self->opts->{stop};
    
    my $active=$schema->resultset('Task')->find(1,{key=>'active'});
    if ($active) {
        $active->active(0);
        $active->stop($time);
        $active->update;
        my $interval=$self->get_printable_interval($active);
        say "worked $interval";

        if ($self->opts->{svn}) {
            system('svn','ci',$self->opts->{file},'-m "autocommit via TimeTracker"');
        }
    }
}

=head2 Helper Methods

=cut

=head3 get_printable_interval

    my $string = $self->get_printable_interval($task, [$start, stop]);

Returns a string like "worked 30 minutes, 23 seconds on Task (foo bar)"

=cut

sub get_printable_interval {
    my ($self,$task,$start,$stop)=@_;
    $start ||= $task->start;
    $stop ||= $task->stop;
    
    my $worked = $stop - $start;
    my @tags=$task->tags;
    my $tag=@tags? ' ('.join(', ',map {$_->tag} @tags).')':'';
    return $self->beautify_duration($worked) . " on " . $task->project->name . $tag;
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
    eval {require DBI};
    my $dbh=DBI->connect("dbi:SQLite:dbname=".$file);
    my $schema=$self->sql_schema;
    foreach my $statement (split /;/, $schema) {
        next unless $statement=~/\w/;
        say $statement;
        $dbh->do($statement) || X::DB->throw("DB error in $statement: $DBI::errstr");
    }
    $dbh->disconnect;
    
}

=head3 beautify_duration

    my $nice_message = $self->beautify_duration($duration);

Turns an DateTime::Duration object into a nicer representation ("4 minutes, 31 seconds")

=cut

sub beautify_duration {
    my ( $self, $delta ) = @_;

    my $s=$delta->delta_seconds;
    my $m=$delta->delta_minutes;
    return $self->beautify_seconds($s + ($m*60));
}

=head3 beautify_seconds

    my $nice_message = $self->beautify_seconds($seconds);

Turns an amount of seconds into a nicer representation ("4 minutes, 31 seconds")

=cut

sub beautify_seconds {
    my ( $self, $s ) = @_;

    my ($m,$h);

    if ($s>=60) {
        $m=int($s / 60);
        $s=$s - ( $m * 60);
    }
    if ($m && $m>=60) {
        $h = int( $m / 60 );
        $m = $m - ( $h * 60 );
    }
    
    my $result;
    if ($h) {
        $result="$h hour". ( $h == 1 ? '' : 's' ).", ";
    }
    if ($m) {
        $result.="$m minute". ( $m == 1 ? '' : 's' ).", ";
    }
    $result.="$s second". ( $s == 1 ? '' : 's' );
    return $result;
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

=head3 now

    my $now = $self->now;

Wrapper around DateTime->now that also sets the timezone to local

=cut

sub now {
    my $dt=DateTime->now();
    $dt->set_time_zone('local');
    return $dt;
}

=head3 sql_schema

Return the SQLite Schema

=cut

sub sql_schema {
    return <<EOSQL;
create table project (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	name text
);
create unique index project_name on project (name);

create table task (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	project INTEGER not null default 0,
	active INTEGER not null default 1,
    start date,
	stop date
);

create table tag (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
    tag text
);
create unique index tag_tag on tag (tag);

create table task_tag (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
    task integer not null default 0,
    tag integer not null default 0
);

EOSQL
}

=head3 schema

Returns the DBIx::Class schema object

=cut

sub schema {
    my $self=shift;
    return $self->_schema if $self->_schema;
    my $schema=App::TimeTracker::Schema->connect('dbi:SQLite:dbname='.$self->opts->{file}) || X::DB->throw("Cannot connect to SQLite DB ".$self->opts->{file});
    $self->_schema($schema);
    return $schema;
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
