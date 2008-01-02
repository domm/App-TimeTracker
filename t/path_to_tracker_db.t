
use Test::More tests => 2;
use Test::NoWarnings;
use TimeTracker;
use TimeTracker::ConfigData;
use File::Spec::Functions;

my $t=TimeTracker->new;
is($t->path_to_tracker_db,catfile(TimeTracker::ConfigData->config( 'home' ),'tracker.db'));



