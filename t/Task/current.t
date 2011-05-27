use 5.010;
use strict;
use warnings;

use Test::Most;
use Test::File;
use Test::Dir;
use Path::Class;
use DateTime;
use File::Temp qw(tempdir);
use File::Copy;

use App::TimeTracker::Data::Task;
my $tmp = Path::Class::Dir->new(tempdir(CLEANUP=>$ENV{NO_CLEANUP} ? 0 : 1));
my $tracker_file = $tmp->file('running.trc');
copy('t/testdata/running.trc',$tracker_file) || die $!;

file_exists_ok("$tmp/running.trc");

foreach my $type (qw(current previous)) {
    my $file = $tmp->file($type);
    my $fh = $file->openw;
    say $fh $tracker_file;
    close $fh;

    file_exists_ok($file);
    my $task = App::TimeTracker::Data::Task->$type($tmp);
    is($task->start->ymd,'2011-05-28','start date');
}

done_testing();
