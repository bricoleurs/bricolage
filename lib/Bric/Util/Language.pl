#!/usr/bin/perl

use strict;

use Bric::Util::Language;

$Bric::Cust = 'mike';

my $lang = Bric::Util::Language->new();

$lang->set_name('pig latin');

$lang->set_description('A funny way a talking');

$lang->set_char_set('Latin1');

$lang->save();

my $id = $lang->get_id();

print "ID is $id\n";

my $lang = Bric::Util::Language->lookup( { id => $id } );

print "Lookup worked for " . $lang->get_name() . "\n";

my ($lang) = Bric::Util::Language->list();

print "List worked for " . $lang->get_name() . "\n";


my ($id) = Bric::Util::Language->list_ids();

print "List IDs  worked for $id \n";
