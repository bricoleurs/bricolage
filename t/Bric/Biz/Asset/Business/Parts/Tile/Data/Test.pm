package Bric::Biz::Asset::Business::Parts::Tile::Data::Test;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;

##############################################################################
# Test class loading.
##############################################################################
sub _test_load : Test(1) {
    use_ok('Bric::Biz::Asset::Business::Parts::Tile::Data');
}

1;
__END__

# Here is the original test script for reference. If there's something usable
# here, then use it. Otherwise, feel free to discard it once the tests have
# been fully written above.

#!/usr/bin/perl

use strict;

use Bric::BC::Asset::Business::Parts::Tile::Data;
use Bric::BC::AssetType::Parts::Data;

eval {

my $atd = Bric::BC::AssetType::Parts::Data->lookup( { id => 1026 });
my $a = Bric::BC::Asset::Business::Parts::Tile::Data->new(
            {   object_id   => 345,
                object_type => 'story',
                field_type_id   => 763,
                parent_id           => 453,
                object_order        => 0 });

$a->set_data(24,$atd,'Mike');

$a->save();

my $id = $a->get_id();

$a = Bric::BC::Asset::Business::Parts::Tile::Data->lookup( { 
                id          => $id, 
                object_id   => 345,
                object_type => 'story'});

my $data = $a->get_data();

print $a->get_id . '  ' . $data . "\n";

};

if ($@) {
    die $@->get_msg();
}
