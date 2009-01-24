use strict;
use warnings;

use Test::Most tests=>7;
use Test::NoWarnings;
use App::TimeTracker;

my $tt = App::TimeTracker->new;

# no projects yet
my $blank = App::TimeTracker::Projects->read( $tt->storage_location );
is(ref $blank->list,'HASH','we have a ref');
is(keys %{$blank->list},'0','no projects');

# add one
$blank->add('SHTOINK_SHTOINK_SHTOINK_SHTOINK');
is($blank->list->{'SHTOINK_SHTOINK_SHTOINK_SHTOINK'},1,'new project in hash');

# write it
$blank->write($tt->storage_location );

# read again
my $projects = App::TimeTracker::Projects->read( $tt->storage_location );
is(ref $projects->list,'HASH','we have a ref');
is(keys %{$projects->list},'1','one projects');
is($projects->list->{'SHTOINK_SHTOINK_SHTOINK_SHTOINK'},1,'new project after new load');

unlink($projects->_file($tt->storage_location));
