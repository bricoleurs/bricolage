<%once>;
my $type = 'element';
my $disp_name = get_disp_name($type);
my %meta_props = ( disp => 'fb_disp',
		   value => 'fb_value',
		   props_type => 'fb_type',
		   props_length => 'fb_length',
		   props_maxlength => 'fb_maxlength',
		   props_rows => 'fb_rows',
		   props_cols => 'fb_cols',
		   props_multiple => 'fb_allowMultiple',
		   props_vals => 'fb_vals',
		   props_pos => 'fb_position'
		 );
</%once>

<%args>
$widget
$param
$field
$obj
</%args>

<%perl>;

return unless $field eq "$widget|addElement_cb" ||
  $field eq "$widget|doRedirect_cb";

my $comp = $obj;

# switch on $field
if ($field eq "$widget|addElement_cb") {

    my @elements = (ref $param->{"$widget|addElement_cb"} eq "ARRAY" )
      ? $param->{"$widget|addElement_cb"}
      : [ $param->{"$widget|addElement_cb"} ];
    # add element to object using id(s)
    $comp->add_containers( @elements );
    $comp->save;
} elsif ($field eq "$widget|doRedirect_cb") {
    set_redirect('/admin/profile/element/'. $param->{element_id} );
}

return $comp;

</%perl>
<%doc>
###############################################################################

=head1 NAME

/widgets/profile/contrib_type.mc - Processes submits from element Profile

=head1 VERSION

$Revision: 1.6 $

=head1 DATE

$Date: 2002-08-30 17:05:24 $

=head1 SYNOPSIS

  $m->comp('/widgets/formBuilder/element.mc', %ARGS);

=head1 DESCRIPTION

This element is called by /widgets/profile/callback.mc when the data to be
processed was submitted from the element Profile page.

</%doc>
