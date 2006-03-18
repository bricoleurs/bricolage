<%args>
$asset
</%args>
<%init>;
return unless $asset->get_publish_status;
my ($letter, $action) = $asset->key_name eq 'template'
  ? ('D (for Deployed)',  'Deployed')
  : ('P (for Published)', 'Published');
if ($asset->needs_publish) {
    return qq{<span class="need" title="}
        . $lang->maketext("Needs to be $action")
        . '">' . $lang->maketext($letter) . '</span>';
} else {
    return qq{<span class="pub" title="}
        . $lang->maketext("$action Version")
        . '">' . $lang->maketext($letter) . '</span>';
}
</%init>
