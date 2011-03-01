use strict;
use warnings;

use Test::Most tests=>7;
use Test::NoWarnings;
use App::TimeTracker;

{
    my $task = App::TimeTracker::Task->new({
        project=>'timetracker',
        start=>'1232749792',
    });
    is($task->_calc_filename,'20090123-232952-timetracker.current','current filename');
    is($task->_calc_dir,'2009/01','current dir');
}

{
    my $task = App::TimeTracker::Task->new({
        project=>'timetracker',
        start=>'1232749792',
        stop=>'1232759792',
    });
    is($task->_calc_filename,'20090123-232952-timetracker.done','done filename');
    is($task->_calc_dir,'2009/01','done dir');
}

{
    my $task = App::TimeTracker::Task->new({
        start=>'1232749792',
    });
    is($task->_calc_filename,'20090123-232952-unknown.current','unknown filename');
    is($task->_calc_dir,'2009/01','unknown dir');
}

