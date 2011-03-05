package App::TimeTracker::Command::RT;
use strict;
use warnings;
use 5.010;

use Moose::Role;
use RT::Client::REST;

has 'rt' => (is=>'ro',isa=>'Str');
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
    return unless my $rt_id = $self->rt;
    $rt_id=~s/\D//g;
    my $ticketname='RT'.$rt_id;

    $self->insert_tag($ticketname);

    if ($self->meta->does_role('App::TimeTracker::Command::Git')) {
        my $ticket=$self->rt_client->show(type => 'ticket', id => $rt_id);
        my $subject = $ticket->{Subject};
        $subject=~s/\W/_/g;
        $subject=~s/_+/_/g;
        $subject=~s/^_//;
        $subject=~s/_$//;

        $self->branch($ticketname.'_'.$subject) unless $self->branch;
    }
};

no Moose::Role;
1;

__END__

