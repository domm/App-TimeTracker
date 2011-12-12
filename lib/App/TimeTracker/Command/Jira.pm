package App::TimeTracker::Command::Jira;
use strict;
use warnings;
use 5.010;

# ABSTRACT: App::TimeTracker Jira plugin
use App::TimeTracker::Utils qw(error_message);

use Moose::Role;
use JIRA::Client;
use Try::Tiny;
use Unicode::Normalize;


has 'jira' => (
    is=>'rw',
    isa=>'TT::Jira',
    #coerce=>1,
    documentation=>'Jira: Ticket key',
    predicate => 'has_jira'
);
has 'jira_client' => (
    is=>'ro',
    isa=>'JIRA::Client',
    lazy_build=>1,
    traits => [ 'NoGetopt' ],
);
has 'jira_ticket' => (
    is=>'ro',
    # this object's type is RemoteIssue in the SOAP WSDL
    # but it's just a hash from perl's perspective
    #isa=>'Maybe[RT::Client::REST::Ticket]',
    # so use this?:
    #isa=>'Maybe[HashRef]',
    lazy_build=>1,
    traits => [ 'NoGetopt' ],
);

sub _build_jira_ticket {
    my ($self) = @_;
    
    if (my $ticket = $self->init_jira_ticket($self->_current_task)) {
        return $ticket
    }
}

sub _build_jira_client {
    my $self = shift;
    my $config = $self->config->{jira};
    
    unless ($config) {
        error_message("Please configure Jira in your TimeTracker config");
        exit;
    }

    my $jira = JIRA::Client->new(
        $config->{server},
        $config->{username},
        $config->{password}
    );
    
    return $jira;
}

before ['cmd_start','cmd_continue'] => sub {
    my $self = shift;
    
    return unless $self->has_jira;
    
    my $ticket = $self->jira_ticket;

    $self->insert_tag($self->jira);
    if (defined $ticket) {
        $self->description($ticket->{summary});
    }

# the RT module also checks if we're using the Git module:
#    if ($self->meta->does_role('App::TimeTracker::Command::Git')) {
#        my $branch = $ticketname;
#
#        if ( $ticket ) {
#            my $subject = $ticket->subject;
#            $subject = NFKD($subject);
#            $subject =~ s/\p{NonspacingMark}//g;
#            $subject=~s/\W/_/g;
#            $subject=~s/_+/_/g;
#            $subject=~s/^_//;
#            $subject=~s/_$//;
#            $branch .= '_'.$subject;
#        }
#        $self->branch($branch) unless $self->branch;
#    }
};

after 'cmd_start' => sub {
    my $self = shift;

    return unless $self->has_jira;

    my $ticket = $self->jira_ticket;

    return
        unless $self->config->{jira}{set_owner_to} && defined $ticket;
    try {
        $self->jira_client->update_issue(
            $ticket, 
            {
                assignee => $self->config->{jira}{set_owner_to},
                status => 'open',
            },
        );
    }
    catch {
        error_message('Could not set Jira owner and status: %s',$_);
    };
};

after 'cmd_stop' => sub {
    my $self = shift;

    return unless $self->jira_client;
    
    return unless $self->config->{jira}{update_time_worked};

    my $task = $self->_previous_task;

    return 
        unless $task && $task->rounded_minutes > 0;

    my $ticket = $self->init_jira_ticket($task);
    unless ($ticket) {
        say "Last task did not contain a Jira ticket id, not updating TimeWorked.";
        return;
    }

    # get the start date/time for the task and use it when logging work in jra
    # strftime: %z is -dddd we want -dd:dd, so handle that first 
    my $date = $task->start;
    $date->set_time_zone(DateTime::TimeZone->new(name => 'local'))
        if $self->config->{jira}{use_local_time_zone};
    $date->strftime("%z") =~ /^(.*)(\d\d)$/;
    my $date_string = $date->strftime("%Y-%m-%dT%H:%M:%S$1:$2");

    $self->jira_client->addWorklogAndAutoAdjustRemainingEstimate($ticket->{key}, {
        timeSpent => $task->rounded_minutes, # default is minutes for timeSpent
        startDate => SOAP::Data->type(dateTime => $date_string),
        # might add a command line arg for comments at some point
        #comment => '',
    });
};

sub init_jira_ticket {
    my ($self, $task) = @_;
    my $id;
    
    if ($task) {
        $id = $task->jira_id;
    }
    elsif ($self->jira) {
        $id = $self->jira;
    }
    return unless $id;

    return $self->jira_client->getIssue($id);
}

sub App::TimeTracker::Data::Task::jira_id {
    my $self = shift;
    # find/return the Jira ID tag (there might be multiple tags)
    foreach my $tag (@{$self->tags}) {
        next unless $tag =~ /^((.+)-(\d+))$/;
        return $1;
    }
}

no Moose::Role;
1;



=pod

=head1 NAME

App::TimeTracker::Command::Jira - App::TimeTracker Jira plugin

=head1 VERSION

version 1.0

=head1 DESCRIPTION

Modeled on the RT TimeTracker plugin, but for Atlassian's Jira
L<http://http://www.atlassian.com/software/jira/>

It can set the description and tags of the current task based on data
entered into Jira, set the owner of the ticket and update the
time-worked.

=head1 CONFIGURATION

=head2 plugins

Add C<Jira> to the list of plugins. 

=head2 rt

add a hash named C<jira>, containing the following keys:

=head3 server [REQUIRED]

The server name Jira is running on.

=head3 username [REQUIRED]

Username to connect with.

=head3 password [REQUIRED]

Password to connect with.

=head3 set_owner_to

If set, set the owner of the current ticket to the specified value during C<start>.

=head3 update_time_worked

If set, store the time worked on this task also in Jira.

=head1 NEW COMMANDS

none

=head1 CHANGES TO OTHER COMMANDS

=head2 start, continue

=head3 --jira

    ~/perl/Your-Project$ tracker start --jira TEST-23

If C<--jira> is set to a valid ticket number:

=over

=item * store the tickets subject in the tasks description ("Rev up FluxCompensator!!")

=item * add the ticket number to the tasks tags ("TEST-23")

=item * set the owner of the ticket in Jira (if C<set_owner_to> is set in config)

=back

=head2 stop

If <update_time_worked> is set in config, add the time worked on this task to the ticket.

=head1 AUTHOR

Andrew Nierman <nierman@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Andrew Nierman.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__
