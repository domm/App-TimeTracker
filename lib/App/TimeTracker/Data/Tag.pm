package App::TimeTracker::Data::Tag;
use 5.010;
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

