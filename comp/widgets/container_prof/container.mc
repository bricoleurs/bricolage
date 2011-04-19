<div id="element_<% $id %>_content" class="content">
% unless ($top_level) {
<fieldset>
<legend class="name">
<a href="#" style="" id="element_<% $id %>_showhide" onclick="Container.toggle(<% $id %>, this); return false;" title="<% escape_html $lang->maketext('Toggle "[_1]"', $element->get_name)  %>">&#x25b<% $displayed ? 'c' : 'a' %>;</a>
<span title="<% $lang->maketext('Drag to reorder') %>"><% $element->get_name %></span>
</legend>
% }
% if ( $parent && !$top_level) {
%     my $minimum_occurrence = 0;
%     if (my $sub_type = $parent->get_element_type->get_containers($element->get_key_name) ) {
%         $minimum_occurrence = $sub_type->get_min_occurrence;
%     }
%     if ( $minimum_occurrence < $parent->get_elem_occurrence($element->get_key_name) ) {
<div class="delete">
    <& '/widgets/profile/button.mc',
        disp        => $lang->maketext("Delete"),
        name        => 'delete_' . $name,
        button      => 'delete',
        extension   => 'png',
        globalImage => 1,
        js          => q{onclick="Container.deleteElement(} . $element->get_parent_id . qq{, '$name'); return false;"},
        useTable    => 0
    &>
</div>
%     }
<div class="copy">
    <& '/widgets/profile/button.mc',
        disp        => $lang->maketext("Copy"),
        name        => 'copy_' . $name,
        button      => 'copy',
        extension   => 'png',
        globalImage => 1,
        js          => q{onclick="Container.copyElement(} . $element->get_parent_id . ', ' . $element->get_id . qq{); return false;"},
        useTable    => 0
    &>
</div>
% }
% if ($hint_val) {
<p class="hint" id="element_<% $id %>_hint"<% $displayed ? ' style="display: none"' : '' %>><strong><% $hint_name %>:</strong> <% escape_html($hint_val) %></p>
% }
<hr id="element_<% $id %>_hr"<% $displayed ? '' : ' style="display: none"' %> />
<ul id="element_<% $id %>" class="elements"<% $top_level || $displayed ? '' : ' style="display: none"' %>>
% foreach my $dt ($element->get_elements()) {
%   if ($dt->is_container) {
    <li id="subelement_con<% $dt->get_id %>" class="container clearboth">
    <& 'container.mc',
        widget  => $widget,
        parent  => $element,
        element => $dt
    &>
    </li>
%   } else {
    <li id="subelement_dat<% $dt->get_id %>" class="element clearboth">
    <& 'field.mc',
        widget  => $widget,
        parent  => $element,
        element => $dt
    &>
    </li>
%   }
% }
% if ($type->is_related_story) {
<li>
    <& '_related.html',
        widget => $widget,
        container => $element,
        type => 'story',
        asset => $story,
        displayed => $displayed,
    &>
</li>
% }
% if ($type->is_related_media) {
<li>
    <& '_related.html',
        widget => $widget,
        container => $element,
        type => 'media',
        asset => $story,
        displayed => $displayed,
    &>
</li>
% }

</ul>
<input type="hidden" name="container_prof|element_<% $id %>" id="container_prof_element_<% $id %>" value="" />
% unless ($top_level ) {
<input type="hidden" name="container_prof|element_<% $id %>_displayed" id="container_<% $id %>_displayed" value="<% $element->get_displayed %>" />
% }
<script type="text/javascript">
Container.updateOrder('element_<% $id %>');
</script>

<div class="actions">
%   if (scalar @$elem_opts) {
%   # XXX mroch: Don't leave this hard-coded! Make a component.
    <div style="display: inline; position: relative;">
    <button id="element_<% $id %>_add" onclick="Desk.menuHandler(this, event); return false"><img src="/media/images/add_element_with_arrow.png" alt="Add Element" /> Add Element</button>
    <div id="element_<% $id %>_add_desks" class="popup-menu" style="display: none; width: 10em; padding: 0;">
        <ul>
%           foreach my $opt (@$elem_opts) {
            <li><a href="#" onclick="Container.addElement(<% $id %>, '<% $opt->[0] %>'); return false" rel="<% $opt->[0] %>"><% $opt->[1] %></a></li>
%           }
            <li style="display: none !important"><a href="#" onclick="Container.addElement(<% $id %>, 'copy_buffer'); return false">Paste</a></li>
        </ul>
    </div>
    </div>
%   if (keys %paste) {
    <script type="text/javascript">
        Container.updatePaste('<% $paste{id} %>', '<% $paste{text} %>');
    </script>
%   }
%   }

% if (get_pref('Show Bulk Edit')) {
<span style="cursor: pointer;" id="<% $top_level ? 'bulk_edit_this_cb' : 'bulk_edit_' . $id %>" onclick="customSubmit('theForm','<% $top_level ? 'container_prof|bulk_edit_this_cb' : 'container_prof|bulk_edit_cb' %>','<% $id %>')" > <img src="/media/images/bulk-edit.png" alt="Bulk Edit" />Bulk Edit</span>
% }
</div>
% unless ($top_level) {
</fieldset>
% }

</div>

<%args>
$widget
$element
$parent => undef
</%args>

<%init>;
my $story = get_state_data('story_prof', 'story');
my $type = $element->get_element_type;
my $id   = $element->get_id;
my $name = 'con' . $id;
my $top_level = (get_state_data($widget, 'element') == $element);
my $displayed = $element->get_displayed;

# Find something to indicate what the element contains, if appropriate.
my ($hint_name, $hint_val);
if ($element->get_parent_id) {
    for my $field ($element->get_fields) {
        $hint_val  = $field->get_value or next;
        $hint_name = $field->get_name;
        $hint_val  = substr($hint_val, 0, 64);
        last;
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

my %paste;
my $buffer = get_state_data('copy_buffer', 'buffer');
if ($buffer) {
    my $buff_type = $buffer->is_container ? $buffer->get_element_type : $buffer->get_field_type;
    my $id = ($buff_type->can('get_sites') ? 'cont_' : 'data_') . $buff_type->get_id;

# Info about the element in the buffer that is used to determine if it can be
# added to the containers on the page
    %paste = (
        id   => $id,
        text => $lang->maketext('Paste ([_1])', $buffer->get_name),
    );
}
</%init>
