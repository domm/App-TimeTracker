package App::TimeTracker::Command::Git;
use strict;
use warnings;
use 5.010;

use Moose::Role;

around 'cmd_stop' => sub {
    my $orig = shift;
    my $self = shift;
    say "git-stop";
    $self->$orig(@_);
    say "yay";
};

sub cmd_git {
    my $self = shift;
    say "git!!";
}

no Moose::Role;
1;

__END__

