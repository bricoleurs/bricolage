<%doc>
###############################################################################

=head1 NAME

=head1 VERSION

$LastChangedRevision$

=head1 DATE

$LastChangedDate$

=head1 SYNOPSIS
$m->comp("/widgets/buttons/back.mc",
  disp      => 'Return',
  widget    => $widget,
  cb        => 'return_cb',
  button    => 'return_dgreen'
);

$m->comp("/widgets/buttons/back.mc",
  disp      => 'Return',
  uri       => '/workflow/profile/workspace/',
  button    => 'return_dgreen'
);

=head1 DESCRIPTION

Easier to use wrapper for displayFormElement.mc

=cut

</%doc>
<%args>
$widget    => undef
$disp      => ''
$cb        => ''
$button    => 'return_dgreen'
$name      => ''
$uri       => undef
$js        => ''
$indent    => ''
$useTable  => 1
$localize  => 1
</%args>
<%perl>;
$url ||= last_page();
$js .= qq{ onclick="window.location.href='} . $uri . qq{'; return false;"};

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
