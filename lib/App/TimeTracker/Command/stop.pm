package App::TimeTracker::Command::stop;
use 5.010;
use strict;
use warnings;
use base qw(App::Cmd::Command App::TimeTracker);

sub usage_desc { "%c stop %o" }

sub opt_spec { 
    my @args=App::TimeTracker::global_opts(@_);
    push(@args,['svn'=>'enable svn autocommit after stop']);
    return @args;
}

sub validate_args { App::TimeTracker::global_validate(@_) }

sub run {
    my ($self, $opt, $args) = @_;

    $self->stop;
}

q{Listening to:
    Massive Attack - Blue Lines
};

__END__

=head1 NAME

App::TimeTracker::Command::stop - stop a task

=head1 DESCRIPTION

Implements the 'stop' command, which tells App::TimeTracker that you've 
stopped working on the current task

  ~$ tracker stop task
  worked 14 minutes, 53 seconds on App::TimeTracker

  ~$ tracker stop --stop 1000

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

