package Bric::App::ApacheHandler;

=head1 Name

Bric::App::ApacheHandler - subclass of HTML::Mason::ApacheHandler

=cut

# Grab the Version Number.
require Bric; our $VERSION = Bric->VERSION;

=head1 Description

This package is a subclass of HTML::Mason::ApacheHandler. It replaces
the functionality previously provided by Bric::App::Handler::load_args;
that is, it does some processing of the GET and POST data.

=cut

################################################################################
# Dependencies
################################################################################
# Standard Dependencies
use strict;

################################################################################
# Programmatic Dependences
use Bric::App::Callback;
use Bric::Util::Fault qw(:all);

################################################################################
# Inheritance
################################################################################
use base qw(HTML::Mason::ApacheHandler);

################################################################################
# Function and Closure Prototypes
################################################################################

################################################################################
# Constants
################################################################################

################################################################################
# Fields
################################################################################
# Public Class Fields

################################################################################
# Private Class Fields

################################################################################
# Instance Fields

################################################################################
# Class Methods
################################################################################

=head1 Interface

=head2 Constructors

Inherited.

=head1 Private

None.

=cut

1;

__END__

=head1 Notes

NONE.

=head1 Author

Scott Lanning <slanning@theworld.com>

=head1 See Also

L<Bric::App::Handler>, L<HTML::Mason::ApacheHander>

=cut
