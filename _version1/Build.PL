use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'App::TimeTracker',
    license             => 'perl',
    dist_author         => 'Thomas Klausner <domm@cpan.org>',
    dist_version_from   => 'lib/App/TimeTracker.pm',
    requires            => {
        'DateTime'          => 0.41,
        'DateTime::Format::Strptime'=> 1.0702,
        'File::HomeDir'     => 0.67,
        'Class::Accessor'   => 0.31,
        'Exception::Class'  => 1.23,
        'App::Cmd'          => 0.012,
        'DateTime::Format::ISO8601'=>'0.06',
    },
    build_requires      => {
        'Test::More'        => 0,
        'Test::NoWarnings'  => 0.084,
        'Test::Most'      => 0,
    },
    add_to_cleanup      => [ 'App::TimeTracker-*' ],
);

$builder->create_build_script();
