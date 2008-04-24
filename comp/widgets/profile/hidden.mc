<%doc>
###############################################################################

=head1 NAME

/widgets/profile/hidden.mc - Simple interface for creating hidden fields.

=head1 VERSION

$LastChangedRevision$

=head1 DATE

$Id$

=head1 SYNOPSIS

$m->comp("/widgets/profile/hidden.mc",
         name      => 'my_hidden_field'
         value     => 'foo'
         js        => 'onClick="alert('Drop dead!)');

=head1 DESCRIPTION

Easier to use wrapper for displayFormElement.mc

=cut

</%doc>

<%args>
$value => ''
$name  => ''
$id    => undef
$length => undef
$maxlength => undef
$js    => undef
</%args>

<%perl>;
$m->comp("/widgets/profile/displayFormElement.mc",
          key  => $name,
          id   => $id,
          vals => { value => $value,
                    js    => $js,
                    props => { type => 'hidden',
                               length => $length,
                               maxlength => $maxlength
                             }
                  },
         useTable => 0
);
</%perl>
