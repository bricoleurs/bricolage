#!/usr/bin/perl

####
# Grp.pl the test script for groups and members
#
#
# VERSION $Revision: 1.1 $
#
#
# Description:
#		This will create a new group, populate it with members then save
#	it.   It will then retrieve the group that it has saved.
#
####

use strict;

use Bric::Util::Grp::AssetVersion;
use Bric::Biz::Asset::Business::Story;


# create fake stories to add to the group
my @stories;
for (1 .. 10) {
	my $story = Bric::Biz::Asset::Business::Story->new($_);
	push @stories, $story;
}

# Set the proper Schema
$Bric::Cust = 'mike';

my $group = Bric::Util::Grp::AssetVersion->new( { name => 'Test Group',
				desc => 'A test of the group system' });

my $criteria = [];
foreach ( @stories ) {
	push @{$criteria}, { obj => $_ };
}

$group->add_members($criteria);
$group->save();

my $id = $group->get_id();
print "Group Created of ID $id\n";

my $group = Bric::Util::Grp::AssetVersion->lookup( {id => $id} );

my $name = $group->get_name();

my $members = $group->get_members();

print "Group of $name name has been retrieved.   It has";


my $len = length @{$members};

print " $len members\n";


