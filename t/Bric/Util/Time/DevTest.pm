package Bric::Util::Time::DevTest;
use strict;
use warnings;
use base qw(Bric::Test::DevBase);
use Test::More;
use Bric::Util::DBI qw(DB_DATE_FORMAT);
use Bric::Config qw(:time);
use Bric::Util::Pref;
use Bric::Util::Time qw(:all);
use DateTime;

my $epoch = CORE::time;

BEGIN {
    # Override the time function, but just have it use CORE::time. This will
    # allow us to hijack the function later by locally redefining
    # CORE::GLOBAL::time. This is to prevent those tests that test for the
    # time *right now* from getting screwed up by the clock turning over.
    *CORE::GLOBAL::time = sub () { CORE::time() };
}

##############################################################################
# Set up needed variables.
##############################################################################
my $format = '%m/%d/%Y at %T';
my $pref_format = Bric::Util::Pref->lookup_val('Date/Time Format');
(my $short_iso_format = ISO_8601_FORMAT) =~ s/\.\%6N$//;

my $now = DateTime->from_epoch( epoch => $epoch, time_zone => 'UTC');
my $db_date = $now->strftime(DB_DATE_FORMAT);
my $utc_date = $now->strftime($pref_format);
my $utc_iso_date = $now->strftime(ISO_8601_FORMAT);
my $utc_iso_short_date = $now->strftime($short_iso_format);
my $fmt_utc = $now->strftime($format);

my $tz = Bric::Util::Pref->lookup_val('Time Zone');
$now->set_time_zone($tz);
my $local_date = $now->strftime($pref_format);
my $local_iso_date = $now->strftime(ISO_8601_FORMAT);
my $local_iso_short_date = $now->strftime($short_iso_format);
my $fmt_local = $now->strftime($format);

##############################################################################
# Test the exported functions.
##############################################################################
# Test strfdate().
sub test_strfdate : Test(4) {
    no warnings qw(redefine);
    local *CORE::GLOBAL::time = sub () { $epoch };
    is( strfdate($epoch), $local_iso_date,
        "Check strfdate is '$local_iso_date'" );
    is( strfdate($epoch, undef, 1), $utc_iso_date,
        "Check strfdate is '$utc_iso_date'" );
    is( strfdate($epoch, $format), $fmt_local,
        "Check strfdate is '$fmt_local" );
    is( strfdate($epoch, $format, 1), $fmt_utc,
        "Check strfdate is '$fmt_utc" );
}

##############################################################################
# Test local_date().
sub test_local_date : Test(6) {
    no warnings qw(redefine);
    local *CORE::GLOBAL::time = sub () { $epoch };
    is( local_date($utc_date), $local_date,
        "Check local date is '$local_date'" );
    is( local_date($utc_iso_short_date), $local_date,
        "Check short local date is '$local_date'" );
    is( local_date($utc_iso_date, $format), $fmt_local,
        "Check local date is '$fmt_local'" );
    is( local_date($utc_iso_date, 'epoch'), $epoch,
        "Check that local date is '$epoch'" );

    # Check the local date with a known format argument.
    my $current = DateTime->now(time_zone => $tz)->strftime(ISO_8601_FORMAT);
    is( local_date(undef, ISO_8601_FORMAT, 1), $current,
        "Check local date is current" );

    # Check the local date in the preferred format.
    $current = DateTime->now(time_zone => $tz)->strftime($pref_format);
    is( local_date(undef, undef, 1), $current,
        "Check local date is current" );
}

##############################################################################
# Test db_date().
sub test_db_date : Test(3) {
    no warnings qw(redefine);
    local *CORE::GLOBAL::time = sub () { $epoch };
    is( db_date($local_iso_date), $db_date, "Check db date is '$db_date'" );
    is( db_date($local_iso_short_date), $db_date,
        "Check short db date is '$db_date'" );
    # Hope that the clock doesn't click over during this test.
    is( db_date(undef, 1), DateTime->now->strftime(DB_DATE_FORMAT),
        "Check db date is curent" );
}

sub test_datetime : Test(16) {
    ok my $dt = datetime('2005-03-23T19:30:05'), "Create dt without subseconds";
    is $dt->year, 2005, '...The year should be correct';
    is $dt->month, 3, '...The month should be correct';
    is $dt->day, 23, '...The day should be correct';
    is $dt->hour, 19, '...The hour should be correct';
    is $dt->minute, 30, '...The minute should be correct';
    is $dt->second, 5, '...The second should be correct';
    is $dt->microsecond, 0, "...The microsecond should be correct";

    ok $dt = datetime('2005-03-23T19:30:05.1234'), "Create dt with subseconds";
    is $dt->year, 2005, '...The year should be correct';
    is $dt->month, 3, '...The month should be correct';
    is $dt->day, 23, '...The day should be correct';
    is $dt->hour, 19, '...The hour should be correct';
    is $dt->minute, 30, '...The minute should be correct';
    is $dt->second, 5, '...The second should be correct';
    is $dt->microsecond, 123400, "...The microsecond should be correct";
}
1;
__END__
