use 5.010;
use strict;
use warnings;
use lib 't';

use Test::Most;
use App::TimeTracker;
use testlib::Fixtures;
my $tmp = testlib::Fixtures::setup_tempdir;

package ThisTest;
use Moose;
extends 'App::TimeTracker';
has 'dt' => (
    isa=>'TT::DateTime',
    is=>'ro',
    coerce=>1,
);

package main;

local $ENV{TZ} = 'UTC';

my $now = DateTime->now;
$now->set_time_zone('local');
my $date = DateTime->new(year=>2012,month=>2,day=>26,time_zone=>'UTC');

foreach my $test (
    ['12:34',$now->clone->set(hour=>12,minute=>34,second=>0)],
    ['0:1',$now->clone->set(hour=>0,minute=>1,second=>0)],
    ['2012-02-26',$date->clone],
    ['2012-02-26 12:34',$date->clone->set(hour=>12,minute=>34,second=>0)],
    # for our crazy American friends...
    ['26-02-2012',$date->clone],
    ['26-02-2012 12:34',$date->clone->set(hour=>12,minute=>34,second=>0)],
) {
    my $tt = ThisTest->new(dt=>$test->[0],home=>$tmp, config=>{});
    is($tt->dt->iso8601,$test->[1]->iso8601,join(' -> ',@$test));
}

done_testing();
