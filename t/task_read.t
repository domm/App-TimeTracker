use strict;
use warnings;

use Test::Most tests=>6;
use Test::NoWarnings;
use App::TimeTracker;

my $tt = App::TimeTracker->new;
my $task = App::TimeTracker::Task->read( $tt->file( qw(2009 01 15-100055-TimeTracker.current)) );

is($task->_path,'t/data/2009/01/15-100055-TimeTracker.current','path');
is($task->project,'TimeTracker','project');
isa_ok($task->start,'DateTime','class of start');
is($task->start->epoch,'1232010055','start as epoch');
is($task->start->iso8601,'2009-01-15T10:00:55','start as iso8601');


