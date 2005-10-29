package Bric::Biz::Person::DevTest;
use strict;
use warnings;
use base qw(Bric::Test::DevBase);
use Bric::Biz::Person;
use Bric::Util::Grp::Person;
use Test::More;

sub table { 'person' };
sub test_class { 'Bric::Biz::Person' }
sub test_grp_class { 'Bric::Util::Grp::Person' }
sub new_args {
    ( lname => 'Whorf',
      fname => 'Benjamin',
      mname => 'Lee',
      prefix => 'Dr.',
      suffix => 'Ph.D.'
    )
}

sub munge {
    $_[1]->{lname} .= $_[2] if $_[2] % 2;
}

sub cleanup_orgs : Test(teardown) {
    Bric::Util::DBI::prepare(qq{DELETE FROM org  WHERE id > 1023})->execute;
}

##############################################################################
# Test constructors.
##############################################################################
# Test the lookup() method.
sub test_lookup : Test(5) {
    my $self = shift;
    my $class = $self->test_class;
    my %name = $self->new_args;
    ok( my $p = $class->new(\%name), "Create $name{lname}" );
    ok( $p->save, "Save $name{lname}" );
    ok( my $id = $p->get_id, "Check for ID" );
    # Save the ID for deleting.
    $self->add_del_ids([$id]);
    # Look up the ID in the database.
    ok( $p = $class->lookup({ id => $id }), "Look up $name{lname}" );
    is( $p->get_id, $id, "Check that ID is the same" );
}

##############################################################################
# Test the list() method.
sub test_list : Test(30) {
    my $self = shift;
    my $class = $self->test_class;
    my $grp_class = $self->test_grp_class;
    my %name = $self->new_args;

    # Create a new person group.
    ok( my $grp = $grp_class->new({ name => 'Test PersonGrp' }),
        "Create group" );

    # Create some test records.
    for my $n (1..5) {
        my %args = %name;
        $self->munge(\%args, $n);
        ok( my $p = $class->new(\%args), "Create $args{lname}" );
        ok( $p->save, "Save $args{lname}" );
        # Save the ID for deleting.
        $self->add_del_ids([$p->get_id]);
        $grp->add_member({ obj => $p }) if $n % 2;
    }

    ok( $grp->save, "Save group" );
    ok( my $grp_id = $grp->get_id, "Get group ID" );
    $self->add_del_ids([$grp_id], 'grp');

    # Try fname.
    ok( my @ps = $class->list({ fname => $name{fname} }),
        "Look up fname $name{fname}" );
    is( scalar @ps, 5, "Check for 5 persons" );

    # Try lname.
    ok( @ps = $class->list({ lname => $name{lname} }),
        "Look up lname $name{lname}" );
    is( scalar @ps, 2, "Check for 2 persons" );

    # Try lname + wildcard.
    ok( @ps = $class->list({ lname => "$name{lname}%" }),
        "Look up lname $name{lname}%" );
    is( scalar @ps, 5, "Check for 5 persons" );

    # Try grp_id.
    my $all_grp_id = $class->INSTANCE_GROUP_ID;
    ok( @ps = $class->list({ grp_id => $all_grp_id,
                             fname => $name{fname} }),
        "Look up grp_id $all_grp_id" );
    is( scalar @ps, 5, "Check for 5 persons" );

    # Try grp_id and make sure we have them all.
    ok( @ps = $class->list({ grp_id => $grp_id }),
        "Look up grp_id $grp_id" );
    is( scalar @ps, 3, "Check for 3 persons" );
    # Make sure we've got all the Group IDs we think we should have.
    foreach my $p (@ps) {
        my %grp_ids = map { $_ => 1 } @{ $p->get_grp_ids };
        ok( $grp_ids{$all_grp_id} && $grp_ids{$grp_id},
          "Check for both IDs" );
    }

    # Try deactivating one group membership.
    ok( my $mem = $grp->has_member({ obj => $ps[0] }), "Get member" );
    ok( $mem->deactivate->save, "Deactivate and save member" );

    # Now there should only be two using grp_id.
    ok( @ps = $class->list({ grp_id => $grp_id }),
        "Look up grp_id $grp_id" );
    is( scalar @ps, 2, "Check for 2 persons" );
}

1;
__END__
