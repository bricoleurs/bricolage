<%doc>
###############################################################################

=head1 NAME

/widgets/profile/source.mc - Processes submits from Source Profile

=head1 VERSION

$Revision: 1.3 $

=head1 DATE

$Date: 2001-11-20 00:04:07 $

=head1 SYNOPSIS

  $m->comp('/widgets/profile/source.mc', %ARGS);

=head1 DESCRIPTION

This element is called by /widgets/profile/callback.mc when the data to be
processed was submitted from the Source Profile page.

</%doc>
<%once>;
my $type = 'source';
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
# Instantiate the grp object and grab its name.
my $source = $obj;
my $used;
my $name = "&quot;$param->{source_name}&quot;";
if ($param->{delete}) {
    # Deactivate it.
    $source->deactivate;
    log_event("${type}_deact", $source);
    add_msg("$disp_name profile $name deleted.");
    $source->save;
} else {
    my $source_id = $param->{"${type}_id"};
    # Make sure the name isn't already in use.
    my @sources = $class->list_ids({ source_name => $param->{source_name} });
    if (@sources > 1) { $used = 1 }
    elsif (@sources == 1 && !defined $source_id) { $used = 1 }
    elsif (@sources == 1 && defined $source_id
	   && $sources[0] != $source_id) { $used = 1 }
    add_msg("The name $name is already used by another $disp_name.") if $used;

    # Roll in the changes.
    if ($param->{org}) {
	$source->set_org(Bric::Biz::Org->lookup({ id => $param->{org} }) );
    } elsif ($param->{name}) {
	$source->set_name($param->{name});
	$source->set_long_name($param->{long_name});
	log_event("org_new", $source);
    } else {
	# Nothing, bucko - it's an existing source!
    }
    $source->set_description($param->{description});
    $source->set_expire($param->{expire});
    if ($used) {
	return $source;
    } else {
	$source->set_source_name($param->{source_name});
	$source->save;
	log_event($type . (defined $param->{source_id} ? '_save' : '_new'), $source);
	add_msg("$disp_name profile $name saved.");
    }
}
# Save changes and redirect back to the manager.
set_redirect('/admin/manager/source');

</%init>
