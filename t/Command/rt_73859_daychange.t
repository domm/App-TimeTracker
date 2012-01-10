use 5.010;
use strict;
use warnings;
use lib qw(t);

use Test::MockTime qw(); # this needs to be loaded before DateTime
                         # http://www.nntp.perl.org/group/perl.datetime/2008/08/msg7043.html
use Test::Most;
use Test::Trap;
use Test::File;
use testlib::FakeHomeDir;
use App::TimeTracker::Proto;
use DateTime;
use File::Copy;

my $tmp = testlib::Fixtures::setup_tempdir;
my $home = $tmp->subdir('TimeTracker');
$tmp->subdir('rt73859')->mkpath;
my $p = App::TimeTracker::Proto->new(home=>$home);

# fake time
my $test_date = DateTime->new(year=>2012,month=>1,day=>9);
Test::MockTime::set_fixed_time($test_date->epoch);
my $basetf = $test_date->ymd('').'-';
my $tracker_dir = $home->subdir($test_date->year,sprintf("%02d",$test_date->month));
my $c = { project=>'rt73859'};

# test what was reported, but it works

{ # start
    @ARGV=('start');
    my $class = $p->setup_class($c);

    my $t = $class->name->new(home=>$home, config=>$c, _current_project=>'rt73859',at=>'23:30');
    trap {$t->cmd_start };
    file_not_empty_ok($tracker_dir->file('20120109-233000_rt73859.trc'),'tracker file exists');

}

{ # stop
    my $stop_date = DateTime->new(year=>2012,month=>1,day=>10,hour=>0,minute=>3);
    Test::MockTime::set_fixed_time($stop_date->epoch);
    @ARGV=('stop');
    my $class = $p->setup_class($c);
    my $t = $class->name->new(home=>$home, config=>$c, _current_project=>'rt73859',at=>'0:30');
    trap {$t->cmd_stop };
    is($trap->stdout,"Worked 01:00:00 on rt73859\n",'stop: output');

    my $task = App::TimeTracker::Data::Task->load($tracker_dir->file('20120109-233000_rt73859.trc')->stringify);
    is($task->seconds,60 * 60,'task seconds');
    is($task->duration,'01:00:00','task duration');
}


# ah, I assume there is a different bug:
# if you issue 'tracker stop --at 00:10' but it is 23:59, the stop-time will be set for the current day, i.e. way before the start time
# solution do not allow to set stop times that are before the start time.

done_testing();
