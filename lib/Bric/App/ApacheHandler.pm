package Bric::App::ApacheHandler;

=head1 NAME

Bric::App::ApacheHandler - subclass of MasonX::ApacheHandler::WithCallbacks

=head1 VERSION

$Revision: 1.2.6.3 $

=cut

# Grab the Version Number.
our $VERSION = (qw$Revision: 1.2.6.3 $ )[-1];

=head1 DATE

$Date: 2003-07-02 08:30:21 $

=head1 DESCRIPTION

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
use Bric::Config qw(:char);
use Bric::Util::CharTrans;

################################################################################
# Inheritance
################################################################################
use base qw(MasonX::ApacheHandler::WithCallbacks);

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
my $ct = Bric::Util::CharTrans->new(CHAR_SET);


################################################################################
# Instance Fields

################################################################################
# Class Methods
################################################################################

=head1 INTERFACE

=head2 Constructors

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_, cb_classes => 'ALL',
                                  exec_null_cb_values => 0);
    return $self;
}

=head2 Destructors

Inherited.

=head2 Public Class Methods

Inherited.

=head2 Public Functions

=over 4

=item my $ah = Bric::App::ApacheHandler->new( ... );

Overrides the HTML::Mason::ApacheHandler::request_args method to process GET
and POST data. By overriding it, we are able to translate the characters to
Unicode. Basically this is the old Bric::App::Handler::load_args method minus
what was already in HTML::Mason::ApacheHander::_mod_perl_args.

B<Throws:>

=over 4

=item *

Error translating from charset to UTF-8.

=back

B<Side Effects:> NONE.

B<NOTES:> NONE.

=cut

sub request_args {
    my $self = shift;
    my ($args, $r, $q) = $self->SUPER::request_args(@_);

    # Translate chars if non-UTF8 (see also Handler.pm)
    unless (CHAR_SET eq 'UTF-8') {
        eval { $ct->to_utf8($args) };
        if ($@) {
            if (isa_bric_exception($@)) {
                rethrow_exception($@);
            } else {
                throw_dp(error => 'Error translating from ' . CHAR_SET . ' to UTF-8.',
                         payload => $@);
            }
        }
    }

    return ($args, $r, $q);
}

=back

=head1 PRIVATE

NONE.

=cut

1;

__END__

=head1 NOTES

NONE.

=head1 AUTHOR

Scott Lanning <slanning@theworld.com>

=head1 SEE ALSO

L<Bric::App::Handler>, L<HTML::Mason::ApacheHander>

=cut
