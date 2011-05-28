use 5.010;
use strict;
use warnings;
use lib 't';

use Test::Most;
use testlib::Fixtures;
use DateTime;
use App::TimeTracker;
my $tmp = testlib::Fixtures::setup_tempdir;

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

{ # tags
    my $t = App::TimeTracker->new({ home=>$tmp, config=>{} });
    cmp_bag($t->tags,[],'no tags');
    $t->add_tag('1');
    $t->add_tag('2');
    $t->insert_tag('3');
    cmp_deeply($t->tags,[3,1,2],'some tags');

}

done_testing();
