<%doc>
###############################################################################

=head1 NAME

=head1 VERSION

$LastChangedRevision$

=head1 DATE

$LastChangedDate$

=head1 SYNOPSIS

  $m->comp("/widgets/profile/select.mc",
           disp      => ''
           value     => ''
           name      => ''
           options   => {}
           js        => ''
  );

=head1 DESCRIPTION

Pretty little wrapper for displayFormElement.mc.

=cut

</%doc>
<%args>
$disp      => ''
$value     => ''
$name      => ''
$options   => {}
$js        => ''
$req       => 0
$useTable  => 1
$width     => ''
$indent    => ''
$multiple  => 0
$size      => 1
$readOnly  => 0
$localize  => 1
$id        => undef
</%args>
<%perl>;
my $vals = {
    disp  => $disp,
    value => $value,
    js    => $js,
    req   => $req,
    props => {
        size     => $size,
        multiple =>  $multiple,
        type     => 'select',
        vals     => $options
    },
};

$m->comp(
    "/widgets/profile/displayFormElement.mc",
    key      => $name,
    vals     => $vals,
    useTable => $useTable,
    readOnly => $readOnly,
    width    => $width,
    indent   => $indent,
    localize => $localize,
    id       => $id,
);
</%perl>
