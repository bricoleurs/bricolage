package Bric::Util::CharTrans;

=head1 NAME

Bric::Util::CharTrans - Interface to Bricolage UTF-8 Character Translations

=head1 VERSION

$Revision: 1.14 $

=cut

# Grab the Version Number.

our $VERSION = (qw$Revision: 1.14 $ )[-1];

=head1 DATE

$Date: 2003-10-14 00:34:18 $

=head1 SYNOPSIS

  # Constructors.
  my $chartrans = Bric::Util::CharTrans->new('iso-8859-1');

  # Instance Methods.
  my $charset     = $chartrans->charset;
  my $charset     = $chartrans->charset('iso-8859-1');

  my $utf8_text   = $chartrans->to_utf8($target_text);
  my $target_text = $chartrans->from_utf8($utf8_text);

  $chartrans->to_utf8(\$some_data);
  $chartrans->from_utf8(\$some_data);


=head1 DESCRIPTION

Bric::Util::CharTrans provides an object-oriented interface to conversion of
characters from a target character set to Unicode UTF-8 and from Unicode UTF-8
to a target character set.

=cut

################################################################################
# Dependencies
################################################################################
# Standard Dependencies
use strict;
use Bric::Util::Fault qw(throw_gen rethrow_exception);

################################################################################
# Programmatic Dependences
use Encode qw(from_to);
use Encode::Alias;
################################################################################
# Inheritance
################################################################################
use base qw(Bric);

################################################################################
# Function Prototypes
################################################################################
sub _convert;

##############################################################################
# Constants
##############################################################################
# Map some useful aliases.
define_alias JIS           => 'ISO-2022-JP';
define_alias 'X-EUC-JP'    => 'ISO-2022-JP';
define_alias 'SHIFT-JIS'   => 'SJIS';
define_alias 'X-SHIFT-JIS' => 'SJIS';
define_alias 'X-SJIS'      => 'SJIS';

################################################################################
# Fields
################################################################################
# Instance Fields
BEGIN {
    Bric::register_fields({
			 # Public Fields

			 # Private Fields
			 _charset => Bric::FIELD_NONE,
			});
}

################################################################################
# Class Methods
################################################################################

=head1 INTERFACE

=head2 Constructors

=over 4

=item my $chartrans = Bric::Util::CharTrans->new($charset)

B<Throws:>

=over 4

=item *

Unspecified charset

=item *

Unknown charset

=back

B<Side Effects:>

B<Notes:> Use new() to get a working CharTrans object.

=cut

sub new {
    my $pkg = shift;
    my $self = bless {}, ref $pkg || $pkg;
    $self->charset(shift);
}

################################################################################

=back

=head2 Public Class Methods

None.

=head2 Public Instance Methods

=over 4

=item my $charset = $chartrans->charset;

=item $chartrans = $chartrans->charset($new_charset);

Gets the current target character set in use.

Optionally sets the current character set.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub charset {
    my $self = shift;
    return $self->{_charset} unless @_;

    my $charset = shift;
    throw_gen "Unspecified character set" unless $charset;
    # getEncoding is undocumented, but very useful. It's in the Encode test
    # suite.
    throw_gen "Invalid character set" unless Encode->getEncoding($charset);

    $self->{_charset} = $charset;
    return $self;
}

##############################################################################

=item $chartrans = $chartrans->to_utf8($somedata);

Performs an in-place conversion of the data in C<$somedata> from the character
set specified via C<charset()> to UTF-8. References to SCALARs, ARRAYs, and
HASHes will be recursively processed and their data replaced.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub to_utf8 {
    my $self = shift;
    return $self unless defined $_[0];
    _convert shift, $self->charset, 'utf8';
    return $self;
}



##############################################################################

=item my $target_text = $chartrans->from_utf8($utf8_text);

Performs an in-place conversion of the UTF-8 data in C<$utf8_text> to the
character set specified via C<charset()>. References to SCALARs, ARRAYs, and
HASHes will be recursively processed and their data replaced.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub from_utf8 {
    my $self = shift;
    return $self unless defined $_[0];
    _convert shift, 'utf8', $self->charset;
    return $self;
}

##############################################################################
# Private Functions.

=begin private

=item _convert

  _convert $string, $from, $to;

Converts C<$string> in-place from character set C<$from> to character set
C<$to>. This is the function that does most of the work for C<to_utf8()> and
C<from_utf8()>, in that it handles recursive conversion of all of the strings
of a data structure.

=cut

sub _convert {
    if (my $ref = ref $_[0]) {
        my $in = shift;
        if ($ref eq 'SCALAR') {
            return from_to($$in, $_[0], $_[1]);
        } elsif ($ref eq 'ARRAY') {
            # Recurse through the array elements.
            _convert($_, @_) for @$in;
        } elsif ($ref eq 'HASH') {
            # Recurse through the hash values.
            _convert($_, @_) for values %$in;
        } else {
            # Do nothing.
        }
    } else {
        return from_to(shift, $_[0], $_[1]);
    }
}

=end private

=cut

1;
__END__

=back

=head1 NOTES

None.

=head1 AUTHOR

Paul Lindner <lindner@inuus.com>

=head1 SEE ALSO

L<Bric|Bric>,
L<Encode|Encode>

=cut
