package App::TimeTracker::Task;

use 5.010;
use warnings;
use strict;

=head1 NAME

App::TimeTracker::Task - interface to one task

=head1 SYNOPSIS

    my $task = App::TimeTracker::Task->new({
        start   => '1232010055',
        project => 'TimeTracker',
        tags    => \@tags,
        basedir =>'/path/to/basedir',
    });
    $task->stop_it;
    $task->write(  );  


    my $task = App::TimeTracker::Task->read('/path/to/file');
    say $task->start;       # epoche
    say $task->is_active;   # 1 or 0
    say $task->duration;    # in seconds

=cut

use base qw(Class::Accessor);
use DateTime;
use DateTime::Format::Strptime;
use File::Spec::Functions qw(splitpath catfile catdir);
use File::HomeDir;
use File::Path;
use App::TimeTracker::Exceptions;
use File::Spec::Functions qw(catfile catdir);


__PACKAGE__->mk_accessors(qw(start stop project tags active _path basedir));

=head1 METHODS

=cut

=head3 new

    my $task = App::TimeTracker::App->new( $data );

Initiate a new task object.

=cut

sub new {
    my ($class, $data) = @_;
    $data ||={};
    my $self = bless $data, $class;
    
    $self->start(
        DateTime->from_epoch( epoch => $self->start, time_zone => 'local' ) )
        if $self->start;
    $self->stop(
        DateTime->from_epoch( epoch => $self->stop, time_zone => 'local' ) )
        if $self->stop;
    $self->project('unknown') unless $self->project;
    return $self;
}

=head3 stop_it

    $self->stop_it;
    $self->stop_it( $dt );

Stop this task, either at the specified C<$epoche>, or C<now()>. Throws an exception if the task is already stopped.

Returns C<$self> for method chaining.

=cut

sub stop_it {
    my ($self, $stop) = @_;
    $stop ||= time();

    $self->stop($stop);
    my $path=$self->_path;
    unlink($path);
    $path=~s/current$/done/;
    $self->_path($path);
    $self->write;
    return $self;

}

=head3 read

    my $task = App::TimeTracker::Task->read( $path );

Reads the specified file, parses it, generates a new object and returns the object.

=cut

sub read {
    my ( $class, $path ) = @_;

    ATTX::File->throw("Cannot find file $path") unless -r $path;

    open( my $fh, "<", $path )
        || ATTX::File->throw("Cannot read file $path: $!");
    my %data;
    while ( my $line = <$fh> ) {
        chomp($line);
        next unless $line =~ /^(\w+): (.*)/;
        $data{$1} = $2;
    }

    my $task = App::TimeTracker::Task->new( \%data );
    $task->_path($path);

    return $task;

}

=head4 write

   $task->write;
   $task->write( $basedir );

Serialises the data and writes it to disk.

If you got the object via L<read>, you don't need to specifiy the 
C<$basedir>. If this is the first time you want to C<write> the 
object, the C<$basedir> is neccesary.

=cut

sub write {
    my ( $self ) = @_;

    ATTX::BadParams->throw("basedir missing and _path not set")
        unless ( $self->basedir || $self->_path );

    unless ( $self->_path ) {
        my $dir = catdir($self->basedir,$self->_calc_dir);
        unless (-d $dir) {
            mkpath($dir) || ATTX::File->throw("Cannot make dir $dir");
        }
        $self->_path( catfile($dir, $self->_calc_filename ));
    }
    my $file = $self->_path;
    open(my $fh,">",$file) || ATTX::File->throw("Cannot write to $file: $!");
    foreach my $fld (qw(project tags)) {
        say $fh "$fld: ".($self->$fld || '') ;
    }
    foreach my $fld (qw(start stop)) {
        say $fh "$fld: ".($self->$fld ? $self->$fld->epoch : '');
    }
    
    close $fh;
}

=head set_current

    $task->set_current;

Makes $task the current task

=cut

sub set_current {
    my ($self ) = @_;
    my $current = $self->_current;

    $self->remove_suspended;

    open( my $fh, ">", $current )
        || ATTX::File->throw("Cannot write file $current: $!");
    say $fh $self->_calc_path;
    close $fh;
    return $self;
}

sub get_current {
    my ($class, $basedir ) = @_;
    my $current = $class->_current($basedir);
    return unless -e $current;

    open( my $fh, "<", $current )
        || ATTX::File->throw("Cannot read file $current: $!");
    my $path = <$fh>;
    chomp($path);
    return $class->read($path);
}


sub remove_suspended {
    my ($self ) = @_;
    my $suspended = $self->_suspended;

    unlink($suspended) if -e $suspended;
    return $self;
}


sub stop_current {
    my ($class, $basedir, $stop) = @_;

    my $current = $class->get_current($basedir);
    return unless $current;
    return $current->stop_it($stop);
}


=head3 get_printable_interval

    my $string = $self->get_printable_interval([$start, stop]);

Returns a string like "worked 30 minutes, 23 seconds on Task (foo bar)"

=cut

sub get_printable_interval {
    my ($self,$start,$stop)=@_;
    $start ||= $self->start;
    $stop ||= $self->stop;
    
    my $worked = $stop - $start;
    return $self->beautify_duration($worked) . " on " . $self->project . $self->nice_tags;
}

=head3 beautify_duration

    my $nice_message = $self->beautify_duration($duration);

Turns an DateTime::Duration object into a nicer representation ("4 minutes, 31 seconds")

=cut

sub beautify_duration {
    my ( $self, $delta ) = @_;

    my $s=$delta->delta_seconds;
    my $m=$delta->delta_minutes;
    return $self->beautify_seconds($s + ($m*60));
}

=head3 beautify_seconds

    my $nice_message = $self->beautify_seconds($seconds);

Turns an amount of seconds into a nicer representation ("4 minutes, 31 seconds")

=cut

sub beautify_seconds {
    my ( $self, $s ) = @_;

    my ($m,$h);

    if ($s>=60) {
        $m=int($s / 60);
        $s=$s - ( $m * 60);
    }
    if ($m && $m>=60) {
        $h = int( $m / 60 );
        $m = $m - ( $h * 60 );
    }
    
    my $result;
    if ($h) {
        $result="$h hour". ( $h == 1 ? '' : 's' ).", ";
    }
    if ($m) {
        $result.="$m minute". ( $m == 1 ? '' : 's' ).", ";
    }
    $result.="$s second". ( $s == 1 ? '' : 's' );
    return $result;
}

sub nice_tags {
    my $self = shift;
    my $t = $self->tags;
    return '' unless $t;
    return ' ('.$t.')';
}


sub _calc_filename {
    my $self = shift;

    return
          $self->start->strftime("%d-%H%M%S") . '-'
        . $self->project . '.'
        . ( $self->stop ? 'done' : 'current' );

}

sub _calc_dir {
    my $self=shift;
    my $start = $self->start;
    my @dir = (split(/-/,$start->strftime("%Y-%m")));
    wantarray ? @dir : catfile(@dir);
}

sub _calc_path {
    my $self=shift;
    return catfile($self->basedir,$self->_calc_dir,$self->_calc_filename)
}

sub _current {
    my ($self, $basedir)=@_;
    return catfile ($basedir || $self->basedir,'current');
}

sub _suspended {
    my ($self)=@_;
    return catfile ($self->basedir,'suspended');
}

# 1; is boring
q{ listeing to:
    Beatles on the radio in the waiting room of the Allergieambulanz
};

__END__

=head1 AUTHOR

Thomas Klausner, C<< <domm at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008, 2009 Thomas Klausner, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
