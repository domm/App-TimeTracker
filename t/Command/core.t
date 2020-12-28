use 5.010;
use strict;
use warnings;
use lib qw(t);

use Test::Most;
use Test::Trap;
use Test::File;
use testlib::FakeHomeDir;
use App::TimeTracker::Proto;
local $ENV{TZ} = 'UTC';

my $tmp = testlib::Fixtures::setup_tempdir;
my $home = $tmp->subdir('.TimeTracker');
$tmp->subdir('some_project')->mkpath;
$tmp->subdir('other_project')->mkpath;
my $p = App::TimeTracker::Proto->new(home=>$home);
my $now = DateTime->now;
$now->set_time_zone('local');
my $basetf = $now->ymd('').'-';
my $tracker_dir = $home->subdir($now->year,sprintf("%02d",$now->month));

{ # init
    @ARGV=('init');
    my $class = $p->setup_class({});

    file_exists_ok($home->file('projects.json'));
    file_exists_ok($home->file('tracker.json'));
    file_not_exists_ok($tmp->file('some_project','.tracker.json'));
    file_not_exists_ok($tmp->file('other_project','.tracker.json'));

    $p->_build_home($home);

    my $t = $class->name->new(home=>$home, config=>{}, _current_project=>'some_project');
    trap { $t->cmd_init($tmp->subdir('some_project')) };
    is($trap->stdout,"Set up this directory for time-tracking via file .tracker.json\n",'init: output');

    file_exists_ok($home->file('projects.json'));
    file_exists_ok($home->file('tracker.json'));
    file_exists_ok($tmp->file('some_project','.tracker.json'));

}

my $c1 = $p->load_config($tmp->subdir(qw(some_project)));

{ # start
    @ARGV=('start');
    my $class = $p->setup_class($c1);

    file_not_exists_ok($tracker_dir->file($basetf.'140000_some_project.trc'),'tracker file does not exist yet');
    my $t = $class->name->new(home=>$home, config=>$c1, _current_project=>'some_project',at=>'14:00');
    trap {$t->cmd_start };
    is($trap->stdout,"Started working on some_project at 14:00:00\n",'start: output');
    file_not_empty_ok($tracker_dir->file($basetf.'140000_some_project.trc'),'tracker file exists');
}

{ # current
#    # TODO: need to monkey-patch $class->now to return a mocked value
    @ARGV=('current');
    my $class = $p->setup_class($c1);
    my $t = $class->name->new(home=>$home, config=>$c1, _current_project=>'some_project');
    trap {$t->cmd_current };
    like($trap->stdout, qr/^Working \d{2}:\d{2}:\d{2} on some_project/, 'current project is some_project');
    like($trap->stdout, qr/Started at 14:00:00/, 'project start time is correct');
}

{ # stop
    @ARGV=('stop');
    my $class = $p->setup_class($c1);
    my $t = $class->name->new(home=>$home, config=>$c1, _current_project=>'some_project',at=>'14:15');
    trap {$t->cmd_stop };
    is($trap->stdout,"Worked 00:15:00 on some_project\n",'stop: output');

    my $task = App::TimeTracker::Data::Task->load($tracker_dir->file($basetf.'140000_some_project.trc')->stringify);
    is($task->seconds,15 * 60,'task seconds');
    is($task->duration,'00:15:00','task duration');

    trap {$t->cmd_current};
    like($trap->stdout, qr/Worked 15 minutes from 14:00:00 till 14:15:00/, '');
}

{ # append
    @ARGV=('append');
    my $class = $p->setup_class($c1);
    my $t = $class->name->new(home=>$home, config=>$c1, _current_project=>'some_project');
    trap {$t->cmd_append };
    is($trap->stdout,"Started working on some_project at 14:15:00\n",'stop: output');

    my $trc = $tracker_dir->file($basetf.'141500_some_project.trc');
    file_not_empty_ok($trc,'tracker file exists');
    my $task = App::TimeTracker::Data::Task->load($trc->stringify);
    is($task->stop,undef,'task stop not set');
}

{ # init other project
    file_not_exists_ok($tmp->file('other_project','.tracker.json'));

    @ARGV=('init');
    my $class = $p->setup_class({});

    my $t = $class->name->new(home=>$home, config=>{}, _current_project=>'other_project');
    trap { $t->cmd_init($tmp->subdir('other_project')) };
    is($trap->stdout,"Set up this directory for time-tracking via file .tracker.json\n",'init: output');
    file_exists_ok($tmp->file('other_project','.tracker.json'));
}

my $c2 = $p->load_config($tmp->subdir(qw(other_project)));

{ # start other project
    @ARGV=('start');
    my $class = $p->setup_class($c2);
    my $trc = $tracker_dir->file($basetf.'143000_other_project.trc');
    file_not_exists_ok($trc,'tracker file does not exist yet');

    my $t = $class->name->new(home=>$home, config=>$c2, _current_project=>'other_project',at=>'14:30');
    trap {$t->cmd_start };
    is($trap->stdout,"Worked 00:15:00 on some_project\nStarted working on other_project at 14:30:00\n",'start: output');
    file_not_empty_ok($trc,'tracker file exists');

    my $task = App::TimeTracker::Data::Task->load($tracker_dir->file($basetf.'141500_some_project.trc')->stringify);
    is($task->seconds,15 * 60,'prev task seconds');
    is($task->duration,'00:15:00','prev task duration');
}

{ # stop it
    @ARGV=('stop');
    my $class = $p->setup_class($c1);
    my $t = $class->name->new(home=>$home, config=>$c2, _current_project=>'other_project',at=>'14:45');
    trap {$t->cmd_stop };
    like($trap->stdout,qr/00:15:00.*other_project/,'stop: output');
}

{ # version
    @ARGV=('version');
    my $version = App::TimeTracker->VERSION;
    my $class = $p->setup_class($c1);
    my $t = $class->name->new(home=>$home, config=>$c2);
    trap {$t->cmd_version };
    like($trap->stdout,qr/$version/,'version: output');
}

{ # commands
    @ARGV = ('commands');
    my $class = $p->setup_class({});

    my $t = $class->name->new(home=>$home, config=>{});
    trap {$t->cmd_commands};
    my @core_commands = qw<
       append
       commands
       continue
       current
       init
       list
       plugins
       recalc_trackfile
       report
       show_config
       start
       stop
       version
       worked>;
    my $output = $trap->stdout;
    my @lines = split /\n/, $output;
    @lines = grep !/Available commands/, @lines;
    s/^\s+//g foreach @lines;  # remove leading whitespace from strings
    is_deeply(\@lines, \@core_commands, 'default list of core commands is sorted');
}

{ # report global
    @ARGV = ('report');
    my $class = $p->setup_class( $c1, 'report' );
    my $t = $class->name->new( home => $home, config => $c1 );
    trap { $t->cmd_report };
    like ($trap->stdout, qr/total\s+00:45:00/, 'report global');
};

{ # report filter project
    @ARGV = ('report');
    my $class = $p->setup_class( $c1, 'report' );
    my $t = $class->name->new(
        home             => $home,
        config           => $c1,
        fprojects =>  ['some_project']
    );
    trap { $t->cmd_report };
    like ($trap->stdout, qr/total\s+00:30:00/, 'report filter project');
}

done_testing();
