<%args>
$asset
$sorted
</%args>
<%init>;
my ($letter, $action, $alias) = $asset->key_name eq 'formatting'
  ? ('D', 'Deployed', '')
  : ('P', 'Published', ($asset->get_alias_id ? 'alias' : ''));

unless ($asset->get_publish_status) {
    $alias = '' if $sorted;
    return qq{<span class="${alias}none$sorted">&nbsp;</span>};
}

if ($asset->needs_publish) {
    return qq{<span class="need" title="} .
     $lang->maketext("Needs to be $action") . qq{">$letter</span>};
}

return qq{<span class="pub" title="} .
  $lang->maketext("$action Version") . qq{">$letter</span>};
</%init>
