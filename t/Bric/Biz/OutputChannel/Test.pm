package Bric::Biz::OutputChannel::Test;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;
use Bric::Config qw(:oc);

##############################################################################
# Test class loading.
##############################################################################
sub _test_load : Test(1) {
    use_ok('Bric::Biz::OutputChannel');
}

##############################################################################
# Test constructors.
##############################################################################
# Test the new() method.
sub test_new : Test(16) {
    ok( my $oc = Bric::Biz::OutputChannel->new, "Create new OC" );
    isa_ok($oc, 'Bric::Biz::OutputChannel');
    isa_ok($oc, 'Bric');
    isa_ok($oc, 'Exporter');

    # Try new() with parameters.
    my $param = { name        => 'mike\'s test5',
                  description => 'a fun test',
                  primary     => 1,
                  filename    => 'home',
                  pre_path    => 'foo',
                  post_path   => 'en',
                  uri_format  => '/categories/year/month/',
                  active      => 1
                };

    ok( $oc = Bric::Biz::OutputChannel->new($param),
        "Create new OC with params" );
    is( $oc->get_name, "mike's test5", "Check name" );
    is( $oc->get_description, 'a fun test', "Check description" );
    is( $oc->get_pre_path, 'foo', "Check pre_path" );
    is( $oc->get_post_path, 'en', "Check post_path" );
    is( $oc->get_filename, 'home', "Check filename" );
    is( $oc->get_file_ext, 'html', "Check file_ext" );
    is( $oc->get_uri_format, '/categories/year/month/',
          "Check uri_format" );
    is( $oc->get_fixed_uri_format, '/categories/',
          "Check fixed_uri_format" );
    is( $oc->get_uri_case, Bric::Biz::OutputChannel::MIXEDCASE(),
        "Check uri_case" );
    ok( !$oc->can_use_slug, "Check can_use_slug" );
    ok( $oc->is_active, "Check is_active" );
}

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

##############################################################################
# Test my_meths().
sub test_my_meths : Test(6) {
    ok( my $meths = Bric::Biz::OutputChannel->my_meths, "Get my_meths" );
    isa_ok($meths, 'HASH', "my_meths is a hash" );
    is( $meths->{name}{type}, 'short', "Check name type" );
    ok( $meths = Bric::Biz::OutputChannel->my_meths(1), "Get my_meths array ref" );
    isa_ok( $meths, 'ARRAY', "my_meths(1) is an array" );
    (is $meths->[0]->{name}, 'name', "Check first meth name" );
}

##############################################################################
# Test instance methods.
##############################################################################
# Test uri_format attribute.
sub test_uri_format : Test(12) {
    ok( my $oc = Bric::Biz::OutputChannel->new, "Create new OC" );
    is( $oc->get_uri_format, '/categories/year/month/day/slug/',
          "Check uri_format" );
    ok( $oc->set_uri_format('/day/month/slug'), "Set new category" );
    is( $oc->get_uri_format, '/day/month/slug/', "Check new category" );
    ok( $oc->set_uri_format('/slug/categories/year'),
        "Set another new category" );
    is( $oc->get_uri_format, '/slug/categories/year/',
        "Check another new category" );

    # Try an empty string format.
    eval { $oc->set_uri_format('') };
    ok( my $ex = $@, "Catch empty string exception" );
    isa_ok( $ex, 'Bric::Util::Fault::Exception::DP',
            'Empty string exception is a DP' );
    is( $ex->get_msg, 'No URI Format value specified',
        "Check empty string ex message" );

    # Try a format with bogus tokens.
    eval { $oc->set_uri_format('/categories/foo') };
    ok( $ex = $@, "Catch bogus token exception" );
    isa_ok( $ex, 'Bric::Util::Fault::Exception::DP',
            'Bogus token exception is a DP' );
    is( $ex->get_msg, 'Invalid URI Format token: foo',
        "Check bogus token ex message" );
}

