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
has 'rt_ticket' => (is=>'ro',isa=>'Maybe[RT::Client::REST::Ticket]',lazy_build=>1);

sub _build_rt_ticket {
    my ($self) = @_;
    
    if (my $ticket = $self->init_rt_ticket($self->_current_task)) {
        return $ticket
    }
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
    
    return unless $self->has_rt;
    
    my $ticket = $self->rt_ticket;
    my $ticketname='RT'.$self->rt;

    $self->insert_tag($ticketname);
    if (defined $ticket) {
        $self->description($ticket->subject);
    }

    if ($self->meta->does_role('App::TimeTracker::Command::Git')) {
        my $branch = $ticketname;

        if ( $ticket ) {
            my $subject = $ticket->subject;
            $subject = NFKD($subject);
            $subject =~ s/\p{NonspacingMark}//g;
            $subject=~s/\W/_/g;
            $subject=~s/_+/_/g;
            $subject=~s/^_//;
            $subject=~s/_$//;
            $branch .= '_'.$subject;
        }
        $self->branch($branch) unless $self->branch;
    }
};

after 'cmd_start' => sub {
    my $self = shift;

    return unless $self->has_rt;

    my $ticket = $self->rt_ticket;

    return
        unless $self->config->{rt}{set_owner_to} && defined $ticket;
    try {
        $ticket->owner($self->config->{rt}{set_owner_to});
        $ticket->status('open');
        $ticket->store();
    }
    catch {
        say $_;    
    };
};

after 'cmd_stop' => sub {
    my $self = shift;

    return 
        unless $self->config->{rt}{update_time_worked};

    my $task = $self->_previous_task;

    return 
        unless $task && $task->rounded_minutes > 0;

    my $ticket = $self->init_rt_ticket($task);
    unless ($ticket) {
        say "Last task did not contain a RT ticket id, not updating TimeWorked.";
        return;
    }

    my $worked = $ticket->time_worked || 0;
    $worked =~s/\D//g;

    $ticket->time_worked( $worked + $task->rounded_minutes );
    $ticket->store;
};

sub init_rt_ticket {
    my ($self, $task) = @_;
    my $id;
    if ($task) {
        $id = $task->rt_id;
    }
    elsif ($self->rt) {
        $id = $self->rt;
    }
    return unless $id;

    my $rt_ticket = RT::Client::REST::Ticket->new(
        rt  => $self->rt_client,
        id  => $id,
    );
    $rt_ticket->retrieve;
    return $rt_ticket;
}

sub App::TimeTracker::Data::Task::rt_id {
    my $self = shift;
    foreach my $tag (@{$self->tags}) {
        next unless $tag =~ /^RT(\d+)/;
        return $1;
    }
}

no Moose::Role;
1;

__END__

