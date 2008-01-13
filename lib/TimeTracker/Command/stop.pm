package TimeTracker::Command::stop;
use 5.010;
use strict;
use warnings;
use base qw(App::Cmd::Command TimeTracker);

sub usage_desc { "stop %o" }

sub opt_spec { return TimeTracker::global_opts(@_) }

sub validate_args { return TimeTracker::global_validate(@_) }

sub run {
    my ($self, $opt, $args) = @_;

    $self->stop;
}

q{Listening to:
    Massive Attack - Blue Lines
};

