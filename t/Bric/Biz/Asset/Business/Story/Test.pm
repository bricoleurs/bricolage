package Bric::Biz::Asset::Business::Story::Test;
use strict;
use warnings;
use base qw(Bric::Biz::Asset::Business::Test);
use Test::More;

my $CLASS = 'Bric::Biz::Asset::Business::Story';
my $ELEMENT_CLASS = 'Bric::Biz::AssetType';
my $OC_CLASS = 'Bric::Biz::OutputChannel';

##############################################################################
# Test class loading.
# NOTE: The tests load alphabetically, and this one has to be first.
##############################################################################
sub first_test_load: Test(3) {
    my $self = shift;
    $self->SUPER::_test_load;
    use_ok($CLASS);
}

##############################################################################
# PRIVATE class methods
##############################################################################
sub test_add_get_categories: Test(4) {
    # make a story
    my $time = time;
    my $element = $ELEMENT_CLASS->new({
                                        id          => 1,
                                        name        => 'test element',
                                        description => 'testing',
                                        active      => 1,
                                     });
    my $story = $CLASS->new({
                           name        => "_test_$time",
                           description => 'this is a test',
                           priority    => 1,
                           source__id  => 1,
                           slug        => 'test',
                           user__id    => 0,
                           element     => $element, 
                       });
    # make a couple of categories
    my $cats = [];
    $cats->[0] = Bric::Biz::Category->new({ 
                                           name => "_test_$time.1", 
                                           description => '',
                                           directory => "_test_$time.1",
                                           id => 1,
                                        });
    $cats->[1] = Bric::Biz::Category->new({ 
                                           name => "_test_$time.2", 
                                           description => '',
                                           directory => "_test_$time.2",
                                           id => 2,
                                        });
    # add the categories 
    ok( $story->add_categories($cats), 'can add an arrayref of new categories');
    # get the categories
    my $rcats;
    ok( $rcats = $story->get_categories, '... and we can call get');
    # are the ones we just added in there?
    is( $rcats->[0]->get_name(), "_test_$time.1", ' ... and they both' );
    is( $rcats->[1]->get_name(), "_test_$time.2", ' ... have the right name' );
}

sub test_set_get_primary_category: Test(8) {
    # make a story
    my $time = time;
    my $element = $ELEMENT_CLASS->new({
                                        id          => 1,
                                        name        => 'test element',
                                        description => 'testing',
                                        active      => 1,
                                     });
    my $story = $CLASS->new({
                           name        => "_test_$time",
                           description => 'this is a test',
                           priority    => 1,
                           source__id  => 1,
                           slug        => 'test',
                           user__id    => 0,
                           element     => $element, 
                       });
    # Test: make sure it has no primary category
    is( $story->get_primary_category(), undef, 'a new story has no primary category' );
    # make a couple of categories
    my $cats = [];
    $cats->[0] = Bric::Biz::Category->new({ 
                                           name => "_test_$time.1", 
                                           description => '',
                                           directory => "_test_$time.1",
                                           id => 1,
                                        });
    $cats->[1] = Bric::Biz::Category->new({ 
                                           name => "_test_$time.2", 
                                           description => '',
                                           directory => "_test_$time.2",
                                           id => 2,
                                        });
    # add the categories 
    ok( $story->add_categories($cats), 'can add an arrayref of new categories');
    # set it as the primary
    ok( $story->set_primary_category($cats->[0]), 'can set it as the primary category');
    # get the primary category
    my $pcat;
    ok( $pcat = $story->get_primary_category(), ' ... and can get it.');
    # Test: is the primary category the one we set
    is( $pcat->get_name(), $cats->[0]->get_name(), ' ... and it appears to be the same one.');
    # set it as the primary
    ok( $story->set_primary_category($cats->[1]), "now let's try to change it");
    # get the primary category
    ok( $pcat = $story->get_primary_category(), ' ... and can get it.');
    # Test: is the primary category the one we set
    is( $pcat->get_name(), $cats->[1]->get_name(), ' ... and it appears to be the new one.');
}

sub test_get_uri: Test(1) {
    # make a story with the slug 'test'
    my $time = time;
    my ($oc) = $OC_CLASS->list(); # any oc will do
    my $element = $ELEMENT_CLASS->new({
                                        id             => 1,
                                        name           => 'test element',
                                        description    => 'testing',
                                        active         => 1,
                                        output_channel => $oc,
                                     });
#    $element->set_primary_oc_id($oc->get_id,100);
    my $story = $CLASS->new({
                           name        => "_test_$time",
                           description => 'this is a test',
                           priority    => 1,
                           source__id  => 1,
                           slug        => 'test',
                           user__id    => 0,
                           element     => $element, 
                       });
    # tryto get the uri before a category assigned. should catch an error
    eval { $story->get_uri };
    isnt( $@, undef, 'Should get an error if we try to get a uri with no category.' );
    # make a couple of categories
    my $cats = [];
    $cats->[0] = Bric::Biz::Category->new({ 
                                           name => "_test_$time.1", 
                                           description => '',
                                           directory => "_test_$time.1",
                                           id => 1,
                                        });
    $cats->[1] = Bric::Biz::Category->new({ 
                                           name => "_test_$time.2", 
                                           description => '',
                                           directory => "_test_$time.2",
                                           id => 2,
                                        });
    # add the categories 
    $story->add_categories($cats);
    $story->set_primary_category($cats->[0]);
    # the uri should now be '/$dir/.*test'
    # XXX try to get the uri with a cat set
    # XXX then try it with a different cat
}

sub test_get_fields_from_new: Test(0) {
    # XXX make a new story with all of the fields
    # XXX Test: does each field have a value matching
    #           that set in the params?
}

sub test_set_get_fields: Test(0) {
    # XXX make a new story with minimal fields set
    # XXX For each field:
    # XXX set the field
    # XXX Test: get the field and compare with what we set
}


1;
__END__
