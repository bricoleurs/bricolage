package Bric::Dist::ServerType::DevTest;
use strict;
use warnings;
use base qw(Bric::Test::DevBase);
use Test::More;
use Bric::Dist::ServerType;
use Bric::Dist::Job;
use Bric::Util::Grp::Dest;

sub table {'server_type '}

my $web_oc_id = 1;

my %dest = ( name        => 'Bogus',
             description => 'Bogus ServerType',
             site_id     => 100,
             move_method => 'File System'
           );

##############################################################################
# Test constructors.
##############################################################################
# Test the lookup() method.
sub test_lookup : Test(9) {
    my $self = shift;
    my %args = %dest;
    ok( my $dest = Bric::Dist::ServerType->new(\%args),
        "Create destination" );
    ok( $dest->save, "Save the destination" );
    ok( my $did = $dest->get_id, "Get the destination ID" );
    $self->add_del_ids($did);
    ok( $dest = Bric::Dist::ServerType->lookup({ id => $did }),
        "Look up the new destination" );
    is( $dest->get_id, $did, "Check that the ID is the same" );
    # Check a few attributes.
    ok( $dest->is_active, "Check that it's activated" );
    ok( $dest->can_publish, "Check can publish" );
    ok( !$dest->can_preview, "Check can't preview" );
    ok( !$dest->can_copy, "Check can't copy" );
}

##############################################################################
# Test the list() method.
sub test_list : Test(45) {
    my $self = shift;

    # Create a new destination group.
    ok( my $grp = Bric::Util::Grp::Dest->new({ name => 'Test DestGrp' }),
        "Create group" );

    # Create a new distribution job.
    ok( my $job = Bric::Dist::Job->new({ name => 'Test Job',
                                         user_id => $self->user_id }),
        "Create job" );

    # Create some test records.
    for my $n (1..5) {
        my %args = %dest;
        # Make sure the name is unique.
        $args{name} .= $n;
        $args{description} .= $n if $n % 2;
        ok( my $dest = Bric::Dist::ServerType->new(\%args),
            "Create $args{name}" );
        if ($n % 2) {
            $dest->copy;
            $dest->on_publish;
            $dest->no_preview;
            $job->add_server_types($dest);
        } else {
            $dest->no_publish;
            $dest->on_preview;
        }
        ok( $dest->save, "Save $args{name}" );
        # Save the ID for deleting.
        $self->add_del_ids($dest->get_id);
        $grp->add_member({ obj => $dest }) if $n % 2;
    }

    # Save the group.
    ok( $grp->save, "Save group" );
    ok( my $grp_id = $grp->get_id, "Get group ID" );
    $self->add_del_ids($grp_id, 'grp');

    # Save the job.
    ok( $job->save, "Save job" );
    ok( my $job_id = $job->get_id, "Get job ID" );
    $self->add_del_ids($job_id, 'job');

    # Try name + wildcard.
    ok( my @dests = Bric::Dist::ServerType->list({ name => "$dest{name}%" }),
        "Look up name $dest{name}%" );
    is( scalar @dests, 5, "Check for 5 destinations" );

    # Try description.
    ok( @dests = Bric::Dist::ServerType->list
        ({ description => "$dest{description}" }),
        "Look up description '$dest{description}'" );
    is( scalar @dests, 2, "Check for 2 destinations" );

    # Try grp_id.
    ok( @dests = Bric::Dist::ServerType->list({ grp_id => $grp_id }),
        "Look up grp_id '$grp_id'" );
    is( scalar @dests, 3, "Check for 3 destinations" );

    # Make sure we've got all the Group IDs we think we should have.
    my $all_grp_id = Bric::Dist::ServerType::INSTANCE_GROUP_ID;
    foreach my $dest (@dests) {
        my %grp_ids = map { $_ => 1 } $dest->get_grp_ids;
        ok( $grp_ids{$all_grp_id} && $grp_ids{$grp_id},
          "Check for both IDs" );
    }

    # Try deactivating one group membership.
    ok( my $mem = $grp->has_member({ obj => $dests[0] }), "Get member" );
    ok( $mem->deactivate->save, "Deactivate and save member" );

    # Now there should only be two using grp_id.
    ok( @dests = Bric::Dist::ServerType->list({ grp_id => $grp_id }),
        "Look up grp_id '$grp_id' again" );
    is( scalar @dests, 2, "Check for 2 destinations" );

    # Try site_id.
    ok( @dests = Bric::Dist::ServerType->list({ site_id => $dest{site_id} }),
        "Look up site_id '$dest{site_id}'" );
    is( scalar @dests, 5, "Check for 5 destinations" );

    # Try a bogus site_id.
    @dests = Bric::Dist::ServerType->list({ site_id => -1 });
    is( scalar @dests, 0, "Check for 0 destinations" );

    # Try move_method.
    ok( @dests = Bric::Dist::ServerType->list
        ({ move_method => $dest{move_method} }),
        "Look up move_method '$dest{move_method}'" );
    is( scalar @dests, 5, "Check for 5 destinations" );

    # Try output_channel_id.
    @dests = Bric::Dist::ServerType->list
      ({ output_channel_id => $web_oc_id });
    # Only the two defaults.
    is( scalar @dests, 0, "Check for 2 destinations" );

    # Try can_copy.
    ok( @dests = Bric::Dist::ServerType->list({ can_copy => 1 }),
        "Look up can_copy => 1" );
    is( scalar @dests, 3, "Check for 3 destinations" );

    # Try can_publish.
    ok( @dests = Bric::Dist::ServerType->list({ can_publish => 1 }),
        "Look up can_publish => 1" );
    is( scalar @dests, 3, "Check for 3 destinations" );

    # Try can_preview.
    ok( @dests = Bric::Dist::ServerType->list({ can_preview => 1 }),
        "Look up can_preview => 1" );
    is( scalar @dests, 2, "Check for 2 destinations" );

    # Try active.
    ok( @dests = Bric::Dist::ServerType->list({ active => 1 }),
        "Look up active => 1" );
    is( scalar @dests, 5, "Check for 5 destinations" );

    # Try job_id.
    ok( @dests = Bric::Dist::ServerType->list({ job_id => $job_id }),
        "Look up job_id '$job_id'" );
    is( scalar @dests, 3, "Check for 3 destinations" );
}

