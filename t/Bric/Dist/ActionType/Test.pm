package Bric::Dist::ActionType::Test;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;

##############################################################################
# Test class loading.
##############################################################################
sub _test_load : Test(1) {
    use_ok('Bric::Dist::ActionType');
}

1;
__END__

# Here is the original test script for reference. If there's something usable
# here, then use it. Otherwise, feel free to discard it once the tests have
# been fully written above.

#!/usr/bin/perl -w
use Test;
use Bric::Dist::ActionType;

BEGIN { plan tests => 10 }

eval {

    if (@ARGV) {
	# Do verbose testing here.
	print "Getting ActionType #4.\n";
	my $at = Bric::Dist::ActionType->lookup({ id => 4 });
	print "ID:         ", $at->get_id, "\n";
	print "Name:       ", $at->get_name, "\n";
	print "Desc:       ", $at->get_description, "\n";
	print "Active:     ", $at->is_active ? 'Yes' : 'No', "\n";
	print "MEDIA Types:";
	if (my @medias = $at->get_media_types) {
	    print "\n  $_" for @medias;
	} else {
	    print " All.";
	}
	print "\n\n";

	print "Getting ActionType 'Put'.\n";
	$at = Bric::Dist::ActionType->lookup({ name => 'Put' });
	print "ID:         ", $at->get_id, "\n";
	print "Name:       ", $at->get_name, "\n";
	print "Desc:       ", $at->get_description, "\n";
	print "Active:     ", $at->is_active ? 'Yes' : 'No', "\n";
	print "MEDIA Types:";
	if (my @medias = $at->get_media_types) {
	    print "\n  $_" for @medias;
	} else {
	    print " All.";
	}
	print "\n\n";

	exit;
    }

    # Do Test::Harness testing here.


    exit;
};

if (my $err = $@) {
    print "Error: ", ref $err ? $err->{msg} . ":\n\n" . $err->{payload}
      . "\n" : "$err\n";
}

