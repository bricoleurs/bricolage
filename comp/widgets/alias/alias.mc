<%once>;
my $widget = 'alias';
</%once>
<%init>;
set_state_data($widget, \%ARGS);
$m->comp('find_alias.html', %ARGS, widget => 'alias');
</%init>
