#!/opt/perl5.10/bin/perl
# generated with /opt/perl5.10/bin/generate_00-load_t.pl
use Test::More tests => 12;


BEGIN {
	use_ok( 'App::TimeTracker' );
}

diag( "Testing App::TimeTracker App::TimeTracker->VERSION, Perl $], $^X" );

use_ok( 'App::TimeTracker::Command' );
use_ok( 'App::TimeTracker::Command::convert_to_0_20' );
use_ok( 'App::TimeTracker::Command::current' );
use_ok( 'App::TimeTracker::Command::report' );
use_ok( 'App::TimeTracker::Command::start' );
use_ok( 'App::TimeTracker::Command::stop' );
use_ok( 'App::TimeTracker::Command::sync' );
use_ok( 'App::TimeTracker::Command::worked' );
use_ok( 'App::TimeTracker::Exceptions' );
use_ok( 'App::TimeTracker::Projects' );
use_ok( 'App::TimeTracker::Task' );
