package Bric::Biz::AssetType;
###############################################################################

=head1 NAME

Bric::Biz::AssetType - Registers new types of assets with their fields and the
rules governing them.

=head1 VERSION

$Revision: 1.22 $

=cut

our $VERSION = (qw$Revision: 1.22 $ )[-1];

=head1 DATE

$Date: 2003-01-16 02:33:11 $

=head1 SYNOPSIS

  # Create new types of assets.
  $element = Bric::Biz::AssetType->new($init)
  $element = Bric::Biz::AssetType->lookup({id => $id})
  ($at_list || @ats) = Bric::Biz::AssetType->list($param)
  ($id_list || @ids) = Bric::Biz::AssetType->list_ids($param)

  # Return the ID of this object.
  $id = $element->get_id()

  # Get/set this asset type's name.
  $element = $element->set_name( $name )
  $name       = $element->get_name()

  # Get/set the description for this asset type
  $element  = $element->set_description($description)
  $description = $element->get_description()

  # Get/set the primary output channel ID for this asset type.
  $element = $element->set_primary_oc_id($oc_id);
  $oc_id = $element->get_primary_oc_id;

  # Attribute methods.
  $val  = $element->set_attr($name, $value);
  $val  = $element->get_attr($name);
  \%val = $element->all_attr;

  # Attribute metadata methods.
  $val = $element->set_meta($name, $meta, $value);
  $val = $element->get_meta($name, $meta);

  # Manage output channels.
  $element        = $element->add_output_channels([$output_channel])
  ($oc_list || @ocs) = $element->get_output_channels()
  $element        = $element->delete_output_channels([$output_channel])

  # Manage the parts of an asset type.
  $element            = $element->add_data($field);
  $element_data       = $element->new_data($param);
  $element            = $element->copy_data($at, $field);
  ($part_list || @parts) = $element->get_data($field);
  $element            = $element->del_data($field);

  # Add, retrieve and delete containers from this asset type.
  $element            = $element->add_containers($at || [$at]);
  (@at_list || $at_list) = $element->get_containers();
  $element            = $element->del_containers($at || [$at]);

  # Set the repeatability of a field.
  ($element || 0) = $element->is_repeatable($at_container);
  $element        = $element->make_repeatable($at_container);
  $element        = $element->make_nonrepeatable($at_container);

  # Get/set the active flag.
  $element  = $element->activate()
  $element  = $element->deactivate()
  (undef || 1) = $element->is_active()

  # Save this asset type.
  $element = $element->save()

=head1 DESCRIPTION

The asset type class registers new type of assets that will go through work
flow. The individual parts will describe how the fields of the story will be
laid out.

The AssetType object is composed of AssetType Parts Data objects and AssetType
Parts Container objects. These hold the fields that will become Assets when
they enter workflow. Rules can be set upon these.

The AssetType object also holds what output channels this asset will be
allowed to go through.

=cut

#==============================================================================#
# Dependencies                         #
#======================================#

#--------------------------------------#
# Standard Dependencies

use strict;

#--------------------------------------#
# Programatic Dependencies

use Bric::Util::DBI qw(:all);
use Bric::Util::Fault::Exception::GEN;
use Bric::Util::Grp::AssetType;
use Bric::Util::Grp::Element;
use Bric::Biz::AssetType::Parts::Data;
use Bric::Util::Attribute::AssetType;
use Bric::Biz::ATType;
use Bric::Util::Class;
use Bric::Biz::OutputChannel::Element;
use Bric::Util::Coll::OCElement;

#==============================================================================#
# Inheritance                          #
#======================================#

use base qw( Bric Exporter );

#=============================================================================#
# Function Prototypes                  #
#======================================#
my $get_oc_coll;

#==============================================================================#
# Constants                            #
#======================================#

use constant DEBUG => 0;

# Constants for DB access.
use constant TABLE  => 'element';
use constant COLS   => qw(name description burner reference 
			  type__id at_grp__id primary_oc__id active);
use constant FIELDS => qw(name description burner reference 
			  type__id at_grp__id primary_oc_id _active);

use constant ORD => qw(name description type_name  burner active);

use constant GROUP_PACKAGE => 'Bric::Util::Grp::Element';
use constant INSTANCE_GROUP_ID => 27;

# possible values for burner
use constant BURNER_MASON    => 1;
use constant BURNER_TEMPLATE => 2;

#==============================================================================#
# Fields                               #
#======================================#

#--------------------------------------#
# Public Class Fields
our $METH;
our @EXPORT_OK = qw(BURNER_MASON BURNER_TEMPLATE);
our %EXPORT_TAGS = ( all => \@EXPORT_OK);

#--------------------------------------#
# Private Class Fields                  

# NONE

#--------------------------------------#
# Instance Fields                       

# None

# This method of Bricolage will call 'use fields' for you and set some permissions.
BEGIN {
    Bric::register_fields({

			 # Public Fields
			 # The database id of the Asset Type
			 'id'		        => Bric::FIELD_READ,

			 # A group for holding AssetTypes that are children.
			 'at_grp__id'           => Bric::FIELD_READ,

			 # The human readable name for the story type
			 'name'		        => Bric::FIELD_RDWR,

			 # The human readable name for the description
			 'description'	        => Bric::FIELD_RDWR,

			 # The burner to use to publish this element
                         'burner'               => Bric::FIELD_RDWR,

			 # The primary output channel ID.
			 'primary_oc_id'        => Bric::FIELD_RDWR,

			 # Whether this asset type reference other data or not.
			 'reference'            => Bric::FIELD_READ,

                         # The type of this asset type.
                         'type__id'             => Bric::FIELD_READ,

			 # Private Fields
			 # The active flag
			 '_active'	        => Bric::FIELD_NONE,

			 # Stores the collection of output channels
                         '_oc_coll'             => Bric::FIELD_NONE,

			 # A list of contained parts
			 '_parts'	        => Bric::FIELD_NONE,

			 # A holding pen for new parts to be added.
			 '_new_parts'           => Bric::FIELD_NONE,

			 # A holding pen for parts to be deleted.
			 '_del_parts'           => Bric::FIELD_NONE,

			 # A group for holding AssetType IDs that are children.
			 '_at_grp_obj'          => Bric::FIELD_NONE,

			 '_attr'                => Bric::FIELD_NONE,
			 '_meta'                => Bric::FIELD_NONE,

			 # Holds the attribute object for this object.
			 '_attr_obj'            => Bric::FIELD_NONE,

			 # Hold the at object.
			 '_att_obj'             => Bric::FIELD_NONE,
			});
}

