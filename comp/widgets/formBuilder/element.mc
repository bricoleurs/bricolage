<%once>;
my $type = 'element';
my $class = get_package_name($type);
my $disp_name = get_disp_name($type);
my %meta_props = ( disp      => 'fb_disp',
		   value     => 'fb_value',
		   type      => 'fb_type',
		   length    => 'fb_size',
		   maxlength => 'fb_maxlength',
		   rows      => 'fb_rows',
		   cols      => 'fb_cols',
		   multiple  => 'fb_allowMultiple',
		   vals      => 'fb_vals',
		   pos       => 'fb_position'
		 );
</%once>

<%args>
$widget
$param
$field
$obj
</%args>

<%perl>;
return unless $field eq "$widget|save_cb"
  || $field eq "$widget|add_cb"
  || $field eq "$widget|save_n_stay_cb"
  || $field eq "$widget|addElement_cb"
  || $field eq "$widget|add_oc_id_cb";
return unless $param->{$field}; # prevent multiple calls to this file

# Instantiate the element object and grab its name.
my $comp = $obj;
my $name = "&quot;$param->{name}&quot;";

my %del_attrs = map( {$_ => 1} @{ mk_aref($param->{del_attr})} );

if ($param->{delete} &&
    ($field eq "$widget|save_cb" || $field eq "$widget|save_n_stay_cb"))
{
    # Deactivate it.
    $comp->deactivate;
    $comp->save;
    log_event("${type}_deact", $comp);
    add_msg($lang->maketext('$disp_name profile [_1] deleted.',$name));
    set_redirect('/admin/manager/element');
}  else {
    # Make sure the name isn't already in use.
    my $no_save;
    #### Bug. I'm passing active => 0 here because Bric::Biz::AssetType has a bug
    # where it ignores the active argument if passed a false value. Really, it should
    # check for when active is set to 0. However, since what I want to do is ignore
    # the active column, this will work for now. Eventually, AssetType should be
    # fixed, and then this call will have to be changed to do a call with active => 1
    # and active => 0, and the resulting list grepped to get rid of duplicate IDs.
    # I would do it now, but I don't want to break anything else that may be relying
    # on the bug in AssetType.
    my @cs = $class->list_ids({ name => $param->{name}, active => 0 });
    if (@cs > 1) { $no_save = 1 }
    elsif (@cs == 1 && !defined $param->{element_id}) { $no_save = 1 }
    elsif (@cs == 1 && defined $param->{element_id}
	   && $cs[0] != $param->{element_id}) {
	$no_save = 1 }
    add_msg($lang->maketext('The name [_1] is already used by another [_2].',$name ,$disp_name)) if $no_save;

    # Roll in the changes. Create a new object if we need to pass in an Element
    # Type ID.
    $comp = $class->new({ type__id => $param->{element_type_id} })
      if exists $param->{element_type_id} && !defined $param->{element_id};
    $comp->activate;
    $comp->set_name($param->{name}) unless $no_save;
    $comp->set_description($param->{description});
    $comp->set_burner($param->{burner}) if defined $param->{burner};

    # Set the primary output channel ID.
    if ($param->{primary_oc_id}) {
        $comp->set_primary_oc_id($param->{primary_oc_id});
    } elsif ($param->{add_primary_oc_id} && ! $comp->get_primary_oc_id) {
        # They're adding the first one. Make it the primary.
        $comp->set_primary_oc_id($param->{add_primary_oc_id});
        $comp->add_output_channel($param->{add_primary_oc_id});
    } elsif (! exists $param->{element_type_id} and !$comp->get_primary_oc_id
             and Bric::Biz::ATType->lookup({ id => $comp->get_type__id })
             ->get_top_level) {
        # They need to add an output channel. This shouldn't happen.
        $no_save = 1;
        add_msg("Element must be associated with at least one output channel.")
    }

    # Update existing attributes. Get them from the Parts::Data class rather than from
    # $comp->get_data so that we can be sure to check for both active and inactive
    # data fields.
    my $all_data = Bric::Biz::AssetType::Parts::Data->list(
      { element__id => $param->{element_id} });
#    my $all_data = $comp->get_data;
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
            add_msg($lang->maketext('An [_1] attribute already exists. "
                     ."Please try another name.',"&quot;$param->{fb_name}&quot;"));
	    $no_save = 1;
	} else {
	    my $sqltype = $param->{fb_type} eq 'date' ? 'date'
	      : $param->{fb_type} eq 'textarea'
	      && (!$param->{fb_maxlength} || $param->{fb_maxlength} > 1024)
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
    if ($param->{del_attr} &&
	($field eq "$widget|save_cb" || $field eq "$widget|save_n_stay_cb"))
    {
	my $del = [];
	foreach my $attr (keys %del_attrs) {
	    push @$del, $data_href->{lc $attr};
	    log_event("${type}_attr_del", $comp, { Name => $attr });
	}
	$comp->del_data($del);
    }

    # Delete output channels.
    if ($param->{rem_oc}) {
        my $primoc = $comp->get_primary_oc_id;
        my $del_oc_ids = mk_aref($param->{rem_oc});
        for (@$del_oc_ids) {
            $comp->set_primary_oc_id(undef) and last if $_ == $primoc;
        }
        $comp->delete_output_channels($del_oc_ids);
    }

    # Enable output channels. The primary OC should always be enabled.
    my %enabled = map { $_ ? ( $_ => 1) : () } @{ mk_aref($param->{enabled}) },
      $comp->get_primary_oc_id;
    foreach my $oc ($comp->get_output_channels) {
        $enabled{$oc->get_id} ? $oc->set_enabled_on : $oc->set_enabled_off;
    }

    # Add output channels.
    $comp->add_output_channel($param->{"$widget|add_oc_id_cb"})
      if $field eq "$widget|add_oc_id_cb";

    # delete any selected sub elements
    if ($param->{"element|delete_cb"}) {
	$comp->del_containers( mk_aref($param->{"element|delete_cb"}) );
    }

    # Force a primary output channel ID if we don't have one but we have OCs.
    unless ($comp->get_primary_oc_id) {
        my $oc = ($comp->get_output_channels)[0];
        $comp->set_primary_oc_id($oc->get_id) if $oc;
    }

    # Save the element.
    $comp->save unless $no_save;
    $param->{element_id} = $comp->get_id;

    my $containers = $comp->get_containers;
    if (($field eq "$widget|save_cb" || $field eq "$widget|save_n_stay_cb")
	&& !$no_save)
    {

	if ($param->{isNew}) {
	    set_redirect('/admin/profile/element/' .$param->{element_id} );
	} else {
	    # log the event
	    log_event($type . (defined $param->{element_id} ? '_save' : '_new'), $comp);
	    # Record a message and redirect if we're saving.
	    add_msg("$disp_name profile $name saved.");
	    # return to profile if creating new object
	    set_redirect('/admin/manager/element')
	      unless $field eq "$widget|save_n_stay_cb";
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

$Revision: 1.22.4.3 $

=head1 DATE

$Date: 2003-03-29 06:33:30 $

=head1 SYNOPSIS

  $m->comp('/widgets/formBuilder/element.mc', %ARGS);

=head1 DESCRIPTION

This element is called by /widgets/profile/callback.mc when the data to be
processed was submitted from the Element Profile page.

</%doc>
