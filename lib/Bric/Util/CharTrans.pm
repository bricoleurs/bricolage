package Bric::Util::CharTrans;



=head1 NAME

Bric::Util::CharTrans - Interface to Bricolage UTF-8 Character Translations

=head1 VERSION

$Revision: 1.3 $

=cut

# Grab the Version Number.

our $VERSION = substr(q$Revision: 1.3 $, 10, -1);

=head1 DATE

$Date: 2001-10-11 00:34:54 $

=head1 SYNOPSIS

  # Constructors.
  my $chartrans = Bric::Util::CharTrans->new('iso-8859-1');

  # Instance Methods.
  my $charset     = $chartrans->charset();
  my $charset     = $chartrans->charset('iso-8859-1');

  my $utf8_text   = $chartrans->to_utf8($target_text);
  my $target_text = $chartrans->from_utf8($utf8_text); 

  $chartrans->to_utf(\$some_data);
  $chartrans->from_utf(\$some_data);


=head1 DESCRIPTION

Bric::Util::CharTrans provides an object-oriented interface
to conversion of characters from a target character set to Unicode UTF-8
and from Unicode UTF-8 to a target character set.

=cut

################################################################################
# Dependencies
################################################################################
# Standard Dependencies
use strict;
use Text::Iconv; # requires v1.1, not 1.0 which is on CPAN

################################################################################
# Programmatic Dependences

################################################################################
# Inheritance
################################################################################
use base qw(Bric);

################################################################################
# Function Prototypes
################################################################################


##############################################################################
# Constants
##############################################################################
#use constant DEBUG => 0;
#use constant UTF8 => 'UTF8';

# This hash contains aliases for common character sets..
# Useful for mapping 

our $CHARSET_ALIASES =  {
    
	'JIS' => 'ISO-2022-JP',
	'X-EUC-JP'=> 'ISO-2022-JP',
	'SHIFT-JIS' => 'SJIS',
	'X-SHIFT-JIS' => 'SJIS', 
	'X-SJIS' => 'SJIS' 
};


################################################################################
# Fields
################################################################################
# Public Class Fields

################################################################################
# Private Class Fields

################################################################################

################################################################################
# Instance Fields
BEGIN {
    Bric::register_fields({
			 # Public Fields

			 # Private Fields
			 _charset => Bric::FIELD_NONE,
			 _to_utf8_converter => Bric::FIELD_NONE,
			 _from_utf8_converter => Bric::FIELD_NONE
			});
}

################################################################################
# Class Methods
################################################################################

=head1 INTERFACE

=head2 Constructors

=over 4

=item my $chartrans = Bric::Util::CharTrans->new($charset)

=over 4

B<Throws:> errors on invalid or missing character sets

B<Side Effects:> 

B<Notes:> Use new() to get a working CharTrans object.

=cut

sub new {
    my ($pkg, $args) = @_;
    my $self = bless {}, ref $pkg || $pkg;

    my $charset  = $args;
    die "Unspecified charset" unless ($charset);

    $self->charset($charset);

    return $self;
}


################################################################################

=head2 Public Class Methods

none

=head2 Public Instance Methods

=over 4

=item my $utf8_text = $chartrans->to_utf8($somedata, $options);

to_utf8() operates in one of two ways.

If passed a scalar value it returns utf8 text corresponding to text
in $sometext that is encoded in the target character set.

If passed a reference it will recursively process the data within and 
convert it all to UTF-8

$options may contains localized overrides in the future...


B<Throws:> error on text that does not correspond to the specified input text.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut 

sub to_utf8 {
    my ($self, $in, $options) = @_;
    
    return(undef) unless(defined($in));

    my $in_ptr;
    my $out_ptr;

    if (my $in_type = ref($in)) {
	if ($in_type eq 'SCALAR') {
	    $in_ptr = $in;
	    $out_ptr = $in;
	} elsif ($in_type eq 'ARRAY') {
	    # recurse through the array elements..

	    foreach my $idx (0..(scalar(@{$in})-1)) {
		if (ref(@{$in}[$idx])) {
		    $self->to_utf8(@{$in}[$idx]);
		} else {
		    $self->to_utf8(\@{$in}[$idx]);
		}
	    }
	    
	    return;
	} elsif ($in_type eq 'HASH') {
	    foreach my $k (keys(%{$in})) {
		if (ref($in->{$k})) {
		    $self->to_utf8($in->{$k});
		} else {
		    $self->to_utf8(\$in->{$k});
		}
	    }
	    return;
	}
	
    } else {
	my $storage;
	$in_ptr = \$in;
	$out_ptr = \$storage;
    }
    
    my $converter = $self->{_to_utf8_converter};
    return($$out_ptr = $converter->convert($$in_ptr));
}



=item my $target_text = $chartrans->from_utf8($utf8_text);

Returns utf8 text corresponding to text in $sometext

from_utf8() operates in one of two ways.

If passed a scalar value it returns native charset text corresponding to utf-8 
text in $utf8_text.

If passed a reference it will recursively process the data within and 
convert it all to the target character set.


Silently returns undef if passed undef.

B<Throws:> error on text that does not correspond to the specified input text.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut 

sub from_utf8 {
     my ($self, $in, $options) = @_;
     return(undef) unless(defined($in));

     my $in_ptr;
     my $out_ptr;

     if (my $in_type = ref($in)) {
	 if ($in_type eq 'SCALAR') {
	     $in_ptr = $in;
	     $out_ptr = $in;
	 }
     } else {
	 my $storage;
	 $in_ptr = \$in;
	 $out_ptr = \$storage;
     }

    return('') unless(defined($$in_ptr));

     my $converter =  $self->{_from_utf8_converter};
     return($$out_ptr = $converter->convert($$in_ptr));
}



=item my $charset = $chartrans->charset(<$new_charset>);

Gets the current target character set in use.

Optionally sets the current character set.

B<Throws:> error on bad character set / utf8 combinations.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut 

sub charset {

    my ($self, $new_charset) = @_;


    return ($self->{'_charset'}) unless ($new_charset);

    $new_charset = uc($new_charset);

    if ($CHARSET_ALIASES->{$new_charset}) {
    	$new_charset = $CHARSET_ALIASES->{$new_charset};
    }


    # Set up the to/from utf converters, store them in the class.  This
    # also returns the validity of the conversion object right away..

    eval {
		my $cvt = Text::Iconv->new($new_charset, 'UTF8');
		$cvt->raise_error(1);
		$self->{'_to_utf8_converter'} = $cvt;
    };

   die "$!" if ($@);

    eval {
		my $cvt = Text::Iconv->new('UTF8', $new_charset);
		$cvt->raise_error(1);
		$self->{'_from_utf8_converter'} = $cvt;
    };
    die "$!" if ($@);

    $self->{'_charset'} = $new_charset;
    
    return($self->{'_charset'});
}



=back 4

=head1 PRIVATE

=head2 Private Class Methods

NONE.

=head2 Private Instance Methods

=head2 Private Functions

NONE.

=cut


1;
__END__

=head1 NOTES


=head1 AUTHOR

Paul Lindner <lindner@inuus.com>

=head1 SEE ALSO

perl(1),
Bric (2),
iconv(3),
/usr/bin/iconv


=cut

