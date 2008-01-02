use strict;
use warnings;
use Module::Build;
use File::HomeDir;
use File::Spec::Functions;

my $builder = Module::Build->new(
    module_name         => 'TimeTracker',
    license             => 'perl',
    dist_author         => 'Thomas Klausner <domm@cpan.org>',
    dist_version_from   => 'lib/TimeTracker.pm',
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'TimeTracker-*' ],
);

my $default_home;
eval { require TimeTracker::ConfigData };
if ($@) {
    $default_home = catdir( File::HomeDir->my_home,'time_tracker' ),
} else {
    $default_home = TimeTracker::ConfigData->config( 'home' );
}


my $home = $builder->prompt("Directory to store TimeTracker data:",$default_home);
$builder->config_data('home'=>$home);

$builder->create_build_script();
