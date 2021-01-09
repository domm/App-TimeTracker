use 5.010;
use strict;
use warnings;
use lib qw(t);

use Test::Most;
use testlib::Fixtures;
use App::TimeTracker::Proto;
use Path::Class;

{
    explain('Test1');
    my $testdir = testlib::Fixtures::setup_tree('tree1');
    my $p       = App::TimeTracker::Proto->new( home => $testdir );
    my $c       = $p->load_config( dir( $testdir, (qw(a b c d)) ) );
    is( $p->project,                         'd', 'project d' );
    is( $c->{rt}{update_time_worked},        1,   'deep config' );
    is( keys %{ $p->config_file_locations }, 5,   '5 config files' );
}

testlib::Fixtures::reset_tempdir();
{
    explain('Test2');
    my $testdir = testlib::Fixtures::setup_tree('tree1');
    my $p       = App::TimeTracker::Proto->new( home => $testdir );
    my $c       = $p->load_config( dir( $testdir, (qw(a b)) ) );
    is( $p->project,                         'b',   'project b' );
    is( $c->{rt}{update_time_worked},        undef, 'not so deep config' );
    is( keys %{ $p->config_file_locations }, 3,     '3 config files' );
}

testlib::Fixtures::reset_tempdir();
{
    explain('Test3');
    my $testdir = testlib::Fixtures::setup_tree('tree1');
    my $p       = App::TimeTracker::Proto->new( home => $testdir );
    my $c       = $p->load_config( dir( $testdir, (qw(z)) ) );
    is( $p->project,                         undef, 'Project not defined' );
    is( keys %{ $p->config_file_locations }, 1,     '1 config files' );
}

testlib::Fixtures::reset_tempdir();
{
    explain('Test4');
    @ARGV = ( '--project', 'test' );
    my $testdir = testlib::Fixtures::setup_tree('tree1');
    my $p       = App::TimeTracker::Proto->new( home => $testdir );
    my $c       = $p->load_config( dir( $testdir, (qw(z)) ) );
    is( $p->project,                         'test', 'project via argv' );
    is( keys %{ $p->config_file_locations }, 1,      '1 config files' );
}

done_testing();
