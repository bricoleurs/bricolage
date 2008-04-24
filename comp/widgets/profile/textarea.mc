<%doc>
###############################################################################

=head1 NAME

=head1 SYNOPSIS
$m->comp("/widgets/profile/textarea.mc",
$disp   => ''
$value  => ''
$name  => ''
$rows   => ''
$cols   => ''
$js     => ''
);
=head1 DESCRIPTION
 Pretty wrapper for displayFormElement.mc.
=cut
</%doc>

<%args>

$disp   => ''
$value  => ''
$name  => ''
$rows   => ''
$cols   => ''
$js     => ''
$req    => 0
$useTable => 1
$localize => 1
$readOnly => 0
$width     => ''
$indent    => ''
</%args>

<%perl>

my $vals = {
    disp      => $disp,
    value     => $value,
    props     => { 
        type => 'textarea',
        rows => $rows,
        cols => $cols
    },
    js        => $js,
    req       => $req
};


$m->comp("/widgets/profile/displayFormElement.mc",
     key      => $name,
     vals     => $vals,
     useTable => $useTable,
     readOnly => $readOnly,
     width    => $width,
     localize => $localize,
     indent   => $indent
);

</%perl>
