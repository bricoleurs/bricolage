#!/usr/bin/perl

use strict;
use Bric::BC::Asset::Formatting;

my $fa = Bric::BC::Asset::Formatting->new( { 
	output_channel_id => 1024, element_id => 1024 } );

$fa->set_description( 'ploop');
$fa->set_data( '<B> I   A M   T H E   K I N G ! ! ! </B>');
$fa->save();
my $id = $fa->get_id();

print "Formatting Asset Created id $id\n";

$fa = undef;


$fa = Bric::BC::Asset::Formatting->lookup( { id => $id } );
$id = undef;
$id = $fa->get_id();
print "Formatting Asset Looked Up id  $id\n";
$fa->checkin();
$fa->save(); 

$fa = Bric::BC::Asset::Formatting->lookup( { id => $id } );

eval { 
    $fa->checkout( {user__id => 32}); 
};

if ($@) { die $@->get_msg() }
