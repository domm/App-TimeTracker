package App::TimeTracker::Exceptions;

use 5.010;
use warnings;
use strict;

=head1 NAME

App::TimeTracker::Exceptions - define exceptions

=head1 SYNOPSIS

Exception hierarchy generated using Exception::Class

=cut

use Exception::Class(
    'ATTX',
    'ATTX::BadParams' => { isa => 'ATTX' },
    'ATTX::BadData'   => { isa => 'ATTX' },
    'ATTX::BadDate'    => {isa=>'ATTX'},
    'ATTX::File'      => {
        isa    => 'ATTX',
        fields => [qw(file)],
    },
    'ATTX::DB' => {isa=>'ATTX'},
);

# 1; is boring
q{ listeing to:
    more radio in the waiting room of the Allergieambulanz
};

__END__

=head1 AUTHOR

Thomas Klausner, C<< <domm at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008, 2009 Thomas Klausner, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
