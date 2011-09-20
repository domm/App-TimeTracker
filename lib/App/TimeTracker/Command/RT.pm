package App::TimeTracker::Command::RT;
use strict;
use warnings;
use 5.010;

# ABSTRACT: App::TimeTracker RT plugin
use App::TimeTracker::Utils qw(error_message);

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
        error_message("Please configure RT in your TimeTracker config")
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

    try {
        $ticket->comment(message=>$task->user." worked on this ticket for ".$task->rounded_minutes." minutes");
    }
    catch {
        say "Could not add comment about time-worked to ticket: $_";
    };
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

=head1 DESCRIPTION

This plugin takes a lot of hassle out of working with Best Practical's
RequestTracker available for free from
L<http://bestpractical.com/rt/>.

It can set the description and tags of the current task based on data
entered into RT, set the owner of the ticket and update the
time-worked in RT. If you also use the C<Git> plugin, this plugin will
generate very nice branch names based on RT information.

=head1 CONFIGURATION

=over

=item * Add C<RT> to the list of plugins. 

=item * add a hash named C<rt>, containing the following keys:

=over

=item * server [REQUIRED]

The server name RT is running on.

=item * username [REQUIRED]

Username to connect with. As the password of this user might be distributed on a lot of computer, grant as little rights as needed.

=item * password [REQUIRED]

Password to connect with.

=item * timeout

Time in seconds to wait for an connection to be established. Default: 300 seconds (via RT::Client::REST)

=item * set_owner_to

If set, set the owner of the current ticket to the specified value during C<start>.

=item * update_time_worked

If set, store the time worked on this task also in RT.

=back

=back

=head1 NEW COMMANDS

none

=head1 CHANGES TO OTHER COMMANDS

=head2 start, continue

B<New Options>:

=over

=item --rt

    ~/perl/Your-Project$ tracker start --rt 1234

If C<--rt> is set to a valid ticket number:

=over

=item * store the tickets subject in the tasks description ("Rev up FluxCompensator!!")

=item * add the ticket number to the tasks tags ("RT1234")

=item * if C<Git> is also used, determine a save branch name from the ticket number and subject, and change into this branch ("RT1234_rev_up_fluxcompensator")

=item * set the owner of the ticket in RT (if C<set_owner_to> is set in config)

=back

=back

=head2 stop

If <update_time_worked> is set in config, add the time worked on this task to the ticket.

