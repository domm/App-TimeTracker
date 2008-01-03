
use Test::More tests => 2;
use Test::NoWarnings;
use TimeTracker;
use TimeTracker::ConfigData;
use File::Spec::Functions;
use File::Temp qw(tempfile);

my $filename=tempfile(UNLINK=>1);

my $t=TimeTracker->new;
$t->opts->{file}=$filename;
is($t->path_to_tracker_db,$filename);



