%#--- Documentation ---#

<%doc>

=head1 NAME

select_time - A widget to facilitate time input.

=head1 VERSION

$Revision: 1.6 $

=head1 DATE

$Date: 2002-05-20 03:21:58 $

=head1 SYNOPSIS

<& '/widgets/select_time/select_time.mc', style => $style &>

=head1 DESCRIPTION

A time input widget.  This widget by default provides input pulldowns for year, 
month, day, hour and minute.  Parameters for this widgets are:

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
respective unit of time.

=item *

default_current

If this is set to a true value, the time widget will use the current time as 
default values for its time fields.

=item *

def_date

This accepts a date formatted as it would be coming out of the database, that 
is 'YYYY/MM/DD hh:mm:ss' and uses it to set the default time of this widget.
Defaults to the current time. If pass in an empty string, it'll default to no
time.

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

Supply default values for each of the time fields.

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

%#--- Arguments ---#

<%args>
$base_name       => 'time'
$style           => 'inline'
$def_date        => strfdate()
$def_year        => undef
$def_mon         => undef
$def_day         => undef
$def_hour        => undef
$def_min         => undef
$no_year         => 0
$no_mon          => 0
$no_day          => 0
$no_hour         => 0
$no_min          => 0
$default_current => 0
$useTable        => 0
$compact         => 0
$indent          => undef
$disp            => undef
$repopulate      => 1
</%args>

<%once>
my $widget = 'select_time';

my @t = localtime;
# Get a good 6 year range starting from last year.
my @year = ($t[5]+1899..$t[5]+1905);
my @mon  = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
my @day  = ('01'..'31');
my @hour = ('00'..'23');
my @min  = ('00'..'59');
</%once>

%#--- Initialization ---#

<%init>

my %fields;
$fields{'year'} = \@year unless $no_year;
$fields{'mon'}  = \@mon  unless $no_mon;
$fields{'day'}  = \@day  unless $no_day;
$fields{'hour'} = \@hour unless $no_hour;
$fields{'min'}  = \@min  unless $no_min;

my @t;

# Get the date parts if a db date value was passed for a default.
if ($def_date) {
    # Code from Bric::Util::DBD::Pg
    eval { @t = unpack('a4 x a2 x a2 x a2 x a2 x a2', $def_date) };

    if ($@) {
	my $err_msg = "Unable to parse date '$def_date'";
	die Bric::Util::Fault::Exception::DP->new({'msg'     => $err_msg,
						 'payload' => $@});
    }
}

# Set default values if they were passed.
my ($s, $sub_widget);

$sub_widget = "$widget.$base_name";

# Only grab the old data if we are repopulating this form ourselves.
if ($repopulate) {
    $s = get_state_data($sub_widget);
}

$s->{'year'} ||= $t[0] || $def_year || '';
$s->{'mon'}  ||= $t[1] || $def_mon || '';
$s->{'day'}  ||= $t[2] || $def_day || '';
$s->{'hour'} ||= $t[3] || $def_hour || '';
$s->{'min'}  ||= $t[4] || $def_min || '';

set_state_data($sub_widget, $s);

$m->comp("$style.html", 
	 widget          => $widget, 
	 base_name       => $base_name, 
	 default_current => $default_current,
	 useTable        => $useTable,
	 indent          => $indent,
	 compact         => $compact,
	 disp            => $disp,
         %fields
	);

# Clear the state data now that the form fields have been repopulated.
set_state_data("$widget.$base_name", {});

</%init>

%#--- Log History ---#


