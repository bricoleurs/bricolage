#!/usr/bin/perl

use Bric::BC::OutputChannel;

use strict;

$Bric::Cust = 'mike';

my $param = {
	'name'			=> 'mike\'s test5',
	'description'	=> 'a fun test',
	'tile_aware'	=> 1,
	'primary'		=> 1,
	'active'		=> 1
};



my $oc = Bric::BC::OutputChannel->new($param);

$oc->save();

my $id = $oc->get_id();

print "OC $id created\n";

$oc = undef;

$oc = Bric::BC::OutputChannel->lookup( { id => $id } );

my $name = $oc->get_name();

print "OC of name = $name has been looked up!\n\n";

$oc = undef;

delete $param->{'description'};

my @ocs = Bric::BC::OutputChannel->list($param);

print "list returned these objects\n";

foreach (@ocs) {
	$id = $_->get_id();
	print "\tID of $id\n";
	$_->set_description('a new description');
	$_->save();
}

