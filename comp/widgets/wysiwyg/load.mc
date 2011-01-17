<%init>
my $editor = lc(WYSIWYG_EDITOR);
$m->comp($editor.".html");
</%init>
<script type="text/javascript">
% my %java_vars = $m->comp('/widgets/wysiwyg/bricolage-wysiwyg.mc');
% foreach my $key_name (keys %java_vars)
% {
    var <% $key_name %> = <% $java_vars{$key_name} %>;
% }
</script>
