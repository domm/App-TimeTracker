package App::TimeTracker::Proto;
use strict;
use warnings;
use 5.010;

# ABSTRACT: TimeTracker Proto Class

use Moose;
use MooseX::Types::Path::Class;
use File::HomeDir ();
use Path::Class;
use Hash::Merge qw();
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

has 'configfile' => (
    is         => 'ro',
    isa        => 'Path::Class::File',
    lazy_build => 1,
);
sub _build_configfile {
    my $self = shift;
    return $self->home->file('tracker.json');
}

has 'project' => (is=>'rw',isa=>'Str',documentation=>'Project name');

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
    my $self = shift;

    my $projects = decode_json( $self->configfile->slurp );
    my $project;
    
    my @argv = @ARGV;
    while (@argv) { # check if project is specified via commandline
        my $arg = shift(@argv);
        if ($arg eq '--project') {
            my $p = lc(shift(@argv));
            foreach (keys %$projects) {
                if (lc($_) eq $p) {
                    $project = $_;
                    last; 
                }
            }
            unless (defined $project) {
                say "Cannot find project $p in config.";
            }
        }
    }
    unless (defined $project) { # try to figure out project via current dir
        my @path = Path::Class::Dir->new->absolute->dir_list;
        while (my $dir = pop(@path)) {
            if ($projects->{$dir}) {
                $project = $dir;
                last;
            }
        }
    }
    unless (defined $project) { # try to figure out project via current task
        my $current =  App::TimeTracker::Data::Task->_load_from_link($self->home,'current');
        if (defined $current) {
            $project = $current->project;
        }
    }
    
    my $config;
    my %seen;
    if (defined $project) {
        $self->project($project);

        my $merger = Hash::Merge->new('RIGHT_PRECEDENT');
        $config = $projects->{$project};
        my $parent = $config->{'parent'};
        while ($parent) {
            croak "Endless recursion on parent $parent, aborting!" if $seen{$parent}++;
            my $parent_config = $projects->{$parent};
            $config = $merger->merge($parent_config,$config);
            $parent = $parent_config->{'parent'};
        }
    } else {
        $config = $projects->{default} || {};
        $self->project('_no_project');
    }
    $config->{_projects} = $projects;
    return $config;
}

1;
