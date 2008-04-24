<%doc>
###############################################################################

=head1 NAME

=head1 VERSION

$LastChangedRevision$

=head1 SYNOPSIS
$m->comp("/widgets/profile/checkbox.mc",
         label_after => 0,
         checked     => 0,
         disp        => '',
         value       => '',
         name        => '',
         js          => ''
);

=head1 DESCRIPTION

Easier to use wrapper for displayFormElement.mc

=cut

</%doc>
<%args>
$label_after => 0
$disp        => ''
$value       => ''
$name        => ''
$js          => ''
$checked     => 0
$useTable    => 0
$readOnly    => 0
$localize    => 1
$id          => undef
</%args>
<%perl>;
my $vals = { disp  => $disp,
             value => $value,
             js    => $js,
             props => { type => 'checkbox',
                        chk  => $checked,
                        label_after => $label_after,
                      } };


$m->comp("/widgets/profile/displayFormElement.mc",
         key  => $name,
         vals => $vals,
         readOnly => $readOnly,
         localize => $localize,
         useTable => $useTable,
         id       => $id
);
</%perl>
