<%doc>

=head1 NAME

grp_membership - Group membership widget

=head1 VERSION

$Revision: 1.1 $

=head1 DATE

$Date: 2003-08-25 18:48:53 $

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
$m->comp("/widgets/wrappers/sharky/table_top.mc",
         caption => 'Group Memberships',
         number  => $num);

$m->comp('/widgets/profile/hidden.mc',
         name => "$widget|manage_grps_cb",
         value => 1) unless $no_cb;

##############################################################################
# Get groups for double-list manager.
my $all_grp = Bric::Util::Grp->lookup({ id => $obj->INSTANCE_GROUP_ID});
my ($left, $right) = ([], []);

push @$right, { value       => $all_grp->get_id,
                description => $all_grp->get_name}
  unless $obj->get_id;

foreach my $grp ( $grp_class->list({ obj => $obj }) ) {
    push @$right, { value       => $grp->get_id,
                    description => $grp->get_name };
}

# Get all groups for double-list manager.
foreach my $grp ( $grp_class->list({all => $all}) ) {
    push @$left, { value       => $grp->get_id,
                   description => $grp->get_name };
}

# Load up the double-list manager.
$m->comp( "/widgets/doubleListManager/doubleListManager.mc",
          rightSort     => 1,
          leftOpts      => $left,
          rightOpts     => $right,
          formName      => $formName,
          leftName      => 'rem_grp',
          rightName     => 'add_grp',
          readOnlyRight => [$obj->INSTANCE_GROUP_ID],
          leftCaption   => 'Available Groups',
          showLeftList  => $no_edit || 1 ,
          rightCaption  => $no_edit ||'Current Groups',
          readOnly      => $no_edit
        );

$m->out($extra_code);

$m->comp("/widgets/wrappers/sharky/table_bottom.mc");
</%perl>
