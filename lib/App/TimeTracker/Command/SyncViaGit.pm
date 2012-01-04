package App::TimeTracker::Command::SyncViaGit;
use strict;
use warnings;
use 5.010;

# ABSTRACT: App::TimeTracker SyncViaGit plugin

use Moose::Role;
use App::TimeTracker::Utils qw(now);
use Git::Repository;

sub cmd_sync {
    my $self = shift;

    my $r = Git::Repository->new( work_tree => $self->home );

    my @new = $r->run('ls-files' =>'-om','--exclude-standard');
    foreach my $changed (@new) {
        say $changed;
        $r->run(add=>$changed);
    }

    my @del = $r->run('ls-files' =>'-d','--exclude-standard');
    foreach my $to_del (@del) {
        say "to del $to_del";
        $r->run(rm=>$to_del);
    }

    $r->run(commit => '-m','synced on '.now());

    foreach my $cmd (qw(pull push)) {
        my $c = $r->command( $cmd );
        print $c->stderr->getlines;
        $c->close;
    }
}

no Moose::Role;
1;

__END__

=head1 DESCRIPTION

This plugin allows you to syncronize your tracker files (living in
F<~/.TimeTracker>) via C<git> to various other computers (eg desktop
machine at work and laptop). All of the complex stuff is done by
C<git>, this plugin is just a telling C<git> what to do (via
L<Git::Repository>).

=head1 CONFIGURATION

=head2 plugins

Add C<SyncViaGit> to the list of plugins. I usually put it into my top-level config file (i.e. F<~/.TimeTracker/tracker.json>).

=head2 other setup

Turn F<~/.TimeTracker> into a git repository and make sure you
can pull/push this repo from all your machines. I do not recommend a
public git hoster, as the information contained in your tracking files
might be rather private.

=head1 NEW COMMANDS

=head2 sync

  ~/somewhere/on/your/disc$ tracker sync
  # some git output

Adds all new tracker files to the git repo, pulls from remote, and
then pushes to remote.

If you get conflicts (which can happen from time to time, especially
if you forget to C<stop>), fix them and call C<tracker sync> again.

=head3 No options

=head1 CHANGES TO OTHER COMMANDS

none.

