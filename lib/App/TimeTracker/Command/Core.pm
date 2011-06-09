package App::TimeTracker::Command::Core;
use strict;
use warnings;
use 5.010;

# ABSTRACT: TimeTracker Core commands

use Moose::Role;
use File::Copy qw(move);
use File::Find::Rule;

sub cmd_start {
    my $self = shift;

    $self->cmd_stop;
    
    my $task = App::TimeTracker::Data::Task->new({
        start=>$self->at || $self->now,
        project=>$self->project,
        tags=>$self->tags,
    });
    $self->_current_task($task);

    $task->do_start($self->home);
}

sub cmd_stop {
    my $self = shift;
    
    my $task = App::TimeTracker::Data::Task->current($self->home);
    return unless $task;
    $self->_current_task($task);

    $task->stop($self->at || $self->now);
    $task->save($self->home);
    
    move($self->home->file('current')->stringify,$self->home->file('previous')->stringify);
    
    say "Worked ".$task->duration." on ".$task->say_project_tags;
}

sub cmd_current {
    my $self = shift;
    
    if (my $task = App::TimeTracker::Data::Task->current($self->home)) {
        say "Working ".$task->_calc_duration($self->now)." on ".$task->say_project_tags;
    }
    elsif (my $prev = App::TimeTracker::Data::Task->previous($self->home)) {
        say "Currently not working on anything, but the last thing you worked on was:";
        say $prev->say_project_tags;
    }
    else {
        say "Currently not working on anything, and I have no idea what you worked on earlier...";
    }
}

sub cmd_append {
    my $self = shift;

    if (my $task = App::TimeTracker::Data::Task->current($self->home)) {
        say "Cannot 'append', you're actually already working on :"
            . $task->say_project_tags . "\n";
    }
    elsif (my $prev = App::TimeTracker::Data::Task->previous($self->home)) {

        my $task = App::TimeTracker::Data::Task->new({
            start=>$prev->stop,
            project => $self->project,
            tags=>$self->tags,
        });
        $self->_current_task($task);
        $task->do_start($self->home);
    }
    else {
        say "Currently not working on anything and I have no idea what you've been doing.";
    }
}

sub cmd_continue {
    my $self = shift;

    if (my $task = App::TimeTracker::Data::Task->current($self->home)) {
        say "Cannot 'continue', you're working on something:\n".$task->say_project_tags;
    }
    elsif (my $prev = App::TimeTracker::Data::Task->previous($self->home)) {
        my $task = App::TimeTracker::Data::Task->new({
            start=>$self->at || $self->now,
            project=>$prev->project,
            tags=>$prev->tags,
        });
        $self->_current_task($task);
        $task->do_start($self->home);
    }
    else {
        say "Currently not working on anything, and I have no idea what you worked on earlier...";
    }
}

sub cmd_worked {
    my $self = shift;

    my @files = $self->find_task_files({
        from=>$self->from,
        to=>$self->to,
        projects=>$self->projects,
    });

    my $total=0;
    foreach my $file ( @files ) {
        my $task = App::TimeTracker::Data::Task->load($file->stringify);
        $total+=$task->seconds // $task->_build_seconds;
    }

    say $self->beautify_seconds($total);
}

sub cmd_report {
    my $self = shift;

    my @files = $self->find_task_files({
        from=>$self->from,
        to=>$self->to,
        projects=>$self->projects,
    });

    my $total = 0;
    my $report={};
    my $format="%- 20s % 12s\n";

    my $job_map = $self->config->{project2job};

    foreach my $file ( @files ) {
        my $task = App::TimeTracker::Data::Task->load($file->stringify);
        my $time = $task->seconds // $task->_build_seconds;
        my $project = $task->project;
        my $job = $job_map->{$project} || '_nojob';

        if ($time >= 60*60*8) {
            say "Found dubious trackfile: ".$file->basename;
            say "  Are you sure you worked ".$self->beautify_seconds($time)." on one task?";
        }

        $total+=$time;

        $report->{$job}{'_total'} += $time;
        $report->{$job}{$project}{'_total'} += $time;

        if ( $self->detail ) {
            my $tags = $task->tags;
            if (@$tags) {
                foreach my $tag ( @$tags ) {
                    $report->{$job}{$project}{$tag} += $time;
                }
            }
            else {
                $report->{$job}{$project}{'_untagged'} += $time;
            }
        }
        if ($self->verbose) {
            printf("%- 40s -> % 8s\n",$file->basename, $self->beautify_seconds($time));
        }
    }

    my $padding='';
    my $tagpadding='   ';
    foreach my $job (sort keys %$report) {
        my $job_total = delete $report->{$job}{'_total'};
        unless ($job eq '_nojob') {
            printf ($format, $job, $self->beautify_seconds( $job_total ) );
            $padding = "   ";
        }

        foreach my $project (sort keys %{$report->{$job}}) {
            my $data = $report->{$job}{$project};
            printf( $padding.$format, $project, $self->beautify_seconds( delete $data->{'_total'} ) );
            printf( $padding.$tagpadding.$format, 'untagged', $self->beautify_seconds( delete $data->{'_untagged'} ) ) if $data->{'_untagged'};

            if ( $self->detail ) {
                foreach my $tag ( sort { $data->{$b} <=> $data->{$a} } keys %{ $data } ) {
                    my $time = $data->{$tag};
                    printf( $padding.$tagpadding.$format, $tag, $self->beautify_seconds($time) );
                }
            }
        }
    }
    #say '=' x 35;
    printf( $format, 'total', $self->beautify_seconds($total) );
}

