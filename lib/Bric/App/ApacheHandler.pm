package Bric::App::ApacheHandler;

=head1 NAME

Bric::App::ApacheHandler - subclass of HTML::Mason::ApacheHandler

=head1 VERSION

$Revision: 1.1 $

=cut

# Grab the Version Number.
our $VERSION = (qw$Revision: 1.1 $ )[-1];

=head1 DATE

$Date: 2002-12-10 18:45:26 $

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
use HTML::Mason::ApacheHandler;
use Bric::Util::Fault::Exception::DP;
use Bric::Config qw(:char);
use Bric::Util::CharTrans;

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
my $ct = Bric::Util::CharTrans->new(CHAR_SET);


################################################################################
# Instance Fields

################################################################################
# Class Methods
################################################################################

=head1 INTERFACE

=head2 Constructors

Inherited.

=head2 Destructors

Inherited.

=head2 Public Class Methods

Inherited.

=head2 Public Functions

=over 4

=item my $ah = Bric::App::ApacheHandler->new( ... );

Overrides the HTML::Mason::ApacheHandler::request_args method to process GET and
POST data. By overriding it, we are able to do a couple of extra things, such as
translate the characters to Unicode and to turn empty strings into undefs.
Basically this is the old Bric::App::Handler::load_args method minus what
was already in HTML::Mason::ApacheHander::_mod_perl_args.

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

    # We'll be checking to see if the data is already Unicode below.
    my $utf = $ct->charset eq 'UTF-8';

    # Note: a lot of this is redundant with $self->SUPER::request_args.
    # It would be more efficient to replace the parent's functionality
    # directly here, but I'm not sure how wise it is to do that.
    foreach my $key ($r->param()) {
        my @values = $r->param($key);

	# Translate value to Unicode, unless it's already Unicode
        eval { $ct->to_utf8(\@values) } unless $utf;

        if ($@) {
            my $msg = 'Error translating from '.$ct->charset.' to UTF-8.';
            # assumes $@ isa Bric::Util::Fault::Exception
            die ref $@ ? $@
                       : Bric::Util::Fault::Exception::DP->new({msg     => $msg,
                                                                payload => $@});
        }

        # XXX: maybe only one of these is necessary?
        $r->param($key => scalar @values == 1 ? $values[0] : \@values);
        $args->{$key} = @values == 1 ? $values[0] : \@values;
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
