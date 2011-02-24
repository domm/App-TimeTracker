package App::TimeTracker::Proto;
use strict;
use warnings;
use 5.010;

use Moose;
use MooseX::Types::Path::Class;
use File::HomeDir ();
use Path::Class;
use Hash::Merge qw();
use JSON;

has 'home' => (
    is         => 'ro',
    isa        => 'Path::Class::Dir',
    lazy_build => 1,
);
sub _build_home {
    my $self = shift;
    my $home =
        Path::Class::Dir->new( File::HomeDir->my_home, '.TimeTracker' );
    $home->mkpath unless -d $home;
    return $home;
}

has 'global_configfile' => (
    is         => 'ro',
    isa        => 'Path::Class::File',
    lazy_build => 1,
);
sub _build_global_configfile {
    my $self = shift;
    return $self->home->file('tracker.json');
}

has 'configfile' => (
    is         => 'ro',
    isa        => 'Path::Class::File',
    lazy_build => 1,
);
sub _build_configfile {
    my $self = shift;
    my $dir  = Path::Class::Dir->new->absolute;
    my $file;
    while ( !$file ) {
        if ( -e $dir->file('.tracker.json') ) {
            $file = $dir->file('.tracker.json');
        }
        else {
            $dir = $dir->parent;
        }

        return Path::Class::file('/nosuchfile')
            if scalar $dir->dir_list <= 1;
    }
    return $file;
}

sub run {
    my $self = shift;

    my @configs;
    push( @configs, decode_json( $self->configfile->slurp ) )
        if -e $self->configfile;
    push( @configs, decode_json( $self->global_configfile->slurp ) )
        if -e $self->global_configfile;
    my $config = Hash::Merge::merge(@configs);

    my $class = Moose::Meta::Class->create_anon_class(
        superclasses => ['App::TimeTracker'],
        roles        => [
            map { 'App::TimeTracker::Command::' . $_ } @{ $config->{Plugins} }
        ],
    );

    my $current_project;
    if ($self->configfile =~/nosuchfile/) {
        $current_project = 'no project';
    }
    else {
        my @dir_tree        = $self->configfile->parent->dir_list;
        $current_project = pop(@dir_tree);
    }

    $class->name->new_with_options( {
            home            => $self->home,
            config          => $config,
            _currentproject => $current_project,
        } )->run;
}

1;