sub cmd_recalc_trackfile {
    my $self = shift;
    my $file = $self->trackfile;
    unless (-e $file) {
        $file =~ /(?<year>\d\d\d\d)(?<month>\d\d)\d\d-\d{6}_\w+\.trc/;
        if ($+{year} && $+{month}) {
            $file = $self->home->file($+{year},$+{month},$file)->stringify;
            unless (-e $file) {
                say "Cannot find file ".$self->trackfile;
                exit;
            }
        }
    }

    my $task = App::TimeTracker::Data::Task->load($file);
    $task->save($self->home);
    say "recalced $file";
}

sub cmd_commands {
    my $self = shift;

    say "Available commands:";
    foreach my $method ($self->meta->get_all_method_names) {
        next unless $method =~ /^cmd_/;
        $method =~ s/^cmd_//;
        say "\t$method";
    }
    exit;
}

sub _load_attribs_worked {
    my ($class, $meta) = @_;
    $meta->add_attribute('from'=>{
        isa=>'TT::DateTime',
        is=>'ro',
        coerce=>1,
        lazy_build=>1,
    });
    $meta->add_attribute('to'=>{
        isa=>'TT::DateTime',
        is=>'ro',
        coerce=>1,
        lazy_build=>1,
    });
    $meta->add_attribute('this'=>{
        isa=>'Str',
        is=>'ro',
    });
    $meta->add_attribute('last'=>{
        isa=>'Str',
        is=>'ro',
    });
    $meta->add_attribute('projects'=>{
        isa=>'ArrayRef[Str]',
        is=>'ro',
    });
}
sub _load_attribs_report {
    my ($class, $meta) = @_;
    $class->_load_attribs_worked($meta);
    $meta->add_attribute('detail'=>{
        isa=>'Bool',
        is=>'ro',
        documentation=>'Be detailed',
    });
    $meta->add_attribute('verbose'=>{
        isa=>'Bool',
        is=>'ro',
        documentation=>'Be verbose',
    });
}

sub _load_attribs_start {
    my ($class, $meta) = @_;
    $meta->add_attribute('at'=>{
        isa=>'TT::DateTime',
        is=>'ro',
        coerce=>1,
        documentation=>'Start at',
    });
    $meta->add_attribute('project'=>{
        isa=>'Str',
        is=>'ro',
        documentation=>'Project name',
        lazy_build=>1,
    });
}

sub _build_project {
    my $self = shift;
    return $self->_currentproject;
}

*_load_attribs_append = \&_load_attribs_start;
*_load_attribs_continue = \&_load_attribs_start;
*_load_attribs_stop = \&_load_attribs_start;

sub _load_attribs_recalc_trackfile {
    my ($class, $meta) = @_;
    $meta->add_attribute('trackfile'=>{
        isa=>'Str',
        is=>'ro',
        required=>1,
    });
}

sub _build_from {
    my $self = shift;
    if (my $last = $self->last) {
        return $self->now->truncate( to => $last)->subtract( $last.'s' => 1 );
    }
    elsif (my $this = $self->this) {
        return $self->now->truncate( to => $this);
    }
}

sub _build_to {
    my $self = shift;
    my $dur = $self->this || $self->last;
    return $self->from->clone->add( $dur.'s' => 1 );
}

no Moose::Role;
1;

__END__

