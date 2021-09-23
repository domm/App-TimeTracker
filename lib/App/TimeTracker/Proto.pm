package App::TimeTracker::Proto;

# ABSTRACT: App::TimeTracker Proto Class
# VERSION

use strict;
use warnings;
use 5.010;

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
use App::TimeTracker::Constants qw(MISSING_PROJECT_HELP_MSG);

has 'home' => (
    is         => 'ro',
    isa        => 'Path::Class::Dir',
    lazy_build => 1,
);

sub _build_home {
    my ( $self, $home ) = @_;

    $home ||=
        Path::Class::Dir->new( $ENV{TRACKER_HOME} || (File::HomeDir->my_home, '.TimeTracker' ));
    unless (-d $home) {
        $home->mkpath;
        $self->_write_config_file_locations( {} );
        my $fh = $self->global_config_file->openw;
        print $fh $self->json_decoder->encode( {} );
        close $fh;
    }
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
    if ( -e $file && -s $file ) {
        my $decoded_json;
        try {
            $decoded_json = decode_json( $file->slurp );
        }
        catch {
            error_message( "Could not json decode '%s'.\nError: '%s'", $file, $_ );
            exit 1;
        };
        return $decoded_json;
    }
    else {
        return {};
    }
}

has 'project' => ( is => 'rw', isa => 'Str', predicate => 'has_project' );

has 'json_decoder' => ( is => 'ro', isa => 'JSON::XS', lazy_build => 1 );

sub _build_json_decoder {
    my $self = shift;
    return JSON::XS->new->utf8->pretty->relaxed;
}

sub run {
    my $self = shift;

    try {
        my $config = $self->load_config;
        my $class  = $self->setup_class($config);
        $class->name->new_with_options( {
                home   => $self->home,
                config => $config,
                (   $self->has_project
                    ? ( _current_project => $self->project )
                    : ()
                ),
            } )->run;
    }
    catch {
        my $e = $_;
        if ( blessed $e && $e->can('message') ) {
            warn $e->message, "\n";
        }
        else {
            warn "$e\n";
        }
    }
}

sub setup_class {
    my ( $self, $config, $command ) = @_;

    # unique plugins
    $config->{plugins} ||= [];
    my %plugins_unique = map { $_ => 1 } @{ $config->{plugins} };
    $config->{plugins} = [ keys %plugins_unique ];

    my $class = Moose::Meta::Class->create_anon_class(
        superclasses => ['App::TimeTracker'],
        roles        => [
            map { 'App::TimeTracker::Command::' . $_ } 'Core',
            @{ $config->{plugins} }
        ],
    );

    my %commands;
    foreach my $method ( $class->get_all_method_names ) {
        next unless $method =~ /^cmd_/;
        $method =~ s/^cmd_//;
        $commands{$method} = 1;
    }

    my $load_attribs_for_command;
    foreach my $cmd ( $command ? $command : @ARGV) {
        if ( defined $commands{$cmd} ) {
            $load_attribs_for_command = '_load_attribs_' . $cmd;

            if ($cmd eq 'start' && !$self->has_project) {
                error_message( MISSING_PROJECT_HELP_MSG );
                exit;
            }

            last;
        }
    }
    if (   $load_attribs_for_command
        && $class->has_method($load_attribs_for_command) )
    {
        $class->name->$load_attribs_for_command($class, $config);
    }
    $class->make_immutable();
    return $class;
}

sub load_config {
    my ($self, $dir, $project) = @_;
    $dir ||= Path::Class::Dir->new->absolute;
    my $config = {};
    my @used_config_files;
    my $cfl = $self->config_file_locations;

    my $projects   = $self->slurp_projects;
    my $opt_parser = Getopt::Long::Parser->new(
        config => [qw( no_auto_help pass_through )] );
    $opt_parser->getoptions( "project=s" => \$project );

    if ( defined $project ) {
        $self->project($project);
        if ( my $project_config = $projects->{$project} ) {
            $dir = Path::Class::Dir->new($project_config);
        }
    }
    if ($dir) {
        my $try = 0;
        $dir = $dir->absolute;
    WALKUP: while ( $try++ < 30 ) {
            my $config_file = $dir->file('.tracker.json');
            my $this_config;
            if ( -e $config_file ) {
                push( @used_config_files, $config_file->stringify );
                $this_config = $self->slurp_config($config_file);
                $config = merge( $config, $this_config );

                my @path    = $config_file->parent->dir_list;
                my $project = exists $this_config->{project} ? $this_config->{project} : $path[-1];
                $cfl->{$project} = $config_file->stringify;
                $self->project($project)
                    unless $self->has_project;
            }
            last WALKUP if $dir->parent eq $dir;

            if ( my $parent = $this_config->{'parent'} ) {
                if ( $projects->{$parent} ) {
                    $dir = Path::Class::file( $projects->{$parent} )->parent;
                }
                else {
                    $dir = $dir->parent;
                    say
                        "Cannot find project >$parent< that's specified as a parent in $config_file";
                }
            }
            else {
                $dir = $dir->parent;
            }
        }
    }
    $self->_write_config_file_locations($cfl);

    if ( -e $self->global_config_file ) {
        push( @used_config_files, $self->global_config_file->stringify );
        $config = merge( $config,
            $self->slurp_config( $self->global_config_file ) );
    }
    $config->{_used_config_files} = \@used_config_files;

    return $config;
}

sub _write_config_file_locations {
    my ( $self, $cfl ) = @_;
    my $fh = $self->home->file('projects.json')->openw;
    print $fh $self->json_decoder->encode( $cfl
            || $self->config_file_locations );
    close $fh;
}

sub slurp_config {
    my ( $self, $file ) = @_;
    try {
        my $content = $file->slurp();
        return $self->json_decoder->decode($content);
    }
    catch {
        error_message( "Cannot parse config file $file:\n%s", $_ );
        exit;
    };
}

sub slurp_projects {
    my $self = shift;
    my $file = $self->home->file('projects.json');
    unless ( -e $file && -s $file ) {
        error_message("Cannot find projects.json\n");
        exit;
    }
    my $projects = decode_json( $file->slurp );
    return $projects;
}

1;

__END__

=head1 DESCRIPTION

Ugly internal stuff, see L<YAPC::Europe 2011 talk...|https://domm.plix.at/talks/2011_riga_app_timetracker/>
