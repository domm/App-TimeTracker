use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'TimeTracker',
    license             => 'perl',
    dist_author         => 'Thomas Klausner <domm@cpan.org>',
    dist_version_from   => 'lib/TimeTracker.pm',
    requires            => {
        'DateTime'          => 0.41, 
        'File::HomeDir'     => 0.67,
        'Class::Accessor'   => 0.31,
        'Exception::Class'  => 1.23,
        'App::Cmd'          => 0.012,
        'DBIx::Class'       => 0.08008,
        'DBD::SQLite'       => 1.14,
    },
    build_requires      => {
        'Test::More'        => 0,
        'Test::NoWarnings'  => 0.084,
    },
    add_to_cleanup      => [ 'TimeTracker-*' ],
);

$builder->create_build_script();
