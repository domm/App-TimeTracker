use 5.010;
use strict;
use warnings;

use Test::Most;
use Test::File;
use Test::Dir;
use Path::Class;
use DateTime;

use App::TimeTracker::Data::Task;
my $tmp = Path::Class::Dir->new('/tmp');

{
    my $task = App::TimeTracker::Data::Task->new({
        project => 'test',
        start   => DateTime->new(year=>2010,month=>2,day=>26,hour=>10,minute=>5,second=>42),
    });
    
    cmp_bag ([$task->_filepath],[qw(2010 02 20100226-100542_test.json)]); 
    is($task->storage_location($tmp),'/tmp/2010/02/20100226-100542_test.json');

}

done_testing();
