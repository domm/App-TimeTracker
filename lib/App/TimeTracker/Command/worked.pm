package App::TimeTracker::Command::worked;
use 5.010;
use strict;
use warnings;
use base qw(App::Cmd::Command App::TimeTracker);
use DateTime;

sub usage_desc { "worked %o task" }

sub opt_spec {
    my @args=App::TimeTracker::global_opts(@_);
    push(@args,
        ['from=s'   => 'report start date/time'],
        ['to=s'     => 'report stop date/time'],
        ['this=s'   => 'report in this week/month/year'],
    );
    return @args;
}

sub validate_args { return App::TimeTracker::global_validate(@_) }

sub run {
    my ($self, $opt, $args) = @_;

    my $project_name=shift(@$args);
    my $tag_name=shift(@$args);
    my $project=$self->schema->resultset('Project')->find($project_name,{key=>'name'});
    X::BadData->throw("No such project: $project_name") unless $project;
    my $dbh=$self->schema->storage->dbh;

    my ($sql_from, $sql_to)=($opt->{from},$opt->{to});
    if (my $this = $opt->{this}) {
        my $from=DateTime->now->truncate(to=>$this);        
        my $to=$from->clone->add($this.'s'=>1);
        $sql_from   = $from->ymd('-');
        $sql_to     = $to->ymd('-');
    }
    $sql_from="AND task.start > '$sql_from' " if $sql_from;
    $sql_to="AND task.stop < '$sql_to' " if $sql_to;

    my $sum; my $current_sum;
    if ($tag_name) {
        $tag_name='%'.$tag_name.'%';
        $sum=$dbh->selectrow_array("select sum(strftime('%s',stop) - strftime('%s',start)) from task,project,tag,task_tag where task.project=project.id AND task_tag.task=task.id AND task_tag.tag=tag.id AND task.active=0 AND project.id=? AND tag.tag like ? $sql_from $sql_to",undef,$project->id,$tag_name);
        $current_sum=$dbh->selectrow_array("select sum(strftime('%s','now') - strftime('%s',start)) from task,project,tag,task_tag where task.project=project.id AND task_tag.task=task.id AND task_tag.tag=tag.id AND task.active=1 AND project.id=? AND tag.tag like ? $sql_from $sql_to",undef,$project->id,$tag_name);

        
    }
    else {
        $tag_name='';
        $sum=$dbh->selectrow_array("select sum(strftime('%s',stop) - strftime('%s',start)) from task,project where task.project=project.id AND task.active=0 AND project.id=? $sql_from $sql_to",undef,$project->id);
        my $current_sum=$dbh->selectrow_array("select sum(strftime('%s','now') - strftime('%s',start)) from task,project where task.project=project.id AND task.active=1 AND project.id=? $sql_from $sql_to",undef,$project->id);
    }

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


