<%once>
my $imageSubmit = sub {
    my ($formName, $callback, $image, $hspace, $vspace, $js,
        $useHidden, $useGlobalImage) = @_;
    my $localorno = $useGlobalImage ? '' : "$lang_key/";

    $m->out(qq{<a href="#" $js>});
    $m->out(qq{<img src=\"/media/images/$localorno$image.gif\" border="0" });
    $m->out(qq{hspace="$hspace" }) if ($hspace);
    $m->out(qq{vspace="$vspace" }) if ($vspace);
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
$useGlobalImage => 0
</%args>
<%init>
&$imageSubmit($formName, $callback, $image, $hspace, $vspace, $js,
              $useHidden, $useGlobalImage);
</%init>
<%doc>
The 'useGlobalImage' arg is for images that aren't language-specific --
for example, note.gif. If 'useGlobalImage' is set to true, instead of
using a base path of '/media/images/en_us/', for instance, it will
use '/media/images/'.
</%doc>