##############################################################################
# Test the href() method.
sub test_href : Test(25) {
    my $self = shift;

    # Create a new destination group.
    ok( my $grp = Bric::Util::Grp::Dest->new({ name => 'Test DestGrp' }),
        "Create group" );

    # Create some test records.
    for my $n (1..5) {
        my %args = %dest;
        # Make sure the name is unique.
        $args{name} .= $n;
        $args{description} .= $n if $n % 2;
        ok( my $dest = Bric::Dist::ServerType->new(\%args),
            "Create $args{name}" );
        ok( $dest->save, "Save $args{name}" );
        # Save the ID for deleting.
        $self->add_del_ids($dest->get_id);
        $grp->add_member({ obj => $dest }) if $n % 2;
    }

    ok( $grp->save, "Save group" );
    ok( my $grp_id = $grp->get_id, "Get group ID" );
    $self->add_del_ids($grp_id, 'grp');

    # Try name + wildcard.
    ok( my $dests = Bric::Dist::ServerType->href({ name => "$dest{name}%" }),
        "Look up name $dest{name}%" );
    is( scalar keys %$dests, 5, "Check for 5 destinations" );

    # Try description.
    ok( $dests = Bric::Dist::ServerType->href
        ({ description => "$dest{description}" }),
        "Look up description '$dest{description}'" );
    is( scalar keys %$dests, 2, "Check for 2 destinations" );

    # Try site_id.
    ok( $dests = Bric::Dist::ServerType->href({ site_id => $dest{site_id} }),
        "Look up site_id '$dest{site_id}'" );
    is( scalar keys %$dests, 5, "Check for 5 destinations" );

    # Try a bogus site_id.
    $dests = Bric::Dist::ServerType->href({ site_id => -1 });
    is( scalar keys %$dests, 0, "Check for 0 destinations" );

    # Try grp_id.
    ok( $dests = Bric::Dist::ServerType->href({ grp_id => $grp_id }),
        "Look up grp_id $grp_id" );
    is( scalar keys %$dests, 3, "Check for 3 destinations" );

    # Make sure we've got all the Group IDs we think we should have.
    my $all_grp_id = Bric::Dist::ServerType::INSTANCE_GROUP_ID;
    foreach my $dest (values %$dests) {
        my %grp_ids = map { $_ => 1 } $dest->get_grp_ids;
        ok( $grp_ids{$all_grp_id} && $grp_ids{$grp_id},
          "Check for both IDs" );
    }
}

