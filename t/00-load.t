#!/opt/perl5.10/bin/perl
# generated with /home/domm/perl/scripts/generate_00-load_t.pl
use Test::More tests => 12;
use Test::NoWarnings;

BEGIN {
	use_ok( 'App::TimeTracker' );
}

diag( "Testing App::TimeTracker App::TimeTracker->VERSION, Perl $], $^X" );

use_ok( 'App::TimeTracker::Schema' );
use_ok( 'App::TimeTracker::Schema::Project' );
use_ok( 'App::TimeTracker::Schema::Tag' );
use_ok( 'App::TimeTracker::Schema::TaskTag' );
use_ok( 'App::TimeTracker::Schema::Task' );
use_ok( 'App::TimeTracker::Command::stop' );
use_ok( 'App::TimeTracker::Command::worked' );
use_ok( 'App::TimeTracker::Command::start' );
use_ok( 'App::TimeTracker::Command::current' );
use_ok( 'App::TimeTracker::Command::report' );
