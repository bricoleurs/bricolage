<%doc>
###############################################################################

=head1 NAME

/widgets/profile/workflow.mc - Processes submits from Workflow Profile

=head1 VERSION

$Revision: 1.1 $

=head1 DATE

$Date: 2001-09-06 21:52:22 $

=head1 SYNOPSIS

  $m->comp('/widgets/profile/workflow.mc', %ARGS);

=head1 DESCRIPTION

This element is called by /widgets/profile/callback.mc when the data to be
processed was submitted from the Workflow Profile page.

=head1 REVISION HISTORY

$Log: workflow.mc,v $
Revision 1.1  2001-09-06 21:52:22  wheeler
Initial revision

</%doc>
<%once>;
my $type = 'workflow';
my $disp_name = get_disp_name($type);
my $class = get_package_name($type);
</%once>
<%args>
$widget
$param
$field
$obj
</%args>
<%init>;
return unless $field eq "$widget|save_cb";
# Instantiate the workflow object and grab its name.
my $name = "&quot;$param->{name}&quot;";

my $wf = $obj;
if ($param->{delete}) {
    # Deactivate it.
    $wf->deactivate;
    $wf->save;
    $c->set('__WORKFLOWS__', 0);
    log_event("${type}_deact", $wf);
    set_redirect('/admin/manager/workflow');
    add_msg("$disp_name profile $name deleted.");
} else {
    my $wf_id = $param->{"${type}_id"};
    # Make sure the name isn't already in use.
    my $used;
    my @wfs = $class->list_ids({ name => $param->{name} });
    if (@wfs > 1) { $used = 1 }
    elsif (@wfs == 1 && !defined $wf_id) { $used = 1 }
    elsif (@wfs == 1 && defined $wf_id
	   && $wfs[0] != $wf_id) { $used = 1 }
    add_msg("The name $name is already used by another $disp_name.") if $used;

    # Roll in the changes.
    $wf->set_name($param->{name}) unless $used;
    $wf->set_description($param->{description});
    $wf->set_type($param->{type}) if exists $param->{type};
    if (! defined $param->{workflow_id}) {
	# It's a new workflow. Set the start desk.
	if ($param->{new_desk_name}) {
	    # They're creating a brand new desk.
	    my $d = (Bric::Biz::Workflow::Parts::Desk->list({ name => $param->{new_desk_name} }))[0]
	      || Bric::Biz::Workflow::Parts::Desk->new;
	    $d->set_name($param->{new_desk_name});
	    $d->save;
	    my $did = $d->get_id;
	    $wf->add_desk({ allowed => [$did] });
	    $wf->set_start_desk($did);
	} else {
	    # Set the start desk from the menu choice.
	    $wf->set_start_desk($param->{first_desk});
	    $param->{new_desk_name} =
	      Bric::Biz::Workflow::Parts::Desk->lookup({ id => $param->{first_desk} })->get_name;
	}
	unless ($used) {
	    $wf->save;
	    $c->set('__WORKFLOWS__', 0);
	    log_event("${type}_add_desk", $wf, { Desk => $param->{new_desk_name} });
	    log_event($type . '_new', $wf);
	}
	return $wf;
    } else {
	# It's an existing desk. Check to see if we're removing any desks.
        if ($param->{remove_desk}) {
	    # Dissocidate any desks, as necessary.
	    my %desks = map { $_->get_id => $_ } $wf->allowed_desks;
	    my $rem_desks = mk_aref($param->{remove_desk});
	    foreach my $did (@$rem_desks) {
	        my $d = delete $desks{$did};
		# Check if we're going to need to set a different desk to be start desk.
		$param->{start} = -1 if $did == $param->{start};
		log_event("${type}_del_desk", $wf, { Desk => $d->get_name });
	    }
	    # Now remove them from the workflow.
	    $wf->del_desk($rem_desks);
	    # Set the start desk ID if it needs to change.
	    $param->{start} = (keys %desks)[0] if $param->{start} == -1;
 	}

	# Set the start desk.
	$wf->set_start_desk($param->{start});

	# Save changes and redirect back to the manager.
	if ($used) {
	    return $wf;
	} else {
	    $wf->save;
	    $c->set('__WORKFLOWS__', 0);
	    add_msg("$disp_name profile $name saved.");
	    log_event($type . '_save', $wf);
	    set_redirect('/admin/manager/workflow');
	}
    }
}
</%init>
