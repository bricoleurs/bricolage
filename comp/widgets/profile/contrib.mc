<%once>;
my $type = 'contrib';
my $disp_name = get_disp_name($type);
</%once>
<%args>
$widget
$param
$field
$obj
</%args>

<%init>;
# make sure we have some business being here...
return unless $field eq "$widget|save_cb";

# Instantiate the grp or person object.
my $contrib = $obj;

if ($param->{delete}) {
    # Deactivate it.
    $contrib->deactivate;
    $contrib->save;
    log_event("${type}_deact", $contrib);
    my $name = "&quot;" . $contrib->get_name . "&quot;";
    add_msg($lang->maketext("$disp_name profile [_1] deleted.",$name));
    set_redirect('/admin/manager/contrib');
    return;
} else {# Roll in the changes.

    # update name elements
    my $meths = $contrib->my_meths;
    $meths->{fname}{set_meth}->($contrib, $param->{fname});
    $meths->{lname}{set_meth}->($contrib, $param->{lname});
    $meths->{mname}{set_meth}->($contrib, $param->{mname});
    $meths->{prefix}{set_meth}->($contrib, $param->{prefix});
    $meths->{suffix}{set_meth}->($contrib, $param->{suffix});
    my $name = "&quot;" . $contrib->get_name . "&quot;";

    if ($param->{mode} eq 'new') {

	# add person object to the selected group
	my $group = Bric::Util::Grp::Person->lookup( { id => $param->{group} } );
	$contrib->save;
	my $member = $group->add_member( { obj => $contrib } );
	$group->save;
	@{$param}{qw(mode contrib_id)} = ('edit', $member->get_id);
	$member = Bric::Util::Grp::Parts::Member::Contrib->lookup(
          { id => $param->{contrib_id} } );

	# Log that we've created a new contributor.
	log_event("${type}_new", $member);
	set_redirect('/admin/profile/contrib/edit/' . $param->{contrib_id}
		     . '/' . '_MEMBER_SUBSYS' );
	return $member;

    } elsif ($param->{mode} eq "edit") {
	# We must be dealing with an existing contributor object

	# get handle to underlying person object
 	my $person = $contrib->get_obj;

	# update contacts on this person object
 	$m->comp("/widgets/profile/updateContacts.mc",
 		 param => $param,
 		 obj   => $person);
 	$person->save;

	# Update attributes.
	# We'll need these to get the SQL type and max length of attributes.
	my $all = $contrib->all_for_subsys;
	my $mem_attr = Bric::Util::Attribute::Grp->new({ id => $contrib->get_grp_id,
						         susbsys => '_MEMBER_SUBSYS' });

	foreach my $aname (@{ mk_aref($param->{attr_name}) } ) {
	    # Grab the SQL type.
	    my $sqltype = $mem_attr->get_sqltype({ name => $aname,
						   subsys => $param->{subsys} });

	    # Truncate the value, if necessary.
	    my $max = $all->{$aname}{meta}{maxlength}{value};
	    my $value = $param->{"attr|$aname"};
	    $value = join('__OPT__', @$value)
	      if $all->{$aname}{meta}{multiple}{value} && ref $value;
	    $value = substr($value, 0, $max) if $max && length $value > $max;

	    # Set the attribute.
	    $contrib->set_attr({ subsys   => $param->{subsys},
				 name     => $aname,
				 value    => $value,
				 sql_type => $sqltype });
	}

	# Save the contributor
 	$contrib->save;
	$param->{contrib_id} = $contrib->get_id;
	if ($field eq "$widget|save_cb") {
	    # Record a message and redirect if we're saving
            add_msg($lang->maketext("$disp_name profile [_1] saved.",$name));
	    log_event("${type}_save", $contrib);
	    clear_state("contrib_profile");
	    set_redirect('/admin/manager/contrib');
	}

    } elsif ($param->{mode} eq "extend") {
	# We're creating a new contributor based on an existing one.
	# Change the mode for the next screen.
	$param->{mode} = 'edit';
	set_state_data("contrib_profile", { extending => 1 } );
	set_redirect('/admin/profile/contrib/edit/' . $contrib->get_id . '/'
		     . escape_uri($param->{subsys}) );
	log_event("${type}_ext", $contrib);
	return $contrib;

    } elsif ($param->{mode} eq 'preEdit') {

	$param->{mode} = 'edit';
	set_state_data("contrib_profile", { extending => 0 } );
	set_redirect('/admin/profile/contrib/edit/' . $contrib->get_id . '/'
		     . escape_uri($param->{subsys}) );
	return $contrib;
    }

}

</%init>
<%doc>
###############################################################################

=head1 NAME

/widgets/profile/contrib.mc - Processes submits from Contributor Profile

=head1 VERSION

$Revision: 1.11 $

=head1 DATE

$Date: 2003-06-13 16:49:11 $

=head1 SYNOPSIS

  $m->comp('/widgets/profile/contrib.mc', %ARGS);

=head1 DESCRIPTION

This element is called by /widgets/profile/callback.mc when the data to be
processed was submitted from the contributor Profile page.

</%doc>
