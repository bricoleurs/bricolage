package Bric::Biz::Category::DevTest;
use strict;
use warnings;
use base qw(Bric::Test::DevBase);
use Test::More;
use Bric::Biz::Category;
use Bric::Biz::Site;
use Bric::Util::DBI qw(:junction);
use Bric::Util::Grp::CategorySet;
use Bric::Util::Priv::Parts::Const qw(:all);

my %cat = ( name        => 'Testing',
            site_id     => 100,
            description => 'Description',
            parent_id   => 1,
            directory   => 'testing',
          );

sub table { 'category' }

sub cleanup_attrs : Test(teardown) {
    Bric::Util::DBI::prepare(
        qq{DELETE FROM attr_category WHERE id > 1023}
    )->execute;
    Bric::Util::DBI::prepare(
        qq{DELETE FROM grp_priv WHERE id > 1023}
    )->execute;
}

##############################################################################
# Test constructors.
##############################################################################
# Test the lookup() method.
sub test_lookup : Test(21) {
    my $self = shift;

    ok (my $cat = Bric::Biz::Category->new({%cat}), "Create $cat{name}");
    ok ($cat->set_ad_string('foo'),                 'Set the ad string');
    ok ($cat->save,                                 "Save $cat{name}");
    ok (my $id = $cat->get_id,                      "Check for ID" );

    # Save the ID for deleting.
    $self->add_del_ids([$id]);
    $self->add_del_ids([$cat->get_asset_grp_id], 'grp');

    # Look up the ID in the database.
    my $uri = '/testing';
    ok ($cat = Bric::Biz::Category->lookup({id => $id}), "Look up $cat{name}");
    is ($cat->get_id, $id,                        'Check that ID is the same');

    # Look up on site and uri
    ok ($cat = Bric::Biz::Category->lookup({uri => "$uri/", site_id => 100}),
        "Look up $cat{name} on URI and Site");
    is ($cat->get_id, $id,                        'Check that ID is the same');

    # Same but without a trailing slash
    ok ($cat = Bric::Biz::Category->lookup({uri => $uri, site_id => 100}),
        "Look up $cat{name} on URI with no trailing slash and Site");
    is ($cat->get_id, $id,                        'Check that ID is the same');

    # Same but using ANY
    ok ($cat = Bric::Biz::Category->lookup({uri => ANY($uri), site_id => 100}),
        "Look up $cat{name} on URI with no trailing slash and using ANY and Site");
    is ($cat->get_id, $id,                        'Check that ID is the same');

    # Make sure we've got the ad string.
    is ($cat->get_ad_string, 'foo', 'Check adstring');

    # Make sure we've got an asset group.
    ok( my $ag = Bric::Util::Grp::Asset->lookup({
        id => $cat->get_asset_grp_id
      }), "Look up asset group");

    ok($ag->is_active, "Check asset group is active" );

    # Now deactivate the category.
    ok( $cat->deactivate, "Deactivate category" );
    ok( $cat->save, "Save deactivated category" );

    # Check that it and the asset group are both deactivated in the database.
    ok($cat = Bric::Biz::Category->lookup({id => $id}),
       "Look up deactivated $cat{name}");
    ok(! $cat->is_active, "Check category is still deactivated" );

    ok( $ag = Bric::Util::Grp::Asset->lookup({
        id => $cat->get_asset_grp_id
      }), "Look up deactivated asset group");

    ok(!$ag->is_active, "Check asset group is deactivated" );
}

