use 5.010;
use strict;
use warnings;
use lib qw(t);

use Test::Most;
use Test::Trap;
use Test::File;
use testlib::FakeHomeDir;
use Term::ANSIColor qw(colorstrip);
use App::TimeTracker::Proto;

my $tmp  = testlib::Fixtures::setup_tempdir;
my $home = $tmp->subdir('.TimeTracker');
$home->mkpath;

my $proto = App::TimeTracker::Proto->new( home => $home, project => '' );
$proto->load_config($home);
my $config = {};

# start
{
    @ARGV = ('start');
    my $class = $proto->setup_class($config);
    my $t     = $class->name->new(
        home   => $home,
        config => $config,
    );
    trap { $t->cmd_start };
    my $expected_start_help_output = <<'EOF';
Could not find project; did you forget to run `tracker init`?
If not, use --project or chdir into the project directory.
EOF
    is( colorstrip( $trap->stdout ),
        $expected_start_help_output, 'Start command help output with undefined project' );
}

done_testing();
