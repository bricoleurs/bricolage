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

__END__
Change Log:
$Log: ActionType.pl,v $
Revision 1.1  2001-09-06 21:54:21  wheeler
Initial revision

Revision 1.8.2.2  2001/09/05 19:00:36  david
