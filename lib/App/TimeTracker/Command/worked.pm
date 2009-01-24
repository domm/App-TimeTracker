package App::TimeTracker::Command::worked;
use 5.010;
use strict;
use warnings;
use App::TimeTracker -command;
use base qw(App::TimeTracker);
use DateTime;
use DateTime::Format::ISO8601;
sub usage_desc { "worked %o task" }

sub opt_spec {
    return (
        ['from=s'   => 'report start date/time'],
        ['to=s'     => 'report stop date/time'],
        ['this=s'   => 'report in this week/month/year'],
        ['last=s'   => 'report in last week/month/year'],
    );
}

sub run {
    my ($self, $opt, $args) = @_;

    my $project=shift(@$args);
    my $tag_name=shift(@$args);

    my ($from, $to);
    if (my $this = $opt->{this}) {
        $from=DateTime->now->truncate(to=>$this);        
        $to=$from->clone->add($this.'s'=>1);
    }
    elsif (my $last = $opt->{last}) {
        $from=DateTime->now->truncate(to=>$last)->subtract($last.'s'=>1);
        $to=$from->clone->add($last.'s'=>1);
    }
    elsif ($opt->{from} && $opt->{to}) {
        $from = DateTime::Format::ISO8601->parse_datetime($opt->{from});
        $to = DateTime::Format::ISO8601->parse_datetime($opt->{to});
    }
    elsif ($opt->{from}) {
        $from = DateTime::Format::ISO8601->parse_datetime($opt->{from});
        $to = $self->app->now;
    }
    elsif ($opt->{to}) {
        $from=$self->app->now->truncate(to=>'year');
        $to = DateTime::Format::ISO8601->parse_datetime($opt->{to});
    }
    
    say $from .' - '. $to;

    

=pod
    if ($current_sum) {
        say "You're still working on $project_name $tag_name at the moment!";
        $sum+=$current_sum;
    }

    if ($sum) {
        say "worked ".$self->beautify_seconds($sum)." on $project_name $tag_name"; 
    }
    else {
        say "didn't work on $project_name at all!";

    }
=cut

}

q{Listening to:
    Zahnarztwartezimmergeraeusche
};

__END__

=head1 NAME

App::TimeTracker::Command::worked - calculate total worked time per task

=head1 DESCRIPTION

Implements the 'worked' command, which you can use to query how long you worked on different tasks

  ~$ tracker worked task
  worked 12 hours, 37 minutes, 34 seconds on task

  ~$ tracker worked task --from 0101

  ~$ tracker worked task --from 0101 --to 0131
  
  ~$ tracker worked task --this week
  
  ~$ tracker worked task --last month


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


