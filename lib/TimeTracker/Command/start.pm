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

    my $project_name=shift(@$args);
    X::BadParams->throw("No project specified") unless $project_name;
    my $schema=$self->schema;

    # check if we already know this task
    my $project=$schema->resultset('Project')->find($project_name,{key=>'name'});
    if (!$project) {
        say "'$project_name' is not among the current list of projects, add it? (y|n) ";
        my $prompt = <STDIN>;
        chomp($prompt);
        unless ( $prompt =~ /^y/i ) {
            say "Aborting...";
            exit;
        }
        $project=$schema->resultset('Project')->create({
            name=>$project_name,    
        });
    }

    # stop last active task
    $self->stop($self->now);

    my $start=$opt->{start};

    # start new task
    my $task=$project->add_to_tasks({
        start=>$start,
        active=>1,
    });

    # add tags
    my $tags=join(' ',@$args);
    if ($tags) {
        my @tags=split(/[,;]\s+/,$tags);
        foreach my $tagname (@tags) {
            my $tag=$schema->resultset('Tag')->find_or_create({
                tag=>$tagname,
            });
            $task->add_to_tags($tag);
        }
    }
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

