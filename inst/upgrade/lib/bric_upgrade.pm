package bric_upgrade;

use strict;
use Bric::Config qw(:dbi);
use Bric::Util::DBI qw(:all);
require Exporter;
use base qw(Exporter);
our @EXPORT_OK = qw($DB_User do_sql test_sql);
our %EXPORT_TAGS = (all => \@EXPORT_OK);
our $DB_User = DBI_USER;

BEGIN {
    $ENV{BRICOLAGE_ROOT} ||= '/usr/local/bricolage';
    eval { require Bric };
    if ($@) {
	# We need to set PERL5LIB.
	require File::Spec::Functions;
	my $lib =  File::Spec::Functions::catdir($ENV{BRICOLAGE_ROOT}, 'lib');
	unshift @INC, $lib;
	$ENV{PERL5LIB} = $lib;

	# Try again.
	eval { require Bric };
	die "Cannot locate Bricolage libraries.\n" if $@;
    }
};

# Get the options.
use Getopt::Std;
our ($opt_u, $opt_p);
getopts('u:p:');
# Set the db admin user and password to some reasonable defaults.
$opt_u ||= 'postgres';
$opt_p ||= 'postgres';

# Connect to the database.
my $ATTR =  { RaiseError => 1,
	      PrintError => 0,
	      AutoCommit => 1,
	      ChopBlanks => 1,
	      ShowErrorStatement => 1,
	      LongReadLen => 32768,
	      LongTruncOk => 0
};

$Bric::Util::DBI::dbh = DBI->connect(join(':', 'DBI', DBD_TYPE,
					  Bric::Util::DBI::DSN_STRING),
				     $opt_u, $opt_p, $ATTR);


sub do_sql {
    begin();
    eval {
	foreach my $sql (@_) {
	    my $sth = prepare($sql);
	    execute($sth);
	}
    };
    if ($@) {
	rollback();
	die "Update failed. Database was not affected. Error: $@;";
    } else {
	commit();
    }
}

sub test_sql {
    eval {
	my $sth = prepare(shift);
	execute($sth);
    };
    return $@ ? 0 : 1;
}
