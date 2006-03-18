<%args>
$doc
$value => undef
$title => "Preview"
$type  => 'story'
$style => ''
$oc_js => undef
</%args>
<%init>;
my $uid = $doc->get_user__id;
my $co = defined $uid && $uid == get_user_id;
$title = $doc->get_title unless defined $title;
return $value unless $co || $doc->get_version;
return $value if $type eq 'media' and not $doc->get_file_name;
my $id = $doc->get_id;
my $uri = escape_html($doc->get_primary_uri);
$value ||= $doc->get_primary_uri;

# Return a simple link unless we've been givin a JS reference to a an
# output channel ID.
return qq{<a href="$uri" } .
  qq{onclick="var newWin = window.open('/workflow/profile/preview/control/$type/$id?checkout=$co', 'preview_} . SERVER_WINDOW_NAME . q{'); newWin.focus(true); return false;" } .
  ($style ? qq{class="$style"} : '') . qq{ title="$title">$value</a>}
  unless $oc_js;

# If we got here, We need to actually load the link based on an oc ID.
return qq{<a href="$uri" onclick="window.open('/workflow/profile/preview/control/$type/$id/' + $oc_js, 'preview_} . SERVER_WINDOW_NAME . qq{'); return false;" title="$uri"><img src="/media/images/$lang_key/preview_lgreen.gif" alt="Preview" title="Preview $uri" border="0" width="74" height="20" /></a>};
</%init>
