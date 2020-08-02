use 5.010;
use strict;
use warnings;
use lib 't';

use Test::Most;
use testlib::Fixtures;
use DateTime;
use App::TimeTracker::Data::Task;

my $tmp = testlib::Fixtures::setup_tempdir;

{
    my $task = App::TimeTracker::Data::Task->new({
        project => 'test',
        start   => DateTime->new(year=>2010,month=>2,day=>26,hour=>10,minute=>5,second=>42),
    });

    cmp_bag ([$task->_filepath],[qw(2010 02 20100226-100542_test.trc)],'filepath has correct elements');
    is($task->storage_location($tmp),$tmp->file('2010','02','20100226-100542_test.trc'),'storage_location');

}

done_testing();
