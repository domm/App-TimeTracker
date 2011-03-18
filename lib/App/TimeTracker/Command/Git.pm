package App::TimeTracker::Command::Git;
use strict;
use warnings;
use 5.010;

# ABSTRACT: TimeTracker Git plugin

use Moose::Role;
use Git::Repository;

has 'branch' => (is=>'rw',isa=>'Str');
has 'merge' => (is=>'ro',isa=>'Bool');
has 'nobranch' => (is=>'ro',isa=>'Bool');

after 'cmd_start' => sub {
    my $self = shift;

    return unless $self->branch;
    return if $self->nobranch;

    my $r = Git::Repository->new( work_tree => '.' );
    my $branch = $self->branch;
    my %branches = map { s/^\s+//; $_=>1 } $r->run('branch');

    if ($branches{'* '.$branch}) {
        say "Already on branch $branch";
        return;
    }

    if (!$branches{$branch}) {
        $r->command('branch',$branch);
    }

    print $r->command('checkout',$branch)->stderr->getlines;
};

after cmd_stop => sub {
    my $self = shift;
    return unless $self->merge;

    my $r = Git::Repository->new( work_tree => '.' );
    my $branch = $self->branch;
    my %branches = map { s/^\s+//; $_=>1 } $r->run('branch');

    unless ($branches{'* '.$branch}) {
        say "Not in branch $branch, won't merge.";
        return;
    }
    my $tags = join(', ',map { $_->name } @{$self->tags}) || '';
    $r->command('checkout','master');
    $r->command("merge",$branch,"--no-ff",'-m',"implemented $branch $tags");
};

sub cmd_merge {
    my $self = shift;
    
    my $r = Git::Repository->new( work_tree => '.' );
    my $branch = $self->branch;
    my %branches = map { s/^\s+//; $_=>1 } $r->run('branch');

    unless ($branches{'* '.$branch}) {
        say "Not in branch $branch, won't merge.";
        return;
    }
    my $tags = join(', ',map { $_->name } @{$self->tags}) || '';
    $r->command('checkout','master');
    $r->command("merge",$branch,"--no-ff",'-m',"implemented $branch $tags");

}

no Moose::Role;
1;

__END__

