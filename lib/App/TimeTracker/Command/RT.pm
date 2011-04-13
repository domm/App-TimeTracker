package App::TimeTracker::Command::RT;
use strict;
use warnings;
use 5.010;

# ABSTRACT: TimeTracker RT plugin

use Moose::Role;
use RT::Client::REST;

has 'rt' => (is=>'ro',isa=>'TT::RT',coerce=>1,);
has 'rt_client' => (is=>'ro',isa=>'RT::Client::REST',lazy_build=>1);
sub _build_rt_client {
    my $self = shift;
    my $config = $self->config->{rt};
    unless ($config) {
        say "Please configure RT in your TimeTracker config";
        exit;
    }

    my $client = RT::Client::REST->new(
        server  => $config->{server},
        timeout => $config->{timeout},
    );

    $client->login( username => $config->{username}, password => $config->{password} );
    return $client;
}

before 'cmd_start' => sub {
    my $self = shift;
    return unless my $rt = $self->rt;
    my $ticketname='RT'.$rt;

    $self->insert_tag($ticketname);

    if ($self->meta->does_role('App::TimeTracker::Command::Git')) {
        my $ticket=$self->rt_client->show(type => 'ticket', id => $rt);
        my $subject = $ticket->{Subject};
        $subject=~s/\W/_/g;
        $subject=~s/_+/_/g;
        $subject=~s/^_//;
        $subject=~s/_$//;

        $self->branch($ticketname.'_'.$subject) unless $self->branch;
    }
};

after 'cmd_stop' => sub {
    my $self = shift;

    return unless $self->config->{rt}{update_time_worked};

    my $task = $self->_current_task;
    my $ticket_id;
    foreach my $tag (@{$task->tags}) {
        next unless $tag =~ /^RT(\d+)/;
        $ticket_id = $1;
        last;
    }

    unless ($ticket_id) {
        say "No RT ticket id found, cannot update TimeWorked";
        return;
    }

    my $old = $self->rt_client->show(type => 'ticket', id => $ticket_id);
    unless ($old) {
        say "Cannot find ticket $ticket_id in RT";
        return;
    }

    my $worked = $old->{TimeWorked} || 0;
    $worked =~s/\D//g;

    $self->rt_client->edit( type => 'ticket', id => $ticket_id, set=>{
        TimeWorked=> $worked + $task->rounded_minutes
    });
};

no Moose::Role;
1;

__END__

