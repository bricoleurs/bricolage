<%doc>
###############################################################################

=head1 NAME

/widgets/profile/element_type.mc - Processes submits from element Type
Profile

=head1 VERSION

$Revision: 1.5 $

=head1 DATE

$Date: 2001-12-04 18:17:41 $

=head1 SYNOPSIS

  $m->comp('/widgets/profile/element_type.mc', %ARGS);

=head1 DESCRIPTION

This element is called by /widgets/profile/callback.mc when the data to be
processed was submitted from the element Type Profile page.

</%doc>
<%once>;
my $type = 'element_type';
my $class = get_package_name('element_type'); # HACK.
my $disp_name = get_disp_name('element_type'); # HACK.
my $story_pkg_id = get_class_info('story')->get_id;
my $media_pkg_id = get_class_info('media')->get_id;
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
my $ct = $obj;
my $name = "&quot;$param->{name}&quot;";
my $used;
if ($param->{delete}) {
    # Deactivate it.
    $ct->deactivate;
    log_event("${type}_deact", $ct);
    add_msg("$disp_name profile $name deleted.");
} else {
    # Make sure the name isn't already in use.
    my @cts = $class->list_ids({ name => $param->{name} });
    if (@cts > 1) { $used = 1 }
    elsif (@cts == 1 && !defined $param->{element_type_id}) { $used = 1 }
    elsif (@cts == 1 && defined $param->{element_type_id}
	   && $cts[0] != $param->{element_type_id}) {
	$used = 1 }
    add_msg("The name $name is already used by another $disp_name.") if $used;

    # Roll in the changes.
    $ct->set_name($param->{name}) unless $used;
    $ct->set_description($param->{description});
    if (! defined $param->{element_type_id}) {
        # It's a new element. Just set the type, save, and return.
	$ct->set_top_level($param->{elem_type} eq 'Element' ? 0 : 1);
        if ($param->{elem_type} eq 'Media') {
            $ct->set_media(1);
	    $ct->set_biz_class_id($media_pkg_id);
        } else {
            $ct->set_media(0);
	    $ct->set_biz_class_id($story_pkg_id);
        }
	unless ($used) {
	    $ct->save;
	    log_event($type . '_new', $ct);
	}
	return $ct;
    } else {
        # If we get here, it's an existing type.
        $ct->set_paginated(defined $param->{paginated} ? 1 : 0);
        $ct->set_fixed_url(defined $param->{fixed_url} ? 1 : 0);
        $ct->set_related_story(defined $param->{related_story} ? 1 : 0);
        $ct->set_related_media(defined $param->{related_media} ? 1 : 0);
        $ct->set_biz_class_id($param->{biz_class_id})
          if defined $param->{biz_class_id};
        add_msg("$disp_name profile $name saved.") unless $used;
        log_event($type . '_save', $ct);
    }
}
# Save changes and redirect back to the manager.
return $ct if $used;
$ct->save;
$param->{"${type}_id"} = $ct->get_id unless defined $param->{"${type}_id"};
set_redirect('/admin/manager/element_type');
</%init>
