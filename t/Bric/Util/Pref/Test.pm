package Bric::Util::Pref::Test;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;

# Register this class for testing.
BEGIN { __PACKAGE__->test_class }

##############################################################################
# Test class loading.
##############################################################################
sub test_load : Test(1) {
    use_ok('Bric::Util::Pref');
}


__END__

# Here is the original test script for reference. If there's something usable
# here, then use it. Otherwise, feel free to discard it once the tests have
# been fully written above.

#!/usr/bin/perl -w
use Test;
use Bric::Util::Pref;

BEGIN { plan tests => 10 }

eval {

    if (@ARGV) {
	# Do verbose testing here.
	print "Getting preference #1\n";
	my $pref = Bric::Util::Pref->lookup({ id => 1 });
	print "Name:    ", $pref->get_name || '', "\n";
	print "Desc:    ", $pref->get_description || '', "\n";
	print "Default: ", $pref->get_default || '', "\n";
	print "Value:   ", $pref->get_value || '', "\n";
	print "ValName: ", $pref->get_val_name, "\n\n";

	print "Changing its value.\n";
	$pref->set_value('Africa/Accra');
	print "ValName: ", $pref->get_val_name, "\n\n";
	$pref->save;

	print "Reloading the pref from the database.\n";
	$pref = Bric::Util::Pref->lookup({ id => 1 });
	print "Name:    ", $pref->get_name || '', "\n";
	print "Desc:    ", $pref->get_description || '', "\n";
	print "Default: ", $pref->get_default || '', "\n";
	print "Value:   ", $pref->get_value || '', "\n";
	print "ValName: ", $pref->get_val_name, "\n\n";

	print "Okay, changing its value back.\n";
	$pref->set_value('UTC');
	$pref->save;

	print "\nList of options:\n";
	foreach my $o ($pref->get_opts) {
	    print "  $o\n";
	}

	print "Hashref of options:\n";
	{
	    my $opts = $pref->get_opts_href;
	    while (my ($k, $v) = each %$opts) {
		print "  $k => $v\n";
	    }
	}

	print "\nGetting value for Time Zone.\n";
	print Bric::Util::Pref->lookup_val('Time Zone') || '', "\n";
	exit;
    }

    # Do Test::Harness testing here.


    exit;
};

if (my $err = $@) {
    if (ref $err) {
	print "Error: ", $err->get_msg, ": ", $err->get_payload, "\n";
    } else {
	print "Error: $err\n";
    }
}

