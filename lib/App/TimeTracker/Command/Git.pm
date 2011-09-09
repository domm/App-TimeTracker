package App::TimeTracker::Command::Git;
use strict;
use warnings;
use 5.010;

# ABSTRACT: App::TimeTracker Git plugin

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
    documentation=>'Git: Merge after stopping'
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

=head1 DESCRIPTION

This plugin makes it easier to set up and manage C<git> C<topic
branches>. When starting a new task, you can at the same time start a
new C<git branch>. Also, when stopping, C<tracker> will merge the
C<topic branch> back into C<master>.

See http://nvie.com/posts/a-successful-git-branching-model/ for a good example on how to work with topic branches (and much more!)

=head1 CONFIGURATION

=over

=item * Add C<Git> to the list of plugins. 

=item * Of course this plugin will only work if the current project is in fact a git repo...

=back

=head1 NEW COMMANDS

none

=head1 CHANGES TO OTHER COMMANDS

=head2 start, continue

B<New Options>:

=over 

=item --branch cool_new_feature

    ~/perl/Your-Project$ tracker start --branch cool_new_feature    
    Started working on Your-Project at 13:35:53
    Switched to branch 'cool_new_feature'

If you pass a branch name via C<--branch>, C<tracker> will create a
new branch (unless it already exists) and then switch into this
branch.

If the branch already existed, it might be out of sync with master. In
this case you should do something like C<git merge master> before
starting to work.

=item --nobranch (--no_branch)

    ~/perl/Your-Project$ tracker start --branch another_featur --no_branch

Do not create a new branch, even if C<--branch> is set. This is only useful if another plugin (eg <RT>) automatically sets C<--branch>.

=back

=head2 stop

B<New Options>:

=over

=item --merge

    ~/perl/Your-Project$ tracker stop --merge

After, stopping, merge the current branch back into C<master> (using C<--no-ff>.

TODO: Turn this into a string option, which should be the name of the
branch we want to merge into. Default to C<master> (or something set
in config..)

=back


