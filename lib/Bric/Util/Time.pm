package Bric::Util::Time;

=pod

=head1 NAME

Bric::Util::Time - Bricolage Time & Date Functions

=head1 VERSION

$Revision: 1.4 $

=cut

# Grab the Version Number.
our $VERSION = (qw$Revision: 1.4 $ )[-1];

=pod

=head1 DATE

$Date: 2001-11-20 00:02:45 $

=head1 SYNOPSIS

  use Bric::Util::Time ':all';
  my $formatted_date = strfdate($epoch_time, $format, $utc);
  my $local_date = local_date($db_date, $format);
  my $db_date = $db_date($iso_local_date);

=head1 DESCRIPTION

This package provides time and date formatting functions that may be imported
into other Bricolage packages and classes.

=cut

################################################################################
# Dependencies
################################################################################
use strict;
use Time::Local;
use Bric::Config qw(:time);
use Bric::Util::Fault::Exception::AP;
use Bric::Util::DBI qw(db_date_parts DB_DATE_FORMAT);
use Bric::Util::Pref;

################################################################################
# Constants
################################################################################
use constant DEBUG => 0;
my $fsub; # Will be used in BEGIN.

# ISO 8601 Date Settings.
my $ISO_TEMPLATE =  'a4 x a2 x a2 x a2 x a2 x a2';

################################################################################
# Inheritance
################################################################################
use base 'Exporter';
# You can explicitly import any of the functions in this class.
our @EXPORT_OK = qw(strfdate local_date db_date);

# But you'll generally just want to import a few standard ones or all of them
# at once.
our %EXPORT_TAGS = (all => \@EXPORT_OK);


############################################################################
# Private Functions
############################################################################
# Decide on a time formatting function. Use Apache::Util::ht_time in an
# Apache Environment, and POSIX::strftime elsewhere.
BEGIN {
    if ($ENV{MOD_PERL}) {
	require Apache::Util;
	die $@ if $@;
	$fsub = sub {
	    my ($t, $f) = @_;
	    $t ||= time;
	    $f ||= ISO_8601_FORMAT;
	    my $time;
	    eval {
		$time = Apache::Util::ht_time($t, $f, 0);
	    };
	    die Bric::Util::Fault::Exception::AP->new(
             { msg => "Unable to format date.", payload => $@ }) if $@;
	    return $time;
	};
    } else {
	require POSIX;
	$fsub = sub {
	    my ($t, $f) = @_;
	    $t ||= time;
	    $f ||= ISO_8601_FORMAT;
	    my $time;
	    eval {
	     $time = POSIX::strftime($f || ISO_8601_FORMAT, localtime($t));
	    };
	    die Bric::Util::Fault::Exception::AP->new(
             { msg => "Unable to format date.", payload => $@ }) if $@;
	    return $time;
	};
    }
}

################################################################################
my $iso_parts = sub {
    # Takes an ISO 8601-formatted date string and returns its parts in the order
    # and format expected by strftime. A similar function, db_date_parts(), is
    # imported from the database driver module.
    my @t;
    eval { @t = unpack($ISO_TEMPLATE, shift) };
    die Bric::Util::Fault::Exception::AP->new(
      { msg => "Unable to unpack date.", payload => $@ }) if $@;
    $t[0] -= 1900;
    $t[1] -= 1;
    return reverse @t;
}; # &$iso_parts()

################################################################################
# Exportable Functions
################################################################################

=pod

=head1 INTERFACE

To use any of the functons in Bric::Util::Time, you must explicitly import them
into your module's namespace. This can be done in one of two ways: All of them
can be imported at once, or they can be imported individually, one a a time:

  use Bric::Util::Time qw(:all);               # Imports them all.
  use Bric::Util::Time qw(local_date db_date); # Imports only those listed.

=head2 Constructors

NONE.

=head2 Destructors

NONE.

=head2 Public Class Methods

NONE.

=head2 Public Instance Methods

NONE.

=head2 Functions

