package Bric::Biz::Person::DevTest;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Bric::Biz::Person;
use Test::More;

my $name = { lname => 'Whorf',
             fname => 'Benjamin',
             mname => 'Lee',
             prefix => 'Dr.',
             suffix => 'Ph.D.'
           };

##############################################################################
# Test constructors.
##############################################################################

sub test_lookup : Test(5) {
    my $self = shift;
    ok( my $p = Bric::Biz::Person->new($name), "Create Whorf" );
    ok( $p->save, "Save Whorf" );
    ok( my $id = $p->get_id, "Check for ID" );
    # Save the ID for deleting.
    $self->add_del_ids($id);
    # Look up the ID in the database.
    ok( $p = Bric::Biz::Person->lookup({ id => $id }),
        "Look up Whorf" );
    is( $p->get_id, $id, "Check that ID is the same" );
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
            DELETE FROM person
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

1;
__END__
