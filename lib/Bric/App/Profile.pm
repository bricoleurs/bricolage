package CE::App::Profile;
###############################################################################

=head1 NAME

CE::App::Profile.pm

=head1 VERSION

$Revision: 1.2.2.2 $

=cut

our $VERSION = (qw$Revision: 1.2.2.2 $ )[-1];

=head1 DATE

$Date: 2001-11-06 23:18:32 $

=head1 SYNOPSIS

[Sample usage of the module]

=head1 DESCRIPTION

Interface for updating the fields of an object.

=cut

#==============================================================================#
# Dependencies                         #
#======================================#

#--------------------------------------#
# Standard Dependencies                 

use strict;

#--------------------------------------#
# Programatic Dependencies              
 
# A sample use module.

#==============================================================================#
# Inheritance                          #
#======================================#

#use base qw( CE );

#=============================================================================#
# Function Prototypes and Closures     #
#======================================#

# Put any function prototypes and lexicals to be defined as closures here.

#==============================================================================#
# Constants                            #
#======================================#


#==============================================================================#
# Fields                               #
#======================================#

#--------------------------------------#
# Public Class Fields                   

# Public fields should use 'vars'

#--------------------------------------#
# Private Class Fields                  

# Private fields use 'my'

#--------------------------------------#
# Instance Fields                       
BEGIN {
#    CE::register_fields({});
}

#==============================================================================#

=head1 INTERFACE

=head2 Constructors

=over 4

=cut

=head2 Destructors

=item $self->DESTROY

Dummy method to prevent wasting time trying to AUTOLOAD DESTROY.

=cut

sub DESTROY {
    # This method should be here even if its empty so that we don't waste time
    # making CE's autoload method try to find it.
}

#--------------------------------------#

=head2 Public Class Methods

%values = CE::App::Profile::get_profile($id, $type); - return hash with object fields => {properties hash}
$bool = CE::App::Profile::set_profile($id, $type); returns 1 if object successfully updated, 0 if not

=cut

sub get_profile {

	my ($id, $type, $pkgType, $obj, $methods);
	my %tmpHash;
	$id = shift;
	$type = shift;

	# get translation from object type to CE package
	# $pkgType = getPackageTypeFromDictionary($type);
	$pkgType = "CE::Biz::Person";
	
	# get handle to object.  If necessary, create a new one.
	if ($id ne "add") {
		$obj = $pkgType->lookup({ id => $id });
	} else {	
		$obj = $pkgType->new();
	}
	
	# fetch ref to introspection hash
	$methods = $obj->my_meths; 
	
	# build hash with object properties => values
	foreach my $field (keys %$methods) {
	
		$tmpHash{$field}{disp}  = $methods->{$field}{disp};
		$tmpHash{$field}{len}   = $methods->{$field}{len};
		$tmpHash{$field}{props} = $methods->{$field}{props};
		$tmpHash{$field}{req}   = $methods->{$field}{req};
	
		if ($methods->{$field}{props} eq "select" || $methods->{$field}{props} eq "radio") {
			$tmpHash{$field}{value} = ( $methods->{$field}->{get_meth}->($obj, $methods->{get_args}) ); # force it to be a list
		} else {
			$tmpHash{$field}{value} = $methods->{$field}->{get_meth}->($obj, $methods->{get_args});
		}
	
	}
	
	# send it home.
	return \%tmpHash;
}

sub set_profile {

	my ($widget, $field, $param, $pkgName, $obj, $methods, $id);
	
	$widget = shift;
	$field  = shift;
	$param  = shift;
	$id = $param->{id};
	
	my ($type,$action) = split /_/, $field;

	$pkgName = CE::Util::Class::get_package_name($type); 
	
	if ($id ne "add") {
		$obj = $pkgName->lookup({id => $id});
	} else {
		$obj = $pkgName->new(); # how many objects require something for their constructor? hmm.
		$obj->save();
		$id = $obj->get_id;
	}
	
	$methods = $obj->my_meths; # returns ref to hash
	
	# call set method if both the method and the field exist in the object
	foreach my $field (keys %$param) {
	
		if ( $methods->{$field} ) {  # in other words, if the field is known and has a set method
			if ( $methods->{$field}{set_meth} ) {		
				$methods->{$field}->{set_meth}->($obj, $param->{$field});
			}
		} else {
			# set new attribute ?
		}
	
	}
	
	# put it back on the shelf
	$obj->save();
	
	return 1;
}





# Add methods here that do not require an object be instantiated to call them.
# Use same POD comment style as above for 'new'.

#--------------------------------------#

=head2 Public Instance Methods

=cut



# Add methods here that only apply to an instantiated object of this class.
# Use same POD comment style as above for 'new'.

#------------------------------------------------------------------------------#

=head1 PRIVATE

=cut

#--------------------------------------#

=head2 Private Class Methods

=cut


# Add methods here that do not require an object be instantiated, and should not
# be called outside this module (e.g. utility functions for class methods).
# Use same POD comment style as above for 'new'.

#--------------------------------------#

=head2 Private Instance Methods

=cut

# Add methods here that apply to an instantiated object, but should not be
# called directly. Use same POD comment style as above for 'new'.

#--------------------------------------#

=head2 Private Functions

=cut

# Add functions here that can be used only internally to the class. They should
# not be publicly available (hence the prefernce for closures). Use the same POD
# comment style as above for 'new'.

1;
__END__

=back

=head1 NOTES

=head1 AUTHOR

dave@creationengines.com

=head1 SEE ALSO

[Mention resources, related modules, etc]

=cut