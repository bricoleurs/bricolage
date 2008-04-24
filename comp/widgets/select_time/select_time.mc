<%doc>

=head1 NAME

select_time - A widget to facilitate time input.

=head1 VERSION

$LastChangedRevision$

=head1 DATE

$Id$

=head1 SYNOPSIS

<& '/widgets/select_time/select_time.mc', style => $style &>

=head1 DESCRIPTION

A time input widget. This widget by default provides input pulldowns for year,
month, day, hour and minute. Optionally, a pulldown for seconds can be added,
as well as a text field for miliseconds or microseconds. Parameters for this
widgets are:

=over 4

=item *

base_name

The base name used for all form field elements in this widget.  For example, 
given a base name of 'time', the month form field will have the name 
'time_mon'.  You can use these names in your widget to retrieve the time values.

=item *

style

The way this widget should look.  Currently the only style available is 'inline'
which displays each time field as a pulldown menu in a horizontal row.  To
define other styles with different controls or a different look, just copy the
default 'inline.html' file in this directory to a different name, and edit it.

=item *

no_year

=item *

no_mon

=item *

no_day

=item *

no_hour

=item *

no_min

These options can be given with true values to turn off collection of their 
respective units of time. They're false by default.

=item *

no_sec

=item *

no_mil

=item *

no_mic

These options can be given with false values to turn on collection of their
respective units of time. They're true by default.

=item *

default_current

If this is set to a true value, the time widget will use the current time as 
default values for its time fields.

=item *

def_date

This accepts a date formatted as it would be coming out of the database
('CCYY-MM-DD hh:mm:ss' or ''CCYY-MM-DD hh:mm:ss.xxxxxx'), and uses it to set
the default time of this widget. Defaults to the current time. If passed an
empty string, it'll default to no time.

=item *

def_year

=item *

def_mon

=item *

def_day

=item *

def_hour

=item *

def_min

=item *

def_sec

=item *

def_mil

=item *

def_mic

Supply default values for each of the time fields.

=item *

precision

Provides a numeric value corresponding to one of the precision constants
exported by Bric::Util::Time to determine what precision level the select time
widget should use. Defaults to C<MINUTE> if not specified.

=back

=head1 NOTES

This widget will set some parameters after it has been submitted on a page.  The
 date that is selected will be formatted and saved in a parameter named 
"$base_name" where $base_name is the value of the base_name argument passed to 
this widget.

Additionally, if the user sets some of the date but leaves other fields unset 
the parameter named "$base_name-partial" will be set to 1.

=cut

</%doc>
<%args>
$base_name       => 'time'
$style           => 'inline'
$def_date        => strfdate()
$def_year        => undef
$def_mon         => undef
$def_day         => undef
$def_hour        => undef
$def_min         => undef
$def_sec         => undef
$def_mil         => undef
$def_mic         => undef
$no_year         => 0
$no_mon          => 0
$no_day          => 0
$no_hour         => 0
$no_min          => 0
$no_sec          => 0
$no_mil          => 0
$no_mic          => 0
$default_current => 0
$useTable        => 0
$compact         => 0
$indent          => undef
$disp            => undef
$repopulate      => 0
$read_only       => 0
$precision       => MINUTE
</%args>
<%once>;
my $widget = 'select_time';
my @mon = map { $lang->maketext($_) }
 qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
my @day  = ('01'..'31');
my @hour = ('00'..'23');
my @min  = ('00'..'59');
</%once>
<%init>;
# Set default values if they were passed.
my $sub_widget = "$widget.$base_name";

# Only grab the old data if we are repopulating this form ourselves.
my $s = $repopulate ? get_state_data($sub_widget) : {};
my $tz = Bric::Util::Pref->lookup_val('Time Zone');

# Get the date parts if a db date value was passed for a default.
if ($def_date || $default_current) {
    my $dt = $def_date
      ? datetime($def_date, $tz)           # Assume preferred TZ.
      : DateTime->now->set_time_zone($tz); # Convert to preferred TZ from UTC.
    $s->{year} ||= $dt->strftime('%Y');
    $s->{mon}  ||= $dt->strftime('%m');
    $s->{day}  ||= $dt->strftime('%d');
    $s->{hour} ||= $dt->strftime('%H');
    $s->{min}  ||= $dt->strftime('%M');
    $s->{sec}  ||= $dt->strftime('%S');
    $s->{mil}  ||= $dt->millisecond;
    $s->{mic}  ||= $dt->microsecond;
} else {
    $s->{year} ||= $def_year || '';
    $s->{mon}  ||= $def_mon  || '';
    $s->{day}  ||= $def_day  || '';
    $s->{hour} ||= $def_hour || '';
    $s->{min}  ||= $def_min  || '';
    $s->{sec}  ||= $def_sec  || '';
    $s->{mil}  ||= $def_mil  || '';
    $s->{mic}  ||= $def_mic  || '';
}

my %fields;
my $y = exists $s->{year} && $s->{year} ne '' && $s->{year} ne '-1'
  ? $s->{year}
  : DateTime->now->set_time_zone($tz)->strftime('%Y');

$precision ||= MINUTE;
$fields{year} = [$y - YEAR_SPAN_BEFORE .. $y + YEAR_SPAN_AFTER]
  unless $precision < YEAR || $no_year;

$fields{mon}  = \@mon  unless $precision < MONTH       || $no_mon;
$fields{day}  = \@day  unless $precision < DAY         || $no_day;
$fields{hour} = \@hour unless $precision < HOUR        || $no_hour;
$fields{min}  = \@min  unless $precision < MINUTE      || $no_min;
$fields{sec}  = \@min  unless $precision < SECOND      || ($no_sec && $no_mil && $no_mic);
$fields{mil}  = 1      unless $precision < MILLISECOND || $no_mil;
$fields{mic}  = 1      unless $precision < MICROSECOND || $no_mic;

set_state_data($sub_widget, $s);

$style .= '_ro' if $read_only;
$m->comp("$style.html",
	 widget          => $widget,
	 base_name       => $base_name,
	 default_current => $default_current,
	 useTable        => $useTable,
	 indent          => $indent,
	 compact         => $compact,
	 disp            => $disp,
         def_date        => $def_date,
         s               => $s,
         %fields
	);

# Clear the state data now that the form fields have been repopulated.
set_state_data("$widget.$base_name", {});
</%init>