##############################################################################
# Test fixed_uri_format attribute.
sub test_fixed_uri_format : Test(12) {
    ok( my $oc = Bric::Biz::OutputChannel->new, "Create new OC" );
    is( $oc->get_fixed_uri_format, '/categories/',
          "Check fixed_uri_format" );
    ok( $oc->set_fixed_uri_format('/day/month/slug'), "Set new category" );
    is( $oc->get_fixed_uri_format, '/day/month/slug/', "Check new category" );
    ok( $oc->set_fixed_uri_format('/slug/categories/year'),
        "Set another new category" );
    is( $oc->get_fixed_uri_format, '/slug/categories/year/',
        "Check another new category" );

    # Try an empty string format.
    eval { $oc->set_fixed_uri_format('') };
    ok( my $ex = $@, "Catch empty string exception" );
    isa_ok( $ex, 'Bric::Util::Fault::Exception::DP',
            'Empty string exception is a DP' );
    is( $ex->get_msg, 'No Fixed URI Format value specified',
        "Check empty string ex message" );

    # Try a format with bogus tokens.
    eval { $oc->set_fixed_uri_format('/categories/foo') };
    ok( $ex = $@, "Catch bogus token exception" );
    isa_ok( $ex, 'Bric::Util::Fault::Exception::DP',
            'Bogus token exception is a DP' );
    is( $ex->get_msg, 'Invalid Fixed URI Format token: foo',
        "Check bogus token ex message" );
}

##############################################################################
# Test filename attribute.
sub test_filename : Test(20) {
    ok( my $oc = Bric::Biz::OutputChannel->new, "Create new OC" );
    is( $oc->get_filename, DEFAULT_FILENAME, "Check filename default" );
    ok( $oc->set_filename('foo'), "Set filename to 'foo'" );
    is( $oc->get_filename, 'foo', "Check for 'foo'" );

    # Create a mock story object.
    ok( my $s = Bric::Biz::Asset::Business::Story->newish('bar'),
        "Create story" );

    # Test it with the story object.
    is( $oc->get_filename($s), 'foo', "Check for 'foo' again" );

    # Now set use_slug.
    ok( $oc->use_slug_on, "Turn on use_slug" );
    is( $oc->get_filename($s), 'bar', "Check for 'bar'" );
    # Now try it with a mock story object that has no slug.
    ok( $s = Bric::Biz::Asset::Business::Story->newish,
        "Create slugless story" );
    is( $oc->get_filename($s), 'foo', "Check for 'foo' again" );

    # Now try with the case changed.
    ok( $oc->set_uri_case(Bric::Biz::OutputChannel::UPPERCASE()),
        "Set for uppercase" );
    is( $oc->get_filename, 'FOO', "Check for 'FOO'" );
    ok( $s = Bric::Biz::Asset::Business::Story->newish('bar'),
        "Create story" );
    is( $oc->get_filename($s), 'BAR', "Check for 'BAR'" );

    # Now try it with a media object.
    ok( my $m = Bric::Biz::Asset::Business::Media->newish('Foo.gif'),
        "Create media" );
    is( $oc->get_filename($m), 'FOO.GIF', "Check for 'FOO.GIF'" );

    # And try it without the case changed.
    ok( $oc->set_uri_case(Bric::Biz::OutputChannel::MIXEDCASE()),
        "Set for mixed case" );
    is( $oc->get_filename($m), 'Foo.gif', "Check for 'Foo.gif'" );

    # And finally, with the case all lowercase.
    ok( $oc->set_uri_case(Bric::Biz::OutputChannel::LOWERCASE()),
        "Set for lower case" );
    is( $oc->get_filename($m), 'foo.gif', "Check for 'foo.gif'" );
}

##############################################################################
# Test file_ext attribute.
sub test_file_ext : Test(6) {
    ok( my $oc = Bric::Biz::OutputChannel->new, "Create new OC" );
    is( $oc->get_file_ext, DEFAULT_FILE_EXT, "Check filename default" );
    ok( $oc->set_file_ext('foo'), "Set filename to 'foo'" );
    is( $oc->get_file_ext, 'foo', "Check for 'foo'" );

    # Try it with the case changed.
    ok( $oc->set_uri_case(Bric::Biz::OutputChannel::UPPERCASE()),
        "Set for uppercase" );
    is( $oc->get_file_ext, 'FOO', "Check for 'FOO'" );
}


##############################################################################
# Create bogus story constructor used by test_filename(). This is a bit fishy,
# so we may want to change it to use a real Story object constructed by new(),
# later.
package Bric::Biz::Asset::Business::Story;
sub newish { bless { slug => $_[1] } }

##############################################################################
# Create bogus media constructor used by test_filename(). This is a bit fishy,
# so we may want to change it to use a real Media object constructed by new(),
# later.
package Bric::Biz::Asset::Business::Media;
sub newish { bless { file_name => $_[1] } }

1;
__END__
