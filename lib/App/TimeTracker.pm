package App::TimeTracker;
use strict;
use warnings;
use 5.010;

use File::HomeDir;
use Moose;
use MooseX::Types::Path::Class;
with 'MooseX::SimpleConfig';
with 'MooseX::Getopt';


has 'home' => (
    is=>'ro',
    isa=>'Path::Class::Dir',
    coerce=>1,
    lazy_build=>1,
);

sub _build_home {
    my $self = shift;
    my $home = Path::Class::Dir->new(File::HomeDir->my_home,'.TimeTracker2');
    warn $home;
    $home->mkpath unless -d $home;
    return $home;
}

has '+configfile' => (
    default=>sub { Path::Class::File->new(File::HomeDir->my_home,'.TimeTracker2','tracker.ini') }
);



has 'foo'=>(isa=>'Str',is=>'rw',default=>'default');

sub run {
    my $self = shift;

}


1;
