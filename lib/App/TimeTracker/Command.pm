package App::TimeTracker::Command;
use 5.010;
use strict;
use warnings;
use App::Cmd::Setup -command;

=head3 opt_spec

Defines the global option definition

Add custom specs by placing them in a method C<_command_opts> in your subclass

=cut

sub opt_spec {
    return (
        [ "start=s",  "start time"],
        [ "stop=s",   "stop time"],
        shift->_command_opts,
    );
}

=head3 global_validate

Global input validation

=cut

sub validate_args {
    my ($self, $opt, $args) = @_;
    
    $self->app->projects(App::TimeTracker::Projects->read($self->storage_location));
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

sub _command_opts { }

1;

