#!/usr/bin/perl -w
use Test;
use Bric::BC::Org;
use Bric::BC::Org::Source;

BEGIN { plan tests => 10 }

eval {

    if (@ARGV) {
	# Do verbose testing here.
	print "Testing my_meths().\n";
	my @meths = keys %{ Bric::BC::Org::Source->my_meths };
	print "Meths: @meths\n\n";
	print "Meths: ";
	print " $_->{name}" for Bric::BC::Org::Source->my_meths(1);
	print "\n\n";

	print "Creating a new Source from an existing Org.\n";
	my $org = Bric::BC::Org->lookup({ id => 1 });
	my $src = Bric::BC::Org::Source->new;
	$src->set_org($org);
	$src->set_source_name('About');
	$src->set_description('About Content.');
	$src->set_expire(0);

	print "ID:       ", $src->get_id || '', "\n";
	print "Org ID:   ", $src->get_org_id || '', "\n";
	print "Name:     ", $src->get_name || '', "\n";
	print "Long:     ", $src->get_long_name || '', "\n";
	print "Src Name: ", $src->get_source_name || '', "\n";
	print "Desc:     ", $src->get_description || '', "\n";
	print "Expire:   ", $src->get_expire, "\n";
	print "Active:   ", $src->is_active ? 'Yes' : 'No', "\n";

	print "Saving...";
	$src->save;
	print "ID ", $src->get_id, "\n\n";

	print "Creating a brand new source from scratch.\n";
	$src = Bric::BC::Org::Source->new;
	$src->set_name('The Chronical');
	$src->set_long_name('The San Francisco Chronical');
	$src->set_source_name('The Chronical');
	$src->set_description('Stuff from the Chron.');
	$src->set_expire(90);
	$src->save;

	print "ID:       ", $src->get_id || '', "\n";
	print "Org ID:   ", $src->get_org_id || '', "\n";
	print "Name:     ", $src->get_name || '', "\n";
	print "Long:     ", $src->get_long_name || '', "\n";
	print "Src Name: ", $src->get_source_name || '', "\n";
	print "Desc:     ", $src->get_description || '', "\n";
	print "Expire:   ", $src->get_expire, "\n";
	print "Active:   ", $src->is_active ? 'Yes' : 'No', "\n\n";

	print "Looking up source ID #1.\n";
	$src = Bric::BC::Org::Source->lookup({ id => 1 });
	print "ID:       ", $src->get_id || '', "\n";
	print "Org ID:   ", $src->get_org_id || '', "\n";
	print "Name:     ", $src->get_name || '', "\n";
	print "Long:     ", $src->get_long_name || '', "\n";
	print "Src Name: ", $src->get_source_name || '', "\n";
	print "Desc:     ", $src->get_description || '', "\n";
	print "Expire:   ", $src->get_expire, "\n";
	print "Active:   ", $src->is_active ? 'Yes' : 'No', "\n\n";

	print "Listing sources associated with Org ID #10.\n";
	foreach my $src (Bric::BC::Org::Source->list({ org_id => 10 })) {
	    print "ID:       ", $src->get_id || '', "\n";
	    print "Org ID:   ", $src->get_org_id || '', "\n";
	    print "Name:     ", $src->get_name || '', "\n";
	    print "Long:     ", $src->get_long_name || '', "\n";
	    print "Src Name: ", $src->get_source_name || '', "\n";
	    print "Desc:     ", $src->get_description || '', "\n";
	    print "Expire:   ", $src->get_expire, "\n";
	    print "Active:   ", $src->is_active ? 'Yes' : 'No', "\n\n";
	}

	print "Cleaning up bogus records.\n";
        Bric::Util::DBI::prepare_c(qq{
            DELETE FROM source
            WHERE  id > 1023
        })->execute;

        Bric::Util::DBI::prepare_c(qq{
            DELETE FROM org
            WHERE  id > 1023
        })->execute;

	print "Done!\n";
	exit;
    }

    # Do Test::Harness testing here.


    exit;
    Bric::Util::DBI::prepare_c(qq{
        DELETE FROM source
        WHERE  id > 1023
    })->execute;

    Bric::Util::DBI::prepare_c(qq{
        DELETE FROM org
        WHERE  id > 1023
    })->execute;
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
$Log: Source.pl,v $
Revision 1.1  2001-09-06 21:54:05  wheeler
Initial revision

