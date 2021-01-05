package App::TimeTracker::Constants;

# ABSTRACT: App::TimeTracker pre-defined constants
# VERSION

use strict;
use warnings;
use 5.010;

use Exporter;
use parent qw(Exporter);

our @EXPORT      = qw();
our @EXPORT_OK   = qw(MISSING_PROJECT_HELP_MSG);

use constant MISSING_PROJECT_HELP_MSG =>
    "Could not find project; did you forget to run `tracker init`?\n" .
    "If not, use --project or chdir into the project directory.";

1;

__END__

=head1 DESCRIPTION

Pre-defined constants used without the module's internals.
