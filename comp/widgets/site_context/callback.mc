<%once>;
my $ctext_key = 'ctext';
</%once>
<%args>
$widget
$field
$param
</%args>

<%init>;
return unless $field eq "$widget|change_context_cb";
$c->set_user_cx(get_user_id, $param->{$field});
</%init>