=over 4

=item strfdate([$time[, $format[, $utc]]])

Returns a formatted date/time string. $time is the epoch time to be formatted.
It will use the Time Zone preference set via Bric::App::Pref unless $utc is true,
in which case the time will be formatted is UTC time. Use POSIX::setlocale to
have the strfdate() output a localized format of $time - otherwise it defaults
to the system's locale. $format is the stftime format in which $time should be
formatted; defaults to ISO 8601-compliant time formatting ("%G-%m-%d %T").

B<Throws:> NONE.

B<Side Effects>: NONE.

B<Notes:>

=over 4

=item *

Unable to format date.

=back

=cut

sub strfdate {
    $ENV{TZ} = $_[2] ? 'UTC' : Bric::Util::Pref->lookup_val('Time Zone');
    return &$fsub(@_[0..1]);
}

################################################################################

=pod

=item local_date($db_date)

=item local_date($db_date, $format)

=item local_date(undef, undef, $bool)

=item local_date(undef, $format, $bool)

Takes a date/time string formatted for the database, converts it to the local
time zone, and returns it in the strftime format provided by $format. If $format
is not provided, the date/time will be returned in the format specified by the
Date/Time Format preference. If $format is 'epoch', it will return the time in
epoch seconds. Set $ENV{TZ} to get a different localtime. If $db_date is not
provided and $bool is false, then local_date() returns undef. If $db_date is not
provided and $bool is true, then local_date() returns the current date/time.

Use this function in your accessors to return a localized date/time string to
your object users.

  sub get_date { local_date($_[0]->_get('date'), $_[1]); }

B<Throws:>

=over 4

=item *

Unable to unpack date.

=item *

Unable to format date.

=back

B<Side Effects>: NONE.

B<Notes:> NONE.

=cut

sub local_date {
    # Converts a database date string into the user's preferred time zone, and
    # formats it into the ISO 8601 date format or whatever format is passed in.
    my ($db_date, $format, $bool) = @_;
    return unless $db_date || $bool;
    $format ||= Bric::Util::Pref->lookup_val('Date/Time Format');
    # Set the time zone.
    $ENV{TZ} = Bric::Util::Pref->lookup_val('Time Zone');
    return $db_date ? timegm(db_date_parts($db_date)) : time
      if $format eq 'epoch';
    &$fsub($db_date ? timegm(db_date_parts($db_date)) : undef, $format);
} # strfdate()

################################################################################

=pod

=item db_date($local_date)

=item db_date($local_date, $now)

Takes an ISO 8601 formatted date/time string in the local time zone, converts it
to UTC, and returns it in the format required by the database. If $iso_date is
not provided, it returns undef, unless $now is true, in which case it provides
the current UTC time.

Use this function to convert a date/time string provided by your object's
consumer into the format required by the database.

  sub set_date { db_date($_[1]); }

B<Throws:>

=over 4

=item *

Unable to unpack date.

=item *

Unable to format date.

=back

B<Side Effects>: NONE.

B<Notes:> NONE.

=cut

sub db_date {
    # Return if there's no date and they don't want the current date.
    return unless $_[0] || $_[1];
    # Set the time zone.
    $ENV{TZ} = Bric::Util::Pref->lookup_val('Time Zone');
    my $local_date = $_[0] ? timelocal(&$iso_parts($_[0])) : time;
    # Set the time zone again.
    $ENV{TZ} = 'UTC';
    # Format the date and return it.
    &$fsub($local_date, DB_DATE_FORMAT);
} # db_date_format()

1;
__END__

=pod

=back 4

=head1 PRIVATE

NONE.

=head2 Private Class Methods

NONE.

=head2 Private Instance Methods

NONE.

=head2 Private Functions

NONE.

=head1 NOTES

NONE.

=head1 AUTHOR

David E. Wheeler <david@wheeler.net>

=head1 SEE ALSO

perl(1), Bric (2), Bric::Util::DBI(3)

=cut


