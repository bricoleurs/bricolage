<%doc>
###############################################################################

=head1 NAME

/widgets/profile/dests.mc - Processes submits from Destination Profiles.

=head1 VERSION

$Revision: 1.7 $

=head1 DATE

$Date: 2002-05-03 16:47:21 $

=head1 SYNOPSIS

  $m->comp('/widgets/profile/dests.mc', %ARGS);

=head1 DESCRIPTION

This element is called by /widgets/profile/callback.mc when the data to be
processed was submitted from the Destination Profile page.

</%doc>

<%args>
$widget
$param
$field
$obj
</%args>
<%once>;
my $type = 'dest';
my $disp_name = get_disp_name($type);
my $class = get_package_name($type);
</%once>
<%init>;
return unless $field eq "$widget|save_cb";
# Instantiate the dest object and its name.
my $dest = $obj;
my $name = "&quot;$param->{name}&quot;";

if ($param->{delete}) {
    # Dissociate output channels.
    $dest->del_output_channels;
    # Deactivate the destination.
    $dest->deactivate;
    $dest->save;
    log_event('dest_deact', $dest);
    add_msg("$disp_name profile $name deleted.");
    # Set the redirection.
    set_redirect("/admin/manager/dest");
    return;
}
my $dest_id = $param->{"${type}_id"};
# Make sure the name isn't already in use.
my $used;
my @dests = $class->list_ids({ name => $param->{name} });
if (@dests > 1) { $used = 1 }
elsif (@dests == 1 && !defined $dest_id) { $used = 1 }
elsif (@dests == 1 && defined $dest_id
       && $dests[0] != $dest_id) { $used = 1 }
add_msg("The name $name is already used by another $disp_name.") if $used;

# If they're editing it, assume it's active.
$param->{active} = 1;

# Set booleans to true if they're present
foreach (qw(publish copy preview)) {
    $param->{$_} = 1 if exists $param->{$_};
}

# Roll in the changes.
foreach my $meth ($dest->my_meths(1)) {
    if ($meth->{name} eq 'name') {
	$meth->{set_meth}->($dest, @{$meth->{set_args}}, $param->{$meth->{name}})
	  unless $used
      } else {
	  $meth->{set_meth}->($dest, @{$meth->{set_args}}, $param->{$meth->{name}})
	    if defined $meth->{set_meth};
      }
}

# Add any new output channels.
if ($param->{add_oc}) {
    my @add = map { Bric::Biz::OutputChannel->lookup({ id => $_ }) }
      @{ mk_aref($param->{add_oc}) };
    $dest->add_output_channels(@add);
}

# Remove output channels.
if ($param->{rem_oc}) {
    my @add = map { Bric::Biz::OutputChannel->lookup({ id => $_ }) }
      @{ mk_aref($param->{rem_oc}) };
    $dest->del_output_channels(@add);
}

if ($used) {
    return $dest;
} else {
    # Save it!
    $dest->save;
    if (defined $dest_id) {
	log_event('dest_' . (defined $param->{dest_id} ? 'save' : 'new'), $dest);
	# Send a message to the browser.
	add_msg("$disp_name profile $name saved.");
	# Set the redirection.
	set_redirect("/admin/manager/dest");
    } else {
	# It's a new destination. Let them add Actions and Servers.
	return $dest;
    }
}
</%init>
