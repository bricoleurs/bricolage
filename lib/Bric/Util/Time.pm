package Bric::Util::Time;

=pod

=head1 Name

Bric::Util::Time - Bricolage Time & Date Functions

=cut

# Grab the Version Number.
require Bric; our $VERSION = Bric->VERSION;

=pod

=head1 Synopsis

  use Bric::Util::Time ':all';
  my $formatted_date = strfdate($epoch_time, $format, $utc);
  my $local_date = local_date($db_date, $format);
  my $db_date = db_date($iso_local_date);
  my $dt = datetime($iso_format_date, $tz);

=head1 Description

This package provides time and date formatting functions that may be imported
into other Bricolage packages and classes.

=cut

##############################################################################
# Dependencies
##############################################################################
use strict;
use DateTime;
use DateTime::TimeZone;
use Bric::Config qw(:time);
use Bric::Util::Fault qw(throw_dp);
use Bric::Util::DBI qw(db_datetime DB_DATE_FORMAT);
use Bric::Util::Pref;

##############################################################################
# Inheritance
##############################################################################
use base 'Exporter';
# You can explicitly import any of the functions in this class.
our @EXPORT_OK = qw(strfdate local_date db_date datetime MICROSECOND
                    MILLISECOND SECOND MINUTE HOUR DAY MONTH YEAR PRECISIONS);

# But you'll generally just want to import a few standard ones or all of them
# at once.
our %EXPORT_TAGS = (all => \@EXPORT_OK);
$ENV{TZ} = 'UTC';

use constant YEAR        => 1;
use constant MONTH       => 2;
use constant DAY         => 3;
use constant HOUR        => 4;
use constant MINUTE      => 5;
use constant SECOND      => 6;
use constant MILLISECOND => 7;
use constant MICROSECOND => 8;
#use constant NANOSECOND  => 9;
use constant PRECISIONS  => [
    [ YEAR,        'Year'        ],
    [ MONTH,       'Month'       ],
    [ DAY,         'Day'         ],
    [ HOUR,        'Hour'        ],
    [ MINUTE,      'Minute'      ],
    [ SECOND,      'Second'      ],
    [ MILLISECOND, 'Millisecond' ],
    [ MICROSECOND, 'Microsecond' ],
#    [ NANOSECOND,  'Nanosecond'  ],
];

# Load time zones.
for my $tz (split ' ', LOAD_TIME_ZONES) {
    eval "use DateTime::TimeZone::" . join '::', split('/', $tz);
    die $@ if $@;
}

##############################################################################
# Exportable Functions
##############################################################################

=head1 Interface

To use any of the functons in Bric::Util::Time, you must explicitly import
them into your module's namespace. This can be done in one of two ways: All of
them can be imported at once, or they can be imported individually, one a a
time:

  use Bric::Util::Time qw(:all);               # Imports them all.
  use Bric::Util::Time qw(local_date db_date); # Imports only those listed.

=head2 Constants

These constants define values that can be used comparatively to determine
which are the more precise time parts. The higher the value, the more precise
the time part.

=over 4

=item YEAR

=item MONTH

=item DAY

=item HOUR

=item MINUTE

=item SECOND

=item MILLISECOND

=item MICROSECOND

=begin comment

=item NANOSECOND

=end comment

=back

=head3 PRECISIONS

This constant contains an array reference of array references with strings
corresponding to the numeric value of each time part. This constant is
suitable for passing to a select list for display.

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

Returns a formatted date/time string. C<$time> is the epoch time to be
formatted. It will use the Time Zone preference set via Bric::App::Pref unless
C<$utc> is true, in which case the time will be formatted in UTC time. Use
C<< DateTime->DefaultLocale() >> to have the C<strfdate()> output a localized
format of C<$time>--otherwise it defaults to the "English" locale. C<$format>
is the stftime format in which C<$time> should be formatted; defaults to ISO
8601-compliant time formatting ("%Y-%m-%d %T.%6N").

B<Throws:> NONE.

B<Side Effects>: NONE.

B<Notes:>

=over 4

=item *

Unable to format date.

=back

=cut

sub strfdate {
    my ($epoch, $format, $utc) = @_;
    my $dt = DateTime->from_epoch(
        epoch     => ( defined $epoch ? $epoch : time),
        time_zone => $utc ? 'UTC' : Bric::Util::Pref->lookup_val('Time Zone')
    );
    return $dt->strftime($format || ISO_8601_FORMAT);
}

##############################################################################

=item local_date($db_date)

=item local_date($db_date, $format)

=item local_date(undef, undef, $bool)

=item local_date(undef, $format, $bool)

Takes a date/time string formatted for the database, converts it to the time
zone set in the "Time Zone" preference, and returns it in the C<strftime>
format provided by C<$format>. If C<$format> is not provided, the date/time
will be returned in the format set in the "Date/Time Format" preference. If
C<$format> is 'epoch', it will return the time in epoch seconds. If
C<$db_date> is not provided and C<$bool> is false, then C<local_date()>
returns C<undef>. If C<$db_date> is not provided and C<$bool> is true, then
C<local_date()> returns the current date/time.

