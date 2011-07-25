#!/opt/perl5.10.1/bin/perl
# generated with /home/domm/perl5/perlbrew/perls/opt_perl5.10.1/bin/generate_00-load_t.pl
use Test::More tests => 9;


BEGIN {
	use_ok( 'App::TimeTracker' );
}

diag( "Testing App::TimeTracker App::TimeTracker->VERSION, Perl $], $^X" );

use_ok( 'App::TimeTracker::Command::Core' );
use_ok( 'App::TimeTracker::Command::Git' );
use_ok( 'App::TimeTracker::Command::Post2IRC' );
use_ok( 'App::TimeTracker::Command::RT' );
use_ok( 'App::TimeTracker::Command::SyncViaGit' );
use_ok( 'App::TimeTracker::Command::TextNotify' );
use_ok( 'App::TimeTracker::Data::Task' );
use_ok( 'App::TimeTracker::Proto' );