##############################################################################
# Test class methods.
##############################################################################
# Test the list_ids() method.
sub test_list_ids : Test(38) {
    my $self = shift;

    # Create a new destination group.
    ok( my $grp = Bric::Util::Grp::Dest->new({ name => 'Test DestGrp' }),
        "Create group" );

    # Create a new distribution job.
    ok( my $job = Bric::Dist::Job->new({ name => 'Test Job',
                                         user_id => 0 }),
        "Create job" );

    # Create some test records.
    for my $n (1..5) {
        my %args = %dest;
        # Make sure the name is unique.
        $args{name} .= $n;
        $args{description} .= $n if $n % 2;
        ok( my $dest = Bric::Dist::ServerType->new(\%args),
            "Create $args{name}" );
        if ($n % 2) {
            $dest->copy;
            $dest->on_publish;
            $dest->no_preview;
            $job->add_server_types($dest);
        } else {
            $dest->no_publish;
            $dest->on_preview;
        }
        ok( $dest->save, "Save $args{name}" );
        # Save the ID for deleting.
        $self->add_del_ids($dest->get_id);
        $grp->add_member({ obj => $dest }) if $n % 2;
    }

    # Save the group.
    ok( $grp->save, "Save group" );
    ok( my $grp_id = $grp->get_id, "Get group ID" );
    $self->add_del_ids($grp_id, 'grp');

    # Save the job.
    ok( $job->save, "Save job" );
    ok( my $job_id = $job->get_id, "Get job ID" );
    $self->add_del_ids($job_id, 'job');

    # Try name + wildcard.
    ok( my @dest_ids = Bric::Dist::ServerType->list_ids
        ({ name => "$dest{name}%" }),
        "Look up name $dest{name}%" );
    is( scalar @dest_ids, 5, "Check for 5 destination IDs" );

    # Try description.
    ok( @dest_ids = Bric::Dist::ServerType->list_ids
        ({ description => "$dest{description}" }),
        "Look up description '$dest{description}'" );
    is( scalar @dest_ids, 2, "Check for 2 destination IDs" );

    # Try site_id.
    ok( @dest_ids = Bric::Dist::ServerType->list_ids
        ({ site_id => $dest{site_id} }),
        "Look up site_id '$dest{site_id}'" );
    is( scalar @dest_ids, 5, "Check for 5 destinations" );

    # Try a bogus site_id.
    @dest_ids = Bric::Dist::ServerType->list_ids({ site_id => -1 });
    is( scalar @dest_ids, 0, "Check for 0 destinations" );

    # Try grp_id.
    ok( @dest_ids = Bric::Dist::ServerType->list_ids({ grp_id => $grp_id }),
        "Look up grp_id $grp_id" );
    is( scalar @dest_ids, 3, "Check for 3 destination IDs" );

    # Try move_method.
    ok( @dest_ids = Bric::Dist::ServerType->list_ids
        ({ move_method => $dest{move_method} }),
        "Look up move_method '$dest{move_method}'" );
    # There'll be an extra because of the default preview destination.
    is( scalar @dest_ids, 5, "Check for 5 destination IDs" );

    # Try output_channel_id.
    @dest_ids = Bric::Dist::ServerType->list_ids
      ({ output_channel_id => $web_oc_id });
    # We didn't assign any output channels!
    is( scalar @dest_ids, 0, "Check for 0 destination IDs" );

    # Try can_copy.
    ok( @dest_ids = Bric::Dist::ServerType->list_ids({ can_copy => 1 }),
        "Look up can_copy => 1" );
    is( scalar @dest_ids, 3, "Check for 3 destination IDs" );

    # Try can_publish.
    ok( @dest_ids = Bric::Dist::ServerType->list_ids({ can_publish => 1 }),
        "Look up can_publish => 1" );
    is( scalar @dest_ids, 3, "Check for 3 destination IDs" );

    # Try can_preview.
    ok( @dest_ids = Bric::Dist::ServerType->list_ids({ can_preview => 1 }),
        "Look up can_preview => 1" );
    is( scalar @dest_ids, 2, "Check for 2 destination IDs" );

    # Try active.
    ok( @dest_ids = Bric::Dist::ServerType->list_ids({ active => 1 }),
        "Look up active => 1" );
    is( scalar @dest_ids, 5, "Check for 5 destination IDs" );

    # Try job_id.
    ok( @dest_ids = Bric::Dist::ServerType->list_ids({ job_id => $job_id }),
        "Look up job_id '$job_id'" );
    is( scalar @dest_ids, 3, "Check for 3 destination IDs" );
}