#==============================================================================#
# Interface Methods                    #
#======================================#

=head1 INTERFACE

=head2 Constructors

=over 4

=item $element = Bric::Biz::AssetType->new($init)

Will return a new asset type object with the optional initial state

Supported Keys:

=over 4

=item name

=item description

=item primary_oc_id

=item reference

=back

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub new {
    my ($class, $init) = @_;

    my $self = bless {}, ref $class || $class;

    $init->{_active} = 1;

    # Set reference unless explicitly set.
    $init->{reference} = $init->{reference} ? 1 : 0;

    $self->SUPER::new($init);

    my $pkg = $self->get_biz_class;

    # If a package was passed in then find the autopopulated field names.
    if ($pkg) {
	# Load the package.
	eval "require $pkg";

	# If this could die, but in that case we just skip this part.
	my @name = eval { $pkg->autopopulated_fields };
	my $i = 0;
	foreach my $n (@name) {
	    my $atd = $self->new_data({'name'        => $n,
				       'description' => "Autopopulated $n field.",
				       'required'    => 1,
				       'sql_type'    => 'short',
				       autopopulated => 1 });
	    $atd->set_attr('html_info', '');
	    $atd->set_meta('html_info', 'disp', $n);
	    $atd->set_meta('html_info', 'type', 'text');
	    $atd->set_meta('html_info', 'length', 32);
	    $atd->set_meta('html_info', 'pos', ++$i);
	}
    }

    $self->activate;

    # Set the dirty bit for this new object.
    $self->_set__dirty(1);

    return $self;
}

#------------------------------------------------------------------------------#

=item $element = Bric::Biz::AssetType->lookup($param)

Keys for $param are:

=over 4

=item *

id

This is an AssetType ID that will return a single unique AssetType object.

=back

This will return the asset type that matches the id that is defined

B<Throws:>

"Missing required paramter 'id'"

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub lookup {
    my $class = shift;
    my ($param) = @_;
    my $self = bless {}, $class;

    # Call our parents constructor.
    $self->SUPER::new();
    
    # Throw an exception if the wrong parameters are given.
    unless (exists $param->{'id'}) {
	my $msg = "Missing required paramter 'id'";
	die Bric::Util::Fault::Exception::GEN->new({'msg' => $msg});
    }
    
    # NOTE: Combine these two queries in a generalized select.
    # Load the values for this object from the element table.
    return unless $self->_select_asset_type('id=?', $param->{'id'});
    
    my $id = $self->get_id;
    my $a_obj = Bric::Util::Attribute::AssetType->new({'object_id' => $id,
						     'subsys'    => "id_$id"});
    $self->_set(['_attr_obj'], [$a_obj]);
    
    # Clear the dirty bit for looked up objects.
    $self->_set__dirty(0);

    return $self;
}

#------------------------------------------------------------------------------#

=item ($at_list || @at_list) = Bric::Biz::AssetType->list($param);

This will return a list of objects that match the criteria defined.

Supported Keys:

=over 4

=item name

The name of the asset type.  Matched with case-insentive LIKE.

=item description

The description of the asset type.  Matched with case-insentive LIKE.

=item output_channel

The ID of an output channel. Returned will be all AssetType objects that
contain this output channel.

=item data_name

The name of an AssetType::Data object. Returned will be all AssetType objects
that reference this particular AssetType::Data object.

=item map_type__id

The map_type__id of an AssetType::Data object.

=item active

Set to 0 to return active and inactive asset types. 1, the default, returns
only active asset types.

=item type__id

match elements of a particular attype

=item top_level

set to 1 to return only top-level elements

=item media

match against a particular media asste type (att.media)

=back

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub list {
    my $class = shift;
    my ($param) = @_;

    # Note that we're not passing the return IDs flag.
    return _do_list($class, $param);
}

#------------------------------------------------------------------------------#

=item ($at_list || @ats) = Bric::Biz::AssetType->list_ids($param)

This will return a list of objects that match the criteria defined 

See the 'list' function for the allowed keys of $param.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub list_ids {
    my $class = shift;
    my ($param) = @_;
    
    # Call this with the return ID flag set to 1.
    return _do_list($class, $param, 1);
}

#--------------------------------------#

=back

=head2 Destructors

=over 4

=item $self->DESTROY

Dummy method to prevent wasting time trying to AUTOLOAD DESTROY.

=cut

sub DESTROY {
    # This method should be here even if its empty so that we don't waste time
    # making Bricolage's autoload method try to find it.
}

#--------------------------------------#

=back

=head2 Public Class Methods

=over 4

=item $meths = Bric::Biz::AssetType->my_meths

=item (@meths || $meths_aref) = Bric::Biz::AssetType->my_meths(TRUE)

Returns an anonymous hash of instrospection data for this object. If called
with a true argument, it will return an ordered list or anonymous array of
intrspection data. The format for each introspection item introspection is as
follows:

Each hash key is the name of a property or attribute of the object. The value
for a hash key is another anonymous hash containing the following keys:

=over 4

=item name

The name of the property or attribute. Is the same as the hash key when an
anonymous hash is returned.

=item disp

The display name of the property or attribute.

=item get_meth

A reference to the method that will retrieve the value of the property or
attribute.

=item get_args

An anonymous array of arguments to pass to a call to get_meth in order to
retrieve the value of the property or attribute.

=item set_meth

A reference to the method that will set the value of the property or
attribute.

=item set_args

An anonymous array of arguments to pass to a call to set_meth in order to set
the value of the property or attribute.

=item type

The type of value the property or attribute contains. There are only three
types:

=over 4

=item short

=item date

=item blob

=back

=item len

If the value is a 'short' value, this hash key contains the length of the
field.

=item search

The property is searchable via the list() and list_ids() methods.

=item req

The property or attribute is required.

=item props

An anonymous hash of properties used to display the property or
attribute. Possible keys include:

=over 4

=item type

The display field type. Possible values are

=over 4

=item text

=item textarea

=item password

=item hidden

=item radio

=item checkbox

=item select

=back

=item length

The Length, in letters, to display a text or password field.

=item maxlength

The maximum length of the property or value - usually defined by the SQL DDL.

=back

=item rows

The number of rows to format in a textarea field.

=item cols

The number of columns to format in a textarea field.

=item vals

An anonymous hash of key/value pairs reprsenting the values and display names
to use in a select list.

