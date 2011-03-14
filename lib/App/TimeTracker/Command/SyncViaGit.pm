package App::TimeTracker::Command::SyncViaGit;
use strict;
use warnings;
use 5.010;

# ABSTRACT: TimeTracker SyncViaGit plugin

use Moose::Role;
use Git::Repository;

sub cmd_sync {
    my $self = shift;

    my $r = Git::Repository->new( work_tree => $self->home );

    my @new = $r->run('ls-files' =>'-om');
    foreach my $changed (@new) {
        $r->run(add=>$changed);
    }
    
    $r->run(commit => '-m','synced on '.$self->now);

    foreach my $cmd (qw(pull push)) {
        my $c = $r->command( $cmd );
        print $c->stderr->getlines;
        $c->close;
    }
}

no Moose::Role;
1;

__END__