##############################################################################
# Test my_meths().
sub test_my_meths : Test(11) {
    ok( my $meths = Bric::Dist::ServerType->my_meths, "Get my_meths" );
    isa_ok($meths, 'HASH', "my_meths is a hash" );
    is( $meths->{name}{type}, 'short', "Check name type" );
    ok( $meths = Bric::Dist::ServerType->my_meths(1), "Get my_meths array ref" );
    isa_ok( $meths, 'ARRAY', "my_meths(1) is an array" );
    (is $meths->[0]->{name}, 'name', "Check first meth name" );

    # Try the identifier methods.
    ok( my $st = Bric::Dist::ServerType->new({ name => 'NewFoo' }),
        "Create destination" );
    ok( my @meths = $st->my_meths(0, 1), "Get ident meths" );
    is( scalar @meths, 1, "Check for 1 meth" );
    is( $meths[0]->{name}, 'name', "Check for 'name' meth" );
    is( $meths[0]->{get_meth}->($st), 'NewFoo', "Check name 'NewFoo'" );
}

##############################################################################
# Test output channel association.
##############################################################################
sub test_output_channels : Test(18) {
    my $self = shift;
    ok( my $dest = Bric::Dist::ServerType->new({name        => 'MyServerMan',
                                                move_method => 'FTP',
                                                site_id     => 100}),
        "Create new ST" );
    my @ocs = $dest->get_output_channels;
    is( scalar @ocs, 0, "No OCs" );

    # Create a new output channel.
    ok( my $oc = Bric::Biz::OutputChannel->new({name    => 'OC Senior',
                                                site_id => 100}),
        "Create new OC" );
    ok( $oc->save, "Save new OC" );
    ok( my $ocid = $oc->get_id, "Get OC ID" );
    $self->add_del_ids([$ocid], 'output_channel');

    # Add the new output channel to the server type.
    ok( $dest->add_output_channels($oc), "Add OC" );
    ok( @ocs = $dest->get_output_channels, "Get OCs" );
    is( scalar @ocs, 1, "Check for 1 OC" );
    is( $ocs[0]->get_name, 'OC Senior', "Check OC name" );

    # Save it and verify again.
    ok( $dest->save, "Save ST" );
    ok( my $destid = $dest->get_id, "Get ST ID" );
    $self->add_del_ids([$destid]);
    ok( @ocs = $dest->get_output_channels, "Get OCs again" );
    is( scalar @ocs, 1, "Check for 1 OC again" );
    is( $ocs[0]->get_name, 'OC Senior', "Check OC name again" );

    # Look up the ST in the database and check OCs again.
    ok( $dest = Bric::Dist::ServerType->lookup({ id => $destid }), "Lookup ST" );
    ok( @ocs = $dest->get_output_channels, "Get OCs 3" );
    is( scalar @ocs, 1, "Check for 1 OC 3" );
    is( $ocs[0]->get_name, 'OC Senior', "Check OC name 3" );
}

##############################################################################
# Test instance methods.
##############################################################################
# Test save()
sub test_save : Test(9) {
    my $self = shift;
    my %args = %dest;
    ok( my $dest = Bric::Dist::ServerType->new(\%args),
        "Create destination" );
    ok( $dest->save, "Save the destination" );
    ok( my $did = $dest->get_id, "Get the destination ID" );
    $self->add_del_ids($did);
    ok( $dest = Bric::Dist::ServerType->lookup({ id => $did }),
        "Look up the new destination" );
    ok( my $old_name = $dest->get_name, "Get its name" );
    my $new_name = $old_name . ' Foo';
    ok( $dest->set_name($new_name), "Set its name to '$new_name'" );
    ok( $dest->save, "Save it" );
    ok( Bric::Dist::ServerType->lookup({ id => $did }),
        "Look it up again" );
    is( $dest->get_name, $new_name, "Check name is '$new_name'" );
}

1;
__END__
