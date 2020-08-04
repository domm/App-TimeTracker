package App::TimeTracker::Command::Core;
use strict;
use warnings;
use 5.010;

# ABSTRACT: App::TimeTracker Core commands

use Moose::Role;
use Moose::Util::TypeConstraints;
use App::TimeTracker::Utils qw(now pretty_date error_message);
use File::Copy qw(move);
use File::Find::Rule;
use Data::Dumper;
use Text::Table;

sub cmd_start {
    my $self = shift;

    unless ( $self->has_current_project ) {
        error_message(
            "Could not find project\nUse --project or chdir into the project directory"
        );
        exit;
    }
    $self->cmd_stop('no_exit');

    my $task = App::TimeTracker::Data::Task->new( {
            start => $self->at || now(),
            project     => $self->project,
            tags        => $self->tags,
            description => $self->description,
        } );
    $self->_current_task($task);

    $task->do_start( $self->home );
}

sub cmd_stop {
    my ($self, $dont_exit) = @_;

    my $task = App::TimeTracker::Data::Task->current( $self->home );
    unless ($task) {
        return if $dont_exit;
        say "Currently not working on anything";
        exit;
    }

    my $proto = App::TimeTracker::Proto->new();
    my $config = $proto->load_config(undef, $task->project);

    my $class = $proto->setup_class($config, 'stop');
    my $stop_self = $class->name->new( {
            home            => $self->home,
            at              => $self->at || now(),
            config          => $config,
            _current_project=> $task->project,
        } );
    $stop_self->_current_command('cmd_stop');
    $stop_self->_previous_task($task);
    # Store in original self too (for plugin usage)
    $self->_previous_task($task);

    $task->stop( $stop_self->at || now() );
    if ( $task->stop < $task->start ) {
        say sprintf(
            qq{The stop time you specified (%s) is earlier than the start time (%s).\nThis makes no sense.},
            $task->stop, $task->start );

        my $what_you_meant = $task->stop->clone;
        for ( 1 .. 5 ) {
            $what_you_meant->add( days => 1 );
            last if $what_you_meant > $task->start;
        }
        if ( $what_you_meant ne $task->start ) {
            say "Maybe you wanted to do:\ntracker stop --at '"
                . $what_you_meant->strftime('%Y-%m-%d %H:%M') . "'";
        }
        else {
            say
                "Maybe it helps if you use the long format to specify the stop time ('2012-01-10 00:15')?";
        }
        exit;
    }
    $task->save( $stop_self->home );

    move(
        $stop_self->home->file('current')->stringify,
        $stop_self->home->file('previous')->stringify
    );

    say "Worked " . $task->duration . " on " . $task->say_project_tags;
}

sub cmd_current {
    my $self = shift;

    if ( my $task = App::TimeTracker::Data::Task->current( $self->home ) ) {
        say "Working "
            . $task->_calc_duration( now() ) . " on "
            . $task->say_project_tags;
        say 'Started at ' . pretty_date( $task->start );
    }
    elsif ( my $prev = App::TimeTracker::Data::Task->previous( $self->home ) )
    {
        say
            "Currently not working on anything, but the last thing you worked on was:";
        say $prev->say_project_tags;
        say 'Worked '
            . $prev->rounded_minutes
            . ' minutes from '
            . pretty_date( $prev->start )
            . ' till '
            . pretty_date( $prev->stop );
    }
    else {
        say
            "Currently not working on anything, and I have no idea what you worked on earlier...";
    }
}

sub cmd_append {
    my $self = shift;

    if ( my $task = App::TimeTracker::Data::Task->current( $self->home ) ) {
        say "Cannot 'append', you're actually already working on :"
            . $task->say_project_tags . "\n";
    }
    elsif ( my $prev = App::TimeTracker::Data::Task->previous( $self->home ) )
    {

        my $task = App::TimeTracker::Data::Task->new( {
                start   => $prev->stop,
                project => $self->project,
                tags    => $self->tags,
            } );
        $self->_current_task($task);
        $task->do_start( $self->home );
    }
    else {
        say
            "Currently not working on anything and I have no idea what you've been doing.";
    }
}

