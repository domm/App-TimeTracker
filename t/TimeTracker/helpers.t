use 5.010;
use strict;
use warnings;

use Test::Most;
use Test::File;
use Test::Dir;
use Path::Class;
use DateTime;
use File::Temp qw(tempdir);

use App::TimeTracker;
my $tmp = Path::Class::Dir->new(tempdir(CLEANUP=>1));

{ # $self->now
    my $exp = DateTime->now(time_zone=>'local');
    my $got = App::TimeTracker->now;
    is($exp->ymd,$got->ymd,'$self->now: ymd');
    is($exp->strftime('%H:%M'),$got->strftime('%H:%M'),'$self->now: hh:mm');
}

{ # beautify_seconds
    my @tests = (
        [undef, '0'],
        ['0', '0'],
        ['59', '00:00:59'],
        ['60', '00:01:00'],
        ['61', '00:01:01'],
        ['263', '00:04:23'],
        [3*60*60, '03:00:00'],
        [(4*60*60)+(42*60)+21, '04:42:21'],
        [(18*60*60), '18:00:00'],
        [(111*60*60)+11, '111:00:11'],
    );
    foreach (@tests) {
        is(App::TimeTracker->beautify_seconds($_->[0]),$_->[1],join(' -> ',map { $_ // 'UNDEF'} @$_));
    }
}

done_testing();
