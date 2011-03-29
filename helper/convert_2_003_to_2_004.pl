#!/env perl

use strict;
use warnings;
use 5.010;

use File::Find::Rule;
use Data::Dumper;
use App::TimeTracker::Data::Task;
use App::TimeTracker::Proto;
use DateTime;
use Path::Class;
use Try::Tiny;
use JSON::XS;
use Path::Class;

$|=1;
my $app = App::TimeTracker::Proto->new;
my @files = File::Find::Rule->file()->name(qr/\.trc$/)
    ->in( $app->home );

foreach my $old (@files) {
    print '.';
    my $json_old = Path::Class::File->new($old)->slurp;
    my $hash = decode_json($json_old);
    if ($hash->{project} && ref($hash->{project}) eq 'HASH') {
        my $p = delete $hash->{project};
        $hash->{project}=$p->{name};
    }
    my $tags = $hash->{tags};
    if (ref($tags) eq 'ARRAY' && @$tags) {
        my @new_tags;
        foreach my $t (@$tags) {
            if (ref($t) eq 'HASH') {
                push(@new_tags,$t->{name});
            }
            else {
                push(@new_tags,$t);
            }
        }
        $hash->{tags}=\@new_tags;
    }

    open(my $out,">",$old);
    print $out encode_json($hash);
}

