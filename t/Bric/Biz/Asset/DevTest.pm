package Bric::Biz::Asset::DevTest;
use strict;
use warnings;
use base qw(Bric::Test::Base);
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
    $elem ||= Bric::Biz::AssetType->lookup({ id => 1 });
    $elem;
}

##############################################################################
# Test basic asset persistence.
##############################################################################
sub test_persist : Test(10) {
    my $self = shift;
    ok( my $class = $self->class, "Get class" );
    ok( my $key = $class->key_name, "Get key_name" );
    return "Abstract class" if $key eq 'asset' or $key eq 'biz';
    ok( my $ass = $self->construct, "Construct new asset" );
    ok( $ass->save, "Save my ass" );

    # Save the ID for cleanup.
    ok( my $aid = $ass->get_id, "Get asset ID" );
    push @{$self->{$key}}, $aid;

    # Update the asset.
    ok( $ass->set_name('Foo'), "set name" );
    ok( $ass->save, "Save my ass again" );

    # Look up the asset.
    ok( $ass = $class->lookup({ id => $aid}), "Lookup asset" );
    is( $ass->get_id, $aid, "Check asset ID" );
    is( $ass->get_name, 'Foo', "Check asset name" );
}

##############################################################################
# Clean up our mess.
##############################################################################
sub cleanup : Test(teardown => 0) {
    my $self = shift;

    # Clean up assets.
    my $key = $self->class->key_name;
    if (my $baids = delete $self->{$key}) {
        $baids = join ', ', @$baids;
        # Delete from the asset table...
        Bric::Util::DBI::prepare(qq{
            DELETE FROM $key
            WHERE  id in ($baids)
        })->execute;

        # ...and from the instance table.
        Bric::Util::DBI::prepare(qq{
            DELETE FROM ${key}_instance
            WHERE  ${key}__id in ($baids)
        })->execute;
    }
}



1;
__END__
