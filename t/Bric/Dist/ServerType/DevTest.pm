package Bric::Dist::ServerType::DevTest;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;
use Bric::Dist::ServerType;

# Register this class for testing.
BEGIN { __PACKAGE__->test_class }

##############################################################################
# Test output channel association.
##############################################################################
sub test_output_channels : Test(18) {
    my $self = shift;
    ok( my $st = Bric::Dist::ServerType->new({ name => 'MyServerMan',
                                               move_method => 'FTP'}),
        "Create new ST" );
    my @ocs = $st->get_output_channels;
    is( scalar @ocs, 0, "No OCs" );

    # Create a new output channel.
    ok( my $oc = Bric::Biz::OutputChannel->new({ name => 'OC Senior' }),
        "Create new OC" );
    ok( $oc->save, "Save new OC" );
    ok( my $ocid = $oc->get_id, "Get OC ID" );
    push @{ $self->{ocids} }, $ocid;

    # Add the new output channel to the server type.
    ok( $st->add_output_channels($oc), "Add OC" );
    ok( @ocs = $st->get_output_channels, "Get OCs" );
    is( scalar @ocs, 1, "Check for 1 OC" );
    is( $ocs[0]->get_name, 'OC Senior', "Check OC name" );

    # Save it and verify again.
    ok( $st->save, "Save ST" );
    ok( my $stid = $st->get_id, "Get ST ID" );
    push @{ $self->{stids} }, $stid;
    ok( @ocs = $st->get_output_channels, "Get OCs again" );
    is( scalar @ocs, 1, "Check for 1 OC again" );
    is( $ocs[0]->get_name, 'OC Senior', "Check OC name again" );

    # Look up the ST in the database and check OCs again.
    ok( $st = Bric::Dist::ServerType->lookup({ id => $stid }), "Lookup ST" );
    ok( @ocs = $st->get_output_channels, "Get OCs 3" );
    is( scalar @ocs, 1, "Check for 1 OC 3" );
    is( $ocs[0]->get_name, 'OC Senior', "Check OC name 3" );
}

##############################################################################
# Clean up our mess.
##############################################################################
sub cleanup : Test(teardown => 0) {
    my $self = shift;

    # Clean up output channels.
    if (my $ocids = $self->{ocids}) {
        $ocids = join ', ', @$ocids;
        Bric::Util::DBI::prepare(qq{
            DELETE FROM output_channel
            WHERE  id in ($ocids)
        })->execute;
    }

    # Clean up server types.
    if (my $stids = $self->{stids}) {
        $stids = join ', ', @$stids;
        Bric::Util::DBI::prepare(qq{
            DELETE FROM server_type
            WHERE  id in ($stids)
        })->execute;
    }
}

1;
__END__
