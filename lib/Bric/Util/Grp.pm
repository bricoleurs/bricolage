package Bric::Util::Grp;
###############################################################################

=head1 NAME

Bric::Util::Grp - A Class for associating Objects 

=head1 VERSION

$Revision: 1.1.1.1.2.2 $

=cut

our $VERSION = (qw$Revision: 1.1.1.1.2.2 $ )[-1];

=head1 DATE

$Date: 2001-11-06 23:18:34 $

=head1 SYNOPSIS

 # Creation of Objects
 $grp = Bric::Util::Grp->new( $init );
 $grp = Bric::Util::Grp->lookup( { id => $id } )
 (@grps || $grp_list) = Bric::Util::Grp->list( $params )

 # List of object ids
 (@g_ids || $g_ids) = Bric::Util::Grp->list_ids( $params )

 # Manipulation of Grp Name
 $grp = $grp->set_name( $name )
 $name = $grp->get_name()

 # Manipulation of Description Field
 $grp = $grp->set_description()
 $desc = $grp->get_description()

 # Return the class of the Grp
 $class_id = $grp->get_class_id()

 # the id of the parent Grp
 $parent_id = $grp->get_parent_id()
 $grp = $grp->set_parent_id()

 # the id of this grp
 $id = $grp->get_id()

 # manipulation of the member objects
 $grp = $grp->add_members( [$obj || { type => $type, id => $id}] )
 (@members || $member_aref) = $grp->get_members()
 $grp = $grp->delete_members([$obj || $member || {type=> $t,id=> $id}])
 ($member || undef) = $grp->has_member(($obj||{type =>$t, id =>$id},$attr) 

 # mainipulation of attributes assigned to members
 (@vals || $val_aref) = $grp->get_member_attrs( [ { name => $name } ])
 $group = $grp->set_member_attrs([ { name => $name, value => $value } ] )

 # mainpulation of attributes assignes to the grp
 (@vals || $val_aref) = $grp->get_grp_attrs( [ $name ] )
 $success = $grp->set_grp_attrs([ {name => $name, value => $value }])

 # save the changes to the database
 $group = $grp->save()

=head1 DESCRIPTION

Grp is a class that associates Objects together.   These can be
assigned Attributes as a group or to the member class which will 
allow attributes to be set on an object in association with a group.

The class is called Grp because group is a reserved oracle word.   So for
the sake of consistancy throughout the class is called grp.

=cut

#==============================================================================#
# Dependencies                         #
#======================================#

#--------------------------------------#
# Standard Dependencies                 

use strict;

#--------------------------------------#
# Programatic Dependencies              
use Bric::Config qw(:admin);
use Bric::Util::DBI qw(:all);
use Bric::Util::Grp::Parts::Member;
use Bric::Util::Attribute::Grp;
use Bric::Util::Fault::Exception::GEN;
use Bric::Util::Class;

use Data::Dumper;

#==============================================================================#
# Inheritance                          #
#======================================#

# The parent module should have a 'use' line if you need to import from it.
# use Bric;
use base qw(Bric);

#=============================================================================#
# Function Prototypes                  #
#======================================#

#NONE

#==============================================================================#
# Constants                            #
#======================================#

use constant DEBUG => 0;

use constant GRP_SUBSYS => '_GRP_SUBSYS';
use constant MEMBER_SUBSYS => Bric::Util::Grp::Parts::Member::MEMBER_SUBSYS;

use constant TABLE => 'grp';
use constant COLS => qw(parent_id class__id name description 
						secret permanent active);
use constant FIELDS => qw(parent_id class_id name description 
						secret permanent _active);
use constant ORD => qw(name description parent_id class_id member_type active);

use constant INSTANCE_GROUP_ID => 35;
use constant GROUP_PACKAGE => 'Bric::Util::Grp::Grp';

#==============================================================================#
# Fields                               #
#======================================#

#--------------------------------------#
# Public Class Fields                   

# Public fields should use 'vars'
#use vars qw();

#--------------------------------------#
# Private Class Fields                  

# Private fields use 'my'
my ($meths, $class, $mem_class);

#--------------------------------------#
# Instance Fields                       

# NONE

# This method of Bricolage will call 'use fields' for you and set some permissions.
BEGIN {
    Bric::register_fields({
			# Public Fields

			# The Name of the group
			'name'				=> Bric::FIELD_RDWR,

			# the human readable description field
			'description'		=> Bric::FIELD_RDWR,

			# The database id field
			'id'				=> Bric::FIELD_READ,

			# The id from the class table
			'class_id'			=> Bric::FIELD_READ,

			# The parent id ( if any )
			'parent_id'			=> Bric::FIELD_RDWR,
			'secret'			=> Bric::FIELD_READ,
			'permanent'			=> Bric::FIELD_READ,

			# Private Fields

			# A List of Member Objects			
			'_members'			=> Bric::FIELD_NONE,

			'_del_members'		=> Bric::FIELD_NONE,

			# Delete me after Changes
			'_meta_store'		=> Bric::FIELD_NONE,

			'_new_members'		=> Bric::FIELD_NONE,

			# flag that states if the member object has
			# been _queried yet
			'_queried'			=> Bric::FIELD_NONE,

			'_update_members'     => Bric::FIELD_NONE,

			# the parent group object
			'_parent_obj'		=> Bric::FIELD_NONE,

			# The attribute object
			'_attr_obj'			=> Bric::FIELD_NONE,	

			# Storage for attribute information before we can get
			# an attribute object
			# attributes
			'_attr_cache'		=> Bric::FIELD_NONE,

			# meta information about the attributes
			'_meta_cache'		=> Bric::FIELD_NONE,

			# flag to update attrs come save time
			'_update_attrs'		=> Bric::FIELD_NONE,

			'_parents'			=> Bric::FIELD_NONE,

			'_active'			=> Bric::FIELD_NONE

	});	
}

# This runs after this package has compiled, but before the program runs.

CHECK { use Bric::Util::Grp::Grp }
#==============================================================================#
# Interface Methods                    #
#======================================#

=head1 INTERFACE

=head2 Constructors

=over 4

=cut

#--------------------------------------#
# Constructors                          

#------------------------------------------------------------------------------#

=item $group = Bric::Util::Grp->new( $initial_state )

This will create a new group object with optional initial state.

Supported Keys:

=over 4

=item *

name

=item *

description

=back

B<Throws:>
NONE

B<Side Effects:>
NONE

B<Notes:>
NONE

=cut

sub new {
	my ($self, $init) = @_;

	$self = bless {}, $self unless ref $self;

	$init->{'_active'} = exists $init->{'active'} ? 0 : 1;
	$init->{'permanent'} = exists $init->{'permanent'} ? 1 : 0;

	$self->_set({ 'secret' => $self->get_secret(),
					'class_id' => $self->get_class_id() });
	# pass the defined initial state to the super's new method 
	# this should set them in register fields
	$self->SUPER::new($init);

	$self->_set({ '_queried' => 1} );

	return $self;

}



=item $group = Bric::Util::Grp->lookup( { id => $id } )

This will lookup an existing group based on the given id.

B<Throws:>

NONE 

B<Side Effects:>

NONE 

B<Notes:>

If COLS var changes index of class id must change

=cut

sub lookup {
	my ($class, $params) = @_;

	# Make sure proper arguments have been passed 
	die Bric::Util::Fault::Exception::GEN->new( 
		{ msg => "Missing Required Parameter 'id' " })
		unless defined $params->{'id'};

	# Populate from database 
	my $ret = _select_group('id=?', $params->{'id'});

	# return undef if nothing found
	return unless $ret;
				
	# Determine if this was called on the Bric::Util::Grp class
	# or one of its sub classes
	my $bless_class;
	if ($class->get_class_id() == $ret->[0]->[2]) {
		# called on one of the subclasses bless this class
		$bless_class = $class;
	} else {
		# called on Bric::Util::Grp::Subclass
		# determine the class
		my $c_obj = Bric::Util::Class->lookup({ id => $ret->[0]->[2] });
		$bless_class = $c_obj->get_pkg_name();
		eval " require $bless_class ";
	}

	my $self = bless {}, $bless_class;

	$self->_set( [ 'id', FIELDS], $ret->[0]);

	$self->SUPER::new();

	# clear the dirty bit
	$self->_set__dirty(0);

	# Return the object
	return $self;
}

=item (@groups || $group_aref) = Bric::Util::Grp->list( $criteria )

Given the criteria this will return a list or a list ref of objects
that match.

Supported Keys:

=over 4

=item *

name

=item * 

obj

=item * 

parent_id

=back

B<Throws:>

NONE 

B<Side Effects:>

NONE 

B<Notes:>

NONE 

=cut

sub list {
	my ($class, $params) = @_;

	# Send to _do_list function which will return objects
	_do_list($class,$params,undef);

}

=over

=item my (%class_keys || $class_keys_href) = Bric::Util::Grp->href_grp_class_keys

=item my (%class_keys || $class_keys_href) = Bric::Util::Grp->href_grp_class_keys(1)

Returns an anonymous hash representing the subclasses of Bric::Util::Grp. The hash
keys are the key_names of those classes, and the hash values are their plural
display names. By default, it will return only those classes whose group
instances are not secret. To get B<all> group subclasses, pass in a true value.

B<Throws:>

=over 4

=item *

Unable to prepare SQL statement.

=item *

Unable to connect to database.

=item *

Unable to execute SQL statement.

=item *

Unable to bind to columns to statement handle.

=item *

Unable to fetch row from statement handle.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

my $class_keys;
my $all_class_keys;
sub href_grp_class_keys {
    my ($pkg, $all) = @_;
    unless ($class_keys) {
	my $sel = prepare_c(qq{
            SELECT key_name, plural_name, pkg_name
            FROM   class
            WHERE  id in (
                       SELECT DISTINCT class__id
                       FROM   grp
                   )
        });
	execute($sel);
	my ($key, $name, $pkg_name);
	bind_columns($sel, \$key, \$name, \$pkg_name);
	while (fetch($sel)) {
	    next if $key eq 'ce';
	    $all_class_keys->{$key} = $name;
	    eval "require $pkg_name";
	    $class_keys->{$key} = $name unless $pkg_name->get_secret;
	}
    }
    my $ret = $all ? $all_class_keys : $class_keys;
    return wantarray ? %$ret : $ret;
}

=back

#--------------------------------------#

=head2 Destructors

=item $self->DESTROY

Dummy method to prevent wasting time trying to AUTOLOAD DESTROY

=cut                           

sub DESTROY {
    # This method should be here even if its empty so that we don't waste time
    # making Bricolage's autoload method try to find it.
}

#--------------------------------------#

=head2 Public Class Methods                  

=cut

=item $class_id = Bric::Util::Grp->get_class_id()

This will return the class id that this group is associated with
it should have an id that maps to the class object instance that is
associated with the class of the grp ie Bric::Util::Grp::AssetVersion


B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

Overwite this in your sub classes

=cut

sub get_class_id {
	return 6;
}

=item $supported_classes = Bric::Util::Grp->get_supported_classes()

This will return a has_ref of the supported classes in the group as 
keys with the short name as a value.   The short name is used to construct 
the member table names and the foreign key in the table

B<Throws:>

"Method not implemented"

B<Side Effects:>

NONE

B<Notes:>

Overwite this in your sub classes

=cut

sub get_supported_classes {
	return undef;
}	

=item (1 || undef) = Bric::Util::Grp->get_secret()

This will determine if this is an end user manageable group or not
the default is that it is not.   Override in your sub class if it is.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_secret {
	return 1;
	# or 0 if it is not
}

################################################################################

=item my $class = Bric::Util::Grp::ElementType->my_class()

Returns a Bric::Util::Class object describing this class.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> Uses Bric::Util::Class->lookup() internally.

=cut

sub my_class {
    $class ||= Bric::Util::Class->lookup({ id => 6 });
    return $class;
}

################################################################################

=item my $class = Bric::Util::Grp::ElementType->member_class()

Returns a Bric::Util::Class object describing the members of this group.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> Uses Bric::Util::Class->lookup() internally.

=cut

sub member_class {
    $mem_class ||= Bric::Util::Class->lookup({ id => 0 });
    return $mem_class;
}

################################################################################

=item ($id_list || @ids) = Bric::Util::Grp->list_ids( $criteria )

This returns a list of ids that match the defined criteria

Supported Keys:

=over 4

=item *

name

=back

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub list_ids {
	my ($class, $criteria) = @_;

	# send to _do_list which will return the ids
	_do_list($class,$criteria,1);
}

=item (1 || undef) Bric::Util::Grp->can_get_member_ids()

Overwrite this in your sub classes if you wish to use the get_member_ids
feature

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

I can not remember why this is here, find out

=cut

sub can_get_member_ids {

	return 1;
}

=item $obj_class_id = Bric::Util::Grp->get_object_class_id();

Forces all members to be considered as being of this class if supported

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_object_class_id {
	return undef;
}

=item ($member_ids || @member_ids) = Bric::Util::Grp->get_member_ids($grp_id)

Returns a list of the object ids that are members of this group

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_member_ids {
	my ($class, $grp_id) = @_;

	# going to assume that there is onle one class here because otherwise
	# allowing this method would be daft!
	my $sc = $class->get_supported_classes();

	my $short = (values %$sc)[-1];

	my $ids = Bric::Util::Grp::Parts::Member->get_all_object_ids($grp_id, $short);

	return wantarray ? @$ids : $ids;
}

=item my $meths = Bric::Util::Grp->my_meths

=item my (@meths || $meths_aref) = Bric::Util::Grp->my_meths(TRUE)

Returns an anonymous hash of instrospection data for this object. If called with
a true argument, it will return an ordered list or anonymous array of
intrspection data. The format for each introspection item introspection is as
follows:

Each hash key is the name of a property or attribute of the object. The value
for a hash key is another anonymous hash containing the following keys:

=over 4

=item *

name - The name of the property or attribute. Is the same as the hash key when
an anonymous hash is returned.

=item *

disp - The display name of the property or attribute.

=item *

get_meth - A reference to the method that will retrieve the value of the
property or attribute.

=item *

get_args - An anonymous array of arguments to pass to a call to get_meth in
order to retrieve the value of the property or attribute.

=item *

set_meth - A reference to the method that will set the value of the
property or attribute.

=item *

set_args - An anonymous array of arguments to pass to a call to set_meth in
order to set the value of the property or attribute.

=item *

type - The type of value the property or attribute contains. There are only
three types:

=over 4

=item short

=item date

=item blob

=back

=item *

len - If the value is a 'short' value, this hash key contains the length of the
field.

=item *

search - The property is searchable via the list() and list_ids() methods.

=item *

req - The property or attribute is required.

=item *

props - An anonymous hash of properties used to display the property or attribute.
Possible keys include:

=over 4

=item *

type - The display field type. Possible values are

=item text

=item textarea

=item password

=item hidden

=item radio

=item checkbox

=item select

=back

=item *

length - The Length, in letters, to display a text or password field.

=item *

maxlength - The maximum length of the property or value - usually defined by the
SQL DDL.

=item *

rows - The number of rows to format in a textarea field.

=item

cols - The number of columns to format in a textarea field.

=item *

vals - An anonymous hash of key/value pairs reprsenting the values and display
names to use in a select list.

=back

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub my_meths {
    my ($pkg, $ord) = @_;

    # Return 'em if we got em.
    return !$ord ? $meths : wantarray ? @{$meths}{&ORD} : [@{$meths}{&ORD}]
      if $meths;

    # We don't got 'em. So get 'em!
    $meths = {
	      name        => {
			      name     => 'name',
			      get_meth => sub { shift->get_name(@_) },
			      get_args => [],
			      set_meth => sub { shift->set_name(@_) },
			      set_args => [],
			      disp     => 'Name',
			      type     => 'short',
			      len      => 64,
			      req      => 1,
			      search   => 1,
			      props    => { type       => 'text',
					    length     => 32,
					    maxlength => 64
					  }
			     },
	      description => {
			      get_meth => sub { shift->get_description(@_) },
			      get_args => [],
			      set_meth => sub { shift->set_description(@_) },
			      set_args => [],
			      name     => 'description',
			      disp     => 'Description',
			      len      => 256,
			      req      => 0,
			      type     => 'short',
			      props    => { type => 'textarea',
					    cols => 40,
					    rows => 4
					  }
			     },
	      parent_id   => {
			      name     => 'parent_id',
			      get_meth => sub { shift->get_parent_id(@_) },
			      get_args => [],
			      set_meth => sub { shift->set_parent_id(@_) },
			      set_args => [],
			      disp => 'Parent ID',
			      type     => 'short',
			      len      => 10,
			      req      => 0,
			      props    => { type      => 'text',
					    length    => 10,
					    maxlength => 10
					  }
			     },
	      class_id    => {
			      name     => 'class_id',
			      get_meth => sub { shift->get_class_id(@_) },
			      get_args => [],
			      disp => 'Class ID',
			      len      => 10,
			      req      => 1,
			     },
	      member_type => {
			      name     => 'member_type',
			      get_meth => sub { shift->member_class->get_disp_name(@_) },
			      get_args => [],
			      disp => 'Member Type'
			     },
	      active      => {
			      name     => 'active',
			      get_meth => sub { shift->is_active(@_) ? 1 : 0 },
			      get_args => [],
			      set_meth => sub { $_[1] ? shift->activate(@_)
						  : shift->deactivate(@_) },
			      set_args => [],
			      disp     => 'Active',
			      len      => 1,
			      req      => 1,
			      type     => 'short',
			      props    => { type => 'checkbox' }
			     }
	     };
    return !$ord ? $meths : wantarray ? @{$meths}{&ORD} : [@{$meths}{&ORD}];
}

=back

=head2 Public Instance Methods

=item (@parents || $parents) = $grp->get_all_parents()

Returns a list of all of this groups parents

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

Remember if this returns an assending or descending list

=cut

sub get_all_parents {
    my ($self) = @_;
    my $dirty = $self->_get__dirty;
    my $parents = $self->_get('_parents');

    unless ($parents) {
	push @$parents, $self->_get('parent_id');
	push @$parents, $self->_get_all_parents($self->_get('parent_id','id'));

	$self->_set(['_parents'], [$parents]);
	
	# This is a set that does not need to be saved in 'save'
	$self->_set__dirty($dirty);
    }

    return wantarray ? @$parents : $parents;
}
	

=item $name = $group->get_name( )

Returns the name that has been given to the group

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut



=item $group = $group->set_name( $name )

sets the name to the given name

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut



=item $desc = $group->get_description( )

Returns the description that was given to the group 

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut



=item $group = $group->set_description( $desc )

Sets the description to the given argument

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut



=item $group = $group->set_parent_id( $parent_id )

Sets the id for the parent of this group

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut


=item $group->get_parent_id( $parent_id )

Returns the id of this groups parent, undef if it is the top level

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut


=item $id = $group->get_id()

Returns the database id of the group object

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

This will return undef if the id has yet to be defined, so if you call
get_id before the group is saved, there there will be none

=cut

=item $member = $group->add_member( $param );

Adds an object to the group.   If attributes are passed as a list
it will associate them to the member

B<Throws:>

"Required Args 'obj' or 'id' and 'package' not passed"

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub add_member {
    my ($self, $param ) = @_;
    my $dirty   = $self->_get__dirty;
    my $members = $self->_get_members();

    # get the package and ids
    my ($package, $id);
    if ($param->{'obj'}) {
	$package = ref $param->{'obj'};
	$id      = $param->{'obj'}->get_id();
    } elsif ($param->{'id'} && $param->{'package'}) {
	$package = $param->{'package'};
	$id      = $param->{'id'};
    } else {
	my $msg = "Required Args 'obj' or 'id' and 'package' not passed";
	die Bric::Util::Fault::Exception::GEN->new({msg => $msg});
    }
	
    # see if the object is already a member
    return $self if exists $members->{$package}->{$id};

    # make sure that we can add these kinds of objects to the group
    my $supported = $self->get_supported_classes();
    if ($supported && (not exists $supported->{$package})) {
	my $msg = "Object of Package $package not allowed in Group";
	die Bric::Util::Fault::Exception::GEN->new({msg => $msg});
    }
	
    # Create a new member object for this object.
    my $member = Bric::Util::Grp::Parts::Member->new(
		 {
		  object          => $param->{'obj'},
		  obj_id          => $id,
		  object_class_id => $self->get_object_class_id(),
		  object_package  => $package,
		  group           => $self
		 });

    # see if any attributes were passed in
    $member->set_attrs($param->{attrs}) if $param->{'attrs'};

    # Add this member to the hash of members.
    $members->{$package}->{$id} = $member;

    # set the new member data structure
    $self->_set(['_members', '_update_members'], [$members, 1]);

    # This doesn't warrant an object update.
    $self->_set__dirty($dirty);

    return $member;
}


=item $group = $group->add_members(
	[{obj => $obj, attr => $attributes }]); 

Takes a list of hash refs with the keys ob obj which has a value of the 
object (or its unique identifiers) and attr which will be the attributes that
are placed on the member object.   This will add the object to the group.

Supported Keys:

=over4

=item *

obj

=item *

class_id

=item *

obj_id

=item *

attr

=back

B<Throws:>

"improper args have been passed to add_members"

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub add_members {
	my ($self, $param) = @_;

	foreach (@{ $param } ) {
		# send to $self->add_member

		$self->add_member($_);
	}

	return $self;
}


=item (@members || $member_aref) = $group->get_members();

Returns a list or a list ref of the member objects that are in the group

B<Throws:>

NONE 

B<Side Effects:>

NONE 

B<Notes:>

NONE

=cut

sub get_members {
	my ($self) = @_;

	my $members = $self->_get_members();

	my @member_objects;
	foreach my $package (keys %{ $members }) {
		foreach (keys %{ $members->{$package} } ) {
			push @member_objects, $members->{$package}->{$_};
		}
	}

	return wantarray ? @member_objects : \@member_objects;
}

=item get_objects {

returns the objects instead of the member objects

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_objects {
	my ($self) = @_;

	my $members = $self->_get_members();

	my @objects;
	foreach my $package (keys %{ $members }) {
		foreach (keys %{ $members->{$package} } ) {
			push @objects, $members->{$package}->{$_}->get_object();
		}
	}

	return wantarray ? @objects : \@objects;
}

=item $group = $group->delete_member($param);

removes a member from the group

B<Throws:>

NONE

B<Side Effects:>

NONE

<Notes:>

NONE

=cut

sub delete_member {
    my ($self, $param) = @_;
    my $dirty          = $self->_get__dirty;
    my $members        = $self->_get_members();
    my $delete_members = $self->_get('_delete_members');

    # see if they have passed a member object
    my ($id, $package);
    if (substr(ref $param, 0, 28) eq 'Bric::Util::Grp::Parts::Member') {
	# Member Object has been passed
	$id      = $param->get_obj_id();
	$package = $param->get_object_package();
    } elsif (ref $param eq 'HASH') {
	# package and id args have been passed
	my $msg = "Improper args for delete member";
	die Bric::Util::Fault::Exception::GEN->new({msg => $msg}) 
	  unless ($param->{'id'} && $param->{'package'});
	
	$id      = $param->{'id'};
	$package = $param->{'package'};
    } else {
	# object has been passed
	$id      = $param->get_id();
	$package = ref $param;
    }
    my $member_object = $members->{$package}->{$id};

    # object is not a member of the group; silently allow it to pass
    return $self unless $member_object;

    $member_object->remove();

    # add to delete list
    push @$delete_members, $member_object;

    delete $members->{$package}->{$id};

    $self->_set(['_members', '_delete_members', '_update_members'],
		[$members,   $delete_members,   1]);

    # This doesn't warrant an object update.
    $self->_set__dirty($dirty);

    return $self;
}

=item $success = $self->delete_members($members);

Takes a lsit of objects or their unique identifiers ard removes them from the
group.   This will delete them, call deactivate on the member objects 
if that is your desire

B<Throws:>
NONE 

B<Side Effects:>
Will delete members for the database ( ie. not make them inactive)

B<Notes:>
NONE

=cut

sub delete_members {
	my ($self, $param) = @_;

	foreach ( @$param ) {
		$self->delete_member($_);
	}

	return $self;
}


=item ($member || undef) = $group->has_member( $obj,  $attr);

Responds with the member object if object is a member or undef otherwise

B<Throws:>

NONE 

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut


sub has_member {
    my ($self, $obj, $attr) = @_;
    my ($package, $id) = (ref $obj, $obj->get_id);
    my $members        = $self->_get_members();
    my $mem            = $members->{$package}->{$id};

    # Return if this member doesn't exist.
    return unless $mem;
    # Return the member only if it has the attributes in $attr
    return $mem->has_attrs($attr) if $attr;
    # Otherwise just return the member.
    return $mem;
}

=item $group = $group->set_member_attr($param)

Sets an individual attribute for the members of this group

B<Throws:>

NONE 

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub set_member_attr {
    my ($self, $param) = @_;

    # set a default subsys if one has not been passed
    $param->{'subsys'}   ||= MEMBER_SUBSYS;
	
    # set the sql_type as short if it was not passed in
    $param->{'sql_type'} ||= 'short';

    # set attribute
    $self->_set_attr($param);

    return $self;
}

################################################################################

=item $group = $group->delete_member_attr($param)

Deletes attributes that apply to members

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub delete_member_attr {
    my ($self, $param) = @_;

    # set a default subsys if one has not been passed
    $param->{'subsys'} ||= MEMBER_SUBSYS;

    $self->_delete_attr($param,1);

    return $self;
}

################################################################################


=item $group = $group->set_member_attrs(
	[ { name => $name, subsys => $subsys, value => $value, 
		sql_type =>$sql_type, new => 1 } ] )

Takes a list of attributes and sets them to apply to the members

B<Throws:>

NONE 

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub set_member_attrs {
    my ($self, $attrs) = @_;

    foreach (@$attrs) {
	# set to the member defualt unless passed in
	$_->{'subsys'}   ||= MEMBER_SUBSYS;

	# set a default sql type
	$_->{'sql_type'} ||= 'short';

	# set the attr
	$self->_set_attr($_);
    }

    return $self;
}

=item $group = $group->set_member_meta($param)

Sets meta information on member attributes

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut


sub set_member_meta {
    my ($self, $param) = @_;

    # set a defualt member subsys unless one was passed in
    $param->{'subsys'} ||= MEMBER_SUBSYS;

    # set the meta info
    $self->_set_meta($param);

    return $self;
}


=item $meta = $group->get_member_meta($param)

Returns the member meta attributes

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut


sub get_member_meta {
    my ($self, $param) = @_;

    # set defualt subsys unless one was passed in
    $param->{'subsys'} ||= MEMBER_SUBSYS;

    # get the meta info pass the flag to return parental defaults
    my $meta = $self->_get_meta($param, 1);

    return $meta;
}

################################################################################

=item $group = $group->delete_member_meta()

Deletes the meta information for these attributes.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub delete_member_meta {
    my ($self, $param) = @_;

    # set defualt subsys unless one was passed in
    $param->{'subsys'} ||= MEMBER_SUBSYS;

    $self->_delete_meta($param, 1);

    return $self;
}

################################################################################


=item $attrs = $grp->all_for_member_subsys( $subsys )

Returns all the attrs as a hashref for a given member subsystem

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub all_for_member_subsys {
	my ($self, $subsys) = @_;

	my $all;

	# get all the attrs for this subsystem
	my $attr = $self->get_member_attr_hash({'subsys' => $subsys});

	# now get the meta for all the attributes
	foreach my $name (keys %$attr) {
		# call the get meta function for this name
		my $meta = $self->get_member_meta({	
			'subsys' => $subsys,
			'name'   => $name
			});
		# add it to the return data structure
		$all->{$name} = {	
			'value' => $attr->{$name},
			'meta'  => $meta
			};
	}

	return $all;
}


=item $attr = $group->get_member_attr($param)

Returns an individual attribute for given parameters

B<Throws:>

NONE 

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_member_attr {
    my ($self, $param) = @_;

    # set a defualt subsystem if none was passed
    $param->{'subsys'} ||= MEMBER_SUBSYS;

    # get the value
    my $val = $self->_get_attr($param);

    return $val;
}


=item $hash = $group->get_member_attr_hash( $param )

Returns a hash of the attributes for a given subsys

B<Throws:>

NONE 

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_member_attr_hash {
    my ($self, $param) = @_;

    # add a default subsys if none was passed
    $param->{'subsys'} ||= MEMBER_SUBSYS;

    my $attrs = $self->_get_attr_hash($param, 1);

    return $attrs;
}

=item (@vals || $val_aref) = $group->get_member_attrs( $param )

Retrieves the value of the attribute that has been assigned as a default
for members that has the given name and subsystem

B<Throws:>

NONE 

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut


sub get_member_attrs {
	my ($self, $param) = @_;

	# return values
	my @values;
	foreach (@$param) {
		# set a defualt subsystem if one was not passed in
		$_->{'subsys'} ||= GRP_SUBSYS;

		# push the value onto the return array
		# check the parent for defualts
		push @values, $self->_get_attr($_, 1);
	}

	return wantarray ? @values : \@values;
}



=item (@vals || $val_aref) = $group->get_group_attrs( [ $param ])

Get attributes that describe the group but do not apply to members.
This retrieves the value in the attribute object from a special subsystem 
which contains these.   This will be returned as a list of values

B<Throws:>

NONE 

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_group_attrs {
	my ($self, $param) = @_;

	my @values;

	foreach (@$param) {
		# set the subsystem for group attrs
		$_->{'subsys'} = GRP_SUBSYS;

		# push the return value onto the return array
		# check parents as well
		push @values, $self->_get_attr( $_, 1 );
	}
	return wantarray ? @values : \@values;
}

=item $group = $group->set_group_attr( $param )

Sets a single attribute on this group

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub set_group_attr {
	my ($self, $param) = @_;

	# set the subsystem to the special group subsystem
	$param->{'subsys'} = GRP_SUBSYS;

	# allow a default sql type as convience
	$param->{'sql_type'} ||= 'short';

	# send to the internal method that will do the bulk of the work
	$self->_set_attr( $param );

	return $self;
}

=item $attr = $group->get_group_attr( $param )

Returns a single attribute that pretains to the group

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_group_attr {
	my ($self, $param) = @_;

	# set the group subsys
	$param->{'subsys'} = GRP_SUBSYS;

	# set a default sql type in case one has not been passed
	$param->{'sql_type'} ||= 'short';

	# return result from internal method
	# pass a flag to check the parent for attributes as well
	my $attr = $self->_get_attr( $param, 1 );

	return $attr;
}

################################################################################

=item $group = $group->delete_group_attr()

Deletes the attributes from the group

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub delete_group_attr {
	my ($self, $param) = @_;

	# set the group subsys
	$param->{'subsys'} = GRP_SUBSYS;

	$self->_delete_attr($param);

	return $self;
}

################################################################################

=item $group = $group->set_group_attrs([ $param ])

Sets attributes that describe the group but do not apply to members.
This sets the value in the attribute object to a special subsystem 
which contains these

B<Throws:>

NONE 

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut


sub set_group_attrs {
	my ($self, $param) = @_;

	foreach (@$param) {
		# set the group subsystem
		$_->{'subsys'} = GRP_SUBSYS;

		# set a default sql_type if one is not already there
		$_->{'sql_type'} ||= 'short';

		$self->_set_attr( $_ );
	}

	return $self;
}

=item $group = $group->set_group_meta($meta)

Sets meta information on group attributes

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub set_group_meta {
	my ($self, $param) = @_;

	# set the subsystem for groups
	$param->{'subsys'} = GRP_SUBSYS;

	# set the meta info
	$self->_set_meta( $param );

	return $self;
}

=item $meta = $grp->get_group_meta($param)

Returns group meta information

B<Throws:>

NONE

B<Side Effects:>

NONE

B<notes:>

NONE

=cut

sub get_group_meta {
	my ($self, $param) = @_;

	# set the subsystem for groups
	$param->{'subsys'} = GRP_SUBSYS;

	# get the meta info to return
	my $meta = $self->_get_meta( $param, 1);

	return $meta;
}

################################################################################

=item $group = $group->delete_group_meta($param)

deletes meta information that pretains to this here group.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub delete_group_meta {
	my ($self, $param) = @_;

	# set the subsystem for groups
	$param->{'subsys'} = GRP_SUBSYS;

	$self->_delete_meta($param);

	return $self;
}

################################################################################

=item $attr_hash = $group->get_group_attr_hash()

Returns all of the group attrs as a hash ref

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_group_attr_hash {
	my ($self) = @_;

	# args to pass to _get_attr_hash 
	my $param->{'subsys'} = GRP_SUBSYS;

	my $attrs = $self->_get_attr_hash($param, 1);

	return $attrs;
}

=item $attrs = $group->all_for_group_subsys()

Returns all the attributes and their meta information for the 
group subsys 

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub all_for_group_subsys {
	my ($self) = @_;

	my $all;

	# get all the attributes
	my $attr = $self->get_group_attr_hash();

	foreach my $name (keys %$attr) {
		# get the meta information
		my $meta = $self->_get_meta({
			'subsys' => GRP_SUBSYS,
			'name'   => $name
			});
		# add it to the return data structure
		$all->{$name} = {
			'value' => $attr->{$name},
			'meta'  => $meta
			};
	}

	return $all;
}

=item $grp = $grp->activate()

Sets the active flag for the object

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub activate {
    my $self = shift;

    $self->_set( { '_active' => 1 } );

    return $self;
}

=item $grp = $grp->deactivate()

Sets the active flag to inactive

B<Throws:>

=over 4

=item *

Cannot permanent group.

=back

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub deactivate {
    my $self = shift;
    my ($id, $perm) = $self->_get(qw(id permanent));
	if ($perm || $id == ADMIN_GRP_ID) {
	    die Bric::Util::Fault::Exception::GEN->new({
	      msg => 'Cannot deactivate permanent group.' });
	}

    $self->_set( { '_active' => 0 } );

    return $self;
}

=item ($grp || undef) = $grp->is_active()

Returns self if the object is active undef otherwise

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub is_active {
    my $self = shift;

    return $self->_get('_active') ? $self : undef;
}


=item $group = $group->save()

Updates the database to reflect the changes made to the object

B<Throws:>

NONE 

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub save {
    my ($self) = @_;

    # Don't save unless the object has changed.
    if ($self->_get__dirty) {
	if ($self->_get('id')) {
	    # do an update
	    $self->_do_update();
	} else {
	    $self->_do_insert();
	}
    }	

    # sync the attributes
    $self->_sync_attributes();
    $self->_sync_members();

    # Clear the dirty bit.
    $self->_set__dirty(0);

    return $self;
}


#==============================================================================#
# Private Methods                      #
#======================================#

=head1 PRIVATE

=cut

#--------------------------------------#

=head2 Private Class Methods                 

NONE

=cut

#--------------------------------------#

=head2 Private Instance Methods              

=item $ret = _select_group( $where, [$bind] )

takes the where clause and the bind vars and preforms the query

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _select_group {
	my ($where, $bind) = @_;

	# declare vars for returned rows and all that will be returned 
	# from this function
	my (@d, @ret);

	# construct the query
	my $sql = 'SELECT ' . join(',', 'id', COLS) . ' FROM ' . TABLE;
	$sql .= ' WHERE ' . $where if $where;

	# execute the query
	my $sth = prepare_c($sql, undef, DEBUG);
	execute($sth, $bind);
	bind_columns($sth, \@d[0 .. (scalar COLS)]);

	while (fetch($sth)) {
		push @ret, [@d];
	}

	# finish the query
	finish($sth);

	return unless @ret;

	return \@ret;
}


=item $members = $grp->_get_members()

Internal method to select the members of this group

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _get_members {
    my ($self) = @_;
    my $dirty   = $self->_get__dirty;
    my $members = $self->_get('_members');

    # Lookup the members if they haven't been yet but not if there is no ID yet.
    unless ($members || not defined($self->get_id)) {
	my $stored = Bric::Util::Grp::Parts::Member->list({grp => $self}) || [];
	foreach (@$stored) {
	    my $package = $_->get_object_package();
	    my $obj_id  = $_->get_obj_id();

	    $members->{$package}->{$obj_id} = $_;
	}
	
	$self->_set(['_members'], [$members]);

	# This is a change that doesn't need to be saved.
	$self->_set__dirty($dirty);
    }

    return $members;
}

=item $attribute_obj = $self->_get_attribute_obj()

Will return the attribute object.    Methods that need it should check to 
see if they have it and if not then get it from here.   If there is an ID
defined then it will look up based on it otherwise it will create a new one.

B<Throws:>

NONE 

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _get_attr_obj {
    my ($self) = @_;
    my $dirty    = $self->_get__dirty;
    my $attr_obj = $self->_get('_attr_obj');

    unless ($attr_obj) {
	# Let's Create a new one if one does not exist
	$attr_obj = Bric::Util::Attribute::Grp->new({id => $self->get_id});
	
	$self->_set(['_attr_obj'], [$attr_obj]);

	# This is a change that doesn't need to be saved.
	$self->_set__dirty($dirty);
    }

    return $attr_obj;
}

=item $self = $self->_set_attr( $param )

Internal method which either sets the attribute upon the attribute 
object, or if we can not get one yet into a cached area

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _set_attr {
    my ($self, $param) = @_;
    my $dirty = $self->_get__dirty;

	# check to see if we have an id, get attr obj if we do
	# otherwise put it into a cache 
	if ($self->_get('id') ) {
		my $attr_obj = $self->_get_attr_obj();

		# param should have been passed in an acceptable manner
		# send it straight to the attr obj
		$attr_obj->set_attr( $param );
	} else {
		# get the cache or create a new one if necessary
		my $attr_cache = $self->_get('_attr_cache') || {};

		# the value for this subsys/name combo
		$attr_cache->{$param->{'subsys'}}->{$param->{'name'}}->{'value'} =
			$param->{'value'};

		# the sql type 
		$attr_cache->{$param->{'subsys'}}->{$param->{'name'}}->{'type'} =
			$param->{'sql_type'};

		# store the cache so we can access it later
		$self->_set( { '_attr_cache' => $attr_cache });
	}

	# set the flag to update the attrs
	$self->_set(['_update_attrs'], [1]);

	# This is a change that doesn't need to be saved.
	$self->_set__dirty($dirty);

	return $self;
}

################################################################################

=item $self = $self->_delete_attr($param)

Deletes the attributes from this group and its members

B<Throws:>

NONE

B<Side Effects:>

Deletes from all the members as well

B<Notes:>

NONE

=cut

sub _delete_attr {
    my ($self, $param, $mem) = @_;
    my $dirty = $self->_get__dirty;

	if ($self->_get('id') ) {
		my $attr_obj = $self->_get_attr_obj();

		$attr_obj->delete_attr($param);
	} else {
		my $attr_cache = $self->_get('_attr_cache');

		delete $attr_cache->{$param->{'subsys'}}->{$param->{'name'}};

		$self->_set( { '_attr_cache' => $attr_cache });
	}

	if ($mem) {
		my $members = $self->get_members();

		foreach (@$members) {
			$_->delete_attr($param);
		}
	}

	$self->_set(['_update_attrs'], [1]);

	# This is a change that doesn't need to be saved.
	$self->_set__dirty($dirty);

	return $self;
}

################################################################################

=item $attr = $self->_get_attr( $param )

Internal Method to return attributes from the object or the cache

B<Throws:> 

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _get_attr {
	my ($self, $param, $parent) = @_;

	# the data that will be returned
	my $attr;

	# check for an id to see if we need to access the cache or
	# the attribute object
	if ($self->_get('id') ) {
		# we have an id so get the attribute object
		my $attr_obj = $self->_get_attr_obj();

		# param should have been passed in a valid format
		# send directly to the attr object
		$attr = $attr_obj->get_attr( $param );
			
	} else {

		# get the cache if it exists or create if it does not
		my $attr_cache = $self->_get('_attr_cache') || {};

		# get the data to return 
		$attr = 
			$attr_cache->{$param->{'subsys'}}->{$param->{'name'}}->{'value'};
	}
	# check to see if the get from parent flag is set
	if ($parent && !$attr) {
		# no attr set upon this group check parent for defaults
		# check if it has a parent
		if ($self->_get('parent_id')) {
			# check for the parent
			my $parent_obj = $self->_get_parent_object();
			if ($parent_obj) {
				$attr = $parent_obj->_get_attr($param);
			}
		}
	}

	return $attr;
}

=item $attrs = $self->_get_attr_hash( $param, $parent)

returns all attrs for a given subsystem

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _get_attr_hash {
	my ($self, $param, $parent) = @_;

	my $attrs;
	# determine if we can get the attr_object
	if ($self->_get('id')) {
		# get the attribute object
		my $attr_obj = $self->_get_attr_obj();

		# get the attrs
		$attrs = $attr_obj->get_attr_hash($param);
	} else {
		# grab the cache
		my $attr_cache = $self->_get('_attr_cache');

		# get the info that is desired
		foreach (keys %{ $attr_cache->{$param->{'subsys'}} } ) {
			$attrs->{$_} = $attr_cache->{$param->{'subsys'}}->{$_}->{'value'};
		}
	}
	# check if we need to hit the parents
	if ($parent) {
		# the parent object
		my $parent_obj = $self->_get_parent_object();
		if ($parent_obj) {
			# call parents method
			my $parent_attrs = $parent_obj->_get_attr_hash($param, 1);
			# combine the two
			%$attrs = (%$parent_attrs, %$attrs);
		}
	}
	return $attrs;
}

=item $self = $self->_set_meta( $param )

Sets the meta information for this group on the attr object or
caches it for later storage

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _set_meta {
    my ($self, $param) = @_;
    my $dirty = $self->_get__dirty;

	# determin if we get the object or cache the data
	if ($self->_get('id')) {
		# get the attr object
		my $attr_obj = $self->_get_attr_obj();

		# set the meta information as it was given with the 
		# arg
		$attr_obj->add_meta( $param );
	} else {
		# get the meta info's cache
		my $mc = $self->_get('_meta_cache') || {};

		# set the information into the cache
		$mc->{$param->{'subsys'}}->{$param->{'name'}}->{$param->{'field'}} =
				$param->{'value'};

		# store the cache for future use
		$self->_set({ '_meta_cache' => $mc });
	}

	$self->_set(['_update_attrs'], [1]);

	# This is a change that doesn't need to be saved.
	$self->_set__dirty($dirty);

	return $self;
}

################################################################################

=item $self = $self->_delete_meta( $param, $mem);

Deletes the meta info from the group and possibly its members

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _delete_meta {
    my ($self, $param, $mem) = @_;
    my $dirty = $self->_get__dirty;

	if ($self->_get('id')) {
		my $attr_obj = $self->_get_attr_obj();

		$attr_obj->delete_meta( $param );
	} else {
		my $meta_cache = $self->_get('meta_cache') || {};

		delete
		$meta_cache->{$param->{'subsys'}}->
			{$param->{'name'}}->{$param->{'field'}};
	}

	if ($mem) {
		my $members = $self->get_members();

		foreach (@$members) {
			$_->delete_meta($param);
		}
	}

	$self->_set(['_update_attrs'], [1]);

	# This is a change that doesn't need to be saved.
	$self->_set__dirty($dirty);

	return $self;
}

################################################################################

=item $meta = $self->_get_meta( $param )

Returns stored meta information from the attr object or the attribute 
cache

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _get_meta {
	my ($self, $param, $parent) = @_;

	my $meta;
	if ($self->_get('id')) {
		# we can have an attribute object so get it
		my $attr_obj = $self->_get_attr_obj();
		$meta = $attr_obj->get_meta($param);
	} else {
		# get the cache if we have one
		my $mc = $self->_get('_meta_cache') || {};

		# see if they want just a field or it all
		if (defined $param->{'field'}) {
			$meta = 
		$mc->{$param->{'subsys'}}->{$param->{'name'}}->{$param->{'field'}};
		} else {
			$meta = $mc->{$param->{'subsys'}};
		}
	}

	# determine if we need to check the parent for anything
	if ($parent) {
		# see if we asked for a hash or a scalar
		if ($param->{'field'}) {
			unless ($meta) {
				# get parent object
				my $parent_obj = $self->_get_parent_object();
				if ($parent_obj) {
					$meta = $parent->get_meta($param);
				} # end if parent
			} # end unless meta
		} else {
			# get the hash to be merged
			my $parent_obj = $self->_get_parent_object();
			if ($parent_obj) {
				my $meta2 = $parent_obj->get_meta($param);
				%$meta = (%$meta2, %$meta);
			}
		} # end if else field block
	} # end if parent block

	return $meta;
}

=item $parent_obj = $self->_get_parent_object()

Will return the group that is this groups' parent if one has been 
defined

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _get_parent_object {
    my ($self) = @_;
    my $dirty  = $self->_get__dirty;
    my $parent = $self->_get('_parent_obj');

    # see if there is a parent to get
    unless ($parent) {
	my $p_id = $self->_get('parent_id');

	if ($p_id) {
	    $parent = Bric::Util::Grp->lookup({id => $p_id});
	    $self->_set(['_parent_obj'], [$parent]);
	
	    # This is a change that doesn't need to be saved.
	    $self->_set__dirty($dirty);
	}
    }

    return $parent;
}


=item $parents = $self->_get_all_parents()

Internal method that recursivly calls its self to determine all of its 
parents

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _get_all_parents {
	my ($self, $parent, $child) = @_;
	my($id,@ids);

	my $sql = 'SELECT p.id, p.parent_id ' .
				' FROM grp p, grp c ' .
				' WHERE c.parent_id=? AND ' .
				' c.id=? AND '.
				' p.id=c.parent_id ';
	my $sth = prepare_c($sql,undef, DEBUG);

	execute($sth,$parent,$child);
	while (my $row = fetch($sth)) {
		push(@ids, $row->[1]);
		push(@ids, $self->_get_all_parents($row->[1],$row->[0]));
	}
	finish($sth);
	return @ids;
}


=item $grp = $grp->_do_insert()

Called from save it will do the insert for the grp object

B<Throws:>
NONE 

B<Side Effects:>
NONE

B<Notes:>
NONE

=cut

sub _do_insert {
	my ($self) = @_;

	# Build insert statement
	my $sql = "INSERT INTO " . TABLE . 
			" (id, " . join(', ', COLS) . ") " .
			"VALUES (${\next_key(TABLE)}," . 
			join(',',('?') x COLS) .") ";

	my $sth = prepare_c($sql, undef, DEBUG);
	execute($sth, $self->_get( FIELDS ) );

	# Now get the id that was created
	$self->_set( { 'id' => last_key(TABLE) } );

	# Add the group to the 'All Groups' group.
	$self->register_instance(INSTANCE_GROUP_ID, GROUP_PACKAGE);

	return $self;
}


=item $self = $self->_do_update()

Called by the save method, this will update the record

B<Throws:>

NONE 

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut


sub _do_update {
    my ($self) = @_;

    my $sql = 'UPDATE '.TABLE.
              ' SET ' . join(', ', map { "$_=?" } COLS).
	      ' WHERE id=? ';

    my $sth = prepare_c($sql, undef, DEBUG);

    execute($sth,($self->_get( FIELDS )), $self->_get('id'));

    return $self;
}

=item $self = $self->_sync_attributes()

Internal method that stores the attributes and meta information 
from a save

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _sync_attributes {
	my ($self) = @_;

	# check to see if anything needs to be done
	return $self unless $self->_get('_update_attrs');

	# get the attribute object
	my $attr_obj = $self->_get_attr_obj();

	# see if we have attr in the cache to be stored...
	my $attr_cache = $self->_get('_attr_cache');
	if ($attr_cache) {
		# retrieve cache and store it on the attribute object
		foreach my $subsys (keys %$attr_cache) {
			foreach my $name (keys %{ $attr_cache->{$subsys} }) {
				# set the attribute
				$attr_obj->set_attr( {
						subsys => $subsys,
						name => $name,
						sql_type => $attr_cache->{$subsys}->{$name}->{'type'},
						value => $attr_cache->{$subsys}->{$name}->{'value'}
					});
			}
		}

		# clear the attribute cache
		$self->_set( { '_attr_cache' => undef });
	}

	# see if we have a meta cache to store
	my $meta_cache = $self->_get('_meta_cache');
	if ($meta_cache) {
		# retrieve meta cache and set it upon the attribute object
		foreach my $subsys (keys %$meta_cache) {
			foreach my $name (keys %{ $meta_cache->{$subsys} }) {
				foreach my $field (keys %{ $meta_cache->{$subsys}->{$name}}) {
					$attr_obj->add_meta( {
						subsys => $subsys,
						name => $name,
						field => $field,
						value => $meta_cache->{$subsys}->{$name}->{$field}
					});
				} # end foreach field
			} # end foreach name
		} # end foreach subsys

		$self->_set( { '_meta_cache' => undef });
	}

	# clear the update flag
	$self->_set( { '_update_attrs' => undef });

	# call save on the attribute object
	$attr_obj->save();

	return $self;
}

=item = $self = $self->_sync_members();

Called By save this will sync all the group's member objects

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _sync_members {
	my ($self) = @_;

	return $self unless $self->_get('_update_members');

	my $members = $self->_get_members();
	my $delete_members = $self->_get('_delete_members');

	# lets call save on all the delete members here
	foreach (@$delete_members) {
		$_->save if $_->get_id();
	}

	foreach my $package (keys %$members) {
		# go through each of this packages objects
		foreach my $id (keys %{ $members->{$package} }) {
			# call save on the object
			unless ($members->{$package}->{$id}->get_grp_id()) {
				# no group id set on member yet, set it now
				$members->{$package}->{$id}->set_grp_id($self->_get('id'));
			}
			$members->{$package}->{$id}->save();
		}
	}

	$self->_set( {
		'_delete_members' => undef,
		'_update_members' => undef
		});

	return $self;
}

=cut

#--------------------------------------#

=head2 Private Functions

=item $results = _do_list( $criteria );

Takes the criteria passed into list and list ids, constructs a query
and returns the results to them

B<Throws:>
"Database error in _do_list.  Error: $@\n";

B<Side Effects:>
NONE

B<Notes:>
NONE

=cut 

sub _do_list {
	my ($class, $criteria,$ids) = @_;

	
	my $sql;
	my @where_clause;
	my @where_param;
	my $chk;
	# if an objject is passed this has to join with the member table
	if (($criteria->{'obj'}) ||
			($criteria->{'package'} && $criteria->{'obj_id'}) ) {
	    $chk = 1;
		my ($pkg,$obj_id);
		if ($criteria->{'obj'}) {
			# figure out what table this needs to be joined to
			$pkg = ref $criteria->{'obj'};
			# Get the object id
			$obj_id = $criteria->{'obj'}->get_id();
		} else {
			$pkg = $criteria->{'package'};
			$obj_id = $criteria->{'obj_id'};
		}

		# Now get the short name to construct the table
		my $short_name = $class->get_supported_classes->{$pkg};

		my $table = $short_name . '_member';

		# build the query
		$sql = qq{
			SELECT
				g.id, g.parent_id, g.class__id, g.name, g.description, 
				g.secret, g.permanent, g.active
			FROM
			        grp g, member m, $table mo
		};
		push @where_clause, ( "mo.object_id=? ", 'mo.member__id = m.id',
				      'm.grp__id = g.id');
		push @where_param, $obj_id;

		# if an active param has been passed in add it here
		# remember that groups can not be deactivated
		push @where_clause, 'm.active = ?';
		push @where_param, exists $criteria->{active} ?
		  $criteria->{active} : 1;

	} else { # end the if Object Block

		# no need for complex join
		$sql = qq{
			SELECT
				id, parent_id, class__id, name, description, 
				secret, permanent, active
			FROM
				grp
			};
	}

	# Add other parameters to the query

	if ( $criteria->{'parent_id'} ) {
		push @where_clause, $chk ? 'g.parent_id=?' : 'parent_id=?';
		push @where_param, $criteria->{'parent_id'};
	}

	if ( $criteria->{'inactive'} ) {
		push @where_clause, $chk ? 'g.active=?' : 'active=?';
		push @where_param, 0;
	} else {
		push @where_clause, $chk ? 'g.active=?' : 'active=?';
		push @where_param, 1;
	}

	unless ( $criteria->{'all'} ) {
		push @where_clause, $chk ? 'g.secret=?' : 'secret=?';
		push @where_param, 0;
	}

	if ( $class->get_class_id != 6 ) {
		push @where_clause, $chk ? 'g.class__id=?' : 'class__id=?';
		push @where_param, $class->get_class_id;
	}

	if ( $criteria->{'name'} ) {
		push @where_clause, $chk ? 'LOWER(g.name) LIKE ?' : 'LOWER(name) LIKE ?';
		push @where_param, lc($criteria->{'name'});
	}


	if ( exists $criteria->{permanent} ) {
		push @where_clause, $chk ? 'g.permanent = ?' : 'permanent = ?';
		push @where_param, $criteria->{permanent} ? 1 : 0;
	}

	if (@where_clause) {
		$sql .= ' WHERE ';
		$sql .= join ' AND ', @where_clause;
	}

	$sql .= $chk ? ' ORDER BY g.name' : ' ORDER BY name';
	my $select = prepare_c($sql, undef, DEBUG);

	# this was a call to list ids
	if ($ids) {
		my $return;
		$return = col_aref($select,@where_param);
		finish($select);

		return wantarray ? @{ $return } : $return;

	} else { # end list ids section

		my @objs;


		execute($select,@where_param);

		my %classes;

		while (my $row = fetch($select) ) {

			my $bless_class;
			if ($class->get_class_id() != 6) {
				$bless_class = $class;
			} else {
				if (exists $classes{$row->[2]}) {
					$bless_class = $classes{$row->[2]};
				} else {
					my $c_obj = Bric::Util::Class->lookup({ id => $row->[2] });
					$bless_class = $c_obj->get_pkg_name();
					eval " require $bless_class ";
					$classes{$row->[2]} = $bless_class;
				}
			} 

			my $self = bless {}, $bless_class;
			$self->SUPER::new();

			$self->_set(
					{ 	'id' 			=> $row->[0], 
						'parent_id' 	=> $row->[1], 
						'class_id' 		=> $row->[2], 
						'name' 			=> $row->[3], 
						'description' 	=> $row->[4],
						'secret'		=> $row->[5],
						'permanent'		=> $row->[6],
						'_active'		=> $row->[7]
					}); 

			# Clear the dirty bit.
			$self->_set__dirty(0);

			push @objs, $self;
		}
		finish($select);


		return wantarray ? @objs : \@objs;

	}


}

1;
__END__

=back

=head1 NOTES

Need to add parentage info and a possible method to list children
and maybe their children and so on as well

=head1 AUTHOR

michael soderstrom ( miraso@pacbell.net )

=head1 SEE ALSO:w


L<Bric.pm>,L<Bric::Util::Grp::Parts::Member>

=cut