sub cmd_continue {
    my $self = shift;

    if ( my $task = App::TimeTracker::Data::Task->current( $self->home ) ) {
        say "Cannot 'continue', you're working on something:\n"
            . $task->say_project_tags;
    }
    elsif ( my $prev = App::TimeTracker::Data::Task->previous( $self->home ) )
    {
        my $task = App::TimeTracker::Data::Task->new( {
                start => $self->at || now(),
                project => $prev->project,
                tags    => $prev->tags,
            } );
        $self->_current_task($task);
        $task->do_start( $self->home );
    }
    else {
        say
            "Currently not working on anything, and I have no idea what you worked on earlier...";
    }
}

sub cmd_worked {
    my $self = shift;

    my @files = $self->find_task_files( {
            from     => $self->from,
            to       => $self->to,
            projects => $self->fprojects,
            tags     => $self->ftags,
            parent   => $self->fparent,
        } );

    my $total = 0;
    foreach my $file (@files) {
        my $task = App::TimeTracker::Data::Task->load( $file->stringify );
        $total += $task->seconds // $task->_build_seconds;
    }

    say $self->beautify_seconds($total);
}

sub cmd_list {
    my $self = shift;

    my @files = $self->find_task_files( {
            from     => $self->from,
            to       => $self->to,
            projects => $self->fprojects,
            tags     => $self->ftags,
            parent   => $self->fparent,
        } );

    my $s     = \' | ';
    my $table = Text::Table->new(
        "Project",
        $s, "Tag", $s,
        "Duration",
        $s, "Start", $s, "Stop",
        (   $self->detail
            ? ( $s, "Seconds", $s, "Description", $s, "File" )
            : ()
        ),
    );
    my $total=0;
    foreach my $file (@files) {
        my $task = App::TimeTracker::Data::Task->load( $file->stringify );
        my $time = $task->seconds // $task->_build_seconds;
        $total+=$time;
        $table->add(
            $task->project,
            join( ', ', @{ $task->tags } ),
            $task->duration || 'working',
            pretty_date( $task->start ),
            pretty_date( $task->stop ),
            (   $self->detail
                ? ( $time, ($task->description_short || ''), $file->stringify )
                : ()
            ),
        );
    }

    print $table->title;
    print $table->rule( '-', '+' );
    print $table->body;
    say "total ".$self->beautify_seconds($total);
}

sub cmd_report {
    my $self = shift;

    my @files = $self->find_task_files( {
            from     => $self->from,
            to       => $self->to,
            projects => $self->fprojects,
            tags     => $self->ftags,
            parent   => $self->fparent,
        } );

    my $total  = 0;
    my $report = {};
    my $format = "%- 20s % 12s\n";
    my $projects = $self->project_tree;

    foreach my $file (@files) {
        my $task    = App::TimeTracker::Data::Task->load( $file->stringify );
        my $time    = $task->seconds // $task->_build_seconds;
        my $project = $task->project;

        if ( $time >= 60 * 60 * 8 ) {
            say "Found dubious trackfile: " . $file->stringify;
            say "  Are you sure you worked "
                . $self->beautify_seconds($time)
                . " on one task?";
        }

        $total += $time;

        $report->{$project}{'_total'} += $time;

        if ( my $level = $self->detail ) {
            my $detail = $task->get_detail($level);
            my $tags   = $detail->{tags};
            if ($tags && @$tags) {
                # Only use the first assigned tag to calculate the aggregated times and use it
                # as tag key.
                # Otherwise the same trackfiles would be counted multiple times and the
                # aggregated sums would not match up.
                $report->{$project}{ $tags->[0] }{time} += $time;

                foreach my $tag (@$tags) {
                    $report->{$project}{ $tags->[0] }{desc} //= '';

                    if ( my $desc = $detail->{desc} ) {
                        $report->{$project}{ $tags->[0] }{desc} .= $desc
                            . "\n"
                            if index( $report->{$project}{ $tags->[0] }{desc},
                            $desc ) == -1;
                    }
                }
            }
            else {
                $report->{$project}{'_untagged'} += $time;
            }
        }
    }

    # sum child-time to all ancestors
    my %top_nodes;
    foreach my $project ( sort keys %$report ) {
        my @ancestors;
        $self->_get_ancestors($report, $projects, $project, \@ancestors);
        my $time = $report->{$project}{'_total'} || 0;
        foreach my $ancestor (@ancestors) {
            $report->{$ancestor}{'_kids'} += $time;
        }
        $top_nodes{$ancestors[0]}++ if @ancestors;
        $top_nodes{$project}++ if !@ancestors;
    }

    $self->_say_current_report_interval;
    my $padding    = '';
    my $tagpadding = '     ';
    foreach my $project ( sort keys %top_nodes ) {
        $self->_print_report_tree( $report, $projects, $project, $padding,
            $tagpadding );
    }

    printf( $format, 'total', $self->beautify_seconds($total) );
}

