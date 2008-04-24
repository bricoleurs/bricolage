<%doc>

=head1 NAME

search - A search widget

=head1 SYNOPSIS

<& '/widgets/search/search.mc', type => $type, object => $object, field => $field &>

=head1 DESCRIPTION

Search the name field of a given object.  The results are displayed on the list
widget.  An optional 'field' argument names a field other than  name to search
upon.  Note that while the name field is standard across objects any field  
passed here must be known to exist for the given object.

=cut

</%doc>
<%args>
$type
$object
$state_key    => $object
$field        => '_default'
$groupList    => undef
$use_form_tag => 1
$wf           => undef
</%args>
<%once>
my $widget = 'search';
</%once>
<%init>

my $state = get_state_data($widget, $state_key) || {};
my $pkg   = get_package_name($object);

# Get the master instance of this class.
my $meth = $pkg->my_meths();

unless ($state->{field}) {
    # Find a real field name if we were given '_default'
    if ($field eq '_default') {
        foreach my $f (keys %$meth)     {
            # Break out of the loop if we find the searchable field.
            $field = $f and last if $meth->{$f}->{search};
        }
    }

    $state->{field} = $field;
}

set_state_data($widget, $state_key => $state);
set_state_name($widget => $state_key);

# Display the correct search box.
$m->comp("$type.html", widget       => $widget,
                       object       => $object,
                       disp_field   => $meth->{$field}->{'disp'},
                       groupList    => $groupList,
                       use_form_tag => $use_form_tag,
                       wf           => $wf,
                       state        => $state,
        );
</%init>
