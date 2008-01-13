package TimeTracker::Command::start;
use 5.010;
use strict;
use warnings;
use base qw(App::Cmd::Command TimeTracker);

sub usage_desc { "yourcmd %o task [tags]" }

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

