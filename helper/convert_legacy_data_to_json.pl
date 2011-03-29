#!/env perl

use strict;
use warnings;
use 5.010;

use File::Find::Rule;
use Data::Dumper;
use App::TimeTracker::Data::Task;
use DateTime;
use Path::Class;
use Try::Tiny;

$|=1;
my ($in, $out) = @ARGV;
die "please specify dir containing old-style files" unless -d $in;
die "please specify dir to contain new-style files" unless -d $out;
$out = Path::Class::dir($out);

my @files = File::Find::Rule->file()->name(qr/\.(done|current)$/)
    ->in( $in );

foreach my $old (@files) {
    open( my $fh, "<", $old ) || die "Cannot read file $old: $!";

    try {

        my %data;
        while ( my $line = <$fh> ) {
            chomp($line);
            next unless $line =~ /^(\w+): (.*)/;
            $data{$1} = $2;
        }

        my @tags;
        if ($data{tags}) {
            foreach (split(/\s+/,$data{tags})) {
                push(@tags,$_);
            }
        }

        my $task = App::TimeTracker::Data::Task->new({
                start=>DateTime->from_epoch(epoch=>$data{start}, time_zone=>'local'),
                stop=>DateTime->from_epoch(epoch=>$data{stop}, time_zone=>'local'),
                project=>$data{project},
                tags=>\@tags,
        });

        $task->save($out);
        print '.';
    }
    catch {
        die "An error occurred converting $old";
    }
}

say "Finished processing " . scalar @files . " historic Tasks";
