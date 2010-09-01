package App::TimeTracker::Data::Task;
use 5.010;
use Moose;
use namespace::autoclean;
use DateTime;

use MooseX::Storage;
with Storage('format' => 'JSON', 'io' => 'File');
MooseX::Storage::Engine->add_custom_type_handler(
    'DateTime' => (
        expand => sub { DateTime::Format::ISO8601->parse_datetime(shift) },
        collapse => sub { (shift)->iso8601 }
    )
);

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
    isa=>'Str',
    is=>'rw',
);
has 'user' => (
    isa=>'Str',
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

