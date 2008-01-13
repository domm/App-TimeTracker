package TimeTracker::Command::current;
use 5.010;
use strict;
use warnings;
use base qw(App::Cmd::Command TimeTracker);

sub usage_desc { "current" }

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

