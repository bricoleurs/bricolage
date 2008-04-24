<%doc>
###############################################################################

=head1 NAME

=head1 VERSION

$LastChangedRevision$

=head1 SYNOPSIS
$m->comp("/widgets/profile/text.mc",
$disp      => ''
$value     => ''
$name     => ''
$length    => ''
$maxlength => ''
$js        => ''
$width     => ''
$indent    => ''
);

=head1 DESCRIPTION

Easier to use wrapper for displayFormElement.mc

=cut

</%doc>
<%args>
$disp      => ''
$value     => ''
$name      => ''
$id        => undef
$length    => ''
$size      => ''
$maxlength => ''
$js        => ''
$req       => 0
$width     => ''
$indent    => ''
$useTable  => 1
$localize  => 1
$readOnly  => 0
$class     => undef
$title     => undef
</%args>
<%perl>;
my $vals = { disp      => $disp,
             value     => $value,
             props     => { type      => 'text',
                            length    => $size || $length,
                            maxlength => $maxlength,
                            title     => $title,
                            class     => $class,
                          },
             js        => $js,
             req       => $req,
           };

$m->comp("/widgets/profile/displayFormElement.mc",
         key       => $name,
         vals      => $vals,
         width     => $width,
         indent    => $indent,
         useTable  => $useTable,
         localize  => $localize,
         readOnly  => $readOnly,
         id        => $id,
);
</%perl>
