#!/usr/bin/perl

use strict;

use Bric::BC::Asset::Business::Parts::Tile::Data;
use Bric::BC::AssetType::Parts::Data;

eval {

my $atd = Bric::BC::AssetType::Parts::Data->lookup( { id => 1026 });
my $a = Bric::BC::Asset::Business::Parts::Tile::Data->new(
			{ 	object_id	=> 345,
				object_type	=> 'story',
				element_data_id	=> 763,
				parent_id			=> 453,
				object_order		=> 0 });

$a->set_data(24,$atd,'Mike');

$a->save();

my $id = $a->get_id();

$a = Bric::BC::Asset::Business::Parts::Tile::Data->lookup( { 
				id 			=> $id, 
				object_id   => 345,
				object_type => 'story'});

my $data = $a->get_data();

print $a->get_id . '  ' . $data . "\n";

};

if ($@) {
	die $@->get_msg();
}