sub _get_ancestors {
    my ( $self, $report, $projects, $node, $ancestors ) = @_;
    my $parent = $projects->{$node}{parent};
    if ($parent) {
        unshift( @$ancestors, $parent );
        $self->_get_ancestors( $report, $projects, $parent, $ancestors );
    }
}

sub _print_report_tree {
    my ( $self, $report, $projects, $project, $padding, $tagpadding ) = @_;
    my $data = $report->{$project};

    my $sum = 0;
    $sum += $data->{'_total'} if $data->{'_total'};
    $sum += $data->{'_kids'} if $data->{'_kids'};
    return unless $sum;

    my $format = "%- 20s % 12s";

    say sprintf( $padding. $format,
        substr( $project, 0, 20 ),
        $self->beautify_seconds( $sum )
    );
    if ( my $detail = $self->detail ) {
        say sprintf( $padding. $tagpadding . $format,
            'untagged',
            $self->beautify_seconds( delete $data->{'_untagged'} ) )
            if $data->{'_untagged'};

        foreach my $tag ( sort { $data->{$b}->{time} <=> $data->{$a}->{time} }
            grep {/^[^_]/} keys %{$data} )
        {
            my $time = $data->{$tag}{time};

            if ($detail eq 'description') {
                my $desc = $data->{$tag}{desc} || 'no desc';
                $desc =~ s/\s+$//;
                $desc =~ s/\v/, /g;
                say sprintf( $padding. $tagpadding . $format.'   %s',
                    $tag, $self->beautify_seconds($time), $desc );
            }
            elsif ($detail eq 'tag') {
                say sprintf( $padding. $tagpadding . $format,
                    $tag, $self->beautify_seconds($time) );
            }
        }
    }
    foreach my $child ( sort keys %{ $projects->{$project}{children} } ) {
        $self->_print_report_tree( $report, $projects, $child,
            $padding . '   ', $tagpadding );
    }
}

sub cmd_recalc_trackfile {
    my $self = shift;
    my $file = $self->trackfile;
    unless ( -e $file ) {
        $file =~ /(?<year>\d\d\d\d)(?<month>\d\d)\d\d-\d{6}_\w+\.trc/;
        if ( $+{year} && $+{month} ) {
            $file
                = $self->home->file( $+{year}, $+{month}, $file )->stringify;
            unless ( -e $file ) {
                error_message( "Cannot find file %s", $self->trackfile );
                exit;
            }
        }
    }

    my $task = App::TimeTracker::Data::Task->load($file);
    $task->save( $self->home );
    say "recalced $file";
}

sub cmd_show_config {
    my $self = shift;
    warn Data::Dumper::Dumper $self->config;
}

