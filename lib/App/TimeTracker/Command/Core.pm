package App::TimeTracker::Command::Core;
use strict;
use warnings;
use 5.010;

use Moose::Role;
use File::Copy qw(move);
use File::Find::Rule;

sub cmd_start {
    my $self = shift;

    $self->cmd_stop;
    
    my @tags = map { App::TimeTracker::Data::Tag->new(name=>$_) } @{$self->tags};
    my $task = App::TimeTracker::Data::Task->new({
        start=>$self->at || $self->now,
        project=>$self->project,
        tags=>\@tags,
    });

    $task->do_start($self->home);
}

sub cmd_stop {
    my $self = shift;
    
    my $task = App::TimeTracker::Data::Task->current($self->home);
    return unless $task;

    $task->stop($self->at || $self->now);
    $task->save($self->home);
    
    move($self->home->file('current')->stringify,$self->home->file('previous')->stringify);
    
    say "Worked ".$task->duration." on ".$task->say_project_tags;
}

sub cmd_current {
    my $self = shift;
    
    if (my $task = App::TimeTracker::Data::Task->current($self->home)) {
        say "Working ".$task->_calc_duration($self->now)." on ".$task->say_project_tags;
    }
    elsif (my $prev = App::TimeTracker::Data::Task->previous($self->home)) {
        say "Currently not working on anything, but the last thing you worked on was:";
        say $prev->say_project_tags;
    }
    else {
        say "Currently not working on anything, and I have no idea what you worked on earlier...";
    }
}

sub cmd_continue {
    my $self = shift;

    if (my $task = App::TimeTracker::Data::Task->current($self->home)) {
        say "Cannot 'continue', you're working on something:\n".$task->say_project_tags;
    }
    elsif (my $prev = App::TimeTracker::Data::Task->previous($self->home)) {
        my $task = App::TimeTracker::Data::Task->new({
            start=>$self->at || $self->now,
            project=>$prev->project,
            tags=>$prev->tags,
        });
        $task->do_start($self->home);
    }
    else {
        say "Currently not working on anything, and I have no idea what you worked on earlier...";
    }
}

sub cmd_report {
    my $self = shift;

    die "not implemented yet"

    # get all task that match --from, --to (or --this, --last) --project, --tag

    # add their seconds

    # say result (maybe with --detail)
}

sub cmd_worked {
    my $self = shift;

    my @files = $self->find_task_files({
        from=>$self->from,
        to=>$self->to,
        project=>$self->project->name,
    });

    my $total=0;
    foreach my $file ( @files ) {
        my $task = App::TimeTracker::Data::Task->load($file->stringify);
        $total+=$task->seconds;
    }

    say $self->beautify_seconds($total);
}


sub cmd_commands {
    my $self = shift;

    say "Available commands:";
    foreach my $method ($self->meta->get_all_method_names) {
        next unless $method =~ /^cmd_/;
        $method =~ s/^cmd_//;
        say "\t$method";
    }
    exit;
}

no Moose::Role;
1;

__END__

