package Bric::Biz::Workflow::Parts::Desk::Test;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;

##############################################################################
# Test class loading.
##############################################################################
sub _test_load : Test(1) {
    use_ok('Bric::Biz::Workflow::Parts::Desk');
}

##############################################################################
# Test the constructor.
##############################################################################
sub test_const : Test(6) {
    my $self = shift;
    my $args = { name => 'Bogus',
                 description => 'Bogus Desk' };

    ok ( my $desk = Bric::Biz::Workflow::Parts::Desk->new($args),
         "Test construtor" );
    ok( ! defined $desk->get_id, 'Undefined ID' );
    is( $desk->get_name, $args->{name}, "Name is '$args->{name}'" );
    is( $desk->get_description, $args->{description},
        "Description is '$args->{description}'" );
    ok( $desk->is_active, "Check that it's activated" );
    ok( !$desk->can_publish, "Check that it's not a publish desk" );
}

##############################################################################
# Test class methods.
##############################################################################
# Test my_meths().
sub test_my_meths : Test(11) {
    ok( my $meths = Bric::Biz::Workflow::Parts::Desk->my_meths,
        "Get my_meths" );
    isa_ok($meths, 'HASH', "my_meths is a hash" );
    is( $meths->{name}{type}, 'short', "Check name type" );
    ok( $meths = Bric::Biz::Workflow::Parts::Desk->my_meths(1),
        "Get my_meths array ref" );
    isa_ok( $meths, 'ARRAY', "my_meths(1) is an array" );
    (is $meths->[0]->{name}, 'name', "Check first meth name" );

    # Try the identifier methods.
    ok( my $desk = Bric::Biz::Workflow::Parts::Desk->new
        ({ name => 'NewFoo' }), "Create desk" );
    ok( my @meths = $desk->my_meths(0, 1), "Get ident meths" );
    is( scalar @meths, 1, "Check for 1 meth" );
    is( $meths[0]->{name}, 'name', "Check for 'name' meth" );
    is( $meths[0]->{get_meth}->($desk), 'NewFoo', "Check name 'NewFoo'" );
}

1;
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
#                        'description' => 'The sports desk'});
#my $d3 = new Bric::BC::Workflow::Parts::Desk({'name'        => 'editorial',
#                        'description' => 'The editorial desk'});

#$d2->save;
#$d3->save;

#my $r1 = lookup Bric::BC::Workflow::Parts::Desk::Parts::Rule({'id' => 1027});
#my $r2 = lookup Bric::BC::Workflow::Parts::Desk::Parts::Rule({'id' => 1028});

#$d1->link_desk({'desk' => $d2,
#        'rule' => $r1});
#$d1->link_desk({'desk' => $d3,
#        'rule' => $r2});

#$d1->save;

print "Done\n";
