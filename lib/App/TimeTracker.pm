package App::TimeTracker;
use strict;
use warnings;
use 5.010;

use File::HomeDir ();
use Data::Dumper;
use Config::Any;

use App::TimeTracker::Data::Project;
use App::TimeTracker::Data::Tag;
use App::TimeTracker::Data::Task;

use Moose;
use MooseX::Types::Path::Class;
with 'MooseX::Getopt';

use Moose::Util::TypeConstraints;
use DateTime;

#coerce 'DateTime' 
#    => from 'Str' 
#    => via {
#        my $raw = shift;
#        my $dt = DateTime->today;
#        my ($h,$m)=split(/:/,$raw);
#        $dt->set(hour=>$h, minute=>$m);
#        return $dt;
#    };


MooseX::Getopt::OptionTypeMap->add_option_type_to_map(
    'App::TimeTracker::Data::Project' => '=s'
);

has 'home' => (
    is=>'ro',
    isa=>'Path::Class::Dir',
    coerce=>1,
    lazy_build=>1,
);

sub _build_home {
    my $self = shift;
    my $home = Path::Class::Dir->new(File::HomeDir->my_home,'.TimeTracker2');
    $home->mkpath unless -d $home;
    return $home;
}

has 'configfile' => (
    is=>'ro',
    isa=>'Path::Class::File',
    coerce=>1,
    lazy_build=>1,
);

sub _build_configfile {
    my $self = shift;
    return $self->home->file('tracker.ini');
}

has 'config' => (
    is=>'ro',
    isa=>'HashRef',
    lazy_build=>1,
    traits => [ 'NoGetopt' ],
);

sub _build_config {
    my $self = shift;
    my $raw_cfany = Config::Any->load_files({
        use_ext         => 1,
        files           => [$self->configfile],
        flatten_to_hash => 1,
    } );
    return $raw_cfany->{$self->configfile};
}

has 'projects' => (
    is => 'ro',
    isa=>'HashRef',
    traits => [ 'NoGetopt' ],
    lazy_build=>1,
);

sub _build_projects {
    my $self = shift;

    my %projects;
    while (my ($name,$conf) = each %{ $self->config->{project}}) {
        $projects{$name} = App::TimeTracker::Data::Project->new({
            name=>$name,    
        });
    }
    return \%projects;
}

coerce 'App::TimeTracker::Data::Project'
    => from 'Str'
    => via {App::TimeTracker::Data::Project->new({name=>$_})
};

has 'project' => (
    isa=>'App::TimeTracker::Data::Project',
    is=>'ro',
    coerce=>1,
    trigger=>\&_check_project,
);
sub _check_project {
    my ($self, $val, $old_val) = @_;
    die "Project >".$val->name."< not in config\n" unless $self->projects->{$val->name};
}

sub run {
    my $self = shift;

    say $self->project->name;

say join(' - ',@{$self->extra_argv});;


    # TODO: dispatch to cmd_* according to argv

#    my $t1 = App::TimeTracker::Data::Tag->new({name=>'test'});
#    my $t2 = App::TimeTracker::Data::Tag->new({name=>'RT1234'});
#
#    my $task = App::TimeTracker::Data::Task->new({
#        start=>$self->now,
#        project=>$self->project,
#        tags=>[$t1, $t2],
#    });
#    
#    say $task->freeze;
#    say $task->storage_location($self->home); 


    my $task = App::TimeTracker::Data::Task->current($self->home);
    say $task->start;
}

sub cmd_start {
    my $self = shift;

    # stop current task
    
    
    
    # start a new one

    my $task = App::TimeTracker::Data::Task->new({
        start=>$self->now,
        project=>$self->project,
    });

    my $task_file = $task->storage_location($self->home)->stringify;
    $task->store($task_file);

    my $fh = $self->home->file('current')->openw;
    say $fh $task_file;
    close $fh;

}

sub cmd_stop {
    my $self = shift;

    # stop current task
}

sub now {
    my $dt = DateTime->now();
    $dt->set_time_zone('local');
    return $dt;
}


1;
