package Bric::Util::Time::Test;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;
use Bric::Util::DBI qw(DB_DATE_FORMAT);
use Bric::Config qw(:time);
use Bric::Util::Pref;
use POSIX ();

my $epoch = 315561600; # gmtime = 315532800;
my $local_iso_date = '1980-01-01 00:00:00';
my $utc_iso_date = '1980-01-01 08:00:00';

my $db_date = POSIX::strftime(DB_DATE_FORMAT, gmtime($epoch));

my $pref_format = Bric::Util::Pref->lookup_val('Date/Time Format');
my $local_date = POSIX::strftime($pref_format, localtime($epoch));
my $utc_date = POSIX::strftime($pref_format, gmtime($epoch));

my $format = '%m/%d/%Y at %T';
my $fmt_local = '01/01/1980 at 00:00:00';
my $fmt_utc = '01/01/1980 at 08:00:00';

##############################################################################
# Test class loading.
##############################################################################
sub _test_load : Test(1) {
    use_ok('Bric::Util::Time', ':all');
}

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

sub test_local_date : Test(5) {
    is( local_date($utc_date), $local_date,
        "Check local date is '$local_date'" );
    is( local_date($utc_date, $format), $fmt_local,
        "Check local date is '$fmt_local'" );
    is( local_date($utc_date, 'epoch'), $epoch,
        "Check that local date is '$epoch'" );
    # Hope that the clock doesn't click over during this test.
    is( local_date(undef, ISO_8601_FORMAT, 1),
        POSIX::strftime(ISO_8601_FORMAT, localtime),
        "Check local date is current" );
    # Hope that the clock doesn't click over during this test.
    is( local_date(undef, undef, 1),
        POSIX::strftime($pref_format, localtime),
        "Check local date is current" );
}

sub test_db_date : Test(2) {
    is( db_date($local_iso_date), $db_date, "Check db date is '$db_date'" );
    # Hope that the clock doesn't click over during this test.
    is( db_date(undef, 1),
        POSIX::strftime(DB_DATE_FORMAT, gmtime),
        "Check db date is curent" );
}

1;
__END__
