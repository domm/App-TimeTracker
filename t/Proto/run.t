use 5.010;
use strict;
use warnings;
use lib qw(t);

use Test::Most;
use Test::Trap;
use testlib::FakeHomeDir;
use App::TimeTracker::Proto;

my $p = App::TimeTracker::Proto->new;

trap { 
    $p->run;
};

is ( $trap->exit, 0, 'exit()' );
like($trap->stdout,qr/^Available commands:/,'List of commands');
like($trap->stdout,qr/\tstart/,'start command in list');

done_testing();
