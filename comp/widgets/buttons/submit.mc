<%doc>
###############################################################################

=head1 NAME

=head1 DATE

$LastChangedDate$

=head1 SYNOPSIS
$m->comp("/widgets/buttons/submit.mc",
  disp      => '',
  widget    => '',
  cb        => '',
  button    => ''
);

=head1 DESCRIPTION

Easier to use wrapper for displayFormElement.mc

=cut

</%doc>
<%args>
$widget    => undef
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
my $key = ($widget) ? "$widget|$cb" : $name;

my $vals = { disp      => '',
             value     => $disp,
             props     => { type      => 'image',
                            src       => "/media/images/$lang_key/$button.gif"
                          },

             js        => $js,
           };

$m->comp("/widgets/profile/displayFormElement.mc",
         key       => $key,
         vals      => $vals,
         indent    => $indent,
         useTable  => $useTable,
         localize  => $localize,
);
</%perl>
