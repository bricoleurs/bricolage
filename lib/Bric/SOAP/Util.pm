package Bric::SOAP::Util;
###############################################################################

use strict;
use warnings;

use Bric::Biz::Asset::Business::Story;
use Bric::Biz::AssetType;
use Bric::Biz::Category;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
		    category_path_to_id 
		    xs_date_to_pg_date pg_date_to_xs_date
		   );

=head1 NAME

Bric::SOAP::Util - utility class for the Bric::SOAP classes

=head1 VERSION

$Revision: 1.1 $

=cut

our $VERSION = (qw$Revision: 1.1 $ )[-1];

=head1 DATE

$Date: 2002-01-25 19:25:11 $

=head1 SYNOPSIS

  use Bric::SOAP::Util qw(category_path_to_script)

  my $category_id = category_path_to_id($path);

=head1 DESCRIPTION

This module provides various utility methods of use throughout the
Bric::SOAP classes.

=cut

=head1 INTERFACE

=head2 Exportable Functions

=over 4

=item * $category_id = category_path_to_id($path)

Returns a category_id for the path specified or undef if none match.

Throws: NONE

Side Effects: NONE

Notes: NONE

=cut

sub category_path_to_id {
  my $path = shift;
  foreach my $cat (Bric::Biz::Category->list()) {
    return $cat->get_id if $cat->ancestry_path eq $path;
  }
  return undef;
}

=item * $pg_date = xs_date_to_pg_date($xs_date)

Transforms an XML Schema dateTime format date to a Postgres format
date.  Returns undef if the input date is invalid.

Throws: NONE

Side Effects: NONE

Notes: NONE

=cut

sub xs_date_to_pg_date {
    my $xs = shift;

    my ($CC, $YY, $MM, $DD, $hh, $mm, $ss, $tz) = $xs =~
	/^(\d\d)(\d\d)-(\d\d)-(\d\d)T(\d\d):(\d\d):(\d\d)(.*)$/;
    return undef unless $CC;
    $tz = 'UTC' if defined $tz and $tz eq 'Z';
	
    return "${CC}${YY}-${MM}-${DD} ${hh}:${mm}:${ss}" .
	(defined $tz ? (' ' . $tz) : '');
}    

=item * $xs_date = pg_date_to_xs_date($pg_date)

Transforms an a Postgres format date into an XML Schema dataTime
format date.  Returns undef if the input date is invalid.

Throws: NONE

Side Effects: NONE

Notes: NONE

=cut

sub pg_date_to_xs_date {
    my $pg = shift;

    my ($CC, $YY, $MM, $DD, $hh, $mm, $ss, $tz) =  $pg =~
	/^(\d\d)(\d\d)-(\d\d)-(\d\d) (\d\d):(\d\d):(\d\d)(.*)$/;
    return undef unless $CC;
	
    # translate timezone 
    if ($tz) {
	if ($tz eq "+00") {
	    $tz = 'Z';
	} elsif ($tz =~ /^\+\d\d$/) {
	    $tz .= ':00';
	}
    } else {
	$tz = "";
    }
	
    return "${CC}${YY}-${MM}-${DD}T${hh}:${mm}:${ss}$tz";
}

=back

=head1 AUTHOR

Sam Tregar <stregar@about-inc.com>

=head1 SEE ALSO

L<Bric::SOAP|Bric::SOAP>

=cut

1;
