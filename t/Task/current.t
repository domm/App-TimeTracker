use 5.010;
use strict;
use warnings;
use lib 't';

use Test::Most;
use Test::File;
use testlib::Fixtures;
use App::TimeTracker::Data::Task;

my $tmp = testlib::Fixtures->setup_running;

foreach my $type (qw(current previous)) {
    file_exists_ok($tmp->file($type));
    my $task = App::TimeTracker::Data::Task->$type($tmp);
    is($task->start->ymd,'2011-05-28','start date');
}

done_testing();
