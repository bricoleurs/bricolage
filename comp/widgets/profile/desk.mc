<%doc>
###############################################################################

=head1 NAME

/widgets/profile/desk.mc - Processes submits from Desk Profile

=head1 VERSION

$Revision: 1.10 $

=head1 DATE

$Date: 2003-07-18 23:45:14 $

=head1 SYNOPSIS

  $m->comp('/widgets/profile/desk.mc', %ARGS);

=head1 DESCRIPTION

This element is called by /widgets/profile/callback.mc when the data to be
processed was submitted from the Desk Profile page.

=cut

</%doc>
<%once>;
my $type = 'desk';
my $wf_type = 'workflow';
my $disp_name = get_disp_name($type);
my $class = get_package_name($type);
my $wf_disp_name = get_disp_name($wf_type);
# We'll use this function to expire the cache for workflows that this desk
# appears in.
my $expire_wf_cache = sub {
    my $did = shift;
    # Expire the cache for all workflows that contain this desk.
    foreach my $wf (Bric::Biz::Workflow->list({ desk_id => $did })) {
        $c->set('__WORKFLOWS__' . $wf->get_site_id, 0);
    }
};
</%once>
<%args>
$widget
$param
$field
$obj
</%args>
<%init>;
return unless $field eq "$widget|save_cb";
# Grab the element type object and its name.
my $desk = $obj;
my $name = "&quot;$param->{name}&quot;" if $param->{name};
if ($param->{delete}) {
    # Deactivate it.
    $desk->deactivate;
    $desk->save;
    $expire_wf_cache->($param->{"${type}_id"});
    log_event("${type}_deact", $desk);
    add_msg($lang->maketext("$disp_name profile [_1] deleted from all workflows.",$name));
    set_redirect(defined $param->{workflow_id} ?
		 "/admin/profile/workflow/$param->{workflow_id}"
		 : last_page());
} else {
    my $desk_id = $param->{"${type}_id"};
    # Make sure the name isn't already in use.
    my $used;
    if ($param->{name}) {
	my @desks = $class->list_ids({ name => $param->{name} });
	if (@desks > 1) { $used = 1 }
	elsif (@desks == 1 && !defined $desk_id) { $used = 1 }
	elsif (@desks == 1 && defined $desk_id
	       && $desks[0] != $desk_id) { $used = 1 }
        add_msg($lang->maketext("The name [_1] is already used by another [_2].",
                                $name, $disp_name)) if $used;
    }

    # Roll in the changes.
    $desk->set_name($param->{name}) if exists $param->{name} && !$used;
    $desk->set_description($param->{description}) if exists $param->{description};
    if (exists $param->{name} && exists $param->{publish}) {
        $desk->make_publish_desk;
    } else {
        $desk->make_regular_desk;
    }
    unless ($used) {
	$desk->save;
        $expire_wf_cache->($desk_id);
	log_event($type . (defined $param->{desk_id} ? '_save' : '_new'), $desk);
    } else {
	$param->{new_desk} = 1;
	return $desk;
    }
    if (defined $param->{workflow_id}) {
	# It's a new desk for this profile. Add it.
	my $wf = Bric::Biz::Workflow->lookup({ id => $param->{workflow_id} });
	$wf->add_desk({ allowed => [$desk->get_id] });
	$wf->save;
        $expire_wf_cache->($desk_id);
	log_event('workflow_add_desk', $wf, { Desk => $desk->get_name });
	set_redirect("/admin/profile/workflow/$param->{workflow_id}");
    } else {
	set_redirect(last_page());
    }
}
</%init>
