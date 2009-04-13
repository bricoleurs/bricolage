<ul id="fast-add-<% $type %>" style="line-height: 2em">
% foreach my $obj (@$objects) {
<li class="<% $type %>">
    <& '/widgets/profile/hidden.mc',
        name  => $type . '_id',
        value => $obj->get_id
    &>
    <span class="value"><% $obj->get_name %></span>
    (<a href="#" onclick="fastadd<% $type %>.remove(this.parentNode); return false">remove</a>)
</li>
% }
</ul>
<input type="text" class="textInput" name="add_<% $type %>" id="add_<% $type %>" />
<div id="add_<% $type %>_autocomplete" class="autocomplete"></div>
<button onclick="fastadd<% $type %>.add('add_<% $type %>'); return false">Add</button>

<script type="text/javascript">
var fastadd<% $type %> = new FastAdd('<% $type %>', {}, { onEnter: function(element) { fastadd<% $type %>.add(element) }});
</script>

<%args>
$type       => "object"
$objects
</%args>
