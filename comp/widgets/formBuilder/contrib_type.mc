<%once>;
my $type = 'contrib_type';
my $class = get_package_name($type);
my $disp_name = get_disp_name($type);
my %meta_props = ( disp => 'fb_disp',
		   value => 'fb_value',
		   type => 'fb_type',
		   length => 'fb_length',
		   maxlength => 'fb_maxlength',
		   rows => 'fb_rows',
		   cols => 'fb_cols',
		   multiple => 'fb_allowMultiple',
		   vals => 'fb_vals',
		   pos => 'fb_position');
</%once>

<%args>
$widget
$param
$field
$obj
</%args>

<%init>;
return unless $param->{$field} &&
  ($field eq "$widget|save_cb" || $field eq "$widget|add_cb");

# Instantiate the grp object and get its name.
my $grp = $obj;
my $name = "&quot;$param->{name}&quot;";

if ($param->{delete}) { # Deactivate it.
    $grp->deactivate;
    $grp->save;
    add_msg("$disp_name profile $name deleted.");
    log_event("${type}_deact", $grp);
    set_redirect('/admin/manager/contrib_type');
} else {
    # Roll in the changes.
    $grp->activate;
    $grp->set_name($param->{name});
    $grp->set_description($param->{description});

    my %del_attrs = map( {$_ => 1} @{ mk_aref($param->{del_attr})} );
    my $data_href = $grp->get_member_attr_hash || {};
    $data_href = {  map { lc($_) => 1 } keys %$data_href };

    # Update existing attributes.
    my $i = 0;
    my $pos = mk_aref($param->{attr_pos});
    foreach my $aname (@{ mk_aref($param->{attr_name}) } ) {
	if (!$del_attrs{$aname}) {
	    $grp->set_member_attr({ name => $aname,
				    value => $param->{"attr|$aname"} }
				 );
	    $grp->set_member_meta({ name => $aname,
				    field => 'pos',
				    value => $pos->[$i] }
				 );
	    ++$i;
	}
    }
    my $no_save;
    # Add in any new attributes.
    if ($param->{fb_name}) {
	# There's a new attribute. Decide what type it is.
	if ($data_href->{lc $param->{fb_name}}) {
	    # There's already an attribute by that name.
	    add_msg("An &quot;$param->{fb_name}&quot; attribute already exists."
		    . " Please try another name.");
	    $no_save = 1;
	} else {
	    my $sqltype = $param->{fb_type} eq 'date' ? 'date'
	      : $param->{fb_type} eq 'textarea'
	      && (!$param->{fb_maxlength} || $param->{fb_maxlength} > 1024)
	      ? 'blob' : 'short';

	    my $value = $sqltype eq 'date' ? undef : $param->{fb_value};

	    # Set it for all members of this group.
	    $grp->set_member_attr({ name => $param->{fb_name},
				    sql_type => $sqltype,
				    value => $value
				  });

	    # Clean any select/radio values.
	    if ($param->{fb_vals}) {
		$param->{fb_vals} =~ s/\r/\n/g;
		$param->{fb_vals} =~ s/\n{2,}/\n/g;
		$param->{fb_vals} =~ s/\s*,\s*/,/g;
		my $tmp;
		foreach my $line (split /\n/, $param->{fb_vals}) {
		    $tmp .= $line =~ /,/ ? "$line\n" : "$line,$line\n";
		}
		$param->{fb_vals} = $tmp;
	    }

	    # Record the metadata so we can properly display the form element.
	    while (my ($k, $v) = each %meta_props) {
		$grp->set_member_meta({ name => $param->{fb_name},
					field => $k,
					value => $param->{$v} });
	    }
	    # Log that we've added it.
	    log_event("${type}_ext", $obj, { 'Name' => $param->{fb_name} });
	}
    }

    # Delete any attributes that are no longer needed.
    if ($param->{del_attr}) {
	foreach my $attr (keys %del_attrs) {
	    $grp->delete_member_attr({ name => $attr });
	    # Log that we've deleted it.
	    log_event("${type}_unext", $obj, { 'Name' => $attr });
	}
    }

    # Save the group
    $grp->save unless $no_save;
    if ($field eq "$widget|save_cb" && !$no_save) {
	# Record a message and redirect if we're saving.
	add_msg("$disp_name profile $name saved.");
	# Log it.
	log_event($type .(defined $param->{contrib_type_id} ?
			  '_save' : '_new'), $grp);
	# Redirect back to the manager.
	set_redirect('/admin/manager/contrib_type');
    }
    # Grab the ID.
    $param->{contrib_type_id} ||= $grp->get_id;

}
</%init>
<%doc>
###############################################################################

=head1 NAME

/widgets/profile/contrib_type.mc - Processes submits from Contributor Type
Profile

=head1 VERSION

$Revision: 1.4 $

=head1 DATE

$Date: 2001-10-23 17:15:02 $

=head1 SYNOPSIS

  $m->comp('/widgets/profile/contrib_type.mc', %ARGS);

=head1 DESCRIPTION

This element is called by /widgets/profile/callback.mc when the data to be
processed was submitted from the User Profile page.

</%doc>
