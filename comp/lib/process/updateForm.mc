<%doc>
###############################################################################

=head1 NAME

/lib/updateForm.mc


=head1 VERSION

$Revision: 1.6 $

=cut

use Bric; our $VERSION = Bric->VERSION;


=head1 DATE

$Date: 2001/12/04 18:17:39 $

=head1 SYNOPSIS

=head1 DESCRIPTION

Takes an existing form object, and modifies it by inserting a new form element at its designated location.  Untested.

=cut
</%doc>

<%perl>
# get largest position within current form array (sizeof array)
my $formSize = @form;

my @newForm;
my @newField;
my %newField;

if (0) {
# build hash with new form field
if ($args{formElement} eq "text" || $args{formElement} eq "password") {

	@newField = ( 
		type => "password", 
		name => $args{name}, 
		caption => $args{caption},  
		size => $args{size}, 
		maxlength => $args{maxlength}
		);

} elsif ($args{formElement} eq "textarea") {

	@newField = ( 
		type => "textarea", 
		name => $args{name}, 
		caption => $args{caption},  
		rows => $args{rows}, 
		cols => $args{cols},  
		maxlength => $args{maxlength}
		);

} elsif ($args{formElement} eq "select") {

	@newField = ( 
		type => "select", 
		name => $args{name}, 
		caption => $args{caption},  
		size => $args{size} 
	);
	
#	$newField{values} =>  $args{values};
	
} elsif ($args{formElement} eq "pulldown") {

	@newField = ( 
		type => "select", 
		name => $args{name}, 
		caption => $args{caption},  
		size => $args{size} 
	);
##	$newField{values} => split(",", $args{values});
	
} elsif ($args{formElement} eq "radio") {

	@newField = (
		type => "radio", 
		name => $args{name}, 
		caption => $args{caption} 
	);
#	$newField{values} => split(",", $args{values});
	
} elsif ($args{formElement} eq "checkbox") {

	@newField = ( 
		type => "checkbox", 
		name => $args{name}, 
		caption => $args{caption} 
	);

}

#$newField{position} => $args{position};


# evaluate position.  if its in between, slice the array, push, and push again. otherwise just push
if ($args{position} == $formSize) {

	#push(@form, %newField); # this may not be right - form needs to get a pointer to this array as it's $position element

} else {

	# slice and dice - safe to assume I'm off by one in one or more places here
	@newForm = ();
	
	for (my $x = 0; $x < $args{position} - 1 ; $x++) {
		$newForm[$x] = $form[$x];
	}
	 # this may not be right - form needs to get a pointer to this array as it's $position element
	$newForm[$args{position} - 1] = %newField;
	
	for (my $x =  $args{position} - 1; $x < @form ; $x++) {
		$newForm[$x] = $form[$x];
	}
	
}
# save state with new form array

##$obj->setForm(@newForm);

}

return @newForm;

</%perl>

<%args>

@form
%args

</%args>


