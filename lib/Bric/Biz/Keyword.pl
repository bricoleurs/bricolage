#!/usr/bin/perl -w

use strict;

use Bric::BC::Keyword;

$Bric::Cust = 'sharky';

my $key = Bric::BC::Keyword->lookup({'id' => 1025});

#my @s = Bric::BC::Keyword->list({'synonyms' => $key});

my $k1 =  new Bric::BC::Keyword({'name'        => 'gforce', 
			       'screen_name' => 'Force, G', 
			       'meaning'     => 'Nickname', 
			       'prefered'    => 0, 
			       'state'       => 1});
$k1->save;

my $k2 =  new Bric::BC::Keyword({'name'        => 'rabbit', 
			       'screen_name' => 'Rabbit', 
			       'meaning'     => 'Nickname', 
			       'prefered'    => 0, 
			       'state'       => 1});
$k2->save;

$key->make_synonymous([$k1,$k2]);

# Create a new keyword object.
$key = new Bric::BC::Keyword({'name'        => 'Foo', 
			    'screen_name' => 'Foo Bar', 
			    'meaning'     => 'This is my meaning', 
			    'prefered'    => 1, 
			    'state'       => 1});

# Get/set the keyword name. 
my $name = $key->get_name();

print "Keyword name is '$name'\n";

my $success = $key->set_name('AckBar');

$name = $key->get_name();

print "Keyword name is NOW '$name'\n";

# Get/set the screen (display) name.
my $screen  = $key->get_screen_name();

print "Keyword screen name is '$screen'\n";

$success = $key->set_screen_name('The Great, AckBar');

$screen  = $key->get_screen_name();

print "Keyword screen name is NOW '$screen'\n";

# Get/set the meaning of this keyword
my $meaning = $key->get_meaning();

print "Keyword meaning is '$meaning'\n";

$success = $key->set_meaning('I am a meaning');

$meaning = $key->get_meaning();

print "Keyword meaning is NOW '$meaning'\n";

# Get/set the prefered flag 
my $bool    = $key->get_prefered();

print "Prefered is '$bool'\n";

$success = $key->set_prefered(0);

$bool = $key->get_prefered();

print "Prefered is NOW '$bool'\n";

# Get/set the state State can be 'pending', 'rejected' or 'accepted'.
my $state = $key->get_state();

print "State is '$state'\n";

$state = $key->set_state(2);

my $state = $key->get_state();

print "State is NOW '$state'\n";

# Add a keyword to a list of synonyms..
#$sets = $key->make_synonymous($set_id || $keyword || $keyword_obj);

# Save this asset to the database.
$success = $key->save();

# Delete this asset from the database.
#$success = $key->delete();
