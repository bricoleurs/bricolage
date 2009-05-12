package Bric::Util::CharTrans;

=head1 Name

Bric::Util::CharTrans - Interface to Bricolage UTF-8 Character Translations

=cut

# Grab the Version Number.

require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

  # Constructors.
  my $chartrans = Bric::Util::CharTrans->new('iso-8859-1');

  # Instance Methods.
  my $charset     = $chartrans->charset;
  my $charset     = $chartrans->charset('iso-8859-1');

  # (note: this is only in-place now -- it used to also return the string)
  $chartrans->to_utf8(\$some_data);
  $chartrans->from_utf8(\$some_data);


=head1 Description

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

################################################################################
# Function Prototypes
################################################################################
sub _convert;

##############################################################################
# Constants
##############################################################################
# Map some useful aliases.
define_alias 'JIS'         => 'ISO-2022-JP';
define_alias 'X-EUC-JP'    => 'ISO-2022-JP';
define_alias 'SHIFT-JIS'   => 'SJIS';
define_alias 'X-SHIFT-JIS' => 'SJIS';
define_alias 'X-SJIS'      => 'SJIS';

################################################################################
# Fields
################################################################################

################################################################################
# Class Methods
################################################################################

=head1 Interface

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

B<Throws:>

=over 4

=item Error converting data from [charset] to utf-8.

=back

B<Side Effects:> NONE.

B<Notes:>

This used to return the converted string, but it doesn't any more.
Instead, it returns the Bric::Util::CharTrans object itself.

=cut

sub to_utf8 {
    my $self = shift;
    return $self unless defined $_[0];
    _convert \&Encode::decode, $self->charset, shift;
    return $self;
}

##############################################################################

=item my $target_text = $chartrans->from_utf8($utf8_text);

Performs an in-place conversion of the UTF-8 data in C<$utf8_text> to the
character set specified via C<charset()>. References to SCALARs, ARRAYs, and
HASHes will be recursively processed and their data replaced.

B<Throws:>

=over 4

=item Error converting data from utf-8 to [charset].

=back

B<Side Effects:> NONE.

B<Notes:>

This used to return the converted string, but it doesn't any more.
Instead, it returns the Bric::Util::CharTrans object itself.

=cut

sub from_utf8 {
    my $self = shift;
    return $self unless defined $_[0];
    _convert \&Encode::encode, $self->charset, shift;
    return $self;
}

##############################################################################
# Private Functions.

=begin private

=item _convert

  _convert $coderef, $encoding, $data;

Converts the C<$data> string or data structure in-place to or from Perl's
internal UTF-8 data structure. The first argument must be a reference to
either C<Encode::encode()> or to C<Encode::decode()>, depending on whether the
data is being converted to UTF-8 (C<decode()> or from UTF-8 (C<encode()>. This
is the function that does most of the work for C<to_utf8()> and
C<from_utf8()>, in that it handles recursive conversion of all of the strings
of a data structure.

=cut

sub _convert {
    my $code = shift;
    my $encoding = shift;
    eval {
        if (my $ref = ref $_[0]) {
            my $in = shift;
            if ($ref eq 'SCALAR') {
                $$in = $code->($encoding, $$in);
                return;
            } elsif ($ref eq 'ARRAY') {
                # Recurse through the array elements.
                _convert($code, $encoding, $_) for @$in;
                return;
            } elsif ($ref eq 'HASH') {
                # Recurse through the hash values.
                _convert($code, $encoding, $_) for values %$in;
                return;
            } else {
                return;
            }
        } else {
            $_[0] = $code->($encoding, $_[0], 1);
        }
    };

    my $err = $@ or return;
    throw_gen error   => "Error converting data from $encoding to UTF-8",
              payload => $@;
}

1;
__END__

=back

=head1 Notes

None.

=head1 Authors

Paul Lindner <lindner@inuus.com>, David Wheeler <david@kineticode.com>

=head1 See Also

L<Bric|Bric>,
L<Encode|Encode>

=cut
