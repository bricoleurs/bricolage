package Bric::Biz::OutputChannel::DevTest;
use strict;
use warnings;
use base qw(Bric::Test::DevBase);
use Test::More;
use Bric::Biz::OutputChannel;

sub table { 'output_channel' }

##############################################################################
# Test constructors.
##############################################################################
# Test the lookup() method.
sub test_lookup : Test(14) {
    ok( my $oc = Bric::Biz::OutputChannel->lookup({ id => 1}),
        "Lookup Web OC" );

    # Make sure it's a good OC.
    isa_ok($oc, 'Bric::Biz::OutputChannel');
    isa_ok($oc, 'Bric');

    # Check its properties.
    is( $oc->get_name, 'Web', "Check name" );
    is( $oc->get_description, 'Output to the web', "Check description" );
    is( $oc->get_pre_path, '', "Check pre_path" );
    is( $oc->get_post_path, '', "Check post_path" );
    is( $oc->get_filename, 'index', "Check filename" );
    is( $oc->get_file_ext, 'html', "Check file_ext" );
    is( $oc->get_uri_format, '/categories/year/month/day/slug/',
          "Check uri_format" );
    is( $oc->get_fixed_uri_format, '/categories/',
          "Check fixed_uri_format" );
    is( $oc->get_uri_case, Bric::Biz::OutputChannel::MIXEDCASE(),
        "Check uri_case" );
    ok( !$oc->can_use_slug, "Check can_use_slug" );
    ok( $oc->is_active, "Check is_active" );
}

