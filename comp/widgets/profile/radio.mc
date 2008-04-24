<%doc>
###############################################################################

=head1 NAME

=head1 VERSION

$LastChangedRevision$

=head1 DATE

$Id$

=head1 SYNOPSIS

$m->comp("/widgets/profile/radio.mc",
         disp        => '',
         value       => '',
         name        => '',
         options     => {}
         js          => '', 
         req         => 0,
         label_after => 0
);

=head1 DESCRIPTION

Easier to use wrapper for displayFormElement.mc.

=cut

</%doc>
<%args>
$after       => 0
$disp        => ''
$value       => ''
$name        => ''
$options     => undef
$js          => ''
$req         => 0
$readOnly    => 0
$localize    => 1
$useTable    => 0
$label_after => 0
$checked     => 0
</%args>
<%perl>;
my $vals;

if ($options) {
    $vals = {disp      => $disp,
             value     => $value,
             js        => $js,
             props     => {type        => 'radio',
                           vals        => $options || {},
                           label_after => $label_after
                          },
            };
} else {
    $vals = {disp      => $disp,
             value     => $value,
             js        => $js,
             props     => {type        => 'single_rad',
                           chk         => $checked,
                           label_after => $label_after
                          },
            };
}

$m->comp("/widgets/profile/displayFormElement.mc",
         key        => $name,
         vals       => $vals,
         readOnly   => $readOnly,
         localize   => $localize,
         useTable   => $useTable
);
</%perl>
