#!/usr/bin/perl -w

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

use Bric::Util::DBI qw(:all);

# Check to see if we've run this before.
eval {
    my $sth = prepare('SELECT burner2 FROM element');
    execute($sth);
};
exit unless $@;

# Okay, we haven't run this before. Let's do it!
# Start by starting the transaction.
begin();

# Now update it all.
eval {
    my $sth = prepare('ALTER TABLE element ADD COLUMN burner NUMERIC(2,0) NOT NULL');
    execute($sth);
    $sth = prepare('ALTER TABLE element ALTER burner SET DEFAULT 1');
    execute($sth);
    $sth = prepare('UPDATE element SET burner = 1');
    execute($sth);
};
if ($@) {
    rollback();
    die "Update failed. Database was not affected. Error: $@;";
} else {
    commit();
}

