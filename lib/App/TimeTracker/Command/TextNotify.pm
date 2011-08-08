package App::TimeTracker::Command::TextNotify;
use strict;
use warnings;
use 5.010;

# ABSTRACT: App::TimeTracker post mac desktop integration plugin

use Moose::Role;

after ['cmd_start','cmd_stop','cmd_current','cmd_continue'] => sub {
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
            && $task->rt_id) {
            $text .= "\nRT" . $task->rt_id;
            $text .= ": ".$task->description if $task->description;
        }
        elsif (my $desc = $task->description) {
            $text .= $desc
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

