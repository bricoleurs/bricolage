package Bric::Util::Coll::Test;

use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;

# Register this class for testing.
BEGIN { __PACKAGE__->test_class }

my ($base_coll, $coll_class, $obj_class);
BEGIN {
    $base_coll = 'Bric::Util::Coll';
    $coll_class = 'Bric::Test::Coll::Fake';
    $obj_class = 'Bric::Test::Coll::FakeClass';
}

##############################################################################
# Test class loading.
##############################################################################
sub _test_load : Test(1) { use_ok($base_coll) }

##############################################################################
# Test class methods.
##############################################################################
sub test_class_name : Test(2) {
    # The abstract method should throw an exception.
    eval { $base_coll->class_name };
    isa_ok($@, 'Bric::Util::Fault::Exception::MNI');
    # But the derived method should work just fine.
    is( $coll_class->class_name, $obj_class, "class_name is $obj_class" );
}

##############################################################################
# Test constructor.
##############################################################################
sub test_construct : Test(3) {
    my $self = shift;
    ok( my $coll = $self->construct, "Construct new collection" );
    isa_ok( $coll, 'Bric::Test::Coll::Fake' );
    isa_ok( $coll, $base_coll );
}

##############################################################################
# Test instance methods.
##############################################################################
# Test get_objs.
sub test_get_objs : Test(8) {
    my $self = shift;
    ok( my $coll = $self->construct, "Construct new collection" );
    my @objs = $coll->get_objs;
    ok( !@objs, "No objects");
    # So add some.
    for (1..4) { ok( $coll->new_obj({ id => $_ }), "Add object $_" ) }
    ok( @objs = $coll->get_objs, "Get objects" );
    is( $#objs, 3, "Got four objects" );
}

##############################################################################
# Test get_new_objs().
sub test_get_new_objs : Test(8) {
    my $self = shift;
    ok( my $coll = $self->construct, "Construct new collection" );
    my @objs = $coll->get_new_objs;
    ok( !@objs, "No objects");
    # So add some.
    for (1..4) { ok( $coll->new_obj({ id => $_ }), "Add object $_" ) }
    ok( @objs = $coll->get_new_objs, "Get new objects" );
    is( $#objs, 3, "Got four objects" );
}

##############################################################################
# Test new_obj().
sub test_new_obj : Test(6) {
    my $self = shift;
    ok( my $coll = $self->construct, "Construct new collection" );
    ok( my $obj = $coll->new_obj({ id => 10 }), "Add new object" );
    isa_ok($obj, $obj_class);
    ok( my ($get) = $coll->get_new_objs, "Get new objects" );
    isa_ok($get, $obj_class);
    is( $get->get_id, $obj->get_id, "Check for same ID." );
}

##############################################################################
# Test add_objs().
sub test_add_objs : Test(5) {
    my $self = shift;
    ok( my $coll = $self->construct, "Construct new collection" );
    my @objs = map { $obj_class->new({ id => $_}) } (1, 2, 3, 4);
    ok( $coll->add_objs(@objs), "Add objects" );
    ok( @objs = $coll->get_objs, "Get objects" );
    is( $#objs, 3, "Got four objects" );
    @objs = $coll->get_new_objs;
    is( scalar @objs, 0, "Got no objects from new_objs" );
}

##############################################################################
# Test add_new_objs().
sub test_add_new_objs : Test(6) {
    my $self = shift;
    ok( my $coll = $self->construct, "Construct new collection" );
    my @objs = map { $obj_class->new({ id => $_}) } (1, 2, 3, 4);
    ok( $coll->add_new_objs(@objs), "Add objects" );
    ok( @objs = $coll->get_objs, "Get objects" );
    is( $#objs, 3, "Got four objects" );
    ok( @objs = $coll->get_new_objs, "Get new objects" );
    is( $#objs, 3, "Got four objects from new_objs" );
}

##############################################################################
# Test del_objs().
sub test_del_objs : Test(13) {
    my $self = shift;
    ok( my $coll = $self->construct, "Construct new collection" );
    # Add a few objects
    my @addobjs = map { $obj_class->new({ id => $_}) } (1, 2, 3, 4);
    ok( $coll->add_objs(@addobjs), "Add objects" );
    ok( my @objs = $coll->get_objs, "Get objects" );
    is( $#objs, 3, "Got four objects" );
    # Now remove two of them.
    ok( $coll->del_objs(@addobjs[0..1]), "Delete first two objects" );
    ok( @objs = $coll->get_objs, "Get objects" );
    is( $#objs, 1, "Got two objects" );

    # Now see how it works when the collection hasn't been populated.
    ok( $coll = $self->construct, "Construct new collection" );
    ok( $coll->add_objs(@addobjs), "Add objects" );
    # Now remove two of them.
    ok( $coll->del_objs(@addobjs[0..1]), "Delete first two objects" );
    ok( ! $coll->is_populated, "Make sure it's not popluated." );
    # Now fetch them all to check the total number.
    ok( @objs = $coll->get_objs, "Get objects" );
    is( $#objs, 1, "Got two objects" );
}

##############################################################################
# Test is_populated().
sub test_is_populated : Test(18) {
    my $self = shift;
    ok( my $coll = $self->construct, "Construct new collection" );
    # No method except get_objs() should populate the collection.
    ok( ! $coll->is_populated, "Not populated one" );
    ok( my $obj = $coll->new_obj({}), "New object" );
    ok( ! $coll->is_populated, "Not populated two" );
    ok( $coll->add_objs($obj), "Add object" );
    ok( ! $coll->is_populated, "Not populated three" );
    ok( $coll->get_new_objs, "Get new objects" );
    ok( ! $coll->is_populated, "Not populated four" );
    ok( $coll->add_new_objs($obj), "Add new object" );
    ok( ! $coll->is_populated, "Not populated five" );
    ok( $coll->del_objs($obj), "Delete object" );
    ok( ! $coll->is_populated, "Not populated six" );
    ok( $coll->save, "Save collection" );
    ok( ! $coll->is_populated, "Not populated seven" );
    ok( $coll->get_objs, "Get objects" );
    ok( $coll->is_populated, "Now it's populated" );

    # Make sure that a new object constructed with no parameters is
    # considered populated.
    ok( $coll = $coll_class->new, "Construct coll without parameters" );
    ok( $coll->is_populated, "It's populated" );
}

##############################################################################
# Test save().
sub test_save : Test(4) {
    my $self = shift;
    ok( my $coll = $self->construct, "Construct new collection" );
    ok( $coll->save, "Save it" );
    # Make sure that the base class doesn't save.
    ok( $coll = $base_coll->new, "Construct base collection" );
    eval { $coll->save };
    isa_ok($@, 'Bric::Util::Fault::Exception::MNI');
}

##############################################################################
# Test private methods.
##############################################################################
# Test _sort_objs().
sub test_sort_objs : Test(14) {
    my $self = shift;
    # Start with the default sort method.
    ok( my $coll = $self->construct, "Construct new collection" );
    my @objs = map { $obj_class->new({ id => $_->[0], name => $_->[1]}) }
      ([1, 'one'], [2, 'two'], [3, 'three'], [4, 'four']);
    ok( $coll->add_objs(@objs), "Add objects" );
    # Check the sort order.
    ok( my @sorted = $coll->get_objs, "Get objects" );
    for my $i (0..3) {
        is($sorted[$i]->get_id, $objs[$i]->get_id,
           "Sorted $i is same as object $i" );
    }

    # Now try the subclass, where _sort_objs has been overridden.
    ok( $coll = Bric::Test::Coll::Fake::Sub->new,
        "Construct subclassed coll" );
    ok( $coll->add_objs(@objs), "Add objects" );
    # Check the sort order.
    ok( @sorted = $coll->get_objs, "Get objects" );
    is($sorted[0]->get_id, 4, "Four is first" );
    is($sorted[1]->get_id, 1, "One is second" );
    is($sorted[2]->get_id, 3, "Three is third" );
    is($sorted[3]->get_id, 2, "Two is fourth" );
}

##############################################################################
# Utility methods.
##############################################################################
sub construct { $coll_class->new({ foober => 1 }) }

1;

package Bric::Test::Coll::Fake;
use strict;
use base qw(Bric::Util::Coll);
sub class_name { 'Bric::Test::Coll::FakeClass' }
sub save { shift }

package Bric::Test::Coll::Fake::Sub;
use strict;
use base qw(Bric::Test::Coll::Fake);
sub _sort_objs {
    my ($pkg, $objs) = @_;
    return sort { lc $a->get_name cmp lc $b->get_name } values %$objs;
}

package Bric::Test::Coll::FakeClass;
use strict;
sub new { bless $_[1] }
sub get_id { $_[0]->{id} }
sub get_name { $_[0]->{name} }
sub href { {} }

1;
__END__

