use 5.010;
use strict;
use warnings;
use lib 't';

use Test::Most;
use testlib::Fixtures;
use DateTime;
use App::TimeTracker;
my $tmp = testlib::Fixtures::setup_tempdir;
local $ENV{TZ} = 'UTC';

my %BASE = ( home=>$tmp, config=>{} );

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
    my $t = App::TimeTracker->new(\%BASE);
    cmp_bag($t->tags,[],'no tags');
    $t->add_tag('1');
    $t->add_tag('2');
    $t->insert_tag('3');
    cmp_deeply($t->tags,[3,1,2],'some tags');

}

{ # to / from
    my $class = Moose::Meta::Class->create_anon_class(
        superclasses => ['App::TimeTracker'],
        roles        => ['App::TimeTracker::Command::Core'],
    );
    my $class_name = $class->name;
    $class_name->_load_attribs_worked($class);

    no warnings 'redefine';
    local *DateTime::now = sub { return DateTime->new( year => 2011, month => 9, day => 7, hour => 12 ) };
    {
        my $t1 = $class_name->new({
            %BASE,
            this    => 'week',
        });

        is($t1->from->iso8601,'2011-09-05T00:00:00','From 1 ok');
        is($t1->to->iso8601,'2011-09-11T23:59:59','To 1 ok');
    }

    {
        my $t2 = $class_name->new({
            %BASE,
            last    => 'week',
        });

        is($t2->from->iso8601,'2011-08-29T00:00:00','From 2 ok');
        is($t2->to->iso8601,'2011-09-04T23:59:59','To 2 ok');
    }

    {
        my $t3 = $class_name->new({
            %BASE,
            last    => 'month',
        });

        is($t3->from->iso8601,'2011-08-01T00:00:00','From 3 ok');
        is($t3->to->iso8601,'2011-08-31T23:59:59','To 3 ok');
    }

    {
        my $t4 = $class_name->new({
            %BASE,
            last    => 'day',
        });

        is($t4->from->iso8601,'2011-09-06T00:00:00','From 4 ok');
        is($t4->to->iso8601,'2011-09-06T23:59:59','To 4 ok');
    }
}

done_testing();
