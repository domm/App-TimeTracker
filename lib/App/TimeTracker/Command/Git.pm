package App::TimeTracker::Command::Git;
use strict;
use warnings;
use 5.010;

# ABSTRACT: TimeTracker Git plugin

use Moose::Role;
use Git::Repository;

has 'branch' => (
    is=>'rw',
    isa=>'Str', 
    documentation=>'Git: Branch name',
);
has 'merge' => (
    is=>'ro',
    isa=>'Bool', 
    documentation=>'Git: Merge after stoping'
);
has 'no_branch' => (
    is=>'ro',
    isa=>'Bool', 
    documentation=>'Git: Do not create a branch',
    traits    => [ 'Getopt' ],
    cmd_aliases => [qw/nobranch/],
);

after 'cmd_start' => sub {
    my $self = shift;

    return unless $self->branch;
    return if $self->no_branch;

    my $r = Git::Repository->new( work_tree => '.' );
    my $branch = $self->branch;
    my %branches = map { s/^\s+//; $_=>1 } $r->run('branch');

    if ($branches{'* '.$branch}) {
        say "Already on branch $branch";
        return;
    }

    if (!$branches{$branch}) {
        print $r->command('checkout', '-b', $branch)->stderr->getlines;
    }
    else {
        print $r->command('checkout',$branch)->stderr->getlines;
    }
};

after 'cmd_continue' => sub {
    my $self = shift;
    
    return unless $self->branch;
    return if $self->no_branch;
    
    my $r = Git::Repository->new( work_tree => '.' );
    print $r->command('checkout',$self->branch)->stderr->getlines;
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

no Moose::Role;
1;

__END__

