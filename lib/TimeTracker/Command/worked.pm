package TimeTracker::Command::worked;
use 5.010;
use strict;
use warnings;
use base qw(App::Cmd::Command TimeTracker);

sub usage_desc { "worked %o task" }

sub opt_spec { return TimeTracker::global_opts(@_) }

sub validate_args { return TimeTracker::global_validate(@_) }

sub run {
    my ($self, $opt, $args) = @_;

    my $project_name=shift(@$args);
    my $project=$self->schema->resultset('Project')->find($project_name,{key=>'name'});


    my $col=$self->schema->resultset('Task')->search(
        {
            'project.name'=>$project_name,
            'active'=>0,
        },
        {
            join=>['project'],
            select=>[{sum=>"strftime('%s',stop) - strftime('%s',start)"}],
            as=>['duration'],
        }
    );
    my $sum=$col->first->get_column('duration');

    if (my $active=$self->schema->resultset('Task')->search(
        {
            'project.name'=>$project_name,
            'active'=>1,
        }, {
            join=>['project'],
            select=>[\"strftime('%s',start)"],
            as=>['start_epoch'],
            }
    )->first) {
        my $start=$active->get_column('start_epoch'); 
        my $stop=$self->now->epoch;
        my $diff=$stop-$start;
        $sum+=$diff;
        say "You're still working on $project_name at the moment!";
    }


    if ($sum) {
        say "worked ".$self->beautify_seconds($sum)." on $project_name"; 
    }
    else {
        say "didn't work on $project_name at all!";

    }
}

q{Listening to:
    Zahnarztwartezimmergeraeusche
};

__END__

=head1 NAME

TimeTracker::Command::worked

=head1 DESCRIPTION

Implements the 'worked' command, which you can use to query how long you worked on different tasks

  ~$ tracker worked task
  worked 12 hours, 37 minutes, 34 seconds on task

  ~$ tracker worked task --from 0101
  not implemented yet

  ~$ tracker worked task --from 0101 --to 0131
  not implemented yet

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


