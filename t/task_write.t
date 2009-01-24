use strict;
use warnings;

use Test::Most tests=>7;
use Test::NoWarnings;
use App::TimeTracker;

my $tt = App::TimeTracker->new;

{   # write a task
    my $task = App::TimeTracker::Task->new({
        project=>'timetracker',
        start=>'1232749792',
        stop=>'1232759792',
        basedir=> $tt->storage_location,
    });
    lives_ok { $task->write( ) };
}

# and now read it back
my $task = App::TimeTracker::Task->read( $tt->file( qw(2009 01 23-232952-timetracker.done)) );

is($task->_path,'t/data/2009/01/23-232952-timetracker.done','path');
is($task->project,'timetracker','project');
isa_ok($task->start,'DateTime','class of start');
is($task->start->epoch,'1232749792','start as epoch');
is($task->start->iso8601,'2009-01-23T23:29:52','start as iso8601');

unlink 't/data/2009/01/23-232952-timetracker.done';
