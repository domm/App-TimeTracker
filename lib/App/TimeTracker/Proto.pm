package App::TimeTracker::Proto;
use strict;
use warnings;
use 5.010;

# ABSTRACT: App::TimeTracker Proto Class

use App::TimeTracker::Utils qw(error_message);

use Moose;
use MooseX::Types::Path::Class;
use File::HomeDir ();
use Path::Class;
use Hash::Merge qw(merge);
use JSON::XS;
use Carp;
use Try::Tiny;

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

has 'json_decoder' => (is=>'ro',isa=>'JSON::XS',lazy_build=>1);
sub _build_json_decoder {
    my $self = shift;
    return JSON::XS->new->utf8->pretty->relaxed;
}

sub run {
    my $self = shift;

    my $config = $self->load_config;

    # unique plugins
    $config->{plugins} ||= [];
    my %plugins_unique = map {$_ =>  1} @{$config->{plugins}};
    $config->{plugins} = [ keys %plugins_unique ];

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
            ($self->has_project ? (_current_project=> $self->project) : ()),
        } )->run;
}

sub load_config {
    my ($self, $dir) = @_;
    $dir ||= Path::Class::Dir->new->absolute;
    my $config={};
    my @used_config_files;
    my $cfl = $self->config_file_locations;

    my $project;
    my $opt_parser = Getopt::Long::Parser->new( config => [ qw( no_auto_help pass_through ) ] );
    $opt_parser->getoptions( "project=s" => \$project );

    if (defined $project) {
        my $file = $self->home->file('projects.json');
        return unless -e $file && -s $file;
        my $projects = decode_json($file->slurp);
        if (my $project_config = $projects->{$project}) {
            $self->project($project);
            $dir = Path::Class::Dir->new($project_config);
        } else {
            my $error = "Cannot find project: $project\nKnown projects are:\n";
            foreach (keys %$projects) {
                $error .= "   ".$_."\n";
            }
            error_message($error);
        }
    }

    WALKUP: while (1) {
        my $config_file = $dir->file('.tracker.json');
        if (-e $config_file) {
            push(@used_config_files, $config_file->stringify);
            $config = merge($config, $self->slurp_config($config_file));

            my @path = $config_file->parent->dir_list;
            my $project = $path[-1];
            $cfl->{$project}=$config_file->stringify;

            $self->project($project) 
                unless $self->has_project;
        }
        last WALKUP if $dir->parent eq $dir;
        $dir = $dir->parent;
    }

    $self->_write_config_file_locations($cfl);

    if (-e $self->global_config_file) {
        push(@used_config_files, $self->global_config_file->stringify);
        $config = merge($config, $self->slurp_config( $self->global_config_file ));
    }
    $config->{_used_config_files} = \@used_config_files;

    return $config;
}

sub _write_config_file_locations {
    my ($self, $cfl) = @_;
    my $fh = $self->home->file('projects.json')->openw;
    print $fh $self->json_decoder->encode($cfl || $self->config_file_locations);
    close $fh;
}

sub slurp_config {
    my ($self, $file ) = @_;
    try {
        my $content = $file->slurp( iomode => '<:encoding(UTF-8)' );
        return $self->json_decoder->decode( $content );
    }
    catch {
        error_message("Cannot parse config file $file:\n%s",$_)
    };
}

1;

__END__

=head1 DESCRIPTION

ugly internal stuff, see upcoming YAPC::Europe 2011 talk...

