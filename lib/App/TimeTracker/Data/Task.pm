package App::TimeTracker::Data::Task;
use 5.010;
use Moose;
use namespace::autoclean;
use App::TimeTracker;
use App::TimeTracker::Data::Project;

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
    required=>1,
    default=>sub { DateTime->now }
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
    is=>'ro',
    required=>1,
);
has 'tags' => (
    isa=>'ArrayRef[App::TimeTracker::Data::Tag]',
    is=>'rw',
    default=>sub { [] }
);

sub _filepath {
    my $self = shift;
    my $start = $self->start;
    return ($start->year,sprintf('%02d',$start->month),$start->strftime("%Y%m%d-%H%M%S").'_'.$self->project->name.'.json');
}

sub storage_location {
    my ($self, $base) = @_;
    return $base->file($self->_filepath);
}


__PACKAGE__->meta->make_immutable;
1;

__END__

