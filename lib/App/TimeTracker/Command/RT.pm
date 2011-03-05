package App::TimeTracker::Command::RT;
use strict;
use warnings;
use 5.010;

use Moose::Role;

has 'rt' => (is=>'ro',isa=>'Int');

before 'cmd_start' => sub {
    my $self = shift;
    return unless $self->rt;

    $self->insert_tag('RT'.$self->rt);

    if ($self->meta->does_role('App::TimeTracker::Command::Git')) {
        $self->branch('RT'.$self->rt) unless $self->branch;
    }
};

no Moose::Role;
1;

__END__

