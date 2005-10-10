<%args>
$asset
</%args>
<%init>;
return unless $asset->get_publish_status;
my ($letter, $action) = $asset->key_name eq 'template'
  ? ('D', 'Deployed')
  : ('P', 'Published');
if ($asset->needs_publish) {
    return qq{<img src="/media/images/$lang_key/$letter\_red.gif" } .
      qq{border="0" width="15" height="15" alt="[$letter]" title="} .
          $lang->maketext("Needs to be $action") . q{" />};
} else {
    return qq{<img src="/media/images/$lang_key/$letter\_green.gif" } .
      qq{border="0" width="15" height="15" alt="[$letter]" title="} .
        $lang->maketext("$action Version") . q{"  />};
}
</%init>
