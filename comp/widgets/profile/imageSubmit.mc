<%once>
my $imageSubmit = sub {
    my ($formName, $callback, $image, $hspace, $vspace, $js, $useHidden) = @_;

    $m->out(qq{<a href="#" $js>});
    $m->out(qq{<img src=\"/media/images/$image.gif\" border="0" });
    $m->out(qq{hspace="$hspace" }) if ($hspace);
    $m->out(qq{vspace=$vspace" }) if ($vspace);
    $m->out("/></a>");
    $m->out(qq{<input type="hidden" name="} . $callback . qq{" value="">}) if ($useHidden);
};
</%once>
<%args>
$formName  => "theForm"
$callback
$value     => 1
$image
$vspace    => undef
$hspace    => undef
$js        => "onClick=\"return customSubmit('".join("', '", $formName, $callback, $value)."')\""
$useHidden => 1
</%args>
<%init>
&$imageSubmit($formName, $callback, $image, $hspace, $vspace, $js, $useHidden);
</%init>
