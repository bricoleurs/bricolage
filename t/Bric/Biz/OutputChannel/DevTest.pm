package Bric::Biz::OutputChannel::DevTest;
use strict;
use warnings;
use base qw(Bric::Test::DevBase);
use Test::More;
use Bric::Biz::OutputChannel qw(:case_constants);
use Bric::Dist::ServerType;

sub table { 'output_channel' }

my %oc = ( name        => 'Bogus',
           description => 'Bogus OC',
           site_id     => 100,
           protocol    => 'http://',
         );
my $web_oc_id = 1;

##############################################################################
# Clean out possible test values from OutputChannel.tst. We can delete this if
# we ever delete the .tst files.
##############################################################################
sub _clean_test_vals : Test(startup) {
    my $self = shift;
    $self->add_del_ids([2, 3, 4]);
}

##############################################################################
# Test constructors.
##############################################################################
# Test the lookup() method.
sub test_lookup : Test(14) {
    ok( my $oc = Bric::Biz::OutputChannel->lookup({ id => $web_oc_id}),
        "Lookup Web OC" );

    # Make sure it's a good OC.
    isa_ok($oc, 'Bric::Biz::OutputChannel');
    isa_ok($oc, 'Bric');

    # Check its properties.
    is ($oc->get_name,        'Web',               "Check name" );
    is ($oc->get_description, 'Output to the web', "Check description" );
    is ($oc->get_site_id,     100,                 'Check site ID');
    is ($oc->get_protocol,    undef,               'Check protocol');
    is ($oc->get_filename,    'index',             "Check filename" );
    is ($oc->get_file_ext,    'html',              "Check file_ext" );
    is ($oc->get_uri_format,  '/%{categories}/%Y/%m/%d/%{slug}/',
          "Check uri_format" );
    is ($oc->get_fixed_uri_format, '/%{categories}/',
          "Check fixed_uri_format" );
    is ($oc->get_uri_case, Bric::Biz::OutputChannel::MIXEDCASE(),
        "Check uri_case" );
    ok (!$oc->can_use_slug,   "Check can_use_slug" );
    ok ($oc->is_active,       "Check is_active" );
}

