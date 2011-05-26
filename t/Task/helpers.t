use 5.010;
use strict;
use warnings;

use Test::Most;
use Test::File;
use Test::Dir;
use Path::Class;
use DateTime;
use File::Temp qw(tempdir);
use IO::Capture::Stdout;
my $capture = IO::Capture::Stdout->new();

use App::TimeTracker::Data::Task;
my $tmp = Path::Class::Dir->new(tempdir(CLEANUP=>1));

{   # _calc_duration, rounded_minutes
    my $task = App::TimeTracker::Data::Task->new({
        project => 'test',
        start   => DateTime->new(year=>2010,month=>2,day=>26,hour=>10,minute=>5,second=>42),
    });
    my $stop = DateTime->new(year=>2010,month=>2,day=>26,hour=>12,minute=>25,second=>13);
    $task->_calc_duration($stop);
    is ($task->seconds,'8371','_calc_duration: seconds');
    is ($task->duration,'02:19:31','_calc_duration: duration');
    is ($task->rounded_minutes,140,'rounded_minutes');

    $stop->add('hours'=>1);
    $task->stop($stop);
    $task->_calc_duration;
    is ($task->seconds,'11971','_calc_duration: seconds');
    is ($task->duration,'03:19:31','_calc_duration: duration');
    is ($task->rounded_minutes,200,'rounded_minutes');
}

done_testing();
