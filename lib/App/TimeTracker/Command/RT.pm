package App::TimeTracker::Command::RT;
use strict;
use warnings;
use 5.010;

use Moose::Role;

has 'rt' => (is=>'ro',isa=>'Str');

before 'cmd_start' => sub {
    my $self = shift;
    return unless my $rt = $self->rt;
    $rt=~s/\D//g;

    $self->insert_tag('RT'.$self->rt);

    if ($self->meta->does_role('App::TimeTracker::Command::Git')) {
        $self->branch('RT'.$self->rt) unless $self->branch;
    }
};

no Moose::Role;
1;

__END__

