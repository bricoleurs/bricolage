package Bric::Biz::Workflow::Parts::Desk::Test;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;

# Register this class for testing.
BEGIN { __PACKAGE__->test_class }

##############################################################################
# Test class loading.
##############################################################################
sub test_load : Test(1) {
    use_ok('Bric::Biz::Workflow::Parts::Desk');
}


__END__

# Here is the original test script for reference. If there's something usable
# here, then use it. Otherwise, feel free to discard it once the tests have
# been fully written above.

#!/usr/bin/perl -w

use strict;


use Bric::BC::Workflow::Parts::Desk;
use Bric::BC::Asset::Business::Story;
use Bric::Util::Fault::Exception::DA;
use Bric::BC::Workflow::Parts::Desk::Parts::Rule;

$Bric::Cust = 'sharky';

my $d1 = Bric::BC::Workflow::Parts::Desk->lookup({'id' => 1043});
my $d2 = Bric::BC::Workflow::Parts::Desk->lookup({'id' => 1033});
my $d3 = Bric::BC::Workflow::Parts::Desk->lookup({'id' => 1032});

my $r1 = lookup Bric::BC::Workflow::Parts::Desk::Parts::Rule({'id' => 1027});
my $r2 = lookup Bric::BC::Workflow::Parts::Desk::Parts::Rule({'id' => 1028});

$d1->link_desk({'desk' => $d2,
		'rule' => $r1});
$d1->link_desk({'desk' => $d3,
		'rule' => $r2});

$d1->save;

my @l = Bric::BC::Workflow::Parts::Desk->list({'links' => $d1});

my $d1 = new Bric::BC::Workflow::Parts::Desk({'name'        => 'legal',
					    'description' => 'The legal desk'});

my $a1 = lookup Bric::BC::Asset::Business::Story({'id' => 1});
my $a2 = lookup Bric::BC::Asset::Business::Story({'id' => 2});
my $a3 = lookup Bric::BC::Asset::Business::Story({'id' => 3});

$d1->accept({'asset' => $a1});
$d1->accept({'asset' => $a2});
$d1->accept({'asset' => $a3});

eval {
    $d1->save;
};
if ($@) {
    my $e = $@;

    print $e->get_pkg, '/', $e->get_filename, ':', $e->get_line,' - ', $e->get_msg, "\n";
}


#my $d4 = Bric::BC::Workflow::Parts::Desk->lookup({'id' => $d1->get_id});

#my @l = Bric::BC::Workflow::Parts::Desk->list({'links' => $d4});

#my @a = $d4->assets();



#my $d2 = new Bric::BC::Workflow::Parts::Desk({'name'        => 'sports',
#					    'description' => 'The sports desk'});
#my $d3 = new Bric::BC::Workflow::Parts::Desk({'name'        => 'editorial',
#					    'description' => 'The editorial desk'});

#$d2->save;
#$d3->save;

#my $r1 = lookup Bric::BC::Workflow::Parts::Desk::Parts::Rule({'id' => 1027});
#my $r2 = lookup Bric::BC::Workflow::Parts::Desk::Parts::Rule({'id' => 1028});

#$d1->link_desk({'desk' => $d2,
#		'rule' => $r1});
#$d1->link_desk({'desk' => $d3,
#		'rule' => $r2});

#$d1->save;

print "Done\n";
