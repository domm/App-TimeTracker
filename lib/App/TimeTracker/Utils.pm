package App::TimeTracker::Utils;
use strict;
use warnings;
use 5.010;

# ABSTRACT: Utility Methods/Functions for App::TimeTracker

use Scalar::Util qw(blessed);
use Term::ANSIColor;

use Exporter;
use parent qw(Exporter);

our @EXPORT = qw();
our @EXPORT_OK = qw(pretty_date now error_message);
our %EXPORT_TAGS = (
    all => \@EXPORT_OK
);

sub error_message {
    my ($message,@params) = @_;

    # TODO better error handling
    my $error = sprintf($message,@params);

    print color 'bold red';
    print $error;
    say color 'reset';
}

sub pretty_date {
    my ($date) = @_;
    
    unless (blessed $date
        && $date->isa('DateTime')) {
        return $date;
    } else {
        my $now = now();
        my $yeseterday = now()->subtract( days => 1);
        if ($date->dmy eq $now->dmy) {
            return $date->hms(':');
        } elsif ($date->dmy eq $yeseterday->dmy) {
            return 'yesterday '.$date->hms(':');
        } else {
            return $date->dmy('.').' '.$date->hms(':');
        }
    }
}

sub now {
    my $dt = DateTime->now();
    $dt->set_time_zone('local');
    return $dt;
}
1;

