package Bric::Util::Language::Test;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;

##############################################################################
# Test class loading.
##############################################################################
sub _test_load : Test(1) {
    use_ok('Bric::Util::Language');
}

1;
__END__

# Here is the original test script for reference. If there's something usable
# here, then use it. Otherwise, feel free to discard it once the tests have
# been fully written above.

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
