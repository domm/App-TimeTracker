use 5.010;
use strict;
use warnings;
use lib qw(t/testlib);

use Test::Most;
use File::Copy;
use Test::Trap;
use FakeHomeDir;

use App::TimeTracker::Proto;
my $p = App::TimeTracker::Proto->new;
copy('t/testdata/test_tracker.json',$p->configfile);

trap { 
    $p->run;
};

is ( $trap->exit, 0, 'exit()' );
like($trap->stdout,qr/^Available commands:/,'List of commands');
like($trap->stdout,qr/\tstart/,'start command in list');

done_testing();
