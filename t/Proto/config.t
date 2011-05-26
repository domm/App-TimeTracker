use 5.010;
use strict;
use warnings;
use lib qw(t/testlib);

use Test::Most;
use Test::File;
use File::Copy;

use FakeHomeDir;

use App::TimeTracker::Proto;
my $p = App::TimeTracker::Proto->new;

like($p->home->stringify,qr/\.TimeTracker/,'we have a home');
copy('t/testdata/test_tracker.json',$p->configfile);
file_exists_ok($p->configfile);

{
    @ARGV=('--project','CPANTS');
    my $c = $p->load_config;
    is($p->project,'CPANTS','project set via ARGV to CPANTS');
    is($c->{rt}{set_owner_to},undef,'no rt->set_owner_to');
    is($c->{rt}{update_time_worked},undef,'no rt->update_time_worked');
}

{
    @ARGV=();
    my $c = $p->load_config;
    is($p->project,'App-TimeTracker','project set via path to TimeTracker');
    is($c->{project2job}{'App-TimeTracker'},'perl','A-TT belongs to perl');
    is($c->{project2job}{'CPANTS'},'vienna.pm','CPANTS belongs to Vienna.pm');
    is($c->{rt}{set_owner_to},'domm','rt->set_owner_to');
    is($c->{rt}{update_time_worked},1,'rt->update_time_worked');
}

done_testing();
