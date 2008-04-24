<%doc>
###############################################################################

=head1 NAME

=head1 SYNOPSIS

  $m->comp("/widgets/profile/date.mc",
           disp      => ''
           value     => ''
           name     => ''
           length    => ''
           maxlength => ''
           js        => ''
           width     => ''
           indent    => ''
  );

=head1 DESCRIPTION

Easier to use wrapper for displayFormElement.mc

=cut

</%doc>
<%args>
$disp      => ''
$value     => ''
$name      => ''
$length    => ''
$size      => ''
$maxlength => ''
$js        => ''
$req       => 0
$width     => ''
$indent    => ''
$useTable  => 1
$readOnly  => 0
$localize  => 1
$precision => MINUTE
</%args>
<%perl>;
my $vals = {
            disp      => $disp,
            value     => $value,
            props     => { type      => 'date',
                           precision => $precision,
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
         readOnly  => $readOnly
);
</%perl>
