<%args>
$asset
$sorted
</%args>
<%init>;
my ($letter, $action, $alias) = $asset->key_name eq 'template'
  ? ('D', 'Deployed', '')
  : ('P', 'Published', ($asset->get_alias_id ? 'alias' : ''));

unless ($asset->get_publish_status) {
    $alias = '' if $sorted;
    return qq{<div class="pubstatus$sorted">&nbsp;</div>};
}

if ($asset->needs_publish) {
    return qq{<div class="pubstatus need" title="} .
     $lang->maketext("Needs to be $action") . qq{">$letter</div>};
}

return qq{<div class="pubstatus" title="} .
  $lang->maketext("$action Version") . qq{">$letter</div>};
</%init>
