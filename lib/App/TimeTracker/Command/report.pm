package App::TimeTracker::Command::report;
use 5.010;
use strict;
use warnings;
use base qw(App::Cmd::Command App::TimeTracker);
use DateTime;

sub usage_desc { "report %o task" }

sub opt_spec {
    my @args=App::TimeTracker::global_opts(@_);
    push(@args,
        ['from=s'   => 'report start date/time'],
        ['to=s'     => 'report stop date/time'],
        ['this=s'   => 'report in this week/month/year'],
        ['last=s'   => 'report in last week/month/year'],
    );
    return @args;
}

sub validate_args { return App::TimeTracker::global_validate(@_) }

sub run {
    my ($self, $opt, $args) = @_;

    my $dbh=$self->schema->storage->dbh;
    my ($sql_from, $sql_to)=($opt->{from}||'',$opt->{to}||'');
    if (my $this = $opt->{this}) {
        my $from=DateTime->now->truncate(to=>$this);        
        my $to=$from->clone->add($this.'s'=>1);
        $sql_from   = $from->ymd('-');
        $sql_to     = $to->ymd('-');
    }
    elsif (my $last = $opt->{last}) {
        my $from=DateTime->now->truncate(to=>$last)->subtract($last.'s'=>1);        
        my $to=$from->clone->add($last.'s'=>1);
        $sql_from   = $from->ymd('-');
        $sql_to     = $to->ymd('-');
    }
    $sql_from="AND task.start > '$sql_from' " if $sql_from;
    $sql_to="AND task.stop < '$sql_to' " if $sql_to;

    my $sth=$dbh->prepare("select project.name,sum(strftime('%s',task.stop) - strftime('%s',task.start)) as cnt from task,project where task.project=project.id $sql_from $sql_to group by project.name order by cnt desc");
    $sth->execute;
    while (my @r=$sth->fetchrow_array) {
        printf("%- 20s %s\n",$r[0],$self->beautify_seconds($r[1]));
    }
}

q{Listening to:
    Zahnarztwartezimmergeraeusche
};

__END__

=head1 NAME

App::TimeTracker::Command::report - generate a report of time spend on all tasks

=head1 DESCRIPTION

Implements the 'report' command, which generates a report of time spend on all tasks.

  ~$ tracker report


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


