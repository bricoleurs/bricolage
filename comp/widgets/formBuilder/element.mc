<%once>;
my $type = 'element';
my $class = get_package_name($type);
my $disp_name = get_disp_name($type);
my %meta_props = ( disp => 'fb_disp',
		   value => 'fb_value',
		   type => 'fb_type',
		   length => 'fb_size',
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
return unless $field eq "$widget|save_cb"
  || $field eq "$widget|add_cb"
  || $field eq "$widget|save_n_stay_cb"
  || $field eq "$widget|addElement_cb"
  || $field eq "$widget|add_oc_id_cb"
  || $field eq "$widget|add_site_id_cb";
return unless $param->{$field}; # prevent multiple calls to this file

# Instantiate the element object and grab its name.
my $comp     = $obj;
my $name     = "&quot;$param->{name}&quot;";
my $key_name = "&quot;$param->{key_name}&quot;";

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
    # AssetType has been updated to take an existing but undefined 'active'
    # flag as meaning, "list both active and inactive"
    my @cs = $class->list_ids({key_name => $param->{key_name},
                               active   => undef});

    # Check if we need to inhibit a save based on some special conditions
    if    (@cs > 1)                                   { $no_save = 1 }
    elsif (@cs == 1 && !defined $param->{element_id}) { $no_save = 1 }
    elsif (@cs == 1 && 
           defined $param->{element_id} && 
           $cs[0] != $param->{element_id})            { $no_save = 1 }

    add_msg($lang->maketext('The key name [_1] is already used by another [_2].',
                            $key_name ,$disp_name))
      if $no_save;

    # Roll in the changes. Create a new object if we need to pass in an Element
    # Type ID.
    $comp = $class->new({ type__id => $param->{element_type_id} })
      if exists $param->{element_type_id} && !defined $param->{element_id};
    $comp->activate;
    $comp->set_name($param->{name});

    # Normalize the key name
    my $kn = lc($param->{key_name});
    $kn =~ y/a-z0-9/_/cs;

    $comp->set_key_name($kn) unless $no_save;
    $comp->set_description($param->{description});
    $comp->set_burner($param->{burner}) if defined $param->{burner};

    # Determine the enabled output channels.
    my %enabled = map { $_ ? ( $_ => 1) : () } @{ mk_aref($param->{enabled}) },
      map { $comp->get_primary_oc_id($_) } $comp->get_sites;

    # Set the primary output channel ID per site
    if (($field eq "$widget|save_cb" || $field eq "$widget|save_n_stay_cb") &&
         $comp->get_top_level) {
        my %oc_ids;
        @oc_ids{map { $_->get_id } $comp->get_sites} = ();

        foreach my $key (keys %$param) {
            next unless $key =~/primary_oc_site(\d+)_cb/;
            my $siteid = $1;
            $comp->set_primary_oc_id($param->{$key}, $siteid);
            my ($oc) = $comp->get_output_channels($param->{$key});
            unless ($oc) {
                $comp->add_output_channel($param->{$key});
                $oc = Bric::Biz::OutputChannel->lookup
                  ({ id => $param->{$key} });
            }

            # Associate it with the site and make sure it's enabled.
            $oc_ids{$siteid} = $param->{$key};
            $enabled{$oc->get_id} = 1;
        }

        foreach my $siteid (keys %oc_ids) {
            unless ($oc_ids{$siteid}) {
                $no_save = 1;
                my $site = Bric::Biz::Site->lookup({id => $siteid});
                add_msg($lang->maketext
                        ("Site [_1] requires a primary output channel",
                         '&quot;' . $site->get_name . '&quot;'));
            }
        }
    } elsif($field eq "$widget|add_oc_id_cb") {
        my $oc = Bric::Biz::OutputChannel::Element->lookup({
            id => $param->{"$widget|add_oc_id_cb"}});
        my $siteid = $oc->get_site_id;
        unless ( $comp->get_primary_oc_id($siteid) ) {
            # They're adding the first one. Make it the primary.
            $comp->set_primary_oc_id($param->{"$widget|add_oc_id_cb"}, $siteid);
        }
    }

    # Update existing attributes. Get them from the Parts::Data class rather than from
    # $comp->get_data so that we can be sure to check for both active and inactive
    # data fields.
    my $all_data = Bric::Biz::AssetType::Parts::Data->list(
      { element__id => $param->{element_id} });
#    my $all_data = $comp->get_data;
    my $data_href = { map { lc ($_->get_key_name) => $_ } @$all_data };
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

	    my $atd = $comp->new_data({ key_name    => $param->{fb_name},
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
            log_event('element_data_new', $comp, { Name => $param->{fb_name} });
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
            log_event('element_data', $comp, { Name => $attr });
	}
	$comp->del_data($del);
    }


    # Delete output channels.
    if ($param->{rem_oc}) {
        my $del_oc_ids = mk_aref($param->{rem_oc});


        # workaround because of wierd relationship
        # between OutputChannel and OutputChannel::Element
        # seems like the object gets loaded by lookup
        # this forces them to be loaded first by the
        # href function, seems like O::E needs a _do_list
        # /Arthur
        # This is now done above, anyway, so it's not necessary
        # here any more.
        # /David
        # $comp->get_output_channels;

        $comp->delete_output_channels($del_oc_ids);
    }

    # Delete sites.
    if ($param->{rem_site}) {
        my $del_site_ids = mk_aref($param->{rem_site});
        if(@$del_site_ids >= @{$comp->get_sites}) {
            add_msg($lang->maketext("You cannot remove all Sites"));
        } else {
            $comp->remove_sites($del_site_ids);
        }
    }

    # Enable output channels.
    foreach my $oc ($comp->get_output_channels) {
        $enabled{$oc->get_id} ? $oc->set_enabled_on : $oc->set_enabled_off;
    }

    # Add output channels.
    $comp->add_output_channel($param->{"$widget|add_oc_id_cb"})
      if $field eq "$widget|add_oc_id_cb";

    # Add sites
    $comp->add_site($param->{"$widget|add_site_id_cb"})
      if $field eq "$widget|add_site_id_cb";

    # delete any selected sub elements
    if ($param->{"element|delete_cb"}) {
	$comp->del_containers( mk_aref($param->{"element|delete_cb"}) );
    }

    # Force a primary output channel ID if we don't have one but we have OCs.
#    unless ($comp->get_primary_oc_id) {
#        my $oc = ($comp->get_output_channels)[0];
#        $comp->set_primary_oc_id($oc->get_id) if $oc;
#    }

    #If it is a new element and top level we must add a site
    if($param->{isNew} && $comp->get_top_level) {
        # Try to get the primary site
        if ($c->get_user_cx(get_user_id)) {
            $comp->add_site($c->get_user_cx(get_user_id));
        } else {
            # Else we must do it some other way!
            my @sites = Bric::Biz::Site->list();
            $comp->add_site($sites[0]);
        }
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

$Revision: 1.31 $

=head1 DATE

$Date: 2003-04-28 13:35:52 $

=head1 SYNOPSIS

  $m->comp('/widgets/formBuilder/element.mc', %ARGS);

=head1 DESCRIPTION

This element is called by /widgets/profile/callback.mc when the data to be
processed was submitted from the Element Profile page.

=cut

</%doc>
