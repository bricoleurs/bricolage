<%doc>
###############################################################################

=head1 NAME

=head1 VERSION

$LastChangedRevision$

=head1 DATE

$LastChangedDate$

=head1 SYNOPSIS
$m->comp("/widgets/profile/button.mc",
$disp      => ''
$value     => ''
$name     => ''
$js        => ''
$indent    => ''
);

=head1 DESCRIPTION

Easier to use wrapper for displayFormElement.mc

=cut

</%doc>
<%args>
$widget
$disp      => ''
$cb        => 'create_cb'
$button    => 'create_red'
$name      => ''
$js        => ''
$indent    => ''
$useTable  => 1
$localize  => 1
</%args>
<%perl>;
my $vals = { disp      => '',
             value     => $disp,
             props     => { type      => 'image',
                            src       => "/media/images/$lang_key/$button.gif"
                          },

             js        => $js,
           };

$m->comp("/widgets/profile/displayFormElement.mc",
         key       => "$widget|$cb",
         vals      => $vals,
         indent    => $indent,
         useTable  => $useTable,
         localize  => $localize,
);
</%perl>
