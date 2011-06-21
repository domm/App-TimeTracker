package App::TimeTracker::Command::RT;
use strict;
use warnings;
use 5.010;

# ABSTRACT: TimeTracker RT plugin

use Moose::Role;
use RT::Client::REST;
use RT::Client::REST::Ticket;
use Try::Tiny;
use Unicode::Normalize;

has 'rt' => (is=>'rw',isa=>'TT::RT',coerce=>1,documentation=>'RT: Ticket number', predicate => 'has_rt');
has 'rt_client' => (is=>'ro',isa=>'RT::Client::REST',lazy_build=>1);
has 'rt_ticket' => (is=>'ro',isa=>'RT::Client::REST::Ticket',lazy_build=>1);

sub _build_rt_ticket {
    my ($self) = @_;
    
    my $task = $self->_current_task;

    if (defined $task
        && defined $task->rt_id
        && ! $self->has_rt) {
        $self->rt($task->rt_id);
    }

    return
        unless $self->has_rt;
    
    my $rt_ticket = RT::Client::REST::Ticket->new(
        rt  => $self->rt_client,
        id  => $self->rt,
    );
    $rt_ticket->retrieve;
    return $rt_ticket;
}

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

before ['cmd_start','cmd_continue'] => sub {
    my $self = shift;
    
    return
        unless $self->has_rt;
    
    my $ticketname='RT'.$self->rt;

    $self->insert_tag($ticketname);
    $self->add_tag('RT: '.$self->rt_ticket->subject);

    if ($self->meta->does_role('App::TimeTracker::Command::Git')) {
        my $ticket= $self->rt_ticket;
        my $subject = $ticket->subject;
        $subject = NFKD($subject);
        $subject =~ s/\p{NonspacingMark}//g;
        $subject=~s/\W/_/g;
        $subject=~s/_+/_/g;
        $subject=~s/^_//;
        $subject=~s/_$//;
        $self->branch($ticketname.'_'.$subject) 
            unless $self->branch;
    }
};

after 'cmd_start' => sub {
    my $self = shift;
    
    return 
        unless $self->config->{rt}{set_owner_to};

    my $task = $self->_current_task;
    return unless $task;
    
    my $ticket_id = $task->rt_id;
    unless ($ticket_id) {
        return;
    }

    try {
        $self->rt_ticket->owner($self->config->{rt}{set_owner_to});
        $self->rt_ticket->status('open');
        $self->rt_ticket->store();
    }
    catch {
        say $_;    
    };
};

after 'cmd_stop' => sub {
    my $self = shift;

    return 
        unless $self->config->{rt}{update_time_worked};

    my $task = $self->_current_task;

    return 
        unless $task && $task->rounded_minutes > 0;

    my $ticket_id = $task->rt_id;
    unless ($ticket_id) {
        say "No RT ticket id found, cannot update TimeWorked";
        return;
    }
    
    unless ($self->rt_ticket) {
        say "Cannot find ticket $ticket_id in RT";
        return;
    }
    
    
    my $worked = $self->rt_ticket->time_worked || 0;
    $worked =~s/\D//g;
    
    $self->rt_ticket->time_worked( $worked + $task->rounded_minutes );
    $self->rt_ticket->store;
};

sub App::TimeTracker::Data::Task::rt_id {
    my $self = shift;
    foreach my $tag (@{$self->tags}) {
        next unless $tag =~ /^RT(\d+)/;
        return $1;
    }
}

sub App::TimeTracker::Data::Task::rt_subject {
    my $self = shift;
    foreach my $tag (@{$self->tags}) {
        next unless $tag =~ /^RT: (.+)/;
        return $1;
    }
}

no Moose::Role;
1;

__END__

