package TimeTracker::Command::current;
use 5.010;
use strict;
use warnings;
use base qw(App::Cmd::Command TimeTracker);

sub usage_desc { "%c current %o" }

sub opt_spec { return TimeTracker::global_opts(@_) }

sub validate_args { return TimeTracker::global_validate(@_) }

sub run {
    my ($self, $opt, $args) = @_;

    my $old = $self->old_data;
    my $found_active;

    foreach my $row ( reverse @$old ) {
        next if $row->[0]=~/^#/;
        if ( $row->[1] && $row->[1] eq 'ACTIVE' ) {
            my $interval=$self->get_printable_interval($row->[0],$self->now->epoch,$row);
            say "working $interval";
        }
        else {
            say "Currently not working on anything...";
        }
        last;
    }
}

q{Listening to:
    Massive Attack - Blue Lines
};

__END__

=head1 NAME

TimeTracker::Command::current

=head1 DESCRIPTION

Implements the 'current' command, which shows what you're currently 
working on (and for how long)

  ~$ tracker current
  working 14 minutes, 53 seconds on TimeTracker

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

