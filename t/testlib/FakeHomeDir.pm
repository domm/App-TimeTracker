package File::HomeDir;

use strict;
use warnings;
use testlib::Fixtures;
use File::Copy;

$INC{'File/HomeDir.pm'}=1;
my $tmp =  testlib::Fixtures::setup_tempdir();
$tmp->subdir('.TimeTracker')->mkpath;

copy('t/testdata/test_tracker.json',$tmp->file('.TimeTracker','tracker.json')) || die $!;
copy('t/testdata/test_projects.json',$tmp->file('.TimeTracker','projects.json')) || die $!;

sub my_home {
    return $tmp;
}

1;
