package TimeTracker::Command::worked;
use 5.010;
use strict;
use warnings;
use base qw(App::Cmd::Command TimeTracker);

sub usage_desc { "worked %o task" }

sub opt_spec { return TimeTracker::global_opts(@_) }

sub validate_args { return TimeTracker::global_validate(@_) }

sub run {
    my ($self, $opt, $args) = @_;

    my $project=shift(@$args);
    
    my %sum;
    my $is_active=0;
    foreach my $row (@{ $self->old_data}) {
        if ($project) {
            next unless $row->[2] && $row->[2] eq $project;
        }
        else {
            next unless $row->[2];
        }
        my $tags=$row->[3];
        my $to;
        if ($row->[1] eq 'ACTIVE') {
            $to=$self->now->epoch;
            $is_active=1;
        }
        else {
            $to=$row->[1];
        }   
        
        my $dur=$to - $row->[0];
        $sum{total}+=$dur;
    }
    $project //= "all projects"; 
    say "You're still working on $project at the moment!" if $is_active;
    say "worked ".$self->beautify_seconds($sum{total})." on $project"; 

}

q{Listening to:
    Zahnarztwartezimmergeraeusche
};

__END__

=head1 NAME

TimeTracker::Command::worked

=head1 DESCRIPTION

Implements the 'worked' command, which you can use to query how long you worked on different tasks

  ~$ tracker worked task
  worked 12 hours, 37 minutes, 34 seconds on task

  ~$ tracker worked task --from 0101
  not implemented yet

  ~$ tracker worked task --from 0101 --to 0131
  not implemented yet

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


