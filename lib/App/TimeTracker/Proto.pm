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

has 'project' => (is=>'rw',isa=>'Str');

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

    my $all_config = decode_json( $self->configfile->slurp );
    my %projects;
    foreach my $job (keys %{$all_config->{jobs}}) {
        foreach my $project (keys %{$all_config->{jobs}{$job}{projects}}) {
            $projects{$project} = $job;
        }
    }

    my $project;
    my @argv = @ARGV;
    while (@argv) { # check if project is specified via commandline
        my $arg = shift(@argv);
        if ($arg eq '--project') {
            my $p = lc(shift(@argv));
            foreach (keys %projects) {
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
        my $cwd = Path::Class::Dir->new->absolute;
        my $regex = join('|',sort { length($b) <=> length($a) } keys %projects);
        if ($cwd =~ m{/($regex)}i) {
            my $p = lc($1);
            foreach (keys %projects) {
                if (lc($_) eq $p) {
                    $project = $_;
                    last; 
                }
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
    if (defined $project) {
        $self->project($project);
        my $job = $projects{$project};
        # merge project <- job <- global config
        $config = Hash::Merge::merge($all_config->{'jobs'}{$job}{'projects'}{$project},$all_config->{'jobs'}{$job}{'job'});
        $config = Hash::Merge::merge($config,$all_config->{'global'});
    } else {
        say "Cannot figure out project. Please check config and/or --project";
        $config = $all_config->{'global'};
        $self->project('_no_project');
    }
    
    $config->{project2job}=\%projects;
    return $config;
}

1;
