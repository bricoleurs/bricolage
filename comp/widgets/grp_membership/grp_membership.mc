<%doc>

=head1 NAME

grp_membership - Group membership widget

=head1 VERSION

$LastChangedRevision$

=head1 DATE

$LastChangedDate$

=head1 SYNOPSIS

<& '/widgets/grp_membership/grp_membership.mc', 
   grp_class => 'Bric::Util::Grp', 
   obj => $obj, 
   formName => 'obj_profile', 
   all => 0
&>

=head1 DESCRIPTION

Generic widget for handling Group membership inside each profile.

=cut

</%doc>
<%args>
$grp_class
$obj
$no_edit
$formName
$widget
$extra_code => undef
$all        => 0
$num        => 0
$no_cb      => 0
</%args>
<%perl>
# Get the groups listed.
$m->comp("/widgets/wrappers/table_top.mc",
         caption => 'Group Memberships',
         number  => $num);

$m->comp('/widgets/profile/hidden.mc',
         name => "$widget|manage_grps_cb",
         value => 1) unless $no_cb;
$m->print("\n");

##############################################################################
# Get groups for double-list manager.
my ($left, $right) = ([], []);
my @rogroups = ($obj->INSTANCE_GROUP_ID);
my @logroups;

unless (defined $obj->get_id) {
    # Make sure the "All" group shows up in the list for new objects.
    my $all_grp = Bric::Util::Grp->lookup({ id => $obj->INSTANCE_GROUP_ID});
    push @$right, { value       => $all_grp->get_id,
                    description => $all_grp->get_name };
}

my $is_user = ref $obj eq 'Bric::Biz::Person::User';

# Now get the list of current groups the group is a member of.
foreach my $grp ( $obj->can('get_grps')
                  ? $obj->get_grps
                  : defined $obj->get_id
                    ? $grp_class->list({ obj => $obj })
                  : ()) {
    # Skip the group if they don't have READ access to it.
    next unless chk_authz($grp, READ, 1);
    my $gid = $grp->get_id;
    push @$right, { value       => $gid,
                    description => $grp->get_name };

    # Dissallow removing groups if the user doesn't have edit permission
    # to the group, or if the user doesn't have edit permission to the
    # members of the group.
    unless ($no_edit or chk_authz($grp, EDIT, 1)
            or (!$is_user && chk_authz(0, EDIT, 1, $gid))) {
        push @rogroups, $gid;
    }
}

# Get all groups for double-list manager.
foreach my $grp ( $grp_class->list({all => $all}) ) {
    # Skip the group if they don't have READ access to it.
    next unless chk_authz($grp, READ, 1);

    my $gid = $grp->get_id;
    push @$left, { value       => $gid,
                   description => $grp->get_name };

    # Dissallow adding groups if the group is a user group (users can
    # only edit user group memberships if they're members) or if
    # they don't have permission to edit the group and its members.
    unless ($no_edit or !$is_user
            or (chk_authz($grp, EDIT, 1) and chk_authz(0, EDIT, 1, $gid))) {
        push @logroups, $gid;
    }
}

# Load up the double-list manager.
$m->comp( "/widgets/doubleListManager/doubleListManager.mc",
          rightSort     => 1,
          leftOpts      => $left,
          rightOpts     => $right,
          formName      => $formName,
          leftName      => 'rem_grp',
          rightName     => 'add_grp',
          readOnlyRight => \@rogroups,
          readOnlyLeft  => \@logroups,
          leftCaption   => 'Available Groups',
          showLeftList  => !$no_edit,
	  rightCaption  => $no_edit ? '' : 'Current Groups',
          readOnly      => $no_edit
        );

$m->out($extra_code);

$m->comp("/widgets/wrappers/table_bottom.mc");
</%perl>
