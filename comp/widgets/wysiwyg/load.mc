<%init>
my $editor = lc(WYSIWYG_EDITOR);
$m->comp($editor.".html");
</%init>
<script type="text/javascript">
% my %config = $m->comp('/widgets/wysiwyg/bricolage-wysiwyg.mc');
%   while (my ($k, $v) = each %config) {
%      $m->print("var $k = $v;\n");
%   }
</script>