Use this function in Bricolage accessor methods to return a localized
date/time string.

  sub get_date { local_date($_[0]->_get('date'), $_[1]); }

B<Throws:>

=over 4

=item *

Unable to parse date.

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
    my $dt = $db_date ? db_datetime($db_date) : DateTime->now;
    $dt->set_time_zone(Bric::Util::Pref->lookup_val('Time Zone'));
    return $format eq 'epoch' ? $dt->epoch : $dt->strftime($format);
} # strfdate()

##############################################################################

=item db_date($local_date)

=item db_date($local_date, $now)

=item db_date($local_date, undef, $tz)

Takes an ISO 8601 formatted date/time string in the time zone set in the "Time
Zone" preference, converts it to UTC, and returns it in the format required by
the database. If C<$local_date> is not provided, it returns C<undef>, unless
C<$now> is true, in which case it provides the current UTC time. If C<$tz> is
set, then C<db_date()> uses the supplied time zone instead of using the local
time zone.

Use this function to convert a date/time string provided by your object's
consumer into the format required by the database.

  sub set_date { db_date($_[1]); }

B<Throws:>

=over 4

=item *

Unable to parse date.

=back

B<Side Effects>: NONE.

B<Notes:> NONE.

=cut

sub db_date {
    my ($date, $now, $tz) = @_;
    return datetime($date, $tz)->set_time_zone('UTC')->strftime(DB_DATE_FORMAT)
      if $date;
    return DateTime->now->strftime(DB_DATE_FORMAT) if $now;
    return;
} # db_date_format()

=item datetime($iso_formatted_date)

=item datetime($iso_formatted_date, $tz)

Takes an ISO 8601 formatted date/time string and returns a DateTime object.
The timze zone set on the DateTime object will be either the value of C<$tz>
or the value set in the "Time Zone" preference.

B<Throws:>

=over 4

=item *

Unable to parse date.

=back

B<Side Effects>: NONE.

B<Notes:> NONE.

=cut

sub datetime {
    my ($date, $tz) = @_;
    return unless $date;
    $tz ||= Bric::Util::Pref->lookup_val('Time Zone');
    my $dt = eval {
        $date =~ m/^(\d\d\d\d).(\d\d).(\d\d).(\d\d).(\d\d).(\d\d)(\.\d*)?/;
        DateTime->new( year       => $1,
                       month      => $2,
                       day        => $3,
                       hour       => $4,
                       minute     => $5,
                       second     => $6,
                       time_zone  => $tz,
                       nanosecond => $7 ? $7 * 1.0E9 : 0
                   );
    };
    throw_dp error   => qq{Unable to parse date "$date" $@},
             payload => $@
        if $@;
    return $dt;
}

=begin comment

The above date parsing can be done with unpack(), too. But I benchmarked them,
and could see virtually no difference in performance. If anything, the regex
approach is a hair faster!

  #!/usr/bin/perl -w
  use warnings;
  use strict;
  use DateTime;
  use Benchmark;

  my $date = '2005-03-23T19:30:05.1234';
  my $ISO_TEMPLATE =  'a4 x a2 x a2 x a2 x a2 x a2 a*';

  sub with_pack {
      my %args;
      @args{qw(year month day hour minute second nanosecond)}
        = unpack $ISO_TEMPLATE, $date;
      { no warnings; $args{nanosecond} *= 1.0E9; }
  }

  sub with_regex {
      $date =~ m/(\d\d\d\d).(\d\d).(\d\d).(\d\d).(\d\d).(\d\d)(\.\d*)?/;
      my %args = (
          year       => $1,
          month      => $2,
          day        => $3,
          hour       => $4,
          minute     => $5,
          second     => $6,
          nanosecond => $7 ? $7 * 1.0E9 : 0
      );
  }

  timethese(100000, {
      pack => \&with_pack,
      regex => \&with_regex
  });

This script yields:

  Benchmark: timing 100000 iterations of pack, regex...
        pack:  3 wallclock secs ( 2.14 usr +  0.00 sys =  2.14 CPU) @ 46728.97/s (n=100000)
       regex:  3 wallclock secs ( 2.11 usr +  0.01 sys =  2.12 CPU) @ 47169.81/s (n=100000)

So we'll just go with the rgex for now.

=end comment

=cut

1;
__END__

=pod

=back

=head1 Private

NONE.

=head2 Private Class Methods

NONE.

=head2 Private Instance Methods

NONE.

=head2 Private Functions

NONE.

=head1 Notes

ISO 8601 date support is incomplete. Currently, time-zone information in the
date string is ignored. Also, date and time parts (CCYY, MM, DD, hh, mm and
ss) must be separated by a single character.

=head1 Author

David E. Wheeler <david@justatheory.com>

=head1 See Also

L<Bric|Bric>,
L<Bric::Util::DBI|Bric::Util::DBI>

=cut
