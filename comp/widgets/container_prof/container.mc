<div id="element_<% $id %>_content" class="content">
% unless ($top_level) {
<h3 class="name"><% $element->get_name %>:</h3>
% }
<ul id="element_<% $id %>" class="elements">
% foreach my $dt ($element->get_elements()) {
%   if ($dt->is_container) {
    <li id="subelement_con<% $dt->get_id %>" class="container clearboth">
    <& 'container.mc',
        widget  => $widget,
        element => $dt
    &>
    </li>
%   } else {
    <li id="subelement_dat<% $dt->get_id %>" class="element clearboth">
    <& 'field.mc',
        widget  => $widget,
        element => $dt
    &>
    </li>
%   }
% }
</ul>
<input type="hidden" name="container_prof|element_<% $id %>" id="container_prof_element_<% $id %>" value="" />
<script type="text/javascript">
Sortable.create('element_<% $id %>', { 
    onUpdate: function(elem) { 
        Container.updateOrder(elem); 
    }, 
    handle: 'name' 
});
Container.updateOrder('element_<% $id %>');
</script>

<div class="actions">
% unless ($top_level) {
    <& '/widgets/profile/button.mc',
        disp      => $lang->maketext("Delete"),
        name      => 'delete_' . $name,
        button    => 'delete_red',
        js        => qq|onclick="if (Container.confirmDelete()) { \$('container_prof_delete_cb').value = '$name'; Container.refresh(| . $element->get_parent_id . qq|); \$('container_prof_delete_cb').value = ''; } return false;"|,
        useTable  => 0 
    &>
% }
    <& '/widgets/profile/button.mc',
        id         => $top_level ? 'bulk_edit_this_cb' : 'bulk_edit_' . $id,
        widget     => 'container_prof',
        cb         => $top_level ? 'bulk_edit_this_cb' : 'bulk_edit_cb',
        button     => 'bulk_edit_lgreen',
        value      => $id,
        useTable   => 0
    &>
    
%   # XXX mroch: Don't leave this hard-coded! Make a component.
    <input type="image" src="/media/images/<% $lang_key %>/add_element_lgreen.gif" alt="Add Element" onclick="$('container_prof_add_element_cb').value = '<% $id %>'; Container.refresh(<% $id %>); $('container_prof_add_element_cb').value = ''; return false" />
    
    <& /widgets/profile/select.mc, name     => $widget.'|add_element_to_'.$id,
                                   options  => $elem_opts,
                                   useTable => 0,
                                   multiple => 0,
                                   size     => 1,
    &>
</div>
</div>

<%args>
$widget
$element
</%args>

<%init>
my $type = $element->get_element_type;
my $id   = $element->get_id;
my $name = 'con' . $id;
my $top_level = (get_state_data($widget, 'element') == $element);

# Get the list of fields and subelements that can be added.
my $elem_opts = [
    map  { $_->[1] }
    sort { $a->[0] cmp $b->[0] }
    map  {
        my $key = $_->can('get_sites') ? 'cont_' : 'data_';
        [ lc $_->get_name => [ $key . $_->get_id => $_->get_name ] ]
    }
        $element->get_possible_field_types,
        grep { chk_authz($_, READ, 1) } $element->get_possible_containers
];
</%init>