##############################################################################
# Test the list() method.
sub test_list : Test(36) {
    my $self = shift;

    # Create a new category group.
    ok( my $grp = Bric::Util::Grp::CategorySet->new
        ({ name => 'Test CatSet' }),
        "Create group" );

    # Create a site.
    ok( my $site = Bric::Biz::Site->new({
        name => 'foo site',
        domain_name => 'foo.com',
    }), 'Create a new site');
    ok $site->deactivate;
    ok $site->save;
    my $site_id = $site->get_id;
    $self->add_del_ids([$site_id], 'site');

    # Create some test records.
    for my $n (1..5) {
        my %args = %cat;
        # Make sure the directory name is unique.
        $args{directory} .= $n;
        $args{name} .= $n if $n % 2;
        $args{site_id} = $site_id unless $n %2;
        ok( my $cat = Bric::Biz::Category->new(\%args), "Create $args{name}" );
        ok( $cat->save, "Save $args{name}" );
        # Save the ID for deleting.
        $self->add_del_ids([$cat->get_id]);
        $self->add_del_ids([$cat->get_asset_grp_id], 'grp');
        $grp->add_member({ obj => $cat }) if $n % 2;
    }

    ok( $grp->save, "Save group" );
    ok( my $grp_id = $grp->get_id, "Get group ID" );
    $self->add_del_ids([$grp_id], 'grp');

    # Try name.
    ok( my @cats = Bric::Biz::Category->list({ name => $cat{name} }),
        "Look up name $cat{name}" );
    is( scalar @cats, 2, "Check for 2 categories" );

    # Try name + wildcard.
    ok( @cats = Bric::Biz::Category->list({ name => "$cat{name}%" }),
        "Look up name $cat{name}%" );
    is( scalar @cats, 5, "Check for 5 categories" );

    # Try site_id
    ok( @cats = Bric::Biz::Category->list({site_id => 100}),
        'Look up site with ID 100');
    # We get 4 because of the default category
    is( scalar @cats, 4, "Check for 4 categories" );

    # Try active_sites.
    ok( @cats = Bric::Biz::Category->list({active_sites => 1}),
        'Look up categories associated with active sites');
    is( scalar @cats, 4, "Check for 4 categories" );

    # Try a bogus site_id.
    @cats = Bric::Biz::Category->list({site_id => -1});
    is( scalar @cats, 0, "Check for 0 categories" );

    # Try grp_id.
    ok( @cats = Bric::Biz::Category->list({ grp_id => $grp_id }),
        "Look up grp_id '$grp_id'" );
    is( scalar @cats, 3, "Check for 3 categories" );

    # Make sure we've got all the Group IDs we think we should have.
    my $all_grp_id = Bric::Biz::Category::INSTANCE_GROUP_ID;
    foreach my $cat (@cats) {
        my %grp_ids = map { $_ => 1 } @{ $cat->get_grp_ids };
        ok( $grp_ids{$all_grp_id} && $grp_ids{$grp_id},
          "Check for both IDs" );

    }

    # Try deactivating one group membership.
    ok( my $mem = $grp->has_member({ obj => $cats[0] }), "Get member" );
    ok( $mem->deactivate->save, "Deactivate and save member" );

    # Now there should only be two using grp_id.
    ok( @cats = Bric::Biz::Category->list({ grp_id => $grp_id }),
        "Look up grp_id '$grp_id' again" );
    is( scalar @cats, 2, "Check for 2 categories" );

    # Try parent_id. The root category shouldn't return itself, but should
    # return all of its children, of course.
    ok( @cats = Bric::Biz::Category->list({ parent_id => 1 }),
        "Look up parent_id 1" );
    is( scalar @cats, 5, "Check for 5 categories" );

}

sub test_root_changes : Test(7) {
    my $cat = Bric::Biz::Category->new(\%cat);
    my @cats;

    is($cat->site_root_category_id, 1, "Correct Root Category");
    ok(@cats = Bric::Biz::Category->list({parent_id => 0}), "List on parent_id of 0");

    # Make sure this isn't returning the master root category
    is(scalar @cats, 1, "Check for 1 category");

    is($cat->is_root_category ? 1 : 0, 0, "Check root on non-root category");
    is($cats[0]->is_root_category ? 1: 0, 1, "Check root on root category");

    is($cat->site_root_category_id, 1, "Check this category knows its root");
    is(Bric::Biz::Category->site_root_category_id(100), 1,
       "Check class method for default category of a site");
}

