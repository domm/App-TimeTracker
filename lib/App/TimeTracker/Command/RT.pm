package App::TimeTracker::Command::RT;
use strict;
use warnings;
use 5.010;

# ABSTRACT: App::TimeTracker RT plugin
use App::TimeTracker::Utils qw(error_message warning_message);

use Moose::Role;
use RT::Client::REST;
use RT::Client::REST::Ticket;
use Try::Tiny;
use Unicode::Normalize;

has 'rt' => (
    is=>'rw',
    isa=>'TT::RT',
    coerce=>1,
    documentation=>'RT: Ticket number',
    predicate => 'has_rt'
);
has 'rt_client' => (
    is=>'ro',
    isa=>'Maybe[RT::Client::REST]',
    lazy_build=>1,
    traits => [ 'NoGetopt' ],
    predicate => 'has_rt_client'
);
has 'rt_ticket' => (
    is=>'ro',
    isa=>'Maybe[RT::Client::REST::Ticket]',
    lazy_build=>1,
    traits => [ 'NoGetopt' ],
);

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
        error_message("Please configure RT in your TimeTracker config");
        return;
    }

    return try {
        my $client = RT::Client::REST->new(
            server  => $config->{server},
            timeout => $config->{timeout},
        );
        $client->login( username => $config->{username}, password => $config->{password} );
        return $client;
    }
    catch {
        error_message("Could not log in to RT: $_");
        return;
    };
}

before ['cmd_start','cmd_continue','cmd_append'] => sub {
    my $self = shift;
    return unless $self->has_rt;

    my $ticketname='RT'.$self->rt;
    $self->insert_tag($ticketname);

    my $ticket;
    if ($self->rt_client) {
        $ticket = $self->rt_ticket;
        if (defined $ticket) {
            if ( defined $self->description ) {
                $self->description(sprintf('%s (%s)', $self->description, $ticket->subject));
            }
            else {
                $self->description($ticket->subject);
            }
        }
    }

    if ($self->meta->does_role('App::TimeTracker::Command::Git')) {
        my $branch = $ticketname;
        if ( $ticket ) {
            my $subject = $self->safe_ticket_subject($ticket->subject);
            $branch .= '_'.$subject;
        }
        $self->branch($branch) unless $self->branch;
    }
};

after ['cmd_start','cmd_continue','cmd_append'] => sub {
    my $self = shift;
    return unless $self->has_rt && $self->rt_client;

    my $ticket = $self->rt_ticket;

    return unless $ticket;
    try {
        my $do_store=0;
        if ( $self->config->{rt}{set_owner_to} ) {
            if ( $ticket->owner() ne 'Nobody' and $ticket->owner() ne $self->config->{rt}{set_owner_to} ) {
                warning_message( 'Will not steal tickets, please do that via RT Web-UI' );
                return;
            }
            $ticket->owner($self->config->{rt}{set_owner_to});
            $do_store=1;
        }

        my $status = $self->config->{rt}{set_status}{start};
        if ( $status and $status ne $ticket->status ) {
            $ticket->status($status);
            $do_store=1;
        }
        $ticket->store() if $do_store;
    }
    catch {
        error_message('Could not set RT owner/status: %s',$_);
    };
};

after 'cmd_stop' => sub {
    my $self = shift;
    return unless $self->rt_client;

    my $task = $self->_previous_task;
    return unless $task;
    my $task_rounded_minutes = $task->rounded_minutes;
    return unless $task_rounded_minutes > 0;

    my $ticket = $self->init_rt_ticket($task);
    if ( not $ticket ) {
        say "Last task did not contain a RT ticket id, not updating TimeWorked or Status.";
        return;
    }

    my $do_store=0;
    if ( $self->config->{rt}{update_time_worked} and $task_rounded_minutes ) {

        my $worked = $ticket->time_worked || 0;
        $worked =~s/\D//g; # RT stores in minutes, API give back a string like "x minutes"

        $ticket->time_worked( $worked + $task_rounded_minutes );
        $do_store=1;
    }

    if ( $self->config->{rt}{update_time_left} and $ticket->time_left ) {
        my $time_left = $ticket->time_left;
        $time_left =~s/\D//g; # RT stores in minutes, API give back a string like "x minutes"
        
        $ticket->time_left( $time_left - $task_rounded_minutes );
        $do_store=1;
    }

    if ( my $status = $self->config->{rt}{set_status}{stop} ) {
        $ticket->status($status);
        $do_store=1;
    }
    return unless $do_store;

    try {
        $ticket->store;
    }
    catch {
        error_message('Could not update ticket: %s',$_);
    };
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

sub safe_ticket_subject {
    my ($self, $subject) = @_;

    $subject = NFKD($subject);
    $subject =~ s/\p{NonspacingMark}//g;
    $subject=~s/\W/_/g;
    $subject=~s/_+/_/g;
    $subject=~s/^_//;
    $subject=~s/_$//;
    return $subject;
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
time-worked as well as time-left in RT. If you also use the C<Git> plugin, this plugin will
generate very nice branch names based on RT information.

=head1 CONFIGURATION

=head2 plugins

Add C<RT> to the list of plugins. 

=head2 rt

add a hash named C<rt>, containing the following keys:

=head3 server [REQUIRED]

The server name RT is running on.

=head3 username [REQUIRED]

Username to connect with. As the password of this user might be distributed on a lot of computer, grant as little rights as needed.

=head3 password [REQUIRED]

Password to connect with.

=head3 timeout

Time in seconds to wait for an connection to be established. Default: 300 seconds (via RT::Client::REST)

=head3 set_owner_to

If set, set the owner of the current ticket to the specified value during C<start> and/or C<stop>.

=head3 update_time_worked

If set, updates the time worked on this task also in RT.

=head3 update_time_left

If set, updates the time left property on this task also in RT using the time worked tracker value.

=head1 NEW COMMANDS

none

=head1 CHANGES TO OTHER COMMANDS

=head2 start, continue

=head3 --rt

    ~/perl/Your-Project$ tracker start --rt 1234

If C<--rt> is set to a valid ticket number:

=over

=item * set or append the ticket subject in the task description ("Rev up FluxCompensator!!")

=item * add the ticket number to the tasks tags ("RT1234")

=item * if C<Git> is also used, determine a save branch name from the ticket number and subject, and change into this branch ("RT1234_rev_up_fluxcompensator")

=item * set the owner of the ticket in RT (if C<set_owner_to> is set in config)

=item * updates the status of the ticket in RT (if C<set_status/start> is set in config)

=back

=head2 stop

If <update_time_worked> is set in config, adds the time worked on this task to the ticket.
If <update_time_left> is set in config, reduces the time left on this task to the ticket.
If <set_status/stop> is set in config, updates the status of the ticket

