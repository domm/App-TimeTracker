use strict;
use warnings;

use Test::Most tests=>4;
use App::TimeTracker;

my $tt=App::TimeTracker->new;
is($tt->storage_location,'t/data','test storage location');
is($tt->file('file'),'t/data/file','storage_location plus file');
is($tt->file(qw(path to some file)),'t/data/path/to/some/file','storage_location plus file list');


delete $INC{'Test/More.pm'};
my $tt2=App::TimeTracker->new;
like($tt2->storage_location,qr/\.TimeTracker/,'real storage location');


