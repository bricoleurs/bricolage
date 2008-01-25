package Bric::Biz::Asset::DevTest;
use strict;
use warnings;
use base qw(Bric::Test::DevBase);
use Test::More;
use Bric::Biz::Asset;

sub class { 'Bric::Biz::Asset' }

##############################################################################
# Constructs a new object.
sub construct {
    my $self = shift;
    $self->class->new({ $self->new_args, @_ });
}

##############################################################################
# Arguments to the new() constructor. Used by construct(). Override in
# subclasses.
sub new_args {
    die "Abstract method new_args() not overridden";
}

##############################################################################
# The element object we'll use throughout. Override in subclass if necessary.
my $elem;
sub get_elem {
    $elem ||= Bric::Biz::ElementType->lookup({ id => 1 });
    $elem;
}

##############################################################################
# Test class methods.
##############################################################################
# Test the class version of get_grp_ids.
sub test_grp_ids : Test(3) {
    my $self = shift;
    ok( my $class = $self->class, "Get class" );
    ok( my $key = $class->key_name, "Get key_name" );
    return "Abstract class" if $key eq 'asset' or $key eq 'biz';
    is_deeply( $class->get_grp_ids, $class->INSTANCE_GROUP_ID,
               "Check for instance group ID in $key class" );
}

###############################################################################
## Test basic asset persistence.
###############################################################################
sub test_persist : Test(10) {
    my $self = shift;
    ok( my $class = $self->class, "Get class" );
    ok( my $key = $class->key_name, "Get key_name" );
    return "Abstract class" if $key eq 'asset' or $key eq 'biz';
    ok( my $ass = $self->construct, "Construct new asset" );
    ok( $ass->save, "Save my ass" );

    # Save the ID for cleanup.
    ok( my $aid = $ass->get_id, "Get asset ID" );
    $self->add_del_ids([$aid], $key);

    # Update the asset.
    ok( $ass->set_name('Foo'), "set name" );
    ok( $ass->save, "Save my ass again" );

    # Look up the asset.
    ok( $ass = $class->lookup({ id => $aid}), "Lookup asset" );
    is( $ass->get_id, $aid, "Check asset ID" );
    is( $ass->get_name, 'Foo', "Check asset name" );
}

##############################################################################
# Test checkin and checkout.
sub test_checkout : Test(30) {
    my $self = shift;
    ok( my $class = $self->class, "Get class" );
    ok( my $key = $class->key_name, "Get key_name" );
    return "Abstract class" if $key eq 'asset' or $key eq 'biz';

    # Create one asset.
    ok( my $ass = $self->construct( note => 'Note 1.1'),
        "Construct new asset with note" );
    ok( $ass->save, "Save my ass" );
    $self->add_del_ids([$ass->get_id], $key);
    ok( $ass->checkin, "Checkin my ass" );
    ok( $ass->save, "Save my ass again" );
    ok( $ass->checkout({ user__id => $self->user_id }), "Checkout again" );
    ok( $ass->set_note('Note 1.2'), "Set version 2 note");
    ok( $ass->save, "Save my ass again" );
    ok( $ass->checkin, "Checkin my ass" );
    ok( $ass->save, "Save my ass again" );        # 1, 2 => 0, 0

    # Create another asset.
    ok( my $ass2 = $self->construct(
        name => 'two',
        note => 'Note 2.1',
    ), "Construct new asset" );
    ok( $ass2->save, "Save my ass" );
    $self->add_del_ids([$ass2->get_id], $key);
    ok( $ass2->checkin, "Checkin my ass" );
    ok( $ass2->save, "Save my ass again" );
    ok( $ass2->checkout({ user__id => $self->user_id }), "Checkout again" );
    ok( $ass2->set_note('Note 2.2'), "Set version 2 note");
    ok( $ass2->save, "Save my ass again" );       # 1, 2, => 0, 1
    ok( $ass2->checkin, "Checkin my ass" );
    ok( $ass2->save, "Save my ass again" );
    ok( $ass2->checkout({ user__id => $self->user_id }), "Checkout again" );
    ok( $ass2->save, "Save my ass again" );       # 1, 2, => 0, 1

    # Now make sure we can still look up the assets.
    ok $ass = $class->lookup({ id => $ass->get_id }), "Look up first asset";
    is $ass->get_id, $ass->get_id, "Compare IDs";
    ok $ass2 = $class->lookup({ id => $ass2->get_id }), "Look up second asset";
    is $ass2->get_id, $ass2->get_id, "Compare IDs";

    # Compare notes.
    is $ass->get_note, 'Note 1.2', 'Check first note';
    is_deeply $ass->get_notes, {
        1 => 'Note 1.1',
        2 => 'Note 1.2',
    }, 'Check first note href';
    is $ass2->get_note, undef, 'The note for a newly-checked out document should be undefined';
    is_deeply $ass2->get_notes, {
        1 => 'Note 2.1',
        2 => 'Note 2.2',
    }, 'Check second note href';
}

###############################################################################
## Clean up our mess.
###############################################################################
sub del_ids : Test(teardown => 0) {
    my $self = shift;

    # Get the list to ids to delete.
    my $to_delete = $self->get_del_ids;# or return;

    # Do the main objects, first.
    $self->SUPER::del_ids(@_);

    # Now delete them from the instance table.
    my $key = $self->class->key_name;
    my $ids = $to_delete->{$key} or return;
    $ids = join ', ', @$ids;
    Bric::Util::DBI::prepare(qq{
        DELETE FROM ${key}_instance
        WHERE  ${key}__id in ($ids)
    })->execute;
}

1;
__END__