sub cmd_init {
    my ( $self, $cwd ) = @_;
    $cwd ||= Path::Class::Dir->new->absolute;
    if ( -e $cwd->file('.tracker.json') ) {
        error_message(
            "This directory is already set up.\nTry 'tracker show_config' to see the current aggregated config."
        );
        exit;
    }

    my @dirs    = $cwd->dir_list;
    my $project = $dirs[-1];
    my $fh      = $cwd->file('.tracker.json')->openw;
    say $fh <<EOCONFIG;
{
    "project":"$project"
}
EOCONFIG

    my $projects_file = $self->home->file('projects.json');
    my $coder  = JSON::XS->new->utf8->pretty->relaxed;
    if (-e $projects_file) {
        my $projects = $coder->decode( scalar $projects_file->slurp );
        $projects->{$project} = $cwd->file('.tracker.json')->absolute->stringify;
        $projects_file->spew($coder->encode($projects));
    }

    say "Set up this directory for time-tracking via file .tracker.json";
}

sub cmd_plugins {
    my $self = shift;

    my $base = Path::Class::file( $INC{'App/TimeTracker/Command/Core.pm'} )
        ->parent;
    my @hits;
    while ( my $file = $base->next ) {
        next unless -f $file;
        next if $file->basename eq 'Core.pm';
        my $plugin = $file->basename;
        $plugin =~ s/\.pm$//;
        push( @hits, $plugin );
    }
    say "Installed plugins:\n  " . join( ', ', @hits );
}

sub cmd_version {
    my $self = shift;
    say "This is App::TimeTracker, version " . App::TimeTracker->VERSION;
    exit;
}

sub cmd_commands {
    my $self = shift;

    my @commands;
    foreach my $method ( $self->meta->get_all_method_names ) {
        next unless $method =~ /^cmd_/;
        $method =~ s/^cmd_//;
        push( @commands, $method );
    }

    @commands = sort @commands;

    if (   $self->can('autocomplete')
        && $self->autocomplete )
    {
        say join( ' ', @commands );
    }
    else {
        say "Available commands:";
        foreach my $command (@commands) {
            say "\t$command";
        }
    }
    exit;
}

sub _load_attribs_worked {
    my ( $class, $meta ) = @_;
    $meta->add_attribute(
        'from' => {
            isa           => 'TT::DateTime',
            is            => 'ro',
            coerce        => 1,
            lazy_build    => 1,
            #cmd_aliases  => [qw/start/],
            documentation => 'Beginning of time period to report',
        } );
    $meta->add_attribute(
        'to' => {
            isa           => 'TT::DateTime',
            is            => 'ro',
            coerce        => 1,
            #cmd_aliases  => [qw/end/],
            lazy_build    => 1,
            documentation => 'End of time period to report',
        } );
    $meta->add_attribute(
        'this' => {
            isa           => 'TT::Duration',
            is            => 'ro',
            documentation => 'Filter by current time period [day|week|month|year], e.g. day=today',
        } );
    $meta->add_attribute(
        'last' => {
            isa           => 'TT::Duration',
            is            => 'ro',
            documentation => 'Filter by previous time period [day|week|month|year], e.g. day=yesterday',
        } );
    $meta->add_attribute(
        'fprojects' => {
            isa           => 'ArrayRef',
            is            => 'ro',
            documentation => 'Filter by project',
        } );
    $meta->add_attribute(
        'ftags' => {
            isa           => 'ArrayRef',
            is            => 'ro',
            documentation => 'Filter by tag',
        } );
    $meta->add_attribute(
        'fparent' => {
            isa           => 'Str',
            is            => 'ro',
            documentation => 'Filter by parent (get all children)',
        } );

}

sub _load_attribs_commands {
    my ( $class, $meta ) = @_;
    $meta->add_attribute(
        'autocomplete' => {
            isa           => 'Bool',
            is            => 'ro',
            default       => 0,
            documentation => 'Output for autocomplete',
        } );
}

