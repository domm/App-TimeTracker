package App::TimeTracker::Command::Overtime;
use strict;
use warnings;
use 5.010;

# ABSTRACT: Tells you if you have already worked enough

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
    my $now = $self->to || now();
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

sub cmd_overtime {
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

sub _load_attribs_overtime {
    my ($class, $meta) = @_;
    $class->_load_attribs_worked($meta);
}

no Moose::Role;
1;

__END__

=head1 DESCRIPTION

This plugin allows you to define the time you plan to work on your projects, and compare the time you actually worked with those targets.

=head1 CONFIGURATION

=head2 plugins

Add C<Overtime> to the list of plugins.

=head2 other setup

You have to add a file called F<target.json> to the directories containing the monthly tracking files (eg F<~/.TimeTracker/2011/10/target.json>). This files has to contain a JSON hash consisting of the project names as keys and the planned time (in hours) as values:

  {
    "some_project":"20",
    "other_project":"35"
  }

Currently, C<Overtime> only supports per-month targets.

=head1 NEW COMMANDS

=head2 overtime

  ~/work/some_project$ tracker overtime --this month
  Project        | Worked   | Target | Status
  ---------------+----------+--------+------------------------------
  some_project   | 21:12:12 | 20     | You missed your target by 01:12:12
  other_project  | 33:39:26 | 35     | Keep working 01:20:34 missing

=head2 Options

Same as report, even though currently only C<--this month> will work.

=head1 CHANGES TO OTHER COMMANDS

none.