=back

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub my_meths {
    my ($pkg, $ord) = @_;

    # Return 'em if we got em.
    return !$ord ? $METH : wantarray ? @{$METH}{&ORD} : [@{$METH}{&ORD}]
      if $METH;

    # We don't got 'em. So get 'em!
    $METH = {
	      name        => {
			      name     => 'name',
			      get_meth => sub { shift->get_name(@_) },
			      get_args => [],
			      set_meth => sub { shift->set_name(@_) },
			      set_args => [],
			      disp     => 'Name',
			      search   => 1,
			      len      => 64,
			      req      => 1,
			      type     => 'short',
			      props    => {   type       => 'text',
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
	      burner      => {
			      get_meth => sub { shift->get_burner(@_) },
			      get_args => [],
			      set_meth => sub { shift->set_burner(@_) },
			      set_args => [],
			      name     => 'burner',
			      disp     => 'Burner',
			      len      => 80,
			      req      => 1,
			      type     => 'short',
			      props    => { type => 'select',
					    vals => [[BURNER_MASON, 'Mason'],
						     [BURNER_TEMPLATE, 'HTML::Template']],
					  }
			     },	     
	      type_name      => {
			     name     => 'type_name',
			     get_meth => sub { shift->get_type_name(@_) },
			     get_args => [],
			     set_meth => sub { shift->set_type_name(@_) },
			     set_args => [],
			     disp     => 'Type',
			     len      => 64,
			     req      => 0,
			     type     => 'short',
			     props    => {   type       => 'text',
					     length     => 32,
					     maxlength => 64
					 }
			    },
	      active     => {
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
			    },
	     };
    return !$ord ? $METH : wantarray ? @{$METH}{&ORD} : [@{$METH}{&ORD}];
}


#--------------------------------------#

=back

=head2 Public Instance Methods

=over 4

=item $id = $element->get_id()

This will return the id for the database

B<Throws:>
NONE

B<Side Effects:>
NONE

B<Notes:>
NONE

=cut

#------------------------------------------------------------------------------#

=item $element = $element->set_name( $name )

This will set the name field for the asset type

B<Throws:>
NONE

B<Side Effects:>
NONE

B<Notes:>
NONE

=cut

#------------------------------------------------------------------------------#

=item $name = $element->get_name()

This will return the name field for the asset type

B<Throws:>
NONE

B<Side Effects:>
NONE

B<Notes:>
NONE

=cut

#------------------------------------------------------------------------------#

=item $element = $element->set_description($description)

this sets the description field

B<Throws:>
NONE

B<Side Effects:>
NONE

B<Notes:>
NONE

=cut

#------------------------------------------------------------------------------#

=item $description = $element->get_description()

This returns the description field

B<Throws:>
NONE

B<Side Effects:>
NONE

B<Notes:>
NONE

=cut

#------------------------------------------------------------------------------#

=item $element = $element->set_primary_oc_id( $primary_oc_id )

This will set the primary output channel id field for the asset type

B<Throws:>
NONE

B<Side Effects:>
NONE

B<Notes:>
NONE

=cut

#------------------------------------------------------------------------------#

=item $primary_oc_id = $element->get_primary_oc_id()

This will return the primary output channel id field for the asset type

B<Throws:>
NONE

B<Side Effects:>
NONE

B<Notes:>
NONE

=cut

#------------------------------------------------------------------------------#

=item $name = $at->get_type_name

Get the type name of the asset type.

B<Throws:>
NONE

B<Side Effects:>
NONE

B<Notes:>
NONE

=cut

#------------------------------------------------------------------------------#

=item $burner = $at->get_burner

Get the burner associated with the asset type.  Possible values are
the constants BURNER_MASON and BURNER_TEMPLATE defined in this package.

B<Throws:>
NONE

B<Side Effects:>
NONE

B<Notes:>
NONE

=cut

#------------------------------------------------------------------------------#

=item $at->set_burner(Bric::Biz::AssetType::BURNER_MASON);

Get the burner associated with the asset type.  Possible values are
the constants BURNER_MASON and BURNER_TEMPLATE defined in this package.

B<Throws:>
NONE

B<Side Effects:>
NONE

B<Notes:>
NONE

=cut


sub get_type_name {
    my $self = shift;
    my $att_obj = $self->_get_at_type_obj;

    return unless $att_obj;

    return $att_obj->get_name;
}

#------------------------------------------------------------------------------#

=item $desc = $at->get_type_description

Get the type description of the asset type.

B<Throws:>
NONE

B<Side Effects:>
NONE

B<Notes:>
NONE

=cut

sub get_type_description {
    my $self = shift;
    my $att_obj = $self->_get_at_type_obj;

    return unless $att_obj;

    return $att_obj->get_description;
}

#------------------------------------------------------------------------------#

=item ($at || undef) = $at->get_top_level

Return whether this is a top level story or not.

B<Throws:>
NONE

B<Side Effects:>
NONE

B<Notes:>
NONE

=cut

sub get_top_level {
    my $self = shift;
    my $att_obj = $self->_get_at_type_obj;

    return unless $att_obj;

    return $att_obj->get_top_level;
}

#------------------------------------------------------------------------------#

=item ($at || undef) = $at->get_paginated

Return whether this asset type should produce a paginated asset or not.

B<Throws:>
NONE

B<Side Effects:>
NONE

B<Notes:>
NONE

=cut

sub get_paginated {
    my $self = shift;
    my $att_obj = $self->_get_at_type_obj;

    return unless $att_obj;

    return $att_obj->get_paginated;
}

#------------------------------------------------------------------------------#

=item ($at || undef) = $at->is_related_media

Return whether this asset type can have related media objects.

B<Throws:>
NONE

B<Side Effects:>
NONE

B<Notes:>
NONE

=cut

sub is_related_media {
    my $self = shift;
    my $att_obj = $self->_get_at_type_obj;

    return unless $att_obj;

    return $att_obj->get_related_media;
}

=item ($at || undef) = $at->is_related_story

Return whether this asset type can have related story objects.

B<Throws:>
NONE

B<Side Effects:>
NONE

B<Notes:>
NONE

=cut

sub is_related_story {
    my $self = shift;
    my $att_obj = $self->_get_at_type_obj;

    return unless $att_obj;

    return $att_obj->get_related_story;
}

#------------------------------------------------------------------------------#

=item ($at || undef) = $at->is_media()

=item $at = $at->set_media()

=item $at = $at->clear_media()

Mark this Asset Type as representing a media object or a story object.  Media
objects do not support all the options that story objects to like nested 
containers or references, but they include options that story doesnt like 
autopopulated fields.

The 'is_media' method returns true if this is a media object and false 
otherwise. The 'set_media' method marks this as a media object.  It does not
take any arguments, and always sets the media flag to true, so you cant do this:

$at->set_media(0)

and expect to set the media flag to false.  To unset the media flag (set it to
false) use the 'clear_media' method.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub is_media {
    my $self = shift;
    my $att_obj = $self->_get_at_type_obj;

    return unless $att_obj;

    return $att_obj->get_media ? $self : undef;
}

sub set_media {
    my $self = shift;
    my $att_obj = $self->_get_at_type_obj;

    return unless $att_obj;

    $att_obj->set_media(1);

    return $self;
}

sub clear_media {
    my $self = shift;
    my $att_obj = $self->_get_at_type_obj;

    return unless $att_obj;

    $att_obj->set_media(0);

    return $self;
}

#------------------------------------------------------------------------------#

=item $at->get_biz_class()

=item $at->get_biz_class_id()

=item $at->set_biz_class('class' => '' || 'id' => '');

The methods 'get_biz_class' and 'get_biz_class_id' get the business class name 
or the business class ID respectively from the class table.

The 'set_biz_class' method sets the business class for this asset type given
either a class name or an ID from the class table.

This value represents the kind of bussiness object this asset type will 
represent.  There are just two main kinds, story and media objects.  However 
media objects have many subclasses, one for each type of supported media (image,
audio, video, etc) increasing the number of package names this value could be 
set to.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_biz_class {
    my $self = shift;
    my $att_obj = $self->_get_at_type_obj;

    return unless $att_obj;

    my $class = Bric::Util::Class->lookup({'id' => $att_obj->get_biz_class_id});

    return unless $class;

    return $class->get_pkg_name;
}

sub get_biz_class_id {
    my $self = shift;
    my $att_obj = $self->_get_at_type_obj;

    return unless $att_obj;

    return $att_obj->get_biz_class_id;
}

#------------------------------------------------------------------------------#

=item ($at || undef) = $at->get_reference

=item $at = $at->set_reference(1 || 0)

Return whether this asset type references other data.

B<Throws:>
NONE

B<Side Effects:>
NONE

B<Notes:>
NONE

=cut

sub get_reference {
    my $self = shift;

    return $self->_get('reference') ? $self : undef;
}

sub set_reference {
    my $self = shift;
    my ($bool) = @_;

    $self->_set(['reference'], [$bool ? 1 : 0]);

    $self->_set__dirty(1);

    return $self;
}

#------------------------------------------------------------------------------#

=item ($at || undef) = $at->get_fixed_url

Return whether this asset type should produce a fixed url asset or not.

B<Throws:>
NONE

B<Side Effects:>
NONE

B<Notes:>
NONE

=cut

sub get_fixed_url {
    my $self = shift;
    my $att_obj = $self->_get_at_type_obj;
    
    return unless $att_obj;

    return $att_obj->get_fixed_url;     
}

#------------------------------------------------------------------------------#

=item $at_type = $at->get_at_type

Return the at_type object associated with this element.

B<Throws:>
NONE

B<Side Effects:>
NONE

B<Notes:>
NONE

=cut

sub get_at_type {
    my $self = shift;
    my $att_obj = $self->_get_at_type_obj;
    
    return $att_obj; 
}

#------------------------------------------------------------------------------#

=item $val = $element->set_attr($name, $value);

=item $val = $element->get_attr($name);

=item $val = $element->del_attr($name);

Get/Set/Delete attributes on this asset type.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut


sub set_attr {
    my $self = shift;
    my ($name, $val) = @_;
    my $attr     = $self->_get('_attr');
    my $attr_obj = $self->_get_attr_obj;

    # If we have an attr object, then populate it
    if ($attr_obj) {
	$attr_obj->set_attr({'name'     => $name,
			     'sql_type' => 'short',
			     'value'    => $val});
    }
    # Otherwise,cache this value until save.
    else {
	$attr->{$name} = $val;
	$self->_set(['_attr'], [$attr]);
    }

    $self->_set__dirty(1);

    return $val;
}

sub get_attr {
    my $self = shift;
    my ($name) = @_;
    my $attr     = $self->_get('_attr');
    my $attr_obj = $self->_get_attr_obj;

    # If we aren't saved yet, return anything we have cached.
    return $attr->{$name} unless $self->get_id;

    return $attr_obj->get_attr({'name' => $name});
}

sub del_attr {
    my $self = shift;
    my ($name) = @_;
    my $attr     = $self->_get('_attr');
    my $attr_obj = $self->_get_attr_obj;

    # If we aren't saved yet, delete from the cache.
    delete $attr->{$name} unless $self->get_id;

    return $attr_obj->delete_attr({'name' => $name});
}

sub all_attr {
    my $self = shift;
    my $attr     = $self->_get('_attr');
    my $attr_obj = $self->_get_attr_obj;

    # If we aren't saved yet, return the cache
    return $attr unless $self->get_id;

    # HACK: This identifies attr names begining with a '_' as private and will 
    # not return them.  This is being done instead of using subsystems because
    # we are using subsystems to keep AssetTypes unique from each other.
    my $ah = $attr_obj->get_attr_hash();

    # Evil delete on a hash slice based on values returned by grep...
    delete(@{$ah}{ grep(substr($_,0,1) eq '_', keys %$ah) });

    return $ah
}

#------------------------------------------------------------------------------#

=item $val = $element->set_meta($name, $field, $value);

=item $val = $element->get_meta($name, $field);

=item $val = $element->get_meta($name);

Get/Set attribute metadata on this asset type.  Calling the 'get_meta' method
without '$field' returns all metadata names and values as a hash.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub set_meta { 
    my $self = shift;
    my ($name, $field, $val) = @_;
    my $attr_obj = $self->_get_attr_obj;
    my $meta     = $self->_get('_meta');

    if ($attr_obj) {
	$attr_obj->add_meta({'name'  => $name,
			     'field' => $field,
			     'value' => $val});
    } else {
	$meta->{$name}->{$field} = $val;
	
	$self->_set(['_meta'], [$meta]);
    }

    $self->_set__dirty(1);

    return $val;
}

sub get_meta {
    my $self = shift;
    my ($name, $field) = @_;
    my $attr_obj = $self->_get_attr_obj;
    my $meta     = $self->_get('_meta');

    unless ($attr_obj) {
	if (defined $field) {
	    return $meta->{$name}->{$field};
	} else {
	    return $meta->{$name};
	}
    }

    if (defined $field) {
	return $attr_obj->get_meta({'name'  => $name,
				    'field' => $field});
    } else {
	my $meta = $attr_obj->get_meta({'name'  => $name});

	return { map { $_ => $meta->{$_}->{'value'} } keys %$meta };
    }
}

#------------------------------------------------------------------------------#

=item ($oc_list || @oc_list) = $element->get_output_channels;

=item ($oc_list || @oc_list) = $element->get_output_channels(@oc_ids);

This returns a list of output channels that have been associated with this
asset type. If C<@oc_ids> is passed, then only the output channels with those
IDs are returned, if they're associated with this asset type.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> The objects returned will be Bric::Biz::OutputChannel::Element
objects, and these objects contain extra information relevant to the
assocation between each output channel and this element object.

=cut

sub get_output_channels { $get_oc_coll->(shift)->get_objs(@_) }

#------------------------------------------------------------------------------#

=item my $oce = $element->add_output_channel($oc)

=item my $oce = $element->add_output_channel($oc_id)

Adds an output channel to this element object and returns the resulting
Bric::Biz::OutputChannel::Element object. Can pass in either an output channel
object or an output channel ID.

B<Throws:> NONE.

B<Side Effects:> If a Bric::Biz::OutputChannel object is passed in as the
first argument, it will be converted into a Bric::Biz::OutputChannel::Element
object.

B<Notes:> NONE.

=cut

sub add_output_channel {
    my ($self, $oc) = @_;
    my $oc_coll = $get_oc_coll->($self);
    $oc_coll->new_obj({ (ref $oc ? 'oc' : 'oc_id') => $oc,
                        element_id => $self->_get('id') });
}

#------------------------------------------------------------------------------#

=item $element = $element->add_output_channels([$output_channels])

This accepts an array reference of output channel objects to be associated
with this asset type.

B<Throws:> NONE.

B<Side Effects:> Any Bric::Biz::OutputChannel objects passed in will be
converted into Bric::Biz::OutputChannel::Element objects.

B<Notes:> NONE.

=cut

sub add_output_channels {
    my ($self, $ocs) = @_;
    $self->add_output_channel($_) for @$ocs;
    return $self;
}

#------------------------------------------------------------------------------#

=item $element = $element->delete_output_channels([$output_channels])

This takes an array reference of output channels and removes their association
from the object.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub delete_output_channels {
    my ($self, $ocs) = @_;
    my $oc_coll = $get_oc_coll->($self);
    $oc_coll->del_objs(@$ocs);
    return $self;
}

#------------------------------------------------------------------------------#

=item ($part_list || @part_list) = $element->get_data()

This will return a list of the fields and containers that make up
this asset type

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

The parts returned here may not have their parent IDs or order set if this 
object has not been saved yet.

=cut

sub get_data {
    my $self = shift;
    my ($field) = @_;
    my $parts     = $self->_get_parts();
    my $new_parts = $self->_get('_new_parts');
    my @all;

    # Include the yet to be added parts.
    while (my ($id,$obj) = each %$new_parts) {
	if ($id == -1) {
	    push @all, @$obj;
	} else {
	    push @all, $obj;
	}
    }

    push @all, values %$parts;

    if ($field) {
	# Return just the field they asked for.
	my ($val) = grep($_->get_name eq $field, @all);
	return unless $val;
	return $val;
    } else {
	# Return all the fields.
	return wantarray ?  sort { $a->get_place <=> $b->get_place } @all :
	  [ sort { $a->get_place <=> $b->get_place } @all ];
    }
}

#------------------------------------------------------------------------------#

=item $element = $element->add_data([$field])

This takes a list of fields and associates them with the element object

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub add_data {
    my $self = shift;
    my ($parts_arg) = @_;
    my $parts = $self->_get_parts();
    my ($new_parts, $del_parts) = $self->_get('_new_parts',
				             '_del_parts');

    foreach my $p (@$parts_arg) {
	unless (ref $p) {
	    my $msg = 'Must pass AssetType field or container objects, not IDs';
	    die Bric::Util::Fault::Exception::GEN->new({'msg' => $msg});
	}

	# Get the ID if we were passed an object.
	my $p_id = $p->get_id();
	
	# Skip adding this part if it already exists.
	next if exists $parts->{$p_id};

	# Add this to the parts list.
	$parts->{$p_id} = $p;
	
	# Remove this value from the deletion list if its there.
	delete $del_parts->{$p_id};
    }

    # Update $self's new and deleted parts lists.
    $self->_set(['_del_parts'], [$del_parts]);

    # Set the dirty bit since something has changed.
    $self->_set__dirty(1);

    return $self;
}

#------------------------------------------------------------------------------#

=item $element = $element->new_data($param)

Adds a new data point, creating a new Bric::Biz::AssetType::Parts::Data object.
The keys to $param are the same as the keys for the hash ref passed to 
Bric::Biz::AssetType::Parts::Data::new.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub new_data {
    my $self = shift;
    my ($param) = @_;
    my ($new_parts) = $self->_get('_new_parts');

    # Create the new part.
    my $part = Bric::Biz::AssetType::Parts::Data->new($param);

    # Add all new values to a special array of new parts until they can be
    # saved and given an ID.
    push @{$new_parts->{-1}}, $part;
    
    # Update $self's new and deleted parts lists.
    $self->_set(['_new_parts'], [$new_parts]);
    
    # Set the dirty bit since something has changed.
    $self->_set__dirty(1);

    return $part;
}

#------------------------------------------------------------------------------#

=item $element = $element->copy_data($param)

Copy the definition for a data field from another asset type. 
Keys for $param are:

=over 4

=item *

at

An existing asset type object

=item *

field_name

A field name defined within the object passed with 'at'

=item *

field_obj

A field object.  Can be given in lieu of 'at' and 'field_name'.

=back

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub copy_data {
    my $self = shift;
    my ($param) = @_;
    my ($new_parts) = $self->_get('_new_parts');
    my $f_obj = $param->{'field_obj'};
    my ($at, $f) = @$param{'at','field_name'};
   
    unless ($f_obj) {
	unless ($at) {
	    my $msg = 'Insufficient argurments';
	    die Bric::Util::Fault::Exception::GEN->new({'msg' => $msg});
	}
	
	$f_obj = $at->get_data($f);
    }
    
    my $part = $f_obj->copy($at->get_id);

    # Add all new values to a special array of new parts until they can be
    # saved and given an ID.
    push @{$new_parts->{-1}}, $part;
    
    # Update $self's new and deleted parts lists.
    $self->_set(['_new_parts'], [$new_parts]);
    
    # Set the dirty bit since something has changed.
    $self->_set__dirty(1);

    return $self;
}

#------------------------------------------------------------------------------#

=item $element = $element->del_data( [ $field || $container ])

This will take a list of parts and will disassociate them from the 
story type

B<Throws:>
NONE

B<Side Effects:>
NONE

B<Notes:>
NONE

=cut

sub del_data {
    my $self = shift;
    my ($parts_arg) = @_; 
    my $parts = $self->_get_parts();
    my ($new_parts, $del_parts) = $self->_get('_new_parts',
					      '_del_parts');

    foreach my $p (@$parts_arg) {
	unless (ref $p) {
	    my $msg = 'Must pass AssetType field or container objects, not IDs';
	    die Bric::Util::Fault::Exception::GEN->new({'msg' => $msg});
	}

	# Get the ID if we were passed an object.
	my $p_id = $p->get_id();

	# Delete this part from the list and put it on the deletion list.
	if (exists $parts->{$p_id}) {
	    delete $parts->{$p_id};
	    # Add the object as a value.
	    $del_parts->{$p_id} = $p;
	}

	# Remove this value from the addition list if its there.
	delete $new_parts->{$p_id};
    }

    # Update $self's new and deleted parts lists.
    $self->_set(['_parts', '_new_parts', '_del_parts'],
		[$parts  , $new_parts  , $del_parts]);

    # Set the dirty bit since something has changed.
    $self->_set__dirty(1);
    return $self;
}

#------------------------------------------------------------------------------#

=item $element = $element->add_containers([$at]);

Add AssetTypes to be contained by this AssetType.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut 

sub add_containers {
    my $self = shift;
    my ($at) = @_;
    my $grp = $self->_get_asset_type_grp;

    # Construct the proper array to pass to 'add_members'
    my @mem = map {ref $_ ? {obj => $_} : 
		            {id  => $_, package => __PACKAGE__}} @$at;

    return unless $grp->add_members(\@mem);
    return $self;
}

#------------------------------------------------------------------------------#

=item (@at_list || $at_list) = $element->get_containers();

Return all contained AssetTypes.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut 

sub get_containers {
    my $self = shift;
    my $grp = $self->_get_asset_type_grp;
    my $mbs = $grp->get_members;

    my @at = map { $_->get_object } @$mbs;

    return wantarray ? @at : \@at;
}

#------------------------------------------------------------------------------#

=item $element = $element->del_containers([$at]);

Release an AssetType from its servitude to this AssetType.  The AssetType itself
will not be deleted.  It will simply not be associated with this AssetType any
more.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub del_containers {
    my $self = shift;
    my ($at) = @_;
    my $grp = $self->_get_asset_type_grp;

    # Construct the proper array to pass to 'add_members'
    my @mem = map {ref $_ ? { obj => $_ }
                     : { id  => $_, package => __PACKAGE__ } }
      @$at;

    return unless $grp->delete_members(\@mem);
    return $self;
}

#------------------------------------------------------------------------------#

=item ($element || 0) = $element->is_repeatable($at_container);

=item $element        = $element->make_repeatable($at_container);

=item $element        = $element->make_nonrepeatable($at_container);

Get/Set the repeatable flag for a contained AssetType. Note that this
repeatability only applies to this AssetTypes relation to the contained
AssetType.

B<Throws:> NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub is_repeatable {
    my $self = shift @_;
    my ($at) = @_;
    my $c_id = $at->get_id;

    $self->get_attr("_child_${c_id}_repeatable");
}

sub make_repeatable {
    my $self = shift @_;
    my ($at) = @_;
    my $c_id = $at->get_id;
    
    $self->set_attr("_child_${c_id}_repeatable", 1);

    return $self;
}

sub make_nonrepeatable {
    my $self = shift @_;
    my ($at) = @_;
    my $c_id = $at->get_id;

    $self->set_attr("_child_${c_id}_repeatable", 0);

    return $self;
}

#------------------------------------------------------------------------------#

=item $element = $element->is_active()

Return the active flag.

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

#------------------------------------------------------------------------------#

=item $element = $element->activate()

This will set the active flag to one for the object

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut 

sub activate {
    my $self = shift;

    $self->_set(['_active'], [1]);

    return $self;
}

#------------------------------------------------------------------------------#

=item $element = $element->deactivate()

This will set the active flag to undef for the asset type

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut 

sub deactivate {
    my $self = shift;

    $self->_set(['_active'], [0]);

    return $self;
}

#------------------------------------------------------------------------------#

=item (undef || 1) $element->get_active()

This will return undef if the element has been deactivated and
one otherwise 

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

#------------------------------------------------------------------------------#

=item (undef || $self) = $field->remove()

Removes this object completely from the DB.  Returns 1 if active or undef 
otherwise

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub remove {
    my $self = shift;
    my $id = $self->get_id;

    # Don't try anything unless we actually have an ID.
    return unless $id;

    my $sql = 'DELETE FROM '.TABLE.' WHERE id=?';

    my $sth = prepare_c($sql, undef, DEBUG);
    execute($sth, $id);

    return $self;
}

#------------------------------------------------------------------------------#

=item $element = $element->save() 
 
This will save all of the changes to the database

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub save {
    my $self = shift;
    my $grp = $self->_get_asset_type_grp;

    # Don't do anything unless the dirty bit is set.
    return unless $self->_get__dirty;

    unless ($self->is_active) {
	# Check to see if this AT is reference anywhere. If not, delete it.
	unless ($self->_is_referenced) {
	    $self->remove;
	    return $self;
	}
    }

    my ($id, $oc_coll) = $self->_get(qw(id _oc_coll));
    # First save the main object information
    $id ? $self->_update_asset_type : $self->_insert_asset_type;


    # Save the attribute information.
    $self->_save_attr;

    # Save the group information.
    $grp->save;

    # Save the parts and the output channels.
    $oc_coll->save if $oc_coll;
    $self->_sync_parts;

    # Call our parents save method.
    $self->SUPER::save;

    return $self;
}

#==============================================================================#

=back

=head1 PRIVATE


=head2 Private Class Methods

=over 4

=item _do_list 

called from list and list ids this will query the db and return either
ids or objects

B<Throws:>
NONE

B<Side Effects:>
NONE

B<Notes:>
NONE

=cut

sub _do_list {
    my $class = shift;
    my ($param, $ids) = @_;
    my ($sql, $sth, %from, @where, @bind);

    # Make sure to set active explictly if its not passed.
    $param->{'active'} = exists $param->{'active'} ? $param->{'active'} : 1;

    # add parameters for output channel and field.
    $sql = 'SELECT '.join(',', map { "a.$_" } 'id', COLS).' '.
           'FROM '.TABLE." a ";

    # Add parameters based on a particular output channel.
    if ($param->{'output_channel'} ) {
	$from{'element__output_channel'} = 'ao';
	push @where, ('ao.output_channel__id=?', 'ao.element__id=a.id');
	push @bind, $param->{'output_channel'};
    }
    
    # Add parameters based on an AssetType::Data name or a map type ID.
    if ($param->{'data_name'} || $param->{'map_type__id'}) {
	$from{'element_data'} = 'd';
	push @where, 'd.element__id=a.id';
	if ($param->{'data_name'}) {
	    push @where, 'd.name=?';
	    push @bind, $param->{'data_name'};
	}
	if ($param->{'map_type__id'}) {
	    push @where, 'd.map_type__id=?';
	    push @bind, $param->{'map_type__id'};
	}
    }

    # Check active
    # Bug. This should test for exists (as should type__id below). Note that
    # when this is fixed, we'll have to fix comp/widgets/formBuilder/element.mc,
    # as well. Maybe other places, too.
    if ($param->{'active'}) {
	push @where, 'a.active=?';
	push @bind, $param->{'active'};
    }

    # Add type__id
    if ($param->{'type__id'}) {
	push @where, 'a.type__id=?';
	push @bind, $param->{'type__id'};
    }

    # Let them search on all top level asset types.
    if (exists $param->{'top_level'}) {
	$from{'at_type'} = 'att';
	push @where, 'att.id=a.type__id';
	push @where, 'att.top_level=?', 'a.type__id=att.id';
	push @bind, ($param->{'top_level'} ? 1 : 0);
    }

    # Let them search on all media asset types.
    if (exists $param->{'media'}) {
	$from{'at_type'} = 'att';
	push @where, 'att.id=a.type__id';
	push @where, 'att.media=?';
	push @bind, ($param->{'media'} ? 1 : 0);
    }

    # Handle all the searchable fields.
    foreach my $f (qw(name description)) {
	next unless exists $param->{$f};
	
	push @where, "LOWER(a.$f) LIKE ?";
	push @bind, lc($param->{$f});
    }

    # Add any additional FROM criteria
    $sql .= ','.join(',', map {$_.' '.$from{$_}} keys %from) if %from;

    # Add any additional WHERE criteria
    $sql .= ' WHERE '.join(' AND ', @where) if @where;
    $sql .= ' ORDER BY a.name';
    $sth = prepare_ca($sql, undef, DEBUG);

    # If called from list_ids give em what they want
    if ($ids) {
	my $return = col_aref($sth,@bind);
		
	# Finish this select
	finish($sth);

	return wantarray ? @$return : $return;
    } 
    # Otherwise collect the full data
    else {
	my (@objs, @d);
	
	execute($sth, @bind);
	bind_columns($sth, \@d[0..(scalar COLS)]);
	
	while (fetch($sth)) {
	    my $self = bless {}, $class;
	    $self->SUPER::new();
	    $self->_set(['id', FIELDS], [@d]);
	    
	    my $id = $self->get_id;
	    my $a_obj = Bric::Util::Attribute::AssetType->new(
						     {'object_id' => $id,
						      'subsys'    => "id_$id"});
	    $self->_set(['_attr_obj'], [$a_obj]);

	    push @objs, $self;
	}
	
	# Finish this select
	finish($sth);

	return wantarray ? @objs : \@objs;
    }
}

#--------------------------------------#

=back

=head2 Private Instance Methods

These need documenting.

=over 4

=item _is_referenced

=cut

sub _is_referenced {
    my $self = shift;
    my $rows;

    # Make sure this isn't referenced from an asset.
    my $table = $self->is_media ? 'media' : 'story';
    my $sql  = "SELECT COUNT(*) FROM $table WHERE element__id = ?";
    my $sth  = prepare_c($sql, undef, DEBUG);
    execute($sth, $self->get_id);
    bind_columns($sth, \$rows);
    fetch($sth);
    finish($sth);

    return 1 if $rows;

    # Make sure this isn't used by another asset type.
    $sql = 'SELECT COUNT(*) '.
           'FROM element_member atm, member m, element at '.
	   'WHERE atm.object_id = ? AND '.
                  'm.id         = atm.member__id AND '.
                  'm.grp__id    = at.at_grp__id';

    $sth  = prepare_c($sql, undef, DEBUG);
    execute($sth, $self->get_id);
    bind_columns($sth, \$rows);
    fetch($sth);
    finish($sth);

    return 1 if $rows;

    return 0;
}

=item _get_attr_obj

=cut

sub _get_attr_obj {
    my $self = shift;
    my $attr_obj = $self->_get('_attr_obj');
    my $id = $self->get_id;

    unless ($attr_obj || not defined($id)) {
	$attr_obj = Bric::Util::Attribute::AssetType->new(
				     {'object_id' => $id,
				      'subsys'    => "id_$id"});
	$self->_set(['_attr_obj'], [$attr_obj]);
    }

    return $attr_obj;
}

=item _get_at_type_obj

=cut

sub _get_at_type_obj {
    my $self = shift;
    my $att_id  = $self->get_type__id;
    my $att_obj = $self->_get('_att_obj');

    return $att_obj if $att_obj;

    if ($att_id) {
	$att_obj = Bric::Biz::ATType->lookup({'id' => $att_id});
	$self->_set(['_att_obj'], [$att_obj]);
    }

    return $att_obj;
}

=item _save_attr

=cut

sub _save_attr {
    my $self = shift;
    my ($attr, $meta, $a_obj) = $self->_get('_attr', '_meta', '_attr_obj');
    my $id   = $self->get_id;

    unless ($a_obj) {
	$a_obj = Bric::Util::Attribute::AssetType->new({'object_id' => $id,
						      'subsys'    => "id_$id"});
	$self->_set(['_attr_obj'], [$a_obj]);

	while (my ($k,$v) = each %$attr) {
	    $a_obj->set_attr({'name'     => $k,
			      'sql_type' => 'short',
			      'value'    => $v});
	}
	
	foreach my $k (keys %$meta) {
	    while (my ($f, $v) = each %{$meta->{$k}}) {
		$a_obj->add_meta({'name'  => $k,
				  'field' => $f,
				  'value' => $v});
	    }
	}
    }

    $a_obj->save;
}

=item _get_asset_type_grp

=cut

sub _get_asset_type_grp {
    my $self = shift;
    my $atg_id  = $self->get_at_grp__id;
    my $atg_obj = $self->_get('_at_grp_obj');
    
    return $atg_obj if $atg_obj;

    if ($atg_id) {
	$atg_obj = Bric::Util::Grp::AssetType->lookup({'id' => $atg_id});
	$self->_set(['_at_grp_obj'], [$atg_obj]);
    } else {
	$atg_obj = Bric::Util::Grp::AssetType->new({'name' => 'AssetType Group'});
	$atg_obj->save;

	$self->_set(['at_grp__id',     '_at_grp_obj'], 
		    [$atg_obj->get_id, $atg_obj]);
    }

    return $atg_obj;
}

=item _sync_parts

=cut

sub _sync_parts {
    my $self = shift;
    my $parts = $self->_get_parts();
    my ($new_parts, $del_parts) = $self->_get('_new_parts',
					      '_del_parts');

    # Pull of the newly created parts.
    my $created = delete $new_parts->{-1};

    # Now that we know we have an ID for $self, set element ID for
    foreach my $p_obj (@$created) {
	$p_obj->set_element__id($self->get_id);

	# Save the parts object.
	$p_obj->save;

	# Add it to the current parts list.
	$parts->{$p_obj->get_id} = $p_obj;
    }

    # Add parts that already existed when they were added..
    foreach my $p_id (keys %$new_parts) {
	# Delete this from the new list and grab the object.
	my $p_obj = delete $new_parts->{$p_id};

	# Save the parts object.
	$p_obj->save;

	# Add it to the current parts list.
	$parts->{$p_id} = $p_obj;
    }

    # Deactivate removed parts.
    foreach my $p_id (keys %$del_parts) {
	# Delete this from the deletion list and grab the object.

	my $p_obj = delete $del_parts->{$p_id};

	# This needs to happen for deleted parts.
	$p_obj->deactivate;
	$p_obj->save;
    }
    return $self;
}

#------------------------------------------------------------------------------#

=item $self = $self->_select_asset_type($id);

Select columns from the element table with primary key $id.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _select_asset_type {
    my $self = shift;
    my ($where, @bind) = @_;
    my @d;

    my $sql = 'SELECT id,'.join(',',COLS).' FROM '.TABLE;

    # Add a where clause if necessary.
    $sql .= " WHERE $where" if $where;

    my $sth  = prepare_c($sql, undef, DEBUG);
    my $rows = execute($sth, @bind);
    bind_columns($sth, \@d[0..(scalar COLS)]);
    fetch($sth);
    finish($sth);

    # Set the columns selected as well as the passed ID.
    $self->_set(['id', FIELDS], [@d]);

    return if $rows eq '0E0';
    return $self;
}

#------------------------------------------------------------------------------#

=item $self = $self->_update_asset_type();

Update values in the element table.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _update_asset_type {
    my $self = shift;

    my $sql = 'UPDATE '.TABLE.
              ' SET '.join(',', map {"$_=?"} COLS).' WHERE id=?';


    my $sth = prepare_c($sql, undef, DEBUG);
    execute($sth, $self->_get(FIELDS), $self->get_id);

    return $self;
}

#------------------------------------------------------------------------------#

=item $self = $self->_insert_asset_type

Insert new values into the element table.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _insert_asset_type {
    my $self = shift;
    my $nextval = next_key(TABLE);

    # Create the insert statement.
    my $sql = 'INSERT INTO '.TABLE.' (id,'.join(',',COLS).') '.
              "VALUES ($nextval,".join(',', ('?') x COLS).')';

    my $sth = prepare_c($sql, undef, DEBUG);
    execute($sth, $self->_get(FIELDS));

    # Set the ID of this object.
    $self->_set(['id'],[last_key(TABLE)]);

    # And finally, register this person in the "All Elements" group.
    $self->register_instance(INSTANCE_GROUP_ID, GROUP_PACKAGE);

    return $self;
}

#------------------------------------------------------------------------------#

=item $self = $self->_get_parts

Call the list function of Bric::Biz::AssetType::Parts::Container to return a list
of conainer parts of this AssetType object, or return the existing parts if
weve already loaded them.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _get_parts {
    my $self = shift;

    my $parts = $self->_get('_parts') || {};

    # Do not attempt to get the AssetType parts if we don't yet have an ID.
    return unless $self->get_id;

    # Do not load parts via 'list' if we've already done it.
    return $parts if substr(%$parts, 0, index(%$parts, '/'));

    my $cont = Bric::Biz::AssetType::Parts::Data->list(
				          { element__id => $self->get_id,
					    order_by    => 'place',
					    active      => 1 }
							);
    my $p_table = {map { $_->get_id => $_ } (@$cont)};

    $self->_set(['_parts'], [$p_table]);

    return $p_table;
}

##############################################################################

=back

=head2 Private Functions

=over 4

=item my $oc_coll = $get_oc_coll->($self)

Returns the collection of output channels for this element. The collection is
a L<Bric::Util::Coll::OCElement|Bric::Util::Coll::OCElement> object. See that
class and its parent, L<Bric::Util::Coll|Bric::Util::Coll>, for interface
details.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=item *

Unable to prepare SQL statement.

=item *

Unable to connect to database.

=item *

Unable to select column into arrayref.

=item *

Unable to execute SQL statement.

=item *

Unable to bind to columns to statement handle.

=item *

Unable to fetch row from statement handle.

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

$get_oc_coll = sub {
    my $self = shift;
    my $dirt = $self->_get__dirty;
    my ($id, $oc_coll) = $self->_get('id', '_oc_coll');
    return $oc_coll if $oc_coll;
    $oc_coll = Bric::Util::Coll::OCElement->new
      (defined $id ? {element_id => $id} : undef);
    $self->_set(['_oc_coll'], [$oc_coll]);
    $self->_set__dirty($dirt); # Reset the dirty flag.
    return $oc_coll;
};

1;
__END__

=back

=head1 NOTES

NONE.

=head1 AUTHOR

michael soderstrom <miraso@pacbell.net>

=head1 SEE ALSO

L<Bric|Bric>, L<Bric::Biz::Asset|Bric::Biz::Asset>,
L<Bric::Util::Coll::OCElement|Bric::Util::Coll::OCElement>.

=cut

