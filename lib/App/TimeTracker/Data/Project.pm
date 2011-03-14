package App::TimeTracker::Data::Project;
use 5.010;

# ABSTRACT: TimeTracker Project storage

use Moose;
use namespace::autoclean;

use MooseX::Storage;
with Storage('format' => 'JSON', 'io' => 'File');

has 'name' => (
    isa=>'Str',
    is=>'rw',
);


__PACKAGE__->meta->make_immutable;
1;

__END__

