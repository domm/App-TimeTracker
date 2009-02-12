package App::TimeTracker::Command::convert_to_0_20;
use 5.010;
use strict;
use warnings;
use App::TimeTracker -command;
use base qw(App::TimeTracker);
use DBI;
use App::TimeTracker::Projects;
use DateTime::Format::ISO8601;

sub usage_desc { "%c covert_to_0_20" }

sub run {
    my ($self, $opt, $args) = @_;

    my $basedir = $self->app->storage_location;

    my $DBH=DBI->connect('dbi:SQLite:dbname='.$basedir.'/timetracker.db');
    $self->_projects($DBH,$basedir);
   
    my $sth=$DBH->prepare("select task.id as id,start,stop,pr.name from task,project as pr where task.project=pr.id");# AND start > '2009-01-01'");
    $sth->execute;
    while (my $r=$sth->fetchrow_hashref) {
        my $sthtag=$DBH->prepare("select tag.tag from tag,task_tag where task_tag.tag=tag.id AND task_tag.task=?");
        $sthtag->execute($r->{id});
        my @tags;
        while (my ($tag)=$sthtag->fetchrow_array) {
            push(@tags,$tag);
        }
        
        my $task = App::TimeTracker::Task->new({
            start=>_dt($r->{start}),
            project=>$r->{name},
            stop=>_dt($r->{stop}),
            tags=>join(' ',@tags),
            basedir=>$basedir,
        })->write;
    }
}

sub _dt {
    my $date=shift;
    $date=~s/ /T/;
    $date=~s/-//g;
    $date=~s/://g;
    my $dt = DateTime::Format::ISO8601->parse_datetime($date);
    return $dt->epoch;
}

sub _projects {
    my ($self,$DBH,$basedir)=@_;
    my $projects = App::TimeTracker::Projects->read( $basedir);

    my $sth=$DBH->prepare("select name from project");
    $sth->execute;
    while (my ($name)=$sth->fetchrow_array) {
        $name=~s/\s+//g;
        $projects->add($name);
    }
    $projects->write($basedir );
}


q{Listening to:
    Arztwartezimmer
};

__END__

=head1 NAME

App::TimeTracker::Command::convert_to_0_20

=head1 DESCRIPTION

Converts an old (pre version 0.20) TimeTracker sqlite DB into the new 
filebased format.

=head1 METHODS

=head3 usage_desc

Usage Description for Getopt::Long::Descriptive

=head3 run

Implementation of command

=head1 AUTHOR

Thomas Klausner, C<< <domm at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Thomas Klausner, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

