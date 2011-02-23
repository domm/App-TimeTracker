#!/env perl

use strict;
use warnings;
use 5.010;

use File::Find::Rule;
use Data::Dumper;
use App::TimeTracker::Data::Task;
use DateTime;
use Path::Class;

$|=1;
my ($in, $out) = @ARGV;
die "please specify dir containing old-style files" unless -d $in;
die "please specify dir to contain new-style files" unless -d $out;
$out = Path::Class::dir($out);

my @files = File::Find::Rule->file()->name(qr/\.(done|current)$/)
    ->in( $in );

foreach my $old (@files) {
    open( my $fh, "<", $old ) || die "Cannot read file $old: $!";
    my %data;
    while ( my $line = <$fh> ) {
        chomp($line);
        next unless $line =~ /^(\w+): (.*)/;
        $data{$1} = $2;
    }
    
    my @tags;
    if ($data{tags}) {
        foreach (split(/\s+/,$data{tags})) {
            push(@tags,App::TimeTracker::Data::Tag->new({name=>$_}));
        }
    }

    my $task = App::TimeTracker::Data::Task->new({
        start=>DateTime->from_epoch(epoch=>$data{start}, time_zone=>'local'),
        stop=>DateTime->from_epoch(epoch=>$data{stop}, time_zone=>'local'),
        project=>App::TimeTracker::Data::Project->new({name=>$data{project}}),
        tags=>\@tags,
    });
   
    $task->save($out);
    print '.';
}

