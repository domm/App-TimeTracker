package TimeTracker::Command::start;
use 5.010;
use strict;
use warnings;
use base qw(App::Cmd::Command TimeTracker);

sub usage_desc { "%c start %o task [tags]" }

sub opt_spec { return TimeTracker::global_opts(@_) }

sub validate_args { return TimeTracker::global_validate(@_) }

sub run {
    my ($self, $opt, $args) = @_;

    my $project=shift(@$args);
    X::BadParams->throw("No project specified") unless $project;
    
    # check if we already know this task
    my %known;
    foreach ( @{ $self->old_data } ) {
        next unless $_->[2];
        $known{ $_->[2] }++;
    }
    unless ( $known{$project} ) {
        say "'$project' is not among the current list of projects:";
        say join( "\t", sort keys %known );
        say "add it? (y|n) ";
        my $prompt = <STDIN>;
        chomp($prompt);
        unless ( $prompt =~ /^y/i ) {
            say "Aborting...";
            exit;
        }
    }

    # stop last active task
    $self->stop($self->now);

    my $start=$opt->{start};

    # start new task
    open( my $out, '>>', $opt->{file} )
      || X::File->throw( file => $self->{file}, message => $! );
    print $out $start->epoch
      . "\tACTIVE\t$project\t"
      . ( $args ? join( ' ', @$args ) : '' ) . "\t"
      . $start->strftime("%Y-%m-%d %H:%M:%S") . "\n";
    close $out;
}

q{Listening to:
    Neigungsgruppe Sex Gewalt & gute Laune - Goodnight Vienna
};

__END__

=head1 NAME

TimeTracker::Command::start

=head1 DESCRIPTION

Implements the 'start' command, which tells TimeTracker that you're 
starting to work on something.

  ~$ tracker start task tag, another tag

  ~$ tracker start --start 1000 task tag, another tag

=head1 METHODS

=head3 usage_desc

Usage Description for Getopt::Long::Descriptive

=head3 opt_spec

Command line options definition

=head3 validate_args

Command line options validation

=head3 run

Implementation of command

=head1 AUTHOR

Thomas Klausner, C<< <domm at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Thomas Klausner, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

