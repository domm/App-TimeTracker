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

{
    my $task = App::TimeTracker::Data::Task->new({
        project => 'test',
        start   => DateTime->new(year=>2010,month=>2,day=>26,hour=>10,minute=>5,second=>42),
    });
    
    $capture->start();
    $task->do_start($tmp);
    $capture->stop();

    ok(-e $task->storage_location($tmp),'task is saved');
    ok(-e $tmp.'/current','current is set');
    
    my $read = $capture->read;
    like($read,qr/started working on test at 10:05:42/i,'stdout');
}

done_testing();
