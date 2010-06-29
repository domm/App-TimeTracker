package App::TimeTracker::Data::Project;
use 5.010;
use Moose;
use namespace::autoclean;

has 'name' => (
    isa=>'String',
    is=>'rw',
);


__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

