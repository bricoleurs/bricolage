package Bric::Util::MediaType::Test;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;

##############################################################################
# Test class loading.
##############################################################################
sub _test_load : Test(1) {
    use_ok('Bric::Util::MediaType');
}

##############################################################################
# Test class methods.
##############################################################################
# Test my_meths().
sub test_my_meths : Test(11) {
    ok( my $meths = Bric::Util::MediaType->my_meths, "Get my_meths" );
    isa_ok($meths, 'HASH', "my_meths is a hash" );
    is( $meths->{name}{type}, 'short', "Check name type" );
    ok( $meths = Bric::Util::MediaType->my_meths(1), "Get my_meths array ref" );
    isa_ok( $meths, 'ARRAY', "my_meths(1) is an array" );
    (is $meths->[0]->{name}, 'name', "Check first meth name" );

    # Try the identifier methods.
    ok( my $mt = Bric::Util::MediaType->new({ name => 'NewFoo',
                                              ext => ['foo'] }),
        "Create media type" );
    ok( my @meths = $mt->my_meths(0, 1), "Get ident meths" );
    is( scalar @meths, 1, "Check for 1 meths" );
    is( $meths[0]->{name}, 'name', "Check for 'name' meth" );
    is( $meths[0]->{get_meth}->($mt), 'NewFoo', "Check name 'NewFoo'" );
}

1;
__END__

# Here is the original test script for reference. If there's something usable
# here, then use it. Otherwise, feel free to discard it once the tests have
# been fully written above.

#!/usr/bin/perl -w
use Test;
use lib '/home/dwheeler/dev/bricolage/lib';
use Bric::Util::MediaType;

BEGIN { plan tests => 10 }

eval {

    if (@ARGV) {
	# Do verbose testing here.
	print "Fething the name of the media type for 'foo.jpeg'.\n";
	print "Name: ", Bric::Util::MediaType->get_name_by_ext('foo.jpeg'), "\n";
	print "Fething the id of the media type for 'foo.gif'.\n";
	print "ID:   ", Bric::Util::MediaType->get_id_by_ext('foo.gif'), "\n";
	print "Fething the name of the media type for 'bogus'.\n";
	print "Name: ", Bric::Util::MediaType->get_name_by_ext('bogus') || '', "\n";

	print "Looking up Media Type #77\n";
	my $mt = Bric::Util::MediaType->lookup({ id => 77 });
	print "ID:        ", $mt->get_id || '', "\n";
	print "Name:      ", $mt->get_name || '', "\n";
	print "Desc:      ", $mt->get_description || '', "\n";
	print "Active:    ", $mt->is_active ? 'Yes' : 'No', "\n";
	print "Extenstions:\n";
	print "\t$_\n" for $mt->get_exts;

	print "Adding extensions.\n";
	$mt->add_exts('foo', 'bar');
	print "Extenstions:\n";
	print "\t$_\n" for $mt->get_exts;

	print "Changing Description.\n";
	$mt->set_description('Foo Bar');
	print "Desc:      ", $mt->get_description || '', "\n\n";


	print "Saving Changes and reloading.\n";
	$mt->save;
	$mt = Bric::Util::MediaType->lookup({ id => 77 });
	print "ID:        ", $mt->get_id || '', "\n";
	print "Name:      ", $mt->get_name || '', "\n";
	print "Desc:      ", $mt->get_description || '', "\n";
	print "Active:    ", $mt->is_active ? 'Yes' : 'No', "\n";
	print "Extenstions:\n";
	print "\t$_\n" for $mt->get_exts;
	print "\n";

	print "Unding changes and re-saving.\n";
	$mt->set_description(undef);
	$mt->del_exts('foo', 'bar');
	$mt->save;
	$mt = Bric::Util::MediaType->lookup({ id => 77 });
	print "Desc:      ", $mt->get_description || '', "\n";
	print "Extenstions:\n";
	print "\t$_\n" for $mt->get_exts;
	print "\n";

	print "Creating a new media type.\n";
	$mt = Bric::Util::MediaType->new;
	$mt->set_name('image/photoshop');
	$mt->set_description("Adobe Photoshop");
	$mt->add_exts('ppd');
	$mt->save;
	$mt = Bric::Util::MediaType->lookup({ id => $mt->get_id });
	print "ID:        ", $mt->get_id || '', "\n";
	print "Name:      ", $mt->get_name || '', "\n";
	print "Desc:      ", $mt->get_description || '', "\n";
	print "Active:    ", $mt->is_active ? 'Yes' : 'No', "\n";
	print "Extenstions:\n";
	print "\t$_\n" for $mt->get_exts;
	print "\n";

	print "Fetching a list of image extensions.\n";
	foreach my $mt (Bric::Util::MediaType->list({ name => 'image%' })) {
	    print "Name:      ", $mt->get_name || '', "\n";
	    print "Extenstions:\n";
	    print "\t$_\n" for $mt->get_exts;
	    print "\n";
	}
	print "\n";

	print "Cleaning up bogus records.\n";
        Bric::Util::DBI::prepare_c(qq{
            DELETE FROM media_type
            WHERE  id > 1023
        })->execute;
	print "Done!\n";
    }

    # Do Test::Harness testing here.


    exit;
    Bric::Util::DBI::prepare_c(qq{
        DELETE FROM media_type
        WHERE  id > 1023
    })->execute;
};

print "Error: $@", if $@

