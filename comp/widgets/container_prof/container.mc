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
         widget     => 'container_prof',
         cb         => 'edit_cb',
         button     => 'edit_lgreen',
         value      => $id,
         useTable   => 0
    &>
    <& '/widgets/profile/button.mc',
        widget     => 'container_prof',
        cb         => 'bulk_edit_cb',
        button     => 'bulk_edit_lgreen',
        value      => $id,
        useTable   => 0
    &>

    <& '/widgets/profile/button.mc',
        disp      => $lang->maketext("Delete"),
        name      => 'delete_' . $name,
        button    => 'delete_red',
        js        => qq{onclick="Container.deleteElement('subelement_$name'); return false;"},
        useTable  => 0 
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

# Find a suitable element to display
my ($disp_buf, $value_buf);
foreach my $field ($element->get_fields) {
    if (my $value = $field->get_value) {
        $disp_buf  = $field->get_name;
        $value_buf = substr($value, 0, 64);
        last;
    }
}
</%init>