##############################################################################
# Test the list() method.
sub test_list : Test(30) {
    # Start with the "name" attribute.
    ok(my @ocs = Bric::Biz::OutputChannel->list({ name => 'Web'}),
       "List name 'Web'" );
    is($#ocs, 0, "Check name number");
    is($ocs[0]->get_name, 'Web', "Check name 'Web'" );
    ok(@ocs = Bric::Biz::OutputChannel->list({ name => 'we%'}),
       "List name 'We%'" );
    is($#ocs, 0, "Check wildcard name number");
    is($ocs[0]->get_name, 'Web', "Check wildcard name 'Web'" );
    @ocs = Bric::Biz::OutputChannel->list({ name => 'foo'});
    ok(!@ocs, "List name 'foo' has no results");

    # Try the "description" attribute.
    ok(@ocs = Bric::Biz::OutputChannel->list
       ({ description => 'Output to the web'}),
       "List desc 'Output to the web'" );
    is($#ocs, 0, "Check desc number");
    is($ocs[0]->get_description, 'Output to the web',
       "Check desc 'Output to the web'" );
    ok(@ocs = Bric::Biz::OutputChannel->list({ description => '%web'}),
       "List desc '%web'" );
    is($#ocs, 0, "Check wildcard desc number");
    is($ocs[0]->get_description, 'Output to the web',
       "Check wildcard desc 'Output to the web'" );
    @ocs = Bric::Biz::OutputChannel->list({ description => 'foo'});
    ok(!@ocs, "List desc 'foo' has no results");

    # Try "primary".
    ok( @ocs = Bric::Biz::OutputChannel->list({ primary => 1 }),
        "Try primary 1" );
    is($#ocs, 0, "Check primary number");
    is( $ocs[0]->get_primary, 1, "Check primary is 1" );

    # Try server_type_id.

    # Try includ_parent_id.

    # Try uri_format.
    ok( @ocs = Bric::Biz::OutputChannel->list
        ({ uri_format => '/cate%' }), "Try uri_format '/cate%'" );
    is( $ocs[0]->get_uri_format, '/categories/year/month/day/slug/',
          "Check uri_format" );

    # Try fixed_uri_format.
    ok( @ocs = Bric::Biz::OutputChannel->list
        ({ fixed_uri_format => '/cate%' }),
        "Try fixed_uri_format '/cate%'" );
    is( $ocs[0]->get_fixed_uri_format, '/categories/',
          "Check fixed_uri_format" );

    # Try uri_case.
    ok( @ocs = Bric::Biz::OutputChannel->list
        ({ uri_case => Bric::Biz::OutputChannel::MIXEDCASE() }),
        "Try uri_case mixed" );
    is( $ocs[0]->get_uri_case, Bric::Biz::OutputChannel::MIXEDCASE(),
        "Check uri_case mixed" );
    @ocs = Bric::Biz::OutputChannel->list
      ({ uri_case => Bric::Biz::OutputChannel::LOWERCASE() });
    ok(!@ocs, "List uri_case lower has no results");

    # Try use_slug.
    ok( @ocs = Bric::Biz::OutputChannel->list({ use_slug => 0 }),
        "Try use_slug 0" );
    ok( ! $ocs[0]->can_use_slug, "Can't use slug" );
    @ocs = Bric::Biz::OutputChannel->list({ use_slug => 1 });
    ok(!@ocs, "List use_slug 1 has no results");

    # Try active.
    ok( @ocs = Bric::Biz::OutputChannel->list({ active => 1 }),
        "Try active 1" );
    ok( $ocs[0]->is_active, "Yes, is_active" );
    @ocs = Bric::Biz::OutputChannel->list({ active => 0 });
    ok(!@ocs, "List active 0 has no results");
}

##############################################################################
# Test href().
sub test_href : Test(30) {
    # Start with the "name" attribute.
    ok(my $ocs = Bric::Biz::OutputChannel->href({ name => 'Web'}),
       "Href name 'Web'" );
    is(scalar keys %$ocs, 1, "Check name number");
    is($ocs->{1}->get_name, 'Web', "Check name 'Web'" );
    ok($ocs = Bric::Biz::OutputChannel->href({ name => 'we%'}),
       "Href name 'We%'" );
    is(scalar keys %$ocs, 1, "Check wildcard name number");
    is($ocs->{1}->get_name, 'Web', "Check wildcard name 'Web'" );
    $ocs = Bric::Biz::OutputChannel->href({ name => 'foo'});
    is(scalar keys %$ocs, 0, "Href name 'foo' has no results");

    # Try the "description" attribute.
    ok($ocs = Bric::Biz::OutputChannel->href
       ({ description => 'Output to the web'}),
       "Href desc 'Output to the web'" );
    is(scalar keys %$ocs, 1, "Check desc number");
    is($ocs->{1}->get_description, 'Output to the web',
       "Check desc 'Output to the web'" );
    ok($ocs = Bric::Biz::OutputChannel->href({ description => '%web'}),
       "Href desc '%web'" );
    is(scalar keys %$ocs, 1, "Check wildcard desc number");
    is($ocs->{1}->get_description, 'Output to the web',
       "Check wildcard desc 'Output to the web'" );
    $ocs = Bric::Biz::OutputChannel->href({ description => 'foo'});
    is(scalar keys %$ocs, 0, "List desc 'foo' has no results");

    # Try "primary".
    ok( $ocs = Bric::Biz::OutputChannel->href({ primary => 1 }),
        "Try href primary 1" );
    is(scalar keys %$ocs, 1, "Check href primary number");
    is( $ocs->{1}->get_primary, 1, "Check primary is 1" );

    # Try server_type_id.

    # Try includ_parent_id.

    # Try uri_format.
    ok( $ocs = Bric::Biz::OutputChannel->href
        ({ uri_format => '/cate%' }), "Try href uri_format '/cate%'" );
    is( $ocs->{1}->get_uri_format, '/categories/year/month/day/slug/',
          "Check uri_format" );

    # Try fixed_uri_format.
    ok( $ocs = Bric::Biz::OutputChannel->href
        ({ fixed_uri_format => '/cate%' }),
        "Try href fixed_uri_format '/cate%'" );
    is( $ocs->{1}->get_fixed_uri_format, '/categories/',
          "Check fixed_uri_format" );

    # Try uri_case.
    ok( $ocs = Bric::Biz::OutputChannel->href
        ({ uri_case => Bric::Biz::OutputChannel::MIXEDCASE() }),
        "Try href uri_case mixed" );
    is( $ocs->{1}->get_uri_case, Bric::Biz::OutputChannel::MIXEDCASE(),
        "Check uri_case mixed" );
    $ocs = Bric::Biz::OutputChannel->href
      ({ uri_case => Bric::Biz::OutputChannel::LOWERCASE() });
    is(scalar keys %$ocs, 0, "Href uri_case lower has no results");

    # Try use_slug.
    ok( $ocs = Bric::Biz::OutputChannel->href({ use_slug => 0 }),
        "Try href use_slug 0" );
    ok( ! $ocs->{1}->can_use_slug, "Can't use slug" );
    $ocs = Bric::Biz::OutputChannel->href({ use_slug => 1 });
    is(scalar keys %$ocs, 0, "Href use_slug 1 has no results");

    # Try active.
    ok( $ocs = Bric::Biz::OutputChannel->href({ active => 1 }),
        "Try href active 1" );
    ok( $ocs->{1}->is_active, "Yes, is_active" );
    $ocs = Bric::Biz::OutputChannel->href({ active => 0 });
    is(scalar keys %$ocs, 0, "Href active 0 has no results");
}

##############################################################################
# Test class methods.
##############################################################################
# Test list_ids().
sub test_list_ids : Test(25) {
    # Start with the "name" attribute.
    ok(my @ids = Bric::Biz::OutputChannel->list_ids({ name => 'Web'}),
       "List name IDs 'Web'" );
    is($#ids, 0, "Check name ID number");
    is( $ids[0], 1, "Check 'Web' ID number" );

    ok(@ids = Bric::Biz::OutputChannel->list_ids({ name => 'we%'}),
       "List name ID 'We%'" );
    is($#ids, 0, "Check wildcard name ID number");
    is($ids[0], 1, "Check wildcard name ID" );
    @ids = Bric::Biz::OutputChannel->list({ name => 'foo'});
    ok(!@ids, "List name 'foo' has no results");

    # Try the "description" attribute.
    ok(@ids = Bric::Biz::OutputChannel->list_ids
       ({ description => 'Output to the web'}),
       "List ID desc 'Output to the web'" );
    is($#ids, 0, "Check desc ID number");
    is($ids[0], 1, "Check desc ID 1" );
    ok(@ids = Bric::Biz::OutputChannel->list_ids({ description => '%web'}),
       "List ID desc '%web'" );
    is($#ids, 0, "Check wildcard ID desc number");
    is($ids[0], 1, "Check wildcard ID desc 1" );
    @ids = Bric::Biz::OutputChannel->list_ids({ description => 'foo'});
    ok(!@ids, "List ID desc 'foo' has no results");

    # Try "primary".
    ok( @ids = Bric::Biz::OutputChannel->list_ids({ primary => 1 }),
        "Try primary ID 1" );
    is($#ids, 0, "Check primary ID number");
    is( $ids[0], 1, "Check ID primary is 1" );

    # Try server_type_id.

    # Try includ_parent_id.

    # Try uri_format.
    ok( @ids = Bric::Biz::OutputChannel->list_ids
        ({ uri_format => '/cate%' }), "Try list_id uri_format '/cate%'" );

    # Try fixed_uri_format.
    ok( @ids = Bric::Biz::OutputChannel->list_ids
        ({ fixed_uri_format => '/cate%' }),
        "Try list_id fixed_uri_format '/cate%'" );

    # Try uri_case.
    ok( @ids = Bric::Biz::OutputChannel->list_ids
        ({ uri_case => Bric::Biz::OutputChannel::MIXEDCASE() }),
        "Try list_id uri_case mixed" );
    @ids = Bric::Biz::OutputChannel->list_ids
      ({ uri_case => Bric::Biz::OutputChannel::LOWERCASE() });
    ok(!@ids, "List IDs uri_case lower has no results");

    # Try use_slug.
    ok( @ids = Bric::Biz::OutputChannel->list_ids({ use_slug => 0 }),
        "Try list_ids use_slug 0" );
    @ids = Bric::Biz::OutputChannel->list_ids({ use_slug => 1 });
    ok(!@ids, "List IDs use_slug 1 has no results");

    # Try active.
    ok( @ids = Bric::Biz::OutputChannel->list_ids({ active => 1 }),
        "Try list_ids active 1" );
    @ids = Bric::Biz::OutputChannel->list_ids({ active => 0 });
    ok(!@ids, "List IDs active 0 has no results");
}


1;
__END__
