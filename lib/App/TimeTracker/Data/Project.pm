package App::TimeTracker::Data::Project;
use 5.010;
use Moose;
use namespace::autoclean;

has 'name' => (
    isa=>'Str',
    is=>'rw',
);


__PACKAGE__->meta->make_immutable;
1;

__END__

