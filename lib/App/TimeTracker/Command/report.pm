package App::TimeTracker::Command::report;
use 5.010;
use strict;
use warnings;
use App::TimeTracker -command;
use base qw(App::TimeTracker);
use DateTime;

sub usage_desc {"report %o task"}

sub opt_spec {
    return ( shift->opt_spec_reports,
        [ 'detail' => 'detailed report including tags' ], 
        [ 'raw' => 'report in seconds' ] );
}

sub run {
    my ( $self, $opt, $args ) = @_;

    my $project = $opt->{project};
    my $tag     = $opt->{tag};
    my $tasks   = $self->find_tasks($opt);

    my %report;
    foreach my $file ( sort @$tasks ) {
        my $task = App::TimeTracker::Task->read($file);

        if ($tag) {
            next unless $task->tags =~ /$tag/;
        }

        my $time
            = (
            $task->is_active ? $self->app->now->epoch : $task->stop->epoch )
            - $task->start->epoch;
        if ( $opt->{detail} ) {
            $report{ $task->project }->[0] += $time;
            foreach my $tag ( split( /\s+/, $task->tags ) ) {
                $report{ $task->project }->[1]{$tag} += $time;
            }
        }
        else {
            $report{ $task->project } += $time;
        }

        say join( " ", $task->project, $task->start, $task->stop, $time )
            if $opt->{verbose};
    }

    if ( $opt->{detail} ) {
        while ( my ( $project, $data ) = each %report ) {
            printf( "%- 20s %s\n",
                $project,
                $opt->{raw} ? $data->[0] :  App::TimeTracker::Task->beautify_seconds( $data->[0] ) );
            my $diff = $data->[0];

            foreach my $tag ( sort { $data->[1]{$b} <=> $data->[1]{$a} } keys %{ $data->[1] } ) {
                my $time = $data->[1]{$tag};
                $diff -= $time;
                printf( "   %- 20s %s\n",
                    $tag, $opt->{raw} ? $time : App::TimeTracker::Task->beautify_seconds($time) );
            }
            printf( "   %- 20s %s\n",'unspecified', $opt->{raw} ? $diff: App::TimeTracker::Task->beautify_seconds($diff));


        }
    }
    else {
        while ( my ( $project, $time ) = each %report ) {
            printf( "%- 20s %s\n",
                $project, $opt->{raw} ? $time : App::TimeTracker::Task->beautify_seconds($time) );
        }
    }

}

q{Listening to:
    howling wind on Feuerkogel
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


