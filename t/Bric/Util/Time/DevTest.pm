package Bric::Util::Time::DevTest;
use strict;
use warnings;
use base qw(Bric::Test::DevBase);
use Test::More;
use Bric::Util::DBI qw(DB_DATE_FORMAT);
use Bric::Config qw(:time);
use Bric::Util::Pref;
use Bric::Util::Time qw(:all);
use POSIX ();

my $USE_CORE = 1;
my $epoch = CORE::time;

BEGIN {
    # Override the time function. Generally use CORE::time, but when $USE_CORE
    # is set to a false value, always return the value of $epoch, which will
    # remain the same for the lifetime of the tests. This is to prevent those
    # tests that test for the time *right now* from getting screwed up by the
    # clock turning over.
    *CORE::GLOBAL::time = sub { $USE_CORE ? CORE::time : $epoch };
}


##############################################################################
# Set up needed variables.
##############################################################################
my $format = '%m/%d/%Y at %T';
my $pref_format = Bric::Util::Pref->lookup_val('Date/Time Format');

my $db_date = POSIX::strftime(DB_DATE_FORMAT, gmtime($epoch));

my $utc_date = POSIX::strftime($pref_format, gmtime($epoch));
my $utc_iso_date = POSIX::strftime(ISO_8601_FORMAT, gmtime($epoch));
my $fmt_utc = POSIX::strftime($format, gmtime($epoch));

my ($local_date, $local_iso_date, $fmt_local);
{
    local $ENV{TZ} = Bric::Util::Pref->lookup_val('Time Zone');
    $local_date = POSIX::strftime($pref_format, localtime($epoch));
    $local_iso_date = POSIX::strftime(ISO_8601_FORMAT, localtime($epoch));
    $fmt_local = POSIX::strftime($format, localtime($epoch));
}

##############################################################################
# Setup and teardown methods.
##############################################################################
# Don't use the core time for any of these tests.
sub hijack_time : Test(setup => 0) { $USE_CORE = 0 }
sub restore_time : Test(teardown => 0) { $USE_CORE = 1 }

##############################################################################
# Test the exported functions.
##############################################################################
# Test strfdate().
sub test_strfdate : Test(4) {
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
sub test_local_date : Test(5) {
    is( local_date($utc_date), $local_date,
        "Check local date is '$local_date'" );
    is( local_date($utc_date, $format), $fmt_local,
        "Check local date is '$fmt_local'" );
    is( local_date($utc_date, 'epoch'), $epoch,
        "Check that local date is '$epoch'" );

    my $current;
    {
        # Make sure to use the time zone from the preferences.
        local $ENV{TZ} = Bric::Util::Pref->lookup_val('Time Zone');
        $current = POSIX::strftime(ISO_8601_FORMAT, localtime);

    }
    # Check the local date with a known format argument.
    is( local_date(undef, ISO_8601_FORMAT, 1), $current,
        "Check local date is current" );

    {
        # Make sure to use the time zone from the preferences.
        local $ENV{TZ} = Bric::Util::Pref->lookup_val('Time Zone');
        $current = POSIX::strftime($pref_format, localtime);
    }
    # Check the local date in the preferred format.
    is( local_date(undef, undef, 1), $current,
        "Check local date is current" );
}

##############################################################################
# Test db_date().
sub test_db_date : Test(2) {
    is( db_date($local_iso_date), $db_date, "Check db date is '$db_date'" );
    # Hope that the clock doesn't click over during this test.
    is( db_date(undef, 1),
        POSIX::strftime(DB_DATE_FORMAT, gmtime),
        "Check db date is curent" );
}

1;
__END__
