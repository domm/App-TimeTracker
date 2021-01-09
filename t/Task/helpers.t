use 5.010;
use strict;
use warnings;
use lib 't';

use Test::Most;
use DateTime;

use App::TimeTracker::Data::Task;

{    # _calc_duration, rounded_minutes
    my $task = App::TimeTracker::Data::Task->new(
        {   project => 'test',
            start   => DateTime->new(
                year   => 2010,
                month  => 2,
                day    => 26,
                hour   => 10,
                minute => 5,
                second => 42
            ),
            description =>
                'Some Test Task described in a very long sentence that will be probably be shortend',
        }
    );
    my $stop = DateTime->new(
        year   => 2010,
        month  => 2,
        day    => 26,
        hour   => 12,
        minute => 25,
        second => 13
    );
    $task->_calc_duration($stop);
    is( $task->seconds,         '8371',     '_calc_duration: seconds' );
    is( $task->duration,        '02:19:31', '_calc_duration: duration' );
    is( $task->rounded_minutes, 140,        'rounded_minutes' );

    $stop->add( 'hours' => 1 );
    $task->stop($stop);
    $task->_calc_duration;
    is( $task->seconds,         '11971',    '_calc_duration: seconds' );
    is( $task->duration,        '03:19:31', '_calc_duration: duration' );
    is( $task->rounded_minutes, 200,        'rounded_minutes' );
    is( $task->description_short, 'Some Test Task described in a very long sentence...',
        'description_short' );
}

{    # rounded_minutes
    my $task = App::TimeTracker::Data::Task->new(
        {   project => 'test',
            start   => DateTime->new(
                year   => 2010,
                month  => 2,
                day    => 26,
                hour   => 10,
                minute => 5,
                second => 0
            ),
            description => 'Worked exactly 15 minutes',
        }
    );
    my $stop = DateTime->new(
        year   => 2010,
        month  => 2,
        day    => 26,
        hour   => 10,
        minute => 20,
        second => 0
    );
    $task->_calc_duration($stop);
    is( $task->duration,        '00:15:00', 'task duration is 15 minutes' );
    is( $task->rounded_minutes, 15,         'rounded_minutes' );
}

done_testing();
