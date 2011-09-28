package App::TimeTracker::Command::CheckTarget;
use strict;
use warnings;
use 5.010;

# ABSTRACT: App::TimeTracker plugin to compare time-worked with a target time

use Moose::Role;
use App::TimeTracker::Utils qw(now);
use JSON::XS;
use Text::Table;
use Term::ANSIColor;

has 'current_target_file' => (
    is         => 'ro',
    isa        => 'Path::Class::File',
    lazy_build => 1,
);
sub _build_current_target_file {
    my $self = shift;
    my $now = now();
    return $self->home->file($now->year,sprintf('%02d',$now->month),'target.json');
}
has 'targets' => (
    is=>'ro',
    isa=>'HashRef',
    lazy_build=>1,
);
sub _build_targets {
    my $self = shift;
    my $file = $self->current_target_file;
    if (-e $file && -s $file) {
        return decode_json($file->slurp);
    }
    else {
        return {};
    }
}

sub cmd_check_target {
    my $self = shift;

    my $targets = $self->targets;
    my $project_tree = $self->project_tree;
    my $raw_filter = $self->fprojects || [keys %$targets];
    my %lookup;
    foreach my $project (@$raw_filter) {
        $lookup{$project} = $project;
        my $up = $project;

        while (my $parent = $project_tree->{$up}{parent}) {
            $lookup{$parent} = $project;
            $up = $parent;
        }
        if ($project_tree->{$project}{children}) { # TODO recurse
            foreach my $child (keys %{$project_tree->{$project}{children}}) {
                $lookup{$child} = $project;
            }
        }
    }

    my @files = $self->find_task_files({
        from     => $self->from,
        to       => $self->to,
        projects => [keys %lookup],
        tags     => $self->ftags,
    });

    my %report;
    foreach my $file ( @files ) {
        my $task = App::TimeTracker::Data::Task->load($file->stringify);
        my $project = $task->project;
        my $book_as = $lookup{$project} || $project;

        if ($targets->{$book_as}) {
            $report{$book_as}+=$task->seconds // $task->_build_seconds;
        }
    }
    my $s=\' | ';
    my $table = Text::Table->new(
        "Project", $s, "Worked", $s, "Target", $s, "Status"
    );

    while (my ($project, $target) = each %$targets) {
        my $seconds = $report{$project};
        my $target_seconds = $target * 60 * 60;
        my $diff = $target_seconds - $seconds;
        my $nice_diff = $self->beautify_seconds(abs($diff));
        my $status;
        if ($diff > 0) {
            $status = (color 'green').'Keep working'.(color 'reset')." $nice_diff missing";
        }
        else {
            $status = (color 'red')."You missed your target".(color 'reset')." by $nice_diff";
        }
        $table->add(
            $project,
            $self->beautify_seconds($seconds),
            $target,
            $status,
        )
    }
    print $table->title;
    print $table->rule('-','+');
    print $table->body;

}

sub _load_attribs_check_target {
    my ($class, $meta) = @_;
    $class->_load_attribs_worked($meta);
}

no Moose::Role;
1;

__END__

=head1 DESCRIPTION

=head1 CONFIGURATION

=over 

=item * 

=back

=head1 NEW COMMANDS

=head2 

  ~/somewhere/on/your/disc$ tracker 
  # some git output

B<Options:> none

=head1 CHANGES TO OTHER COMMANDS

none.

