package Bric::Biz::Asset::Template::Test;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;

##############################################################################
# Test class loading.
##############################################################################
sub _test_load : Test(1) {
    use_ok('Bric::Biz::Asset::Template');
}

1;
__END__

# Here is the original test script for reference. If there's something usable
# here, then use it. Otherwise, feel free to discard it once the tests have
# been fully written above.

#!/usr/bin/perl

use strict;
use Bric::BC::Asset::Template;

my $fa = Bric::BC::Asset::Template->new( { 
    output_channel_id => 1024, element_id => 1024 } );

$fa->set_description( 'ploop');
$fa->set_data( '<B> I   A M   T H E   K I N G ! ! ! </B>');
$fa->save();
my $id = $fa->get_id();

print "Template Asset Created id $id\n";

$fa = undef;


$fa = Bric::BC::Asset::Template->lookup( { id => $id } );
$id = undef;
$id = $fa->get_id();
print "Template Asset Looked Up id  $id\n";
$fa->checkin();
$fa->save(); 

$fa = Bric::BC::Asset::Template->lookup( { id => $id } );

eval { 
    $fa->checkout( {user__id => 32}); 
};

if ($@) { die $@->get_msg() }
