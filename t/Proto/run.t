use 5.010;
use strict;
use warnings;
use lib qw(t);

use Test::Most;
use Test::Trap;
use testlib::Fixtures;
use App::TimeTracker::Proto;

my $testdir = testlib::Fixtures::setup_tree('tree1');
chdir($testdir);
my $p = App::TimeTracker::Proto->new( home => $testdir );

trap {
    $p->run;
};

is( $trap->exit, 0, 'exit()' );
like( $trap->stdout, qr/^Available commands:/, 'List of commands' );
like( $trap->stdout, qr/\tstart/,              'start command in list' );

done_testing();
