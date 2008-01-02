#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'TimeTracker' );
}

diag( "Testing TimeTracker $TimeTracker::VERSION, Perl $], $^X" );
