package Bric::Biz::Category::DevTest;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;
use Bric::Biz::Category;
use Bric::Util::Grp::CategorySet;

my %cat = ( name => 'Testing',
            description => 'Description',
            parent_id => 0,
            directory => 'testing',
          );

##############################################################################
# Test constructors.
##############################################################################
# Test the lookup() method.
sub test_lookup : Test(7) {
    my $self = shift;
    ok( my $cat = Bric::Biz::Category->new(\%cat), "Create $cat{name}" );
    ok( $cat->set_ad_string('foo'), "Set the ad string" );
    ok( $cat->save, "Save $cat{name}" );
    ok( my $id = $cat->get_id, "Check for ID" );
    # Save the ID for deleting.
    $self->add_del_ids($id);
    # Look up the ID in the database.
    ok( $cat = Bric::Biz::Category->lookup({ id => $id }),
        "Look up $cat{name}" );
    is( $cat->get_id, $id, "Check that ID is the same" );
    # Make sure we've got the ad string.
    is( $cat->get_ad_string, 'foo', "Check adstring" );
}

##############################################################################
# Test the list() method.
sub test_list : Test(22) {
    my $self = shift;

    # Create a new category group.
    ok( my $grp = Bric::Util::Grp::CategorySet->new
        ({ name => 'Test CatSet' }),
        "Create group" );

    # Create some test records.
    for my $n (1..5) {
        my %args = %cat;
        # Make sure the directory name is unique.
        $args{directory} .= $n;
        $args{name} .= $n if $n % 2;
        ok( my $cat = Bric::Biz::Category->new(\%args), "Create $args{name}" );
        ok( $cat->save, "Save $args{name}" );
        # Save the ID for deleting.
        $self->add_del_ids($cat->get_id);
        $grp->add_member({ obj => $cat }) if $n % 2;
    }

    ok( $grp->save, "Save group" );
    ok( my $grp_id = $grp->get_id, "Get group ID" );
    $self->add_grp_del_ids($grp_id);

    # Try name.
    ok( my @cats = Bric::Biz::Category->list({ name => $cat{name} }),
        "Look up name $cat{name}" );
    is( scalar @cats, 2, "Check for 2 categories" );

    # Try name + wildcard.
    ok( @cats = Bric::Biz::Category->list({ name => "$cat{name}%" }),
        "Look up name $cat{name}%" );
    is( scalar @cats, 5, "Check for 5 categories" );

    # Try grp_id.
    my $all_grp_id = Bric::Biz::Category::INSTANCE_GROUP_ID;
    ok( @cats = Bric::Biz::Category->list
        ({ grp_id => $grp_id,
           uri => "/$cat{directory}%",
           name => "$cat{name}%" }),
        "Look up grp_id $grp_id" );
    is( scalar @cats, 3, "Check for 3 categories" );
    # Make sure we've got all the Group IDs we think we should have.
    foreach my $cat (@cats) {
        my %grp_ids = map { $_ => 1 } @{ $cat->get_grp_ids };
        ok( $grp_ids{$all_grp_id} && $grp_ids{$grp_id},
          "Check for both IDs" );
    }
}

##############################################################################

##############################################################################
# Clean up our mess.
##############################################################################
sub cleanup : Test(teardown => 0) {
    my $self = shift;

    # Delete any persons we've created.
    if (my $ids = delete $self->{del_ids}) {
        $ids = join ', ', @$ids;
        Bric::Util::DBI::prepare(qq{
            DELETE FROM category
            WHERE  id IN ($ids)
        })->execute;
    }

    if (my $ids = delete $self->{grp_del_ids}) {
        $ids = join ', ', @$ids;
        Bric::Util::DBI::prepare(qq{
            DELETE FROM grp
            WHERE  id IN ($ids)
        })->execute;
    }
}

##############################################################################
# Use this method to store IDs to be deleted from the database when a test
# method finishes running.
sub add_del_ids {
    my $self = shift;
    push @{$self->{del_ids}}, @_;
}

sub add_grp_del_ids {
    my $self = shift;
    push @{$self->{grp_del_ids}}, @_;
}


1;
__END__
