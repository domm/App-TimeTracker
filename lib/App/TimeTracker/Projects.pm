package App::TimeTracker::Projects;

use 5.010;
use warnings;
use strict;

=head1 NAME

App::TimeTracker::Projects - interface to project definitions

=head1 SYNOPSIS

    my $projects = App::TimeTracker::Projects->read( '/path/to/basedir' );
    $projects->add('new_project');
    $projects->write( '/path/to/basedir' );

=cut

use base qw(Class::Accessor);
use File::Spec::Functions qw(splitpath catfile catdir);
use File::HomeDir;
use App::TimeTracker::Exceptions;

__PACKAGE__->mk_accessors(qw(list));

=head1 METHODS

=cut

=head3 read

    my $projects = App::TimeTracker::Projects->read( $basedir );

Reads the list of projects.

=cut

sub read {
    my ( $class, $basedir ) = @_;

    my $path = $class->_file($basedir);

    my %projects;
    if (-r $path) {
        open( my $fh, "<", $path )
            || ATTX::File->throw("Cannot read file $path: $!");
        while ( my $line = <$fh> ) {
            chomp($line);
            next unless $line =~ /\w/;
            $projects{$line} = 1;
        }
    }
    my $self = App::TimeTracker::Projects->new( {list=>\%projects} );

    return $self;

}

=head3 add

    $projects->add('new_project');

Add a new project.

=cut

sub add {
    my ($self, $project) = @_;

    ATTX::BadParams->throw('project must not contain spaces or fancy chars') unless $project =~ /^\w+$/;

    $self->list->{$project}=1;
    return $self;

}

=head4 write

   $projects->write( $basedir );

Serialises the data and writes it to disk.

=cut

sub write {
    my ( $self, $basedir ) = @_;

    ATTX::BadParams->throw("basedir missing")
        unless ( $basedir );

    my $path = $self->_file($basedir);
    
    open(my $fh,">",$path) || ATTX::File->throw("Cannot write to $path: $!");

    foreach my $project (keys %{$self->list}) {
        say $fh $project ;
    }
    
    close $fh;
}

sub _file {
    my ($self, $basedir) = @_;
    return catfile($basedir,'projects');
}

# 1; is boring
q{ listeing to:
    digital mystikz vs loefah & sgt pokes - kiss fm june 2007
};

__END__

=head1 AUTHOR

Thomas Klausner, C<< <domm at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008, 2009 Thomas Klausner, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