sub test_permission_inheritance : Test(30) {
    my $self = shift;
    ok my $cat = Bric::Biz::Category->new({%cat}), "Create $cat{name}";
    ok $cat->save,                                 "Save $cat{name}";
    ok my $id = $cat->get_id,                      'Get ID';
    ok my $asset_grp_id = $cat->get_asset_grp_id, 'Get asset group id';

    # Save the ID for deleting.
    $self->add_del_ids([$id]);
    $self->add_del_ids([$asset_grp_id], 'grp');

    # Create a new category group and add the category to it.
    ok my $grp = Bric::Util::Grp::CategorySet->new({ name => 'Test CatSet' }),
        'Create category group';
    ok $grp->add_member({ obj => $cat }), 'Add category to group';
    ok $grp->save, 'Save category group';
    ok my $grp_id = $grp->get_id, 'Get group ID';
    $self->add_del_ids([$grp_id] => 'grp');

    # Grant the Story Editors group permission to edit assets in the new
    # category.
    ok my $editors = Bric::Util::Grp->lookup({ name => 'Story Editors' }),
        'Look up the Story Editors group';
    ok my $perm = Bric::Util::Priv->new({
        usr_grp => $editors->get_id,
        obj_grp => $asset_grp_id,
        value   => EDIT,
    }), 'Create a new permission';
    ok $perm->save, 'Save the new permission';

    # Look up the category to get grp_ids updated.
    ok $cat = Bric::Biz::Category->lookup({ id => $id }),
        'Look up the new category';

    # So the membership should all be as expected.
    my @grp_ids = (Bric::Biz::Category::INSTANCE_GROUP_ID, $grp_id);
    is_deeply [sort { $a <=> $b } @{ $cat->get_grp_ids }], \@grp_ids,
        'The category should be associated with both grp ids';

    is_deeply [$id], [map { $_->get_id } $grp->get_objects ],
        'And the group should know it has the category member';

    # And the permission should be as expected.
    ok my @privs = Bric::Util::Priv->list({ obj_grp_id => $asset_grp_id }),
        'Get list of permissions';
    is scalar @privs, 1, 'There should be one permission object';
    is $privs[0]->get_usr_grp_id, $editors->get_id,
        'It should be granted to Story Editors';
    is $privs[0]->get_value, EDIT, 'And it should be EDIT';

    # Create a new category with the last category as its parent.
    ok my $cat2 = Bric::Biz::Category->new({
        %cat,
        name      => 'Testing2',
        parent_id => $id,
    }), 'Create subcategory';
    ok $cat2->save,                                    'Save subcategory';
    ok my $sub_id = $cat2->get_id,                     'Get ID';
    ok my $sub_asset_grp_id = $cat2->get_asset_grp_id, 'Get asset grp ID';

    # Save the ID for deleting.
    $self->add_del_ids([$sub_id]);
    $self->add_del_ids([$sub_asset_grp_id], 'grp');

    # Look up the category to get grp_ids updated.
    ok $cat2 = Bric::Biz::Category->lookup({ id => $sub_id }),
        'Look up the subcategory';

    # It should be in the same groups as the parent.
    is_deeply [sort { $a <=> $b } @{ $cat2->get_grp_ids }], \@grp_ids,
        'The subcategory should be in the same groups as the parent';

    # And the group should know it.
    ok $grp = Bric::Util::Grp->lookup({ id => $grp_id }),
        'Look up the group again';
    is_deeply [$id, $sub_id], [map { $_->get_id } $grp->get_objects ],
        'And the group should know it now has two category members';

    # And the permission should be the same as for the parent.
    ok @privs = Bric::Util::Priv->list({ obj_grp_id => $sub_asset_grp_id }),
        'Get list of permissions for subcategory';
    is scalar @privs, 1, 'There should be one permission object';
    is $privs[0]->get_usr_grp_id, $editors->get_id,
        'It should be granted to Story Editors';
    is $privs[0]->get_value, EDIT, 'And it should be EDIT';
}

1;
__END__
