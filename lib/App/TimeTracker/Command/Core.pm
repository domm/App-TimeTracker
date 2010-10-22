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
    my @tags = map { App::TimeTracker::Data::Tag->new(name=>$_) } @{$self->tags};
    
    my $task = App::TimeTracker::Data::Task->new({
        start=>$self->at || $self->now,
        project=>$self->project,
        tags=>\@tags,
    });

    my $saved_to = $task->save($self->home);

    my $fh = $self->home->file('current')->openw;
    say $fh $saved_to;
    close $fh;

    say "Started working on ".$task->say_project_tags ." at ". $task->start->hms;
}

sub cmd_stop {
    my $self = shift;
    
    my $task = App::TimeTracker::Data::Task->current($self->home);
    return unless $task;

    $task->stop($self->at || $self->now);
    $task->save($self->home);
    
    unlink $self->home->file('current')->stringify;
    
    say "Worked ".$task->duration." on ".$task->say_project_tags;
}

sub cmd_current {
    my $self = shift;
    
    my $task = App::TimeTracker::Data::Task->current($self->home);
    return unless $task;

    $task->stop($self->now);
    say "Working ".$task->duration." on ".$task->say_project_tags;
}

no Moose::Role;
1;

__END__

