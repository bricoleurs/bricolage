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

1;
__END__
