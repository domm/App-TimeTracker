package App::TimeTracker::Command::TextNotify;
use strict;
use warnings;
use 5.010;

# ABSTRACT: TimeTracker post mac desktop integration plugin

use Moose::Role;

after 'cmd_start' => sub {
    my $self = shift;
    $self->_update_text_notify();
};

after 'cmd_stop' => sub {
    my $self = shift;
    $self->_update_text_notify();
};

after 'cmd_current' => sub {
    my $self = shift;
    $self->_update_text_notify();
};

after 'cmd_continue' => sub {
    my $self = shift;
    $self->_update_text_notify();
};


sub _update_text_notify {
    my $self = shift;
    
    my $notify_file = $self->home->file('current.txt');
    
    if (my $task = App::TimeTracker::Data::Task->current($self->home)) {
        my $fh = $notify_file->openw();
        my $text = $task->project.' since '.$task->start->hms(':');
        
        if ($task->can('rt_id')
            && $task->can('rt_subject')
            && $task->rt_id) {
            $text .= "\nRT" . $task->rt_id. ": ".$task->rt_subject;
        }
        print $fh $text;
        say $text;
        $fh->close;
    } else {
        $notify_file->remove()
            if -e $notify_file;
    }
}


no Moose::Role;
1;

__END__

