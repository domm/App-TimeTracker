package App::TimeTracker::Command::Post2IRC;
use strict;
use warnings;
use 5.010;

# ABSTRACT: TimeTracker post to irc plugin

use Moose::Role;
use LWP::UserAgent;
use Digest::SHA1 qw(sha1_hex);

has 'irc_quiet' => (is=>'ro',isa=>'Bool',documentation=>'IRC: Do not post to IRC');

after ['cmd_start','cmd_continue'] => sub {
    my $self = shift;
    return if $self->irc_quiet;
    my $task = $self->_current_task;
    $self->_post_to_irc(start => $task);
};

after 'cmd_stop' => sub {
    my $self = shift;
    return if $self->irc_quiet;
    return unless $self->_current_command eq 'cmd_stop';
    my $task = App::TimeTracker::Data::Task->previous($self->home);
    $self->_post_to_irc(stop => $task);
};

sub _post_to_irc {
    my ($self, $status, $task) = @_;
    my $cfg = $self->config->{post2irc};
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

