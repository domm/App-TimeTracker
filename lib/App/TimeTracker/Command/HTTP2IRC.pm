package App::TimeTracker::Command::HTTP2IRC;
use strict;
use warnings;
use 5.010;

use Moose::Role;
use LWP::UserAgent;
use Digest::SHA1 qw(sha1_hex);

after 'cmd_start' => sub {
    my $self = shift;
    my $task = App::TimeTracker::Data::Task->current($self->home);
    $self->_post_to_irc(start => $task);
};

after 'cmd_stop' => sub {
    my $self = shift;
    return unless $self->_current_command eq 'cmd_stop';
    my $task = App::TimeTracker::Data::Task->previous($self->home);
    $self->_post_to_irc(stop => $task);
};

sub _post_to_irc {
    my ($self, $status, $task) = @_;
    my $cfg = $self->config->{http2irc};
    return unless $cfg;

    my $ua = LWP::UserAgent->new;
    my $message = $task->user 
        . ( $status eq 'start' ? ' is now' : ' stopped' ) 
        . ' working on '
        . $task->say_project_tags;
    my $token = sha1_hex($message, $cfg->{secret});
    my $res = $ua->get($cfg->{host}.'?message='.$message.'&token='.$token);
    unless ($res->is_success) {
        say "Could not post to IRC...";
    }
}

no Moose::Role;
1;

__END__

