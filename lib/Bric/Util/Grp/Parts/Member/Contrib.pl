#!/usr/bin/perl -w
use Test;
use Bric::Util::Grp::Parts::Member::Contrib;

BEGIN { plan tests => 10 }

eval {

    if (@ARGV) {
	# Do verbose testing here.
	print "Getting a list of contributors.\n";
	foreach my $c (Bric::Util::Grp::Parts::Member::Contrib->list) {
	    print "ID:     ", $c->get_id || '', "\n";
	    print "PID:    ", $c->get_obj_id || '', "\n";
	    print "GID:    ", $c->get_grp_id || '', "\n\n";
	}

	print "Testing my_meths().\n";
	foreach my $meth (Bric::Util::Grp::Parts::Member::Contrib->my_meths(1)) {
	    print "$meth->{disp}\n";
	}
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

__END__
Change Log:
$Log: Contrib.pl,v $
Revision 1.1  2001-09-06 21:56:03  wheeler
Initial revision

