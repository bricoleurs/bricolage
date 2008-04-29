<%doc>
###############################################################################

=head1 NAME

=head1 DATE

$LastChangedDate$

=head1 SYNOPSIS
$m->comp("/widgets/profile/button.mc",
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
$extension => 'gif'
$globalImage => 0
$id        => undef
$name      => ''
$value     => undef
$js        => ''
$indent    => ''
$useTable  => 1
$localize  => 1
</%args>
<%perl>;
my $key = ($widget) ? "$widget|$cb" : $name;
my $local = $globalImage ? '' : "$lang_key/";

my $vals = { disp      => '',
             value     => $value || $disp,
             props     => { type      => 'image',
                            src       => "/media/images/$local$button.$extension",
                            title     => $disp
                          },

             js        => $js,
           };

$m->comp("/widgets/profile/displayFormElement.mc",
         id        => $id,
         key       => $key,
         vals      => $vals,
         indent    => $indent,
         useTable  => $useTable,
         localize  => $localize,
);
</%perl>
