#!/usr/bin/perl -w
use Bric::Util::EventType;
use Test;


BEGIN { plan tests => 56 }

eval {
    if (@ARGV) {
	print "Fetching EventType 1024.\n";
	my $et = Bric::Util::EventType->lookup({id => 1029});
	print "ID:      ", $et->get_id, "\n";
	print "Class:   ", $et->get_class, "\n";
	print "KeyName: ", $et->get_key_name, "\n";
	print "Name:    ", $et->get_name, "\n";
	print "Desc:    ", $et->get_description, "\n";
	print "Active:  ", $et->is_active ? "Yes\n\n" : "No\n\n";
	print "Getting its attributes.\n";
	print "Attr:    ", $et->get_attr ? "Yes\n\n" : "No\n\n";

	print "Getting a list of all event types for stories.\n";
	foreach my $et ( Bric::Util::EventType->list(
          {class => 'Bric::Biz::Asset::Business::Story'}) ) {
	    print "ID:      ", $et->get_id, "\n";
	    print "Class:   ", $et->get_class, "\n";
	    print "KeyName: ", $et->get_key_name, "\n";
	    print "Name:    ", $et->get_name, "\n";
	    print "Desc:    ", $et->get_description, "\n\n";
	}

	print "Getting a list of Story event type IDs.\n";
	my $ids = Bric::Util::EventType->list_ids(
          {class => 'Bric::Biz::Asset::Business::Story'});
	local $" = ', ';
	print "IDs: @$ids\n\n";

	print "Getting a list of classes for which types of events have been defined.\n";
	my $classes = Bric::Util::EventType->list_classes;
	while (my ($pkg, $dis) = each %$classes) {
	    print "$dis: $pkg\n";
	}
	print "\n";
	exit;
    }

    # Now, the Test::Harness code.
    exit;
};

if (my $err = $@) {
    print "Error: ", ref $err ? $err->get_msg . ":\n\n" . $err->get_payload
      . "\n" : "$err\n";
}
