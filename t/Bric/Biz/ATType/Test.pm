package Bric::Biz::ATType::Test;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;

my $story_class_id;

##############################################################################
# Test class loading.
##############################################################################
sub _test_load : Test(1) {
    use_ok('Bric::Biz::ATType');
    $story_class_id = Bric::Biz::ATType->STORY_CLASS_ID;
}

##############################################################################
# Test the constructor.
##############################################################################
sub test_const : Test(11) {
    my $self = shift;
    my $args = { name => 'Bogus',
                 description => 'Bogus ATType',
                 fixed_url => 1
               };

    ok ( my $et = Bric::Biz::ATType->new($args), "Test construtor" );
    ok( ! defined $et->get_id, 'Undefined ID' );
    is( $et->get_name, $args->{name}, "Name is '$args->{name}'" );
    is( $et->get_description, $args->{description},
        "Description is '$args->{description}'" );
    ok( $et->is_active, "Check that it's activated" );
    ok( $et->get_fixed_url, "Check is fixed URL" );
    ok( !$et->get_top_level, "Check not top level" );
    ok( !$et->get_media, "Check not media" );
    ok( !$et->get_related_story, "Check not related story" );
    ok( !$et->get_related_media, "Check not related media" );
    is( $et->get_biz_class_id, $story_class_id, "Check no biz class ID" );
}

##############################################################################
# Test class methods.
##############################################################################
# Test my_meths().
sub test_my_meths : Test(11) {
    ok( my $meths = Bric::Biz::ATType->my_meths, "Get my_meths" );
    isa_ok($meths, 'HASH', "my_meths is a hash" );
    is( $meths->{name}{type}, 'short', "Check name type" );
    ok( $meths = Bric::Biz::ATType->my_meths(1), "Get my_meths array ref" );
    isa_ok( $meths, 'ARRAY', "my_meths(1) is an array" );
    (is $meths->[0]->{name}, 'name', "Check first meth name" );

    # Try the identifier methods.
    ok( my $att = Bric::Biz::ATType->new({ name => 'NewFoo' }),
        "Create ATType" );
    ok( my @meths = $att->my_meths(0, 1), "Get ident meths" );
    is( scalar @meths, 1, "Check for 1 meth" );
    is( $meths[0]->{name}, 'name', "Check for 'name' meth" );
    is( $meths[0]->{get_meth}->($att), 'NewFoo', "Check name 'NewFoo'" );
}

1;
__END__
