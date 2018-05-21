use 5.010;
use strict;
use warnings;
use lib 't';

use Test::Most;
use IO::Capture::Stdout;
use testlib::Fixtures;
use App::TimeTracker::Data::Task;
local $ENV{TZ} = 'UTC';

my $capture = IO::Capture::Stdout->new();
my $tmp = testlib::Fixtures::setup_tempdir;

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
