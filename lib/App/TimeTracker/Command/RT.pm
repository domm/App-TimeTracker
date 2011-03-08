package App::TimeTracker::Command::RT;
use strict;
use warnings;
use 5.010;

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

no Moose::Role;
1;

__END__

