<li id="subelement_<% $name %>" class="container clearboth">
<h3 class="name"><% $element->get_name %>:</h3>
<div class="content">
<ul id="element_<% $id %>" class="elements">
% foreach my $dt ($element->get_elements()) {
<%perl>
    if ($dt->is_container) {
        $m->comp('container.mc',
            widget  => $widget,
            element => $dt
        );
    } else {
        $m->comp('field.mc',
            widget  => $widget,
            element => $dt
        );
    }
</%perl>
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

% if ($type->is_related_media || $type->is_related_story) {
<p><b><% $lang->maketext($type->is_related_media ? "URL" : "Title" )%>:</b><% $info %></p>
% }
<p>
    <& '/widgets/profile/button.mc',
        disp      => $lang->maketext("Delete"),
        name      => 'delete_' . $name,
        button    => 'delete_red',
        js        => qq{onclick="Container.deleteElement('subelement_$name'); return false;"},
        useTable  => 0 
    &>
    <& '/widgets/profile/button.mc',
        widget     => 'container_prof',
        cb         => 'bulk_edit_cb',
        button     => 'bulk_edit_lgreen',
        value      => $id,
        useTable   => 0
    &>
    
%   # XXX mroch: Don't leave this hard-coded! Make a component.
    <input type="image" src="/media/images/<% $lang_key %>/add_element_lgreen.gif" alt="Add Element" onclick="$('container_prof_add_element_container').value = '<% $id %>'; new Ajax.Updater('element_<% $id %>',  '/widgets/container_prof/add_element.html', { parameters: Form.serialize(this.form), asynchronous: true, insertion: Insertion.Bottom, onComplete: function(request) { Container.updateOrder('element_<% $id %>')} } ); return false" />
    
    <& /widgets/profile/select.mc, name     => $widget.'|add_element_to_'.$id,
                                   options  => $elem_opts,
                                   useTable => 0,
                                   multiple => 0,
                                   size     => 1,
    &>
</p>
</div>
</li>

<%args>
$widget
$element
</%args>

<%init>
my $type = $element->get_element_type;
my $id   = $element->get_id;
my $name = 'con' . $id;

my $info = '';
if ($type->is_related_media || $type->is_related_story) {
    if ($type->is_related_media) {
        my $rel = $element->get_related_media;
        $info = $rel->get_uri if $rel;
    } else {
        my $rel = $element->get_related_story;
        $info = $rel->get_title if $rel;
    }
}

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