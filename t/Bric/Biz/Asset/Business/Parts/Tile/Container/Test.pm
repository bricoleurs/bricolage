package Bric::Biz::Asset::Business::Parts::Tile::Container::Test;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;

##############################################################################
# Test class loading.
##############################################################################
sub _test_load : Test(1) {
    use_ok('Bric::Biz::Asset::Business::Parts::Tile::Container');
}

1;
__END__

# Here is the original test script for reference. If there's something usable
# here, then use it. Otherwise, feel free to discard it once the tests have
# been fully written above.

#!/usr/bin/perl

use strict;

use Bric::BC::Asset::Business::Parts::Tile::Container;
use Bric::BC::AssetType::Parts::Data;
use Bric::BC::AssetType;
use Bric::BC::Asset::Business::Story;

eval {

my $at = Bric::BC::AssetType->lookup( { id => 1024 } );
my $atd = Bric::BC::AssetType::Parts::Data->lookup( { id => 1026 });
my $story = Bric::BC::Asset::Business::Story->lookup( { id => 1029 });

my $c = Bric::BC::Asset::Business::Parts::Tile::Container->new(
			{ 	'object_type' 	=> 'story',
				'object_id'		=> 35,
				'element'	=> $at  	});

$c->add_data($atd, $story, 'Chomp');

$c->save();

print "Container Created ID " . $c->get_id() . "\n";
my $id = $c->get_id();

$c = undef;

$c = Bric::BC::Asset::Business::Parts::Tile::Container->lookup( { 
				id => $id,
				object_type => 'story' });

print "Looked up ID " . $c->get_id() . "\n";

my $data = $c->get_data('title');

print "Data: $data\n";

my @objs = Bric::BC::Asset::Business::Parts::Tile::Container->list(
			{ object_type => 'story'} );

foreach (@objs) {
	print  $_->get_id() . " \n";
}

};

if ($@) {
	die $@->get_msg();
}
