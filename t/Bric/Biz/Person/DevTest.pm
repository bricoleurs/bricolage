package Bric::Biz::Person::DevTest;
use strict;
use warnings;
use base qw(Bric::Test::DevBase);
use Bric::Biz::Person;
use Bric::Util::Grp::Person;
use Test::More;

my %name = ( lname => 'Whorf',
             fname => 'Benjamin',
             mname => 'Lee',
             prefix => 'Dr.',
             suffix => 'Ph.D.'
           );

sub table { 'person' };

##############################################################################
# Test constructors.
##############################################################################
# Test the lookup() method.
sub test_lookup : Test(5) {
    my $self = shift;
    ok( my $p = Bric::Biz::Person->new(\%name), "Create $name{lname}" );
    ok( $p->save, "Save $name{lname}" );
    ok( my $id = $p->get_id, "Check for ID" );
    # Save the ID for deleting.
    $self->add_del_ids([$id]);
    # Look up the ID in the database.
    ok( $p = Bric::Biz::Person->lookup({ id => $id }),
        "Look up $name{lname}" );
    is( $p->get_id, $id, "Check that ID is the same" );
}

##############################################################################
# Test the list() method.
sub test_list : Test(26) {
    my $self = shift;

    # Create a new person group.
    ok( my $grp = Bric::Util::Grp::Person->new
        ({ name => 'Test PersonGrp' }),
        "Create group" );

    # Create some test records.
    for my $n (1..5) {
        my %args = %name;
        $args{lname} = $name{lname} . $n if $n % 2;
        ok( my $p = Bric::Biz::Person->new(\%args), "Create $args{lname}" );
        ok( $p->save, "Save $args{lname}" );
        # Save the ID for deleting.
        $self->add_del_ids([$p->get_id]);
        $grp->add_member({ obj => $p }) if $n % 2;
    }

    ok( $grp->save, "Save group" );
    ok( my $grp_id = $grp->get_id, "Get group ID" );
    $self->add_del_ids([$grp_id], 'grp');

    # Try fname.
    ok( my @ps = Bric::Biz::Person->list({ fname => $name{fname} }),
        "Look up fname $name{fname}" );
    is( scalar @ps, 5, "Check for 5 persons" );

    # Try lname.
    ok( @ps = Bric::Biz::Person->list({ lname => $name{lname} }),
        "Look up lname $name{lname}" );
    is( scalar @ps, 2, "Check for 2 persons" );

    # Try lname + wildcard.
    ok( @ps = Bric::Biz::Person->list({ lname => "$name{lname}%" }),
        "Look up lname $name{lname}%" );
    is( scalar @ps, 5, "Check for 5 persons" );

    # Try grp_id.
    my $all_grp_id = Bric::Biz::Person::INSTANCE_GROUP_ID;
    ok( @ps = Bric::Biz::Person->list({ grp_id => $all_grp_id,
                                        fname => $name{fname} }),
        "Look up grp_id 1" );
    is( scalar @ps, 5, "Check for 5 persons" );

    # Try grp_id and make sure we have them all.
    ok( @ps = Bric::Biz::Person->list({ grp_id => $grp_id }),
        "Look up grp_id $grp_id" );
    is( scalar @ps, 3, "Check for 3 persons" );
    # Make sure we've got all the Group IDs we think we should have.
    foreach my $p (@ps) {
        my %grp_ids = map { $_ => 1 } @{ $p->get_grp_ids };
        ok( $grp_ids{$all_grp_id} && $grp_ids{$grp_id},
          "Check for both IDs" );
    }
}

1;
__END__