sub _load_attribs_list {
    my ( $class, $meta ) = @_;
    $class->_load_attribs_worked($meta);
    $meta->add_attribute(
        'detail' => {
            isa           => 'Bool',
            is            => 'ro',
            default       => 0,
            documentation => 'Be detailed',
        } );
}

sub _load_attribs_report {
    my ( $class, $meta ) = @_;
    $class->_load_attribs_worked($meta);
    $meta->add_attribute(
        'detail' => {
            isa => enum( [qw(tag description)] ),
            is => 'ro',
            documentation => 'Be detailed: [tag|description]',
        } );
}

sub _load_attribs_start {
    my ( $class, $meta ) = @_;
    $meta->add_attribute(
        'at' => {
            isa           => 'TT::DateTime',
            is            => 'ro',
            coerce        => 1,
            documentation => 'Start at',
        } );
    $meta->add_attribute(
        'project' => {
            isa           => 'Str',
            is            => 'ro',
            documentation => 'Project name',
            lazy_build    => 1,
        } );
    $meta->add_attribute(
        'description' => {
            isa           => 'Str',
            is            => 'rw',
            documentation => 'Description',
        } );
}

sub _build_project {
    my $self = shift;
    return $self->_current_project;
}

*_load_attribs_append   = \&_load_attribs_start;
*_load_attribs_continue = \&_load_attribs_start;
*_load_attribs_stop     = \&_load_attribs_start;

sub _load_attribs_recalc_trackfile {
    my ( $class, $meta ) = @_;
    $meta->add_attribute(
        'trackfile' => {
            isa      => 'Str',
            is       => 'ro',
            required => 1,
        } );
}

sub _build_from {
    my $self = shift;
    if ( my $last = $self->last ) {
        return now()->truncate( to => $last )->subtract( $last . 's' => 1 );
    }
    elsif ( my $this = $self->this ) {
        return now()->truncate( to => $this );
    }
    else {
        return now()->truncate( to => 'month' );
    }
}

sub _build_to {
    my $self = shift;

    if ( my $date = $self->this || $self->last ) {
        return $self->from->clone->add( $date . 's' => 1 )
            ->subtract( seconds => 1 );
    }
    else {
        return now();
    }
}

sub _say_current_report_interval {
    my $self = shift;
    printf( "From %s to %s you worked on:\n", $self->from, $self->to );
}

no Moose::Role;
1;

__END__

=head1 CORE COMMANDS

More commands are implemented in various plugins. Plugins might also alter and/or amend commands.

=head2 start

    ~/perl/Your-Project$ tracker start
    Started working on Your-Project at 23:44:19

Start tracking the current project now. Automatically stop the previous task, if there was one.

=head3 Options:

=head4 --at TT::DateTime

    ~/perl/Your-Project$ tracker start --at 12:42
    ~/perl/Your-Project$ tracker start --at '2011-02-26 12:42'

Start at the specified time/datetime instead of now. If only a time is
provided, the day defaults to today. See L<TT::DateTime> in L<App::TimeTracker>.

=head4 --project SomeProject

  ~/perl/Your-Project$ tracker start --project SomeProject

Use the specified project instead of the one determined by the current
working directory.

=head4 --description 'some prosa'

  ~/perl/Your-Project$ tracker start --description "Solving nasty bug"

Supply some descriptive text to the task. Might be used by reporting plugins etc.

=head4 --tags RT1234 [Multiple]

  ~/perl/Your-Project$ tracker start --tag RT1234 --tag testing

A list of tags to add to the task. Can be used by reporting plugins.

=head2 stop

    ~/perl/Your-Project$ tracker stop
    Worked 00:20:50 on Your-Project

Stop tracking the current project now.

=head3 Options

=head4 --at TT::DateTime

Stop at the specified time/datetime instead of now.

=head2 continue

    ~/perl/Your-Project$ tracker continue

Continue working on the previous task after a break.

