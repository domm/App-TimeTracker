use 5.010;
use strict;
use warnings;
use lib qw(t);

use Test::Most;
use testlib::Fixtures;
use App::TimeTracker::Proto;
use Path::Class;

{
    my $testdir = testlib::Fixtures::setup_tree('tree1');
    my $p = App::TimeTracker::Proto->new(home=>$testdir);
    my $c = $p->load_config(dir($testdir,(qw(a b c d))));
    is($p->project,'d','project d');
    is($c->{rt}{update_time_worked},1,'deep config');
    is(keys %{$p->config_file_locations},4, '4 config files');
}

testlib::Fixtures::reset_tempdir();
{
    my $testdir = testlib::Fixtures::setup_tree('tree1');
    my $p = App::TimeTracker::Proto->new(home=>$testdir);
    my $c = $p->load_config(dir($testdir,(qw(a b))));
    is($p->project,'b','project b');
    is($c->{rt}{update_time_worked},undef,'not so deep config');
    is(keys %{$p->config_file_locations},2, '2 config files');
}

testlib::Fixtures::reset_tempdir();
{
    my $testdir = testlib::Fixtures::setup_tree('tree1');
    my $p = App::TimeTracker::Proto->new(home=>$testdir);
    my $c = $p->load_config(dir($testdir,(qw(z))));
    is($p->project,'no_project','no_project');
    is(keys %{$p->config_file_locations},0, '0 config files');
}

testlib::Fixtures::reset_tempdir();
{
    @ARGV=('--project','CPANTS');
    my $testdir = testlib::Fixtures::setup_tree('tree1');
    my $p = App::TimeTracker::Proto->new(home=>$testdir);
    my $c = $p->load_config(dir($testdir,(qw(z))));
    is($p->project,'CPANTS','project via argv');
    is(keys %{$p->config_file_locations},0, '0 config files');
}

done_testing();
