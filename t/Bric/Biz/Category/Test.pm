package Bric::Biz::Category::Test;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;

##############################################################################
# Test class loading.
##############################################################################
sub _test_load : Test(1) {
    use_ok('Bric::Biz::Category');
}

##############################################################################
# Test class methods.
##############################################################################
# Test my_meths().
sub test_my_meths : Test(11) {
    ok( my $meths = Bric::Biz::Category->my_meths, "Get my_meths" );
    isa_ok($meths, 'HASH', "my_meths is a hash" );
    is( $meths->{name}{type}, 'short', "Check name type" );
    ok( $meths = Bric::Biz::Category->my_meths(1), "Get my_meths array ref" );
    isa_ok( $meths, 'ARRAY', "my_meths(1) is an array" );
    (is $meths->[0]->{name}, 'name', "Check first meth name" );

    # Try the identifier methods.
    ok( my $cat = Bric::Biz::Category->new({ uri => '/foo/bar' }),
        "Create Category" );
    ok( my @meths = $cat->my_meths(0, 1), "Get ident meths" );
    is( scalar @meths, 1, "Check for 1 meth" );
    is( $meths[0]->{name}, 'uri', "Check for 'uri' meth" );
    is( $meths[0]->{get_meth}->($cat), '/foo/bar', "Check uri '/foo/bar'" );
}

1;
__END__

# Here is the original test script for reference. If there's something usable
# here, then use it. Otherwise, feel free to discard it once the tests have
# been fully written above.

#!/usr/bin/perl -w

use strict;

use Bric::BC::Category;

$Bric::Cust = 'sharky';

my $c = Bric::BC::Category->lookup({'id' => 1068});

my @child = $c->children;

print "Creating new category\n";

# Return a new category object.
my $cat = new Bric::BC::Category({'name'        => 'Science',
				'description' => 'All things science'});

my $name = $cat->get_name;

print "Category name is '$name'\n";

my $desc = $cat->get_description;

print "Category description is '$desc'\n";


print "Creating science sub-categories space, physical and material\n";

my $space = new Bric::BC::Category({'name'        => 'Space',
				  'description' => 'Pigs in space!'});
$space->save;

my $phy = new Bric::BC::Category({'name'        => 'Physical',
				'description' => 'I teach gym as well!'});
$phy->save;

my $mat = new Bric::BC::Category({'name'        => 'Material',
				'description' => 'Torque, tensile et al.'});
$mat->save;

print "Adding categories.\n";

$cat->add_child([$space, $phy, $mat]);

$cat->save;


## Return a list of keywords associated with this category.
#@keys   = $cat->keywords();
## Return a list of assets asscociated with this category.
#@assets = $cat->assets();
## Return a list of child categories of this category.
#@cats   = $cat->children();
## Return the parent of this category.
#$parent = $cat->parent();

## Add/Delete child categories for this category.
#$cat->add_child([$cat || $cat_id]);
#$cat->del_child([$cat || $cat_id]);

## Add/Delete keywords associated with this category.
#$cat->add_keyword([$kw || $kw_id]);
#$cat->del_keyword([$kw || $kw_id]);

## Add/Delete assets associated with this category.
#$cat->add_asset([$asset || $asset_id]);
#$cat->del_asset([$asset || $asset_id]);

## Save information for this category to the database.
#$cat->save;

