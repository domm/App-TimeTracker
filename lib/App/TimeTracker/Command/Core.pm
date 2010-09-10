package App::TimeTracker::Command::Core;
use strict;
use warnings;
use 5.010;

use Moose::Role;

sub cmd_start {
    my $self = shift;

    # stop current task
    $self->cmd_stop;
    
    # start a new one
    my $task = App::TimeTracker::Data::Task->new({
        start=>$self->now,
        project=>$self->project,
    });

    my $saved_to = $task->save($self->home);

    my $fh = $self->home->file('current')->openw;
    say $fh $saved_to;
    close $fh;
}

sub cmd_stop {
    my $self = shift;

    my $task = App::TimeTracker::Data::Task->current($self->home);
    return unless $task;

    $task->stop($self->now);
    $task->save($self->home);
    
    unlink $self->home->file('current')->stringify;

}

no Moose::Role;
1;

__END__

