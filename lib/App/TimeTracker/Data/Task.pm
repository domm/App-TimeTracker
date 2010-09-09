package App::TimeTracker::Data::Task;
use 5.010;
use Moose;
use namespace::autoclean;
use DateTime;
use App::TimeTracker::Data::Project;

use MooseX::Storage;
with Storage('format' => 'JSON', 'io' => 'File');
MooseX::Storage::Engine->add_custom_type_handler(
    'DateTime' => (
        expand => sub { DateTime::Format::ISO8601->parse_datetime(shift) },
        collapse => sub { (shift)->iso8601 }
    )
);
use Moose::Util::TypeConstraints;
use DateTime::Format::Strptime;


subtype 'ATT::Project' => as 'App::TimeTracker::Data::Project';
coerce 'ATT::Project' 
    => from 'Str' 
    => via {
        App::TimeTracker::Data::Project->new({ name => @_ });
    };

subtype 'ATT::DateTime' => as 'DateTime';
coerce 'ATT::DateTime' 
    => from 'Str' 
    => via {
        my $raw = shift;
        my $dt = DateTime->today;
        my ($h,$m)=split(/:/,$raw);
        $dt->set(hour=>$h, minute=>$m);
        return $dt;
    };




has 'start' => (
    isa=>'ATT::DateTime',
    is=>'rw',
    required=>1,
    coerce=>1,
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
    isa=>'ATT::Project',
    is=>'ro',
    required=>1,
    coerce=>1,
);
has 'tags' => (
    isa=>'ArrayRef[App::TimeTracker::Data::Tag]',
    is=>'rw',
    default=>sub { [] }
);

#has 'storage_location' => (
#    isa=>'Path::Class::File',
#    coerce=>1,
#    is=>'ro',
#    lazy_build=>1,
#);
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

