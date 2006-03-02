<%args>
$formName  => 'theForm'
$callback
$value     => 1
$image
$vspace    => undef
$hspace    => undef
$js        => qq{onclick="return customSubmit('$formName', '$callback', '$value')"}
$useHidden => 1
$useGlobalImage => 0
$alt       => ''
</%args>
<%init>;
my $localorno = $useGlobalImage ? '' : "$lang_key/";
$m->print(
    qq{<a href="#" $js>},
    qq{<img src="/media/images/$localorno$image.gif" border="0" },
    qq{alt="$alt" },
    ( $hspace ? qq{hspace="$hspace" } : ()),
    ( $vspace ? qq{vspace="$vspace" } : ()),
    qq{style="vertical-align: middle;" /></a>},
    ($useHidden ? qq{<input type="hidden" name="$callback" value="" />} : ()),
);
</%init>
<%doc>
The 'useGlobalImage' arg is for images that aren't language-specific --
for example, note.gif. If 'useGlobalImage' is set to true, instead of
using a base path of '/media/images/en_us/', for instance, it will
use '/media/images/'.
</%doc>
