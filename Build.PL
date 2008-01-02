use strict;
use warnings;
use Module::Build;

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

$builder->create_build_script();
