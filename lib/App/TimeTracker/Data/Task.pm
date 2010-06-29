package App::TimeTracker::Data::Task;
use 5.010;
use Moose;
use namespace::autoclean;
use DateTime;

has 'start' => (
    isa=>'DateTime',
    is=>'rw',
);
has 'stop' => (
    isa=>'DateTime',
    is=>'rw',
);
has 'duration' => (
    isa=>'Int',
    is=>'rw',
);
has 'status' => (
    isa=>'String',
    is=>'rw',
);
has 'user' => (
    isa=>'String',
    is=>'rw',
    default=>'domm' # TODO: get user from config / system
);
has 'project' => (
    isa=>'App::TimeTracker::Data::Project',
    is=>'rw',
);
has 'tags' => (
    isa=>'ArrayRef[App::TimeTracker::Data::Tag]',
    is=>'rw',
    default=>sub { [] }
);


__PACKAGE__->meta->make_immutable;
1;

__END__

