<%args>
$widget
$field
$param
$obj
</%args>

%#-- Once Section --#
<%once>;
my $type = 'output_channel';
my $disp_name = get_disp_name($type);
my $class = get_package_name($type);
</%once>

<%init>;
return unless $field eq "$widget|save_cb"
  || ($field eq "$widget|include_oc_id_cb" && $param->{$field} ne '');
# Instantiate the output channel object and grab its name.
my $oc = $obj;
my $name = "&quot;$param->{name}&quot;";
my $used;

if ($param->{delete}) {
    # Deactivate it.
    $oc->deactivate;
    log_event('output_channel_deact', $oc);
    add_msg("$disp_name profile $name deleted.");
    $oc->save;
    set_redirect('/admin/manager/output_channel');
} else {
    my $oc_id = $param->{"${type}_id"};
    # Make sure the name isn't already in use.
    my @ocs = $class->list_ids({ name => $param->{name} });
    if (@ocs > 1) { $used = 1 }
    elsif (@ocs == 1 && !defined $oc_id) { $used = 1 }
    elsif (@ocs == 1 && defined $oc_id
	   && $ocs[0] != $oc_id) { $used = 1 }
    add_msg("The name $name is already used by another $disp_name.") if $used;

    # Set the basic properties.
    $oc->set_description( $param->{description} );
    $oc->set_pre_path( $param->{pre_path} );
    $oc->set_post_path( $param->{post_path});
    $oc->set_filename( $param->{filename});
    $oc->set_file_ext( $param->{file_ext});
    $oc->set_uri_case($param->{uri_case});
    exists $param->{use_slug} ? $oc->use_slug_on : $oc->use_slug_off;
    $oc->activate;

    # Set the URI Formatting properties, catching all exceptions.
    my $bad_uri;
    eval { $oc->set_uri_format($param->{uri_format}) };
    $bad_uri = 1 && add_msg($@->get_msg) if $@;
    eval { $oc->set_fixed_uri_format($param->{fixed_uri_format}) };
    $bad_uri = 1 && add_msg($@->get_msg) if $@;

    return $oc if $used;
    $oc->set_name($param->{name});
    return $oc if $bad_uri;

    if ($oc_id) {
	if ($param->{include_id}) {
	    # Take care of deleting included OCs, if necessary.
	    my $del = mk_aref($param->{include_oc_id_del});
	    my %del_ids = map { $_ => 1 } @$del;
	    $oc->del_includes(@$del) if @$del;

	    # Process all existing included OCs and save the changes.
	    my @inc_ord;
	    my $pos = mk_aref($param->{include_pos});
	    my $i = 0;
	    # Put the included OC IDs in the desired order.
	    foreach my $inc_id (@{ mk_aref($param->{include_id}) }) {
		$inc_ord[$pos->[$i++]] = $inc_id;
	    }

	    # Cull out all the deleted OCs.
	    @inc_ord = map { $del_ids{$_} ? () : $_ } @inc_ord
	      if $param->{include_oc_id_del};

	    # Now, compare their positions with what's currently in the OC.
	    $i = 0;
	    my @cur_inc = $oc->get_includes;
	    foreach (@cur_inc) {
		next if $_->get_id == $inc_ord[$i++];

		# If we're here, we have to reorder.
		$oc->set_includes($oc->get_includes(@inc_ord));
		last;
	    }
	}

	# Now append any new includes.
	if ($field eq "$widget|include_oc_id_cb" && $param->{$field} ne '') {
	    # Add includes.
	    $oc->add_includes($class->lookup({ id => $param->{$field} }));
	    $oc->save;
	    return $oc;
	}

	$oc->save;
	log_event('output_channel_save', $oc);
	add_msg("$disp_name profile $name saved.");
	set_redirect('/admin/manager/output_channel');
    } else {
	$oc->save;
	log_event('output_channel_new', $oc);
	return $oc;
    }
}
</%init>
