package App::TimeTracker::Command::start;
use 5.010;
use strict;
use warnings;
use base qw(App::Cmd::Command App::TimeTracker);

sub usage_desc { "%c start %o task [tags]" }

sub validate_args { return App::TimeTracker::global_validate(@_) }

sub run {
    my ($self, $opt, $args) = @_;

    my $project=shift(@$args);
    X::BadParams->throw("No project specified") unless $project;

    # check if we already know this task
    unless ($self->app->projects->list->{$project}) {
        say "'$project' is not among the current list of projects, add it? (y|n) ";
        my $prompt = <STDIN>;
        chomp($prompt);
        unless ( $prompt =~ /^y/i ) {
            say "Aborting...";
            exit;
        }
       
        $self->app->projects->add($project)->write($self->app->storage_location);
    }
    
    # stop last active task
    App::TimeTracker::Task->stop_current($self->app->storage_location,$opt->{start} || $self->now);

    # start new task
    my $task = App::TimeTracker::Task->new({
        start=>$opt->{start}->epoch,
        project=>$project,
        tags=>join(' ',@$args),
        basedir=>$self->app->storage_location,
    })->set_current->write;
}

q{Listening to:
    Neigungsgruppe Sex Gewalt & gute Laune - Goodnight Vienna
};

__END__

=head1 NAME

App::TimeTracker::Command::start - start a new task

=head1 DESCRIPTION

Implements the 'start' command, which tells App::TimeTracker that you're 
starting to work on something.

  ~$ tracker start task tag, another tag

  ~$ tracker start --start 1000 task tag, another tag

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

