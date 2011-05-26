package File::HomeDir;
use strict;
use warnings;
use File::Temp qw(tempdir);
use Path::Class::Dir;

$INC{'File/HomeDir.pm'}=1;
my $tmp = Path::Class::Dir->new(tempdir(CLEANUP=>$ENV{NO_CLEANUP} ? 0 : 1));

sub my_home {
    return $tmp;
}

1;
