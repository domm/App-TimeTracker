use 5.010;
use strict;
use warnings;
use lib 't';

use Test::Most;
use testlib::Fixtures;
use DateTime;
use App::TimeTracker;
local $ENV{TZ} = 'UTC';

my $tmp = testlib::Fixtures->setup_2011_05;
my $t   = App::TimeTracker->new( home => $tmp, config => {} );

{
    my @files = $t->find_task_files(
        {   from => DateTime->new( year => '2011', month => 5, day => 20 ),
            to   => DateTime->new( year => '2011', month => 5, day => 25 ),
        }
    );
    is( scalar @files, 6, 'got 6 files' );
    is( $files[0],     $tmp->file( '2011', '05', '20110520-093423_oe1_orf_at.trc' ), 'first file' );
    is( $files[5], $tmp->file( '2011', '05', '20110525-224324_App_TimeTracker.trc' ), 'last file' );
}

{
    my @files = $t->find_task_files( { projects => ['TimeTracker'], } );
    is( scalar @files,                              7, 'got 7 files' );
    is( ( scalar grep {/App_TimeTracker/} @files ), 7, 'all match project' );
}

{
    my @files = $t->find_task_files(
        {   from     => DateTime->new( year => '2011', month => 5, day => 1 ),
            projects => ['oe1'],
        }
    );
    is( scalar @files, 16, 'got 16 files' );
}

done_testing();
