package Bric::Util::Time::Test;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;
use Bric::Util::DBI qw(DB_DATE_FORMAT);
use Bric::Config qw(:time);
use Bric::Util::Pref;
use Bric::Util::Time qw(:all);
use POSIX ();

my $epoch = 315561600; # gmtime = 315532800;
my $local_iso_date = '1980-01-01 00:00:00';
my $utc_iso_date = '1980-01-01 08:00:00';

my $db_date = POSIX::strftime(DB_DATE_FORMAT, gmtime($epoch));

my $pref_format = Bric::Util::Pref->lookup_val('Date/Time Format');
my $utc_date = POSIX::strftime($pref_format, gmtime($epoch));
my $local_date;
{
    local $ENV{TZ} = Bric::Util::Pref->lookup_val('Time Zone');
    $local_date = POSIX::strftime($pref_format, localtime($epoch));
}

my $format = '%m/%d/%Y at %T';
my $fmt_local = '01/01/1980 at 00:00:00';
my $fmt_utc = '01/01/1980 at 08:00:00';

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
    # Hope that the clock hasn't click over during this test.
    is( local_date(undef, ISO_8601_FORMAT, 1), $current,
        "Check local date is current" );

    {
        # Make sure to use the time zone from the preferences.
        local $ENV{TZ} = Bric::Util::Pref->lookup_val('Time Zone');
        $current = POSIX::strftime($pref_format, localtime);
    }
    # Hope that the clock hasn't click over during this test.
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
