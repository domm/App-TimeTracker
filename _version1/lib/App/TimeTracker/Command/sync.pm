package App::TimeTracker::Command::sync;
use 5.010;
use strict;
use warnings;
use App::TimeTracker -command;
use base qw(App::TimeTracker);

sub usage_desc {"%c sync"}

sub run {
    my ( $self, $opt, $args ) = @_;

    my $v = $opt->{verbose};

    my $has_git = `git --version`;
    ATTX->throw("You need git for sync to work!")
        unless $has_git && $has_git =~ /git version/;

    my $dir = $self->app->storage_location;
    chdir($dir);

    my @new = split( /\n/, `git ls-files -o` );
    foreach (@new) {
        chomp;
        `git add $_`;
    }

    my $msg       = 'synced on ' . scalar localtime();
    my $rv_commit = `git commit -a -m '$msg'`;
    say $rv_commit if $v;

    my $rv_pull = `git pull`;
    say $rv_pull if $v;

    my $rv_push = `git push`;
    say $rv_push if $v;

}

q{Listening to:
    Arztwartezimmer
};

__END__

=head1 NAME

App::TimeTracker::Command::sync - synchronise tasks via git

=head1 DESCRIPTION

Syncs your "database" of tracked time via git. I use this to be able 
to track my worktime on my laptop and my work machine.

C<sync> will first add all your new changes, pull from remote and then 
push.

  ~$ tracker sync
  ... git output ...

=head1 METHODS

=head3 usage_desc

Usage Description for Getopt::Long::Descriptive

=head3 opt_spec

Command line options definition

=head3 run

Implementation of command

=head1 AUTHOR

Thomas Klausner, C<< <domm at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Thomas Klausner, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

