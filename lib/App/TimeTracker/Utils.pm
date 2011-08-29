package App::TimeTracker::Utils;
use strict;
use warnings;
use 5.010;

use Scalar::Util qw(blessed);

use Exporter;
use parent qw(Exporter);

our @EXPORT = qw();
our @EXPORT_OK = qw(pretty_date now);
our %EXPORT_TAGS = (
    all => \@EXPORT_OK
);

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