##############################################################################
# Test the list() method.
sub test_list : Test(75) {
    my $self = shift;
    # Create a new output channel group.
    ok( my $grp = Bric::Util::Grp::OutputChannel->new
        ({name => 'Test OC Grp'}), "Create group" );

    # Look up the default "Web" group.
    ok( my $web_oc = Bric::Biz::OutputChannel->lookup({id => $web_oc_id}),
        "Look up web OC" );

    # Construct a server type.
    ok( my $st = Bric::Dist::ServerType->new({name        => 'Bogus',
                                              move_method => 'FTP',
                                              site_id     => 100}),
        "Create server type" );

    my $alt_format = '/%Y/%m/%{categories}/%d/%{slug}/';
    # Create some test records.
    for my $n (1..5) {
        my %args = %oc;
        # Make sure the name is unique.
        $args{name}   .= $n;

        if ($n % 2) {
            # There'll be three of these.
            $args{description} .= $n;
            $args{protocol}    .= $n;
            $args{uri_case}     = UPPERCASE;
            $args{uri_format}   = $alt_format;
            $args{use_slug}     = 1;
            $args{primary}      = 1;
        } else {
            # And two of these.
            $args{protocol}         = '';
            $args{file_name}        = 'home';
            $args{file_ext}         = '.pl';
            $args{fixed_uri_format} = $alt_format;
            $args{post_path}        = 'bar';
        }
        ok( my $oc = Bric::Biz::OutputChannel->new(\%args),
            "Create $args{name}" );
        # Add three of them as includes in the web OC.
        $web_oc->add_includes($oc) if $n % 2;
        ok( $oc->save, "Save $args{name}" );
        # Save the ID for deleting.
        $self->add_del_ids($oc->get_id);
        $grp->add_member({ obj => $oc }) if $n % 2;
        # Add three two of them to the server type.
        $st->add_output_channels($oc) unless $n % 2;
    }

    # Save the group.
    ok( $grp->save, "Save group" );
    ok( my $grp_id = $grp->get_id, "Get group ID" );
    $self->add_del_ids($grp_id, 'grp');

    # Save the server type.
    ok( $st->save, "Save server type" );
    ok( my $st_id = $st->get_id, "Get server type ID" );
    $self->add_del_ids($st->get_id, 'server_type');

    # Save the web output channel.
    ok( $web_oc->save, "Save web OC" );

    # Start with the "name" attribute.
    ok(my @ocs = Bric::Biz::OutputChannel->list({ name => 'Web'}),
       "List name 'Web'" );
    is(scalar @ocs, 1, "Check name number = 1");
    is($ocs[0]->get_name, 'Web', "Check name 'Web'" );
    @ocs = Bric::Biz::OutputChannel->list({ name => 'foo'});
    ok(!@ocs, "List name 'foo' has no results");

    # Try name + wildcard.
    ok( @ocs = Bric::Biz::OutputChannel->list({ name => "$oc{name}%" }),
        "Look up name $oc{name}%" );
    is( scalar @ocs, 5, "Check for 5 output channels" );

    # Try the "description" attribute.
    ok(@ocs = Bric::Biz::OutputChannel->list
       ({ description => 'Output to the web'}),
       "List desc 'Output to the web'" );
    is(scalar @ocs, 1, "Check desc number");
    is($ocs[0]->get_description, 'Output to the web',
       "Check desc 'Output to the web'" );
    @ocs = Bric::Biz::OutputChannel->list({ description => 'foo'});
    ok(!@ocs, "List desc 'foo' has no results");

    # Try description again.
    ok( @ocs = Bric::Biz::OutputChannel->list
        ({ description => $oc{description} }),
        "Look up description '$oc{description}'" );
    is( scalar @ocs, 2, "Check for 2 output channels" );

    # Try description with wild card.
    ok( @ocs = Bric::Biz::OutputChannel->list
        ({ description => "$oc{description}%" }),
        "Look up description '$oc{description}%'" );
    is( scalar @ocs, 5, "Check for 5 output channels" );

    # Try site_id
    ok (@ocs = Bric::Biz::OutputChannel->list({site_id => $oc{site_id}}),
        "Look up site '$oc{site_id}'");
    is (scalar @ocs, 6, "Check for 6 output channels" );

    # Try protocol
    ok (@ocs = Bric::Biz::OutputChannel->list({protocol => $oc{protocol}.'%'}),
        "Look up site '$oc{protocol}%'");
    is (scalar @ocs, 3, "Check for 3 output channels" );

    # Try "primary".
    ok( @ocs = Bric::Biz::OutputChannel->list({ primary => 1 }),
        "Try primary 1" );
    is(scalar @ocs, 4, "Check primary number");
    is( $ocs[0]->get_primary, 1, "Check primary is 1" );

    # Try grp_id.
    ok( @ocs = Bric::Biz::OutputChannel->list({ grp_id => $grp_id }),
        "Look up grp_id $grp_id" );
    is( scalar @ocs, 3, "Check for 3 output channels" );

    # Make sure we've got all the Group IDs we think we should have.
    my $all_grp_id = Bric::Biz::OutputChannel::INSTANCE_GROUP_ID;
    foreach my $dest (@ocs) {
        my %grp_ids = map { $_ => 1 } $dest->get_grp_ids;
        ok( $grp_ids{$all_grp_id} && $grp_ids{$grp_id},
          "Check for both IDs" );
    }

    # Try deactivating one group membership.
    ok( my $mem = $grp->has_member({ obj => $ocs[0] }), "Get member" );
    ok( $mem->deactivate->save, "Deactivate and save member" );

    # Now there should only be two using grp_id.
    ok( @ocs = Bric::Biz::OutputChannel->list({ grp_id => $grp_id }),
        "Look up grp_id '$grp_id' again" );
    is( scalar @ocs, 2, "Check for 2 output channels" );


    # Try include_parent_id.
    ok( @ocs = Bric::Biz::OutputChannel->list
        ({ include_parent_id => $web_oc_id }),
        "Look up with parent ID $web_oc_id" );
    is( scalar @ocs, 3, "Check for 3 output channels" );

    # Try server_type_id.
    ok( @ocs = Bric::Biz::OutputChannel->list({ server_type_id => $st_id }),
        "Look up with server_type_id $st_id" );
    is( scalar @ocs, 2, "Check for 2 output channels" );

    # story_instance_id and media_instance_id are actually tested by
    # Bric::Biz::Asset::Business::Story::DevTes and
    # Bric::Biz::Asset::Business::Media::DevTest.

    # Try uri_format.
    ok( @ocs = Bric::Biz::OutputChannel->list({ uri_format => '/\\%{cate%' }),
        "Try uri_format '/\\%{cate%'" );
    is( $ocs[0]->get_uri_format, '/%{categories}/%Y/%m/%d/%{slug}/',
          "Check uri_format" );
    ok( @ocs = Bric::Biz::OutputChannel->list({ uri_format => $alt_format }),
        "Try uri_format '$alt_format'" );
    is( scalar @ocs, 3, "Check for 3 output channels" );

    # Try fixed_uri_format.
    ok( @ocs = Bric::Biz::OutputChannel->list
        ({ fixed_uri_format => '/\\%{cate%' }),
        "Try fixed_uri_format '/\\%{cate%'" );
    is( $ocs[0]->get_fixed_uri_format, '/%{categories}/',
          "Check fixed_uri_format" );
    ok( @ocs = Bric::Biz::OutputChannel->list
        ({ fixed_uri_format => $alt_format }),
        "Try fixed_uri_format '$alt_format'" );
    is( scalar @ocs, 2, "Check for 2 output channels" );

    # Try uri_case.
    ok( @ocs = Bric::Biz::OutputChannel->list({ uri_case => MIXEDCASE }),
        "Try uri_case mixed" );
    is( $ocs[0]->get_uri_case, MIXEDCASE, "Check uri_case mixed" );
    is( scalar @ocs, 3, "Check for 3 output channels" );
    @ocs = Bric::Biz::OutputChannel->list({ uri_case => LOWERCASE });
    ok(!@ocs, "List uri_case lower has no results");
    ok( @ocs = Bric::Biz::OutputChannel->list({ uri_case => UPPERCASE }),
        "Try user_case upper" );
    is(scalar @ocs, 3, "List uri_case upper has 3 results");

    # Try use_slug.
    ok( @ocs = Bric::Biz::OutputChannel->list({ use_slug => 0 }),
        "Try use_slug 0" );
    ok( ! $ocs[0]->can_use_slug, "Can't use slug" );
    is( scalar @ocs, 3, "Check for 3 output channels" );
    ok( @ocs = Bric::Biz::OutputChannel->list({ use_slug => 1 }),
        "Try use_slug 1" );
    is( scalar @ocs, 3, "Check for 3 output channels" );

    # Try active.
    ok( @ocs = Bric::Biz::OutputChannel->list({ active => 1 }),
        "Try active 1" );
    ok( $ocs[0]->is_active, "Yes, is_active" );
    is( scalar @ocs, 6, "Check for 6 output channels" );
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
        ({ uri_format => '/\\%{cate%' }), "Try href uri_format '/\\%{cate%'" );
    is( $ocs->{1}->get_uri_format, '/%{categories}/%Y/%m/%d/%{slug}/',
          "Check uri_format" );

    # Try fixed_uri_format.
    ok( $ocs = Bric::Biz::OutputChannel->href
        ({ fixed_uri_format => '/\\%{cate%' }),
        "Try href fixed_uri_format '/\\%{cate%'" );
    is( $ocs->{1}->get_fixed_uri_format, '/%{categories}/',
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
        ({ uri_format => '/\\%{cate%' }), "Try list_id uri_format '/\\%{cate%'" );

    # Try fixed_uri_format.
    ok( @ids = Bric::Biz::OutputChannel->list_ids
        ({ fixed_uri_format => '/\\%{cate%' }),
        "Try list_id fixed_uri_format '/\\%{cate%'" );

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
