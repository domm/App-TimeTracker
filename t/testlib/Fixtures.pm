package testlib::Fixtures;
use strict;
use warnings;
use 5.010;

use File::Temp qw(tempdir);
use Path::Class;
use File::Copy::Recursive qw(dircopy);
use File::Copy;

my $tempdir;
sub setup_tempdir {
    return $tempdir if $tempdir;
    $tempdir = Path::Class::Dir->new(tempdir(CLEANUP=>$ENV{NO_CLEANUP} ? 0 : 1));
    return $tempdir;
}

sub setup_2011_05 {
    my $tmp = setup_tempdir();
    dircopy('t/testdata/2011',$tmp->subdir('2011')) || die $!;
    return $tmp;
}

sub setup_running {
    my $tmp = setup_tempdir();

    my $tracker_file = $tmp->file('running.trc');
    copy('t/testdata/running.trc',$tracker_file) || die $!;
    
    foreach my $type (qw(current previous)) {
        my $file = $tmp->file($type);
        my $fh = $file->openw;
        say $fh $tracker_file;
        close $fh;
    }
    
    return $tmp;
}

1;
