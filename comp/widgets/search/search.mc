%#--- Documentation ---#

<%doc>

=head1 NAME

search - A search widget

=head1 VERSION

$Revision: 1.1.1.1.2.1 $

=head1 DATE

$Date: 2001-10-09 21:51:03 $

=head1 SYNOPSIS

<& '/widgets/search/search.mc', type => $type, object => $object, field => $field &>

=head1 DESCRIPTION

Search the name field of a given object.  The results are displayed on the list
widget.  An optional 'field' argument names a field other than  name to search
upon.  Note that while the name field is standard across objects any field  
passed here must be known to exist for the given object.

=cut

</%doc>

%#--- Arguments ---#

<%args>
$type
$object
$field        => '_default'
$groupList    => undef
$use_form_tag => 1
</%args>

%#--- Initialization ---#

<%once>
my $widget = 'search';
</%once>

<%init>

# Clear out the state information if the object changes.
my $obj_state = get_state_data($widget, 'object') || '';
if ($object ne $obj_state) {
    set_state_data($widget, {'object' => $object});
}

# Get paths and remove trailing slash
my ($prev, $cur) = (get_state_data($widget, 'crit_set_uri'), $r->uri);
$prev ? ($prev =~ s!/$!!) : ($prev = '');
$cur ? ($cur =~ s!/$!!) : ($cur = '');

# Clear state if the URI changes
unless ($prev eq $cur) {
    set_state_data($widget, {'object' => $object});
}

my $pkg = get_package_name($object);

# Get the master instance of this class.
my $meth = $pkg->my_meths();

unless (get_state_data($widget, 'field')) {
    # Find a real field name if we were given '_default'
    if ($field eq '_default') {	
	foreach my $f (keys %$meth) 	{
	    # Break out of the loop if we find the searchable field.
	    $field = $f and last if $meth->{$f}->{'search'};
	}
    }

    # Set the field on which to search.
    set_state_data($widget, 'field',  $field);
}

# Display the correct search box.
$m->comp("$type.html", widget       => $widget,
                       object       => $object,
                       disp_field   => $meth->{$field}->{'disp'},
	               groupList    => $groupList,
		       use_form_tag => $use_form_tag
	);

</%init>

%#--- Log History ---#


