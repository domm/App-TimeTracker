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

my $tmp = testlib::Fixtures::setup_tempdir;
my $home = $tmp->subdir('TimeTracker');
$tmp->subdir('rt73859')->mkpath;
my $p = App::TimeTracker::Proto->new(home=>$home);

my $tracker_dir = $home->subdir('2012','01');
my $c = { project=>'rt73859'};

# test what was reported, but it works
diag("Test initial bug report");

{ # start
    my $test_date = DateTime->new(year=>2012,month=>1,day=>9,hour=>21,time_zone=>'local');
    Test::MockTime::set_fixed_time($test_date->epoch);

    @ARGV=('start');
    my $class = $p->setup_class($c);
    my $t = $class->name->new(home=>$home, config=>$c, _current_project=>'rt73859',at=>'23:30');
    trap {$t->cmd_start };

    is($trap->stdout,"Started working on rt73859 at 23:30:00\n",'start: output');
    file_not_empty_ok($tracker_dir->file('20120109-233000_rt73859.trc'),'tracker file exists');
}

{ # stop
    my $test_date = DateTime->new(year=>2012,month=>1,day=>10,hour=>'00',minute=>3,time_zone=>'local');
    Test::MockTime::set_fixed_time($test_date->epoch);

    @ARGV=('stop');
    my $class = $p->setup_class($c);
    my $t = $class->name->new(home=>$home, config=>$c, _current_project=>'rt73859',at=>'0:30');
    trap {$t->cmd_stop };

    is($trap->stdout,"Worked 01:00:00 on rt73859\n",'stop: output');
    my $task = App::TimeTracker::Data::Task->load($tracker_dir->file('20120109-233000_rt73859.trc')->stringify);
    is($task->seconds,60 * 60,'task: seconds');
    is($task->duration,'01:00:00','task: duration');
}


# ah, I assume there is a different bug:
# if you issue 'tracker stop --at 00:10' but it is 23:59, the stop-time will be set for the current day, i.e. way before the start time
# solution do not allow to set stop times that are before the start time.
diag("Test de facto bug");

{ # start
    my $test_date = DateTime->new(year=>2012,month=>1,day=>8,hour=>23,minute=>30,time_zone=>'local');
    Test::MockTime::set_fixed_time($test_date->epoch);

    @ARGV=('start');
    my $class = $p->setup_class($c);
    my $t = $class->name->new(home=>$home, config=>$c, _current_project=>'rt73859');
    trap {$t->cmd_start };

    is($trap->stdout,"Started working on rt73859 at 23:30:00\n",'start: output');
    file_not_empty_ok($tracker_dir->file('20120108-233000_rt73859.trc'),'tracker file exists');
}

{ # stop
    my $test_date = DateTime->new(year=>2012,month=>1,day=>8,hour=>23,minute=>45,time_zone=>'local');
    Test::MockTime::set_fixed_time($test_date->epoch);

    @ARGV=('stop');
    my $class = $p->setup_class($c);
    my $t = $class->name->new(home=>$home, config=>$c, _current_project=>'rt73859',at=>'0:30');
    trap {$t->cmd_stop };

    like($trap->stdout,qr/This makes no sense/,'stop: aborted output');
    my $task = App::TimeTracker::Data::Task->load($tracker_dir->file('20120108-233000_rt73859.trc')->stringify);
    is($task->stop,undef,'task: no stop time');
    file_not_empty_ok($home->file('current'),'"current" file still exists');
}

{ # stop again, with long --at
    my $test_date = DateTime->new(year=>2012,month=>1,day=>8,hour=>23,minute=>45,time_zone=>'local');
    Test::MockTime::set_fixed_time($test_date->epoch);

    @ARGV=('stop');
    my $class = $p->setup_class($c);
    my $t = $class->name->new(home=>$home, config=>$c, _current_project=>'rt73859',at=>'2012-01-09 00:30');
    trap {$t->cmd_stop };

    is($trap->stdout,"Worked 01:00:00 on rt73859\n",'stop: output');

    my $task = App::TimeTracker::Data::Task->load($tracker_dir->file('20120108-233000_rt73859.trc')->stringify);
    is($task->seconds,60 * 60,'task seconds');
    is($task->duration,'01:00:00','task duration');
    file_not_exists_ok($home->file('current'),'"current" file is gone now');
}

done_testing();
