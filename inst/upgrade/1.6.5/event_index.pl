#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir catfile);
use FindBin;
use File::Copy;
our ($CONFIG, $INSTALL);

BEGIN {
    # As of Bricolage 1.6.5, the new Config.pm needs to be used for
    # upgrades, as it looks for the BRIC_DBI_USER and BRIC_DBI_PASS
    # environment variables to login as the PostgreSQL super user. So
    # we have to copy the file to its new home now so that the below
    # upgrade will work. And if anyone ends upgrading from any pre-1.6.5
    # version to any post-1.6.5 version, this will cover them, as well.
    my $old;
    if (-e 'config.db') {
        do "./config.db" or die "Failed to read config.db: $!";
        $old = catfile $CONFIG->{MODULE_DIR}, qw(Bric Config.pm);
    } else {
        $ENV{BRICOLAGE_ROOT} ||= "/usr/local/bricolage";
        my $instdb = catfile $ENV{BRICOLAGE_ROOT}, qw(conf install.db);
        die "Cannot find installed configuration data file $instdb.\n"
          unless -e $instdb;
        do "$instdb" or die "Failed to read $instdb: $!";
        $old = catfile $INSTALL->{CONFIG}{MODULE_DIR}, qw(Bric Config.pm);
    }

    die "File '$old' should exist but doesn't.\n" unless -e $old;
    my $new = catfile $FindBin::Bin, updir, updir, updir, qw(lib Bric Config.pm);
    die "Cannot find new file '$new'\n" unless -e $old;
    copy $new, $old or die "Cannot copy '$new' to '$old': $!\n";
}

use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

# check if we're already upgraded.
exit if fetch_sql(q{
    SELECT 1
    FROM   pg_class
    WHERE  relname = 'idx_event__obj_id'
});

do_sql 'CREATE INDEX idx_event__obj_id ON event(obj_id)';
