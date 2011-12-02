<%args>
$disp      => ''
$formName  => 'theForm'
$callback  => undef
$value     => 1
$image
$vspace    => 0
$hspace    => 0
$js        => qq{onclick="return customSubmit('$formName', '$callback', '$value')"}
$useHidden => 1
$useGlobalImage => 0
$alt       => ''
</%args>
<%init>;
my $localorno = $useGlobalImage ? '' : "$lang_key/";
$disp = $lang->maketext($disp) if $disp;
$m->print(
    qq{<a href="#" $js>},
    qq{<img src="/media/images/$localorno$image.gif" },
    qq{alt="$alt" },
    qq{title="$disp" },
    qq{style="vertical-align: middle; margin: ${vspace}px ${hspace}px;" /></a>},
    ($useHidden ? qq{<input type="hidden" name="$callback" value="" />} : ()),
);
</%init>
<%doc>
The 'useGlobalImage' arg is for images that aren't language-specific --
for example, note.gif. If 'useGlobalImage' is set to true, instead of
using a base path of '/media/images/en_us/', for instance, it will
use '/media/images/'.
</%doc>
