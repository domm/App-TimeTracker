package App::TimeTracker::Proto;
use strict;
use warnings;
use 5.010;

# ABSTRACT: TimeTracker Proto Class

use Moose;
use MooseX::Types::Path::Class;
use File::HomeDir ();
use Path::Class;
use Hash::Merge qw(merge);
use JSON;
use Carp;

use App::TimeTracker::Data::Task;

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

has 'global_config_file' => (
    is         => 'ro',
    isa        => 'Path::Class::File',
    lazy_build => 1,
);
sub _build_global_config_file {
    my $self = shift;
    return $self->home->file('tracker.json');
}

has 'config_file_locations' => (
    is         => 'ro',
    isa        => 'HashRef',
    lazy_build => 1,
);
sub _build_config_file_locations {
    my $self = shift;
    my $file = $self->home->file('projects.json');
    if (-e $file && -s $file) {
        return decode_json($file->slurp);
    }
    else {
        return {};
    }
}

has 'project' => (is=>'rw',isa=>'Str',predicate => 'has_project');

sub run {
    my $self = shift;

    my $config = $self->load_config;

    my $class = Moose::Meta::Class->create_anon_class(
        superclasses => ['App::TimeTracker'],
        roles        => [
            map { 'App::TimeTracker::Command::' . $_ } 'Core', @{ $config->{plugins} }
        ],
    );

    my %commands;
    foreach my $method ($class->get_all_method_names) {
        next unless $method =~ /^cmd_/;
        $method =~ s/^cmd_//;
        $commands{$method}=1;
    }
    my $load_attribs_for_command;
    foreach (@ARGV) {
        if ($commands{$_}) {
            $load_attribs_for_command='_load_attribs_'.$_;
            last;
        }
    }
    if ($load_attribs_for_command && $class->has_method($load_attribs_for_command)) {
        $class->name->$load_attribs_for_command($class);
    }

    $class->name->new_with_options( {
            home            => $self->home,
            config          => $config,
            _currentproject => $self->project,
        } )->run;
}

sub load_config {
    my ($self, $dir) = @_;
    $dir ||= Path::Class::Dir->new->absolute;
    my $config={};

    WALKUP: while (1) {
        my $config_file = $dir->file('.tracker.json');
        if (-e $config_file) {
            my $this_config = decode_json( $config_file->slurp );
            $config = merge($config, $this_config);

            my @path = $config_file->parent->dir_list;
            my $project = $path[-1];
            $self->config_file_locations->{$project}=$config_file->stringify;

            $self->project($project) unless $self->has_project;
        }
        last WALKUP if $dir->parent eq $dir;
        $dir = $dir->parent;
    }

    $self->_write_config_file_locations;

    if (-e $self->global_config_file) {
        warn $self->global_config_file
        $config = merge($config, decode_json($self->global_config_file->slurp));
    }
    
    unless ($self->has_project) {
        $self->find_project_in_argv;
    }

    return $config;
}

sub find_project_in_argv {
    my $self = shift;

    my @argv = @ARGV;
    while (@argv) {
        my $arg = shift(@argv);
        if ($arg eq '--project') {
            my $p = shift(@argv);
            $self->project($p);
            return;
        }
    }
    $self->project('no_project');
}

sub _write_config_file_locations {
    my $self = shift;
    my $fh = $self->home->file('projects.json')->openw;
    print $fh encode_json($self->config_file_locations);
    close $fh;
}

1;
