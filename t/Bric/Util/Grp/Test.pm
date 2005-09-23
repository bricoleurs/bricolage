package Bric::Util::Grp::Test;

use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;

##############################################################################
# Test class loading.
##############################################################################
sub _load_test : Test(26) {
    # Load Grp and all of the subclasses. AssetVersion may not be used
    # anymore, but I leave it to another day to decide if that's so and take
    # it out if it is.
    use_ok('Bric::Util::Grp');
    use_ok('Bric::Util::Pref');
    for (qw(Person User AlertType Asset ElementType AssetVersion CategorySet
            ContribType Desk Dest ATType SubelementType Event Formatting Grp
            Job Media Org OutputChannel Person Pref Source Story Workflow)) {
        use_ok("Bric::Util::Grp::$_");
    }
}

##############################################################################
# Test the class methods.
##############################################################################
sub test_class_meths : Test(8) {
    is( Bric::Util::Grp->get_class_id, 6, "Class class ID is 6" );
    is( Bric::Util::Grp::Person->get_class_id, 9,
        "Person class class ID is 9" );
    ok( ! Bric::Util::Grp->get_supported_classes,
        "Check Grp supported classes." );
    is_deeply( Bric::Util::Grp::Person->get_supported_classes,
               { 'Bric::Biz::Person' => 'person',
                 'Bric::Biz::Person::User' => 'person' },
               "Check Person supported classes" );
    is( Bric::Util::Grp->get_secret, 1, "Check Grp secret" );
    is( Bric::Util::Grp::Source->get_secret, 0, "Check Source secret" );
    ok( !Bric::Util::Grp->get_object_class_id, "Check grp object_class_id" );
    is( Bric::Util::Grp::Person->get_object_class_id, 1,
        "Check Person object_class_id" );
}

##############################################################################
# Make sure that get_object_class_id and get_supported_classes always return a
# scalar value.
sub test_class_scalar_meths : Test(6) {
    ok( my @vals = Bric::Util::Grp->get_object_class_id,
        "Get Grp's obj class ID" );
    ok( @vals == 1, "Should be one value for obj class ID" );
    ok( ! defined $vals[0], "One value undef for obj class ID" );
    ok( @vals = Bric::Util::Grp->get_supported_classes,
        "Get Grp's supported classes" );
    ok( @vals == 1, "Should be one value for supported classes" );
    ok( ! defined $vals[0], "One value undef for supported classes" );
}

##############################################################################
# Test my_meths.
sub test_my_meths : Test(6) {
    ok( my $meths = Bric::Util::Grp->my_meths, "Get my_meths" );
    isa_ok( $meths, 'HASH', "my_meths is a hash" );
    is( $meths->{name}{type}, 'short', "Check name type" );
    ok( $meths = Bric::Util::Grp->my_meths(1), "Get my_meths array ref" );
    isa_ok( $meths, 'ARRAY', "my_meths(1) is an array" );
    (is $meths->[0]->{name}, 'name', "Check first meth name" );
}

1;
__END__
