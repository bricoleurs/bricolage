<%once>;
my $type = 'element';
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
		   pos => 'fb_position'
		 );
</%once>

<%args>
$widget
$param
$field
$obj
</%args>

<%perl>;

return unless $field eq "$widget|save_cb" || $field eq "$widget|add_cb" || $field eq "$widget|addElement_cb";
return unless $param->{$field}; # prevent multiple calls to this file


# Instantiate the element object and grab its name.
my $comp = $obj;
my $name = "&quot;$param->{name}&quot;";

my %del_attrs = map( {$_ => 1} @{ mk_aref($param->{del_attr})} );

if ($param->{delete} && $field eq "$widget|save_cb") {
    # Deactivate it.
    $comp->deactivate;
    $comp->save;
    log_event("${type}_deact", $comp);
    add_msg("$disp_name profile $name deleted.");
    set_redirect('/admin/manager/element');
}  else {
    # Make sure the name isn't already in use.
    my $no_save;
    my @cs = $class->list_ids({ name => $param->{name}, active => undef });
    if (@cs > 1) { $no_save = 1 }
    elsif (@cs == 1 && !defined $param->{element_id}) { $no_save = 1 }
    elsif (@cs == 1 && defined $param->{element_id}
	   && $cs[0] != $param->{element_id}) {
	$no_save = 1 }
    add_msg("The name $name is already used by another $disp_name.") if $no_save;

    # Roll in the changes. Create a new object if we need to pass in an Element
    # Type ID.
    $comp = $class->new({ type__id => $param->{element_type_id} })
      if exists $param->{element_type_id} && !defined $param->{element_id};
    $comp->activate;
    $comp->set_name($param->{name}) unless $no_save;
    $comp->set_description($param->{description});
    $comp->set_primary_oc_id($param->{primary_oc_id}) if exists $param->{primary_oc_id};

    # Update existing attributes.
    my $all_data = $comp->get_data;
    my $data_href = { map { lc ($_->get_name) => $_ } @$all_data };
    my $pos = mk_aref($param->{attr_pos});
    my $i = 0;
    foreach my $aname (@{ mk_aref($param->{attr_name}) } ) {
	if (!$del_attrs{$aname} ) {
	    my $key = lc $aname;
	    $data_href->{$key}->set_place($pos->[$i]);
	    $data_href->{$key}->set_meta('html_info', 'pos', $pos->[$i]);
	    $data_href->{$key}->set_meta('html_info', 'value', $param->{"attr|$aname"});
	    $data_href->{$key}->save;
	    $i++;
	}
    }

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
	      : $param->{fb_type} eq 'textarea' && $param->{fb_size} > 1024
		? 'blob' : 'short';

	    my $value = $sqltype eq 'date' ? undef : $param->{fb_value};

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

	    my $max = $param->{fb_maxlength} ? $param->{fb_maxlength}
	      : $param->{fb_maxlength} eq '0' ? 0 : undef;

	    my $atd = $comp->new_data({ name        => $param->{fb_name},
					required    => $param->{fb_req} ? 1 : 0,
					quantifier  => $param->{fb_quant} ? 1 : 0,
					sql_type    => $sqltype,
					place       => $param->{fb_position},
					publishable => 1,
					max_length  => $max,
				      });

	    # create name/value field for element
	    $atd->set_attr('html_info', $value);

	    # Record the metadata so we can properly display the form element.
	    while (my ($k, $v) = each %meta_props) {
		$atd->set_meta('html_info', $k, $param->{$v});
	    }

	    # Checkboxes need a default value.
	    $atd->set_meta('html_info', 'value', 1)
	      if $param->{fb_type} eq 'checkbox';

	    # Log that we've created it.
	    log_event("${type}_attr_add", $comp, { Name => $param->{fb_name} });
	}

    }

    # Delete any attributes that are no longer needed.
    if ($param->{del_attr} && $field eq "$widget|save_cb") {
	my $del = [];
	foreach my $attr (keys %del_attrs) {
	    push @$del, $data_href->{lc $attr};
	    log_event("${type}_attr_del", $comp, { Name => $attr });
	}
	$comp->del_data($del);
    }

    # add or delete output channels
    $comp->add_output_channels( mk_aref($param->{add_oc}) )
      if $param->{add_oc};
    $comp->delete_output_channels( mk_aref($param->{rem_oc}) )
      if $param->{rem_oc};

    # delete any selected sub elements 
    if ($param->{"element|delete_cb"}) {
	$comp->del_containers( mk_aref($param->{"element|delete_cb"}) );
    }

    # Save the element.
    $comp->save unless $no_save;
    $param->{element_id} = $comp->get_id;

    my $containers = $comp->get_containers;

    if ($field eq "$widget|save_cb" && !$no_save) {

	if ($param->{isNew}) {
	    set_redirect('/admin/profile/element/' .$param->{element_id} );
	} else {
	    # log the event
	    log_event($type . (defined $param->{element_id} ? '_save' : '_new'), $comp);
	    # Record a message and redirect if we're saving.
	    add_msg("$disp_name profile $name saved.");
	    set_redirect('/admin/manager/element'); # return to profile if creating new object
	}

    } elsif ($field eq "$widget|addElement_cb" && !$no_save) {
	# redirect, and tack object id onto path
	set_redirect('/admin/manager/element/'. $param->{element_id} );
    }
    return $comp;
}

</%perl>
<%doc>
###############################################################################

=head1 NAME

/widgets/profile/contrib_type.mc - Processes submits from Element Profile

=head1 VERSION

$Revision: 1.4 $

=head1 DATE

$Date: 2001-10-05 20:03:42 $

=head1 SYNOPSIS

  $m->comp('/widgets/formBuilder/element.mc', %ARGS);

=head1 DESCRIPTION

This element is called by /widgets/profile/callback.mc when the data to be
processed was submitted from the Element Profile page.

=head1 REVISION HISTORY

$Log: element.mc,v $
Revision 1.4  2001-10-05 20:03:42  samtregar
Merged changes from Release_1_0


</%doc>
