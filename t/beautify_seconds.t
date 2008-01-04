
use Test::More tests => 7;
use Test::NoWarnings;
use TimeTracker;

my $t=TimeTracker->new;

is($t->beautify_seconds(1),'1 second','1s');
is($t->beautify_seconds(10),'10 seconds','10s');
is($t->beautify_seconds(70),'1 minute, 10 seconds','70s');
is($t->beautify_seconds(170),'2 minutes, 50 seconds','170s');
is($t->beautify_seconds((60*60)+170),'1 hour, 2 minutes, 50 seconds','3770s');
is($t->beautify_seconds((3*60*60)+170),'3 hours, 2 minutes, 50 seconds','10970s');



