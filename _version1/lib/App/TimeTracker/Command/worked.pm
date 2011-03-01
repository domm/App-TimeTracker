package App::TimeTracker::Command::worked;
use 5.010;
use strict;
use warnings;
use App::TimeTracker -command;
use base qw(App::TimeTracker);
use DateTime;
use DateTime::Format::ISO8601;
use File::Find::Rule;

sub usage_desc {"worked %o task"}

sub opt_spec {
    return shift->opt_spec_reports;
}

sub run {
    my ( $self, $opt, $args ) = @_;

    my $project = $opt->{project};
    my $tag     = $opt->{tag};
    my $tasks   = $self->find_tasks($opt);

    my $total;
    my $still_active = 0;
    foreach my $file ( sort @$tasks ) {
        my $task = App::TimeTracker::Task->read($file);

        if ($tag) {
            next unless $task->tags =~ /$tag/;
        }
        $still_active = $task->is_active;

        $total
            += (
            $task->is_active ? $self->app->now->epoch : $task->stop->epoch )
            - $task->start->epoch;
        say join( " ", $task->project, $task->start, $task->stop, $total )
            if $opt->{verbose};
    }

    my $project_out = ( $project ? $project : 'all projects' )
        . ( $tag ? " ($tag)" : '' );
    if ($total) {
        say "You're still working on $project_out at the moment!"
            if $still_active;
        say "worked "
            . App::TimeTracker::Task->beautify_seconds($total)
            . " on $project_out";
    }
    else {
        say "Did not work on $project_out";
    }
}

q{Listening to:
    Zahnarztwartezimmergeraeusche
};

__END__

=head1 NAME

App::TimeTracker::Command::worked - calculate total worked time per task

=head1 DESCRIPTION

Implements the 'worked' command, which you can use to query how long you worked on different tasks

  ~$ tracker worked task
  worked 12 hours, 37 minutes, 34 seconds on task

  ~$ tracker worked task --from 0101

  ~$ tracker worked task --from 0101 --to 0131
  
  ~$ tracker worked task --this week
  
  ~$ tracker worked task --last month


=head1 METHODS

=head3 usage_desc

Usage Description for Getopt::Long::Descriptive

=head3 opt_spec

Command line options definition

=head3 validate_args

Command line options validation

=head3 run

Implementation of command

=head1 AUTHOR

Thomas Klausner, C<< <domm at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Thomas Klausner, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


