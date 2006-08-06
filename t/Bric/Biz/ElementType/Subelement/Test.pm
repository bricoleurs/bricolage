package Bric::Biz::ElementType::Subelement::Test;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;

##############################################################################
# Test class loading.
##############################################################################
sub _test_load : Test(1) {
    use_ok('Bric::Biz::ElementType::Subelement');
}

##############################################################################
# Test the new() constructor.
sub test_new : Test(9) {
    my %et = (
        name        => 'Test ElementType',
        key_name    => 'test_element_type',
        description => 'Testing Element Type API',
    );
    ok( my $elemt = Bric::Biz::ElementType->new(\%et), 'Create a new element type');


    # Try creating one from the element type object
    ok( my $sube = Bric::Biz::ElementType::Subelement->new({child => $elemt}),
        "Create Subelement with object" );

    isa_ok($sube, 'Bric::Biz::ElementType::Subelement');
    isa_ok($sube, 'Bric::Biz::ElementType');
    is scalar $sube->get_min_occurrence, 0, "Check min occurrence";
    is scalar $sube->get_max_occurrence, 0, "Check max occurrence";
    is scalar $sube->get_place, 0, "Check place";

    # Try creating one from the element type id
    ok( $sube = Bric::Biz::ElementType::Subelement->new({child_id => $elemt->get_id}),
        "Create Subelement with id" );
    isa_ok($sube, 'Bric::Biz::ElementType::Subelement');
    isa_ok($sube, 'Bric::Biz::ElementType');
    is scalar $sube->get_min_occurrence, 0, "Check min occurrence";
    is scalar $sube->get_max_occurrence, 0, "Check max occurrence";
    is scalar $sube->get_place, 0, "Check place";
}

1;
__END__
