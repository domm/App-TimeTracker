#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'App::TimeTracker' );
}

diag( "Testing App::TimeTracker $App::TimeTracker::VERSION, Perl $], $^X" );