Example:

    ~$ tracker start --project ExplainContinue --tag testing
    Started working on ExplainContinue (testing) at 12:42

    # ... time passes, it's now 13:17
    ~$ tracker stop
    Worked 00:35:00 on ExplainContinue

    # back from lunch at 13:58
    ~$ tracker continue
    Started working on ExplainContinue (testing) at 13:58

=head3 Options:

same as L<start|/start>

=head2 append

    ~/perl/Your-Project$ tracker append

Start working on a task at exactly the time you stopped working at the previous task.

Example:

    ~$ tracker start --project ExplainAppend --tag RT1234
    Started working on ExplainAppend (RT1234) at 14:23

    # ... time passes (14:46)
    ~$ tracker stop
    Worked 00:23:00 on ExplainAppend (RT1234)

    # start working on new ticket
    # ...
    # but forgot to hit start (14:53)
    ~$ tracker append --tag RT7890
    Started working on ExplainAppend (RT7890) at 14:46

=head3 Options:

same as L<start|/start>

=head2 current

    ~/perl/Your-Project$ tracker current
    Working 00:20:17 on Your-Project

Display what you're currently working on, and for how long.

=head3 No options

=head2 worked

    ~/perl/Your-Project$ tracker worked [SPAN]

Report the total time worked in the given time span, maybe limited to
some projects.

=head3 Options:

=head4 --from TT::DateTime [REQUIRED (or use --this/--last)]

Begin of reporting interval, defaults to first day of current month.

=head4 --to TT::DateTime [REQUIRED (or use --this/--last)]

End of reporting interval, default to DateTime->now.

=head4 --this [day, week, month, year]

Automatically set C<--from> and C<--to> to the calculated values

    ~/perl/Your-Project$ tracker worked --this week
    17:01:50

=head4 --last [day, week, month, year]

Automatically set C<--from> and C<--to> to the calculated values

    ~/perl/Your-Project$ tracker worked --last day (=yesterday)
    06:39:12

=head4 --project SomeProject [Multiple]

    ~$ tracker worked --last day --project SomeProject
    02:04:47

=head2 report

    ~/perl/Your-Project$ tracker report

Print out a detailed report of what you did. All worked times are
summed up per project (and optionally per tag)

=head3 Options:

The same options as for L<worked|/worked>, plus:

=head4 --detail

    ~/perl/Your-Project$ tracker report --last month --detail tag

Valid options are: tag, description

Will print the tag(s) and/or description.

Also calc sums per tag.

=head4 --verbose

    ~/perl/Your-Project$ tracker report --last month --verbose

Lists all found trackfiles and their respective duration before printing out the report.

=head2 list

    ~/perl/Your-Project$ tracker list

Print out a detailed report of what you did in a tabular format including start and stop
times.

=head3 Options:

The same options as for L<report|/report>

=head2 init

    ~/perl/Your-Project$ tracker init

Create a rather empty F<.tracker.json> config file in the current directory.

=head3 No options

=head2 show_config

    ~/perl/Your-Project$ tracker show_config

Dump the config that's valid for the current directory. Might be handy when setting up plugins etc.

=head3 No options

=head2 plugins

    ~/perl/Your-Project$ tracker plugins

List all installed plugins (i.e. stuff in C<App::TimeTracker::Command::*>)

=head3 No options

=head2 recalc_trackfile

    ~/perl/Your-Project$ tracker recalc_trackfile --trackfile 20110808-232327_App_TimeTracker.trc

Recalculates the duration stored in an old trackfile. Might be useful
after a manual update in a trackfile. Might be unnecessary in the
future, as soon as task duration is always calculated lazily.

=head3 Options:

=head4 --trackfile name_of_trackfile.trc REQUIRED

Only the name of the trackfile is required, but you can also pass in
the absolute path to the file. Broken trackfiles are sometimes
reported during L<report|/report>.

=head2 commands

    ~/perl/Your-Project$ tracker commands

List all available commands, based on your current config.

=head3 No options

