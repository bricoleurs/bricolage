package Bric::Biz::AssetType::Parts::Data;
###############################################################################

=head1 NAME

Bric::Biz::AssetType::Parts::Data - The place where fields with in an element are registered with rules to their usage

=head1 VERSION

$LastChangedRevision$

=cut

require Bric; our $VERSION = Bric->VERSION;

=head1 DATE

$LastChangedDate$

=head1 SYNOPSIS

 $field = Bric::Biz::AssetType::Parts::Data->new( $initial_state )

 $field = Bric::Biz::AssetType::Parts::Data->lookup( { id => $id } )

 ($field_list || @fields) = Bric::Biz::AssetType::Parts::Data->list($criteria)

 ($ids || @ids) = Bric::Biz::AssetType::Parts::Data->list_ids($criteria)


 $id    = $field->get_id()

 # Get/Set the name of this field.
 $field = $field->set_key_name($name)
 $name  = $field->get_key_name()

 # Get/set the description for this field.
 $field = $field->set_description($description)
 $desc  = $field->get_description()

 # Get/Set the publishable status of this field.
 $field       = $field->set_publishable(undef || 1)
 (undef || 1) = $field->is_publishable()

 # Get/Set the maximum length for the data in this field.
 $field = $field->set_max_length($max_length)
 $max   = $field->get_max_length()

 # Get/Set whether this field is required or not.
 $field       = $field->set_required(1 || undef)
 (1 || undef) = $field->get_required()

 # Get/Set the quantifier flag.
 $field      = $field->set_quantifier( $quantifier )
 $quantifier = $field->get_quantifier()

 # Get/Set the data type (or SQL type) of this field.
 $field    = $field->set_sql_type();
 $sql_type = $field->get_sql_type()

 # Set the active flag for this field.
 $field       = $field->activate()
 $field       = $field->deactivate()
 (undef || 1) = $field->is_active()

 (undef || $self) = $field->remove()

 $field = $field->save()

=head1 DESCRIPTION

This class holds the data about data that will eventualy populate Published
Assets. The C<key_name> and C<description> fields can be set as can a number
of rules.

The max length field.   This will allow someone to set the max length allowed
for their field.   It will have a rule set upon it so that the max length will
not be greater than any available storage.   The field length will map to
what ever storarge is available for a field just larger than the one listed
( Thought needs to be given how to handle those that change their length
after data has been entered as it might switch storage catagories)

The quantifier field will state whether the field may be repeated indefinitely,
zero or more times, zero or one, one, or an arbitrary number of times.

the sql type will map to a type in the DB ( varchar or date )

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
use Bric::Util::Attribute::AssetTypeData;
use Bric::Util::Fault qw(throw_gen);

#==============================================================================#
# Inheritance                          #
#======================================#

# The parent module should have a 'use' line if you need to import from it.
# use Bric;
use base qw(Bric);

#=============================================================================#
# Function Prototypes                  #
#======================================#

# None

#==============================================================================#
# Constants                            #
#======================================#

use constant DEBUG => 0;

use constant TABLE => 'at_data';
use constant COLS  => qw(
                         element__id
                         key_name
                         description
                         place
                         required
                         quantifier
                         autopopulated
                         map_type__id
                         publishable
                         max_length
                         sql_type
                         active);

use constant ATTRS  => qw(
                         element_type_id
                         key_name
                         description
                         place
                         required
                         quantifier
                         autopopulated
                         map_type_id
                         publishable
                         max_length
                         sql_type
                         active);

use constant ORD => qw(key_name description max_length required quantifier active);

#==============================================================================#
# Fields                               #
#======================================#

#--------------------------------------#
# Public Class Fields
our $METHS;

#--------------------------------------#
# Private Class Fields
# NONE

#--------------------------------------#
# Instance Fields

# This method of Bricolage will call 'use fields' for you and set some permissions.
BEGIN {
    Bric::register_fields({
                         # Public Fields

                         # The database id field
                         'id'                  => Bric::FIELD_READ,

                         # the element type that this is associated with
                         'element_type_id'    => Bric::FIELD_RDWR,

                         # The meta object ID.
                         'map_type_id'        => Bric::FIELD_RDWR,

                         # The human readable name field
                         'key_name'            => Bric::FIELD_RDWR,

                         # The human readable description Field
                         'description'         => Bric::FIELD_RDWR,

                         # the order in which this will be in the container
                         'place'               => Bric::FIELD_RDWR,

                         # The max length in chars
                         'max_length'          => Bric::FIELD_RDWR,

                         # The required flag
                         'required'            => Bric::FIELD_RDWR,

                         # The type of repeatability for this field
                         'quantifier'          => Bric::FIELD_RDWR,

                         # The type in the data base
                         'sql_type'            => Bric::FIELD_RDWR,

                         # If this field is publishable
                         'publishable'         => Bric::FIELD_RDWR,

                         autopopulated         => Bric::FIELD_READ,

                         # The active flag
                         'active'              => Bric::FIELD_READ,

                         # Private Fields

                         # Hold attribute info until this object is saved.
                         '_attr'                => Bric::FIELD_NONE,
                         '_meta'                => Bric::FIELD_NONE,

                         # Holds the attribute object for this object.
                         '_attr_obj'            => Bric::FIELD_NONE,
                        });
}

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

=item  $field = Bric::Biz::AssetType::Parts::Data->new( $initial_state )

Creates a new element type Field Part with the values associated with the
initial state

Supported Keys:

=over 4

=item *

element_type_id (required)

=item *

meta_object

=item *

key_name

=item *

description

=item *

place

=item *

required

=item *

quantifier

=item *

sql_type

=item *

publishable

=item *

active

=back

B<Throws:>
NONE

B<Side Effects:>
NONE

B<Notes:>
NONE

=cut

sub new {
    my $class = shift;
    my ($init) = @_;

    $init->{'active'} = exists $init->{'active'} ? $init->{'active'} : 1;
    $init->{$_} = $init->{$_} ? 1 : 0 for qw(required publishable autopopulated);
    $init->{element_type_id} ||=
          exists $init->{element_id}  ? delete $init->{element_id}
        : exists $init->{element__id} ? delete $init->{element__id}
                                      : $init->{element_type_id}
        ;
    $init->{map_type_id} = delete $init->{map_type__id}
      if exists $init->{map_type__id};

    $init->{'place'}  ||= 0;
    delete $init->{'meta_object'};
    my $self = bless {}, $class;
    $self->SUPER::new($init);
    return $self;
}

#------------------------------------------------------------------------------#

=item  $field = $field->copy($at_id);

Makes a copy of itself and passes back a new object. The only argument is an
asset type ID. This needs to be passed since a field of one name cannot be
inserted twice into the same asset type.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub copy {
    my $self = shift;
    my ($at_id) = @_;
    my $self_copy;

    return unless $at_id;
    return unless $self;

    $self_copy = bless {}, ref $self;

    my @k = keys %$self;

    # Copy the object.
    $self_copy->_set(\@k, [$self->_get(@k)]);
    # Clear out fields specific to the original.
    $self_copy->_set(['id', 'element_type_id'], [undef, $at_id]);

    $self_copy->SUPER::new();

    return $self_copy;
}

#------------------------------------------------------------------------------#

=item $field = Bric::Biz::AssetType::Parts::Data->lookup( { id => $id } )

Returns an existing Asset type field object that has the id that was given
as an argument

B<Throws:>
NONE

B<Side Effects:>
NONE

B<Notes:>
NONE

=cut

sub lookup {
    my ($class, $param) = @_;
    my $self = $class->cache_lookup($param);
    return $self if $self;

    $self = bless {}, $class;
    return unless $param->{'id'};
    $self->SUPER::new();
    $self->_select_data($param->{'id'});

    # Set the attribute object.
    my $id = $self->get_id;
    my $a_obj = Bric::Util::Attribute::AssetTypeData->new({
        'object_id' => $id,
        'subsys'    => "id_$id"
    });
    $self->_set(['_attr_obj'], [$a_obj]);
    return $self;
}

#------------------------------------------------------------------------------#

=item ($parts || @parts) = Bric::Biz::AssetType::Parts::Data->list($params)

Returns a list or array refeference of field objects that match the criteria
in the C<$params> hash reference. Supported criteria are:

=over 4

=item id

Field ID. May use C<ANY> for a list of possible values.

=item element_type_id

The ID of the Bric::Biz::AssetType object with which the field is associated.
May use C<ANY> for a list of possible values.

=item key_name

The field key name. May use C<ANY> for a list of possible values.

=item description

The field description. May use C<ANY> for a list of possible values.

=item place

The field place relative to other fields in the same element type. May use
C<ANY> for a list of possible values.

=item quantifier

Boolean value indicating whether the field is single or can be multiple.

=item autopopulated

Boolean value indicating whether the field's value is autopopulated by a media
document.

=item map_type_id

May use C<ANY> for a list of possible values.

=item max_length

The maximum length of the field. May use C<ANY> for a list of possible values.

=item publishable

Boolean value indicating whether or not the field is publishable.

=item required

Boolean value indicating whether or not the field is always included in an
element.

=item sql_type

Indicates how the field value should be stored in the database. Possible
values are "short", "blob", and "date". May use C<ANY> for a list of possible
values.

=item active

Boolean valule indicating whether or not the field is active.

=back

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub list {
    my $class = shift;
    my ($param) = @_;
    _do_list($class,$param);
}

##############################################################################

=item my $data_href = Bric::Biz::Site->href($params);

Returns an anonymous hash of data objects based on the search parameters
passed via an anonymous hash. The hash keys will be the site IDs, and the
values will be the corresponding data elements. The supported lookup keys are
the same as those for C<list()>.

B<Throws:>

=over 4

=item Exception::DA

=back

=cut

sub href { _do_list(@_, undef, 1) }

=back

=head2 Destructors

=over 4

=item $self->DESTROY

Dummy method to prevent wasting time trying to AUTOLOAD DESTROY.

=back

=cut

sub DESTROY {
    # This method should be here even if its empty so that we don't waste time
    # making Bricolage's autoload method try to find it.
}

#--------------------------------------#

=head2 Public Class Methods

=over 4

=item $meths = Bric::Biz::AssetType->my_meths

=item (@meths || $meths_aref) = Bric::Biz::AssetType->my_meths(TRUE)

=item my (@meths || $meths_aref) = Bric::Biz::AssetType->my_meths(0, TRUE)

Returns an anonymous hash of introspection data for this object. If called
with a true argument, it will return an ordered list or anonymous array of
introspection data. If a second true argument is passed instead of a first,
then a list or anonymous array of introspection data will be returned for
properties that uniquely identify an object (excluding C<id>, which is
assumed).

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

B<Notes:> Not yet written.

=cut

sub my_meths {
    my ($pkg, $ord, $ident) = @_;

    # Create 'em if we haven't got 'em.
    $METHS ||= {
              name        => {
                  name     => 'name',
                  get_meth => sub { shift->get_key_name() },
                  get_args => [],
                  set_meth => sub { shift->set_key_name(@_) },
                  set_args => [],
                  disp     => 'Key Name',
                  search   => 1,
                  len      => 64,
                  req      => 1,
                  type     => 'short',
                  props    => {
                      type      => 'text',
                      length    => 32,
                      maxlength => 64,
                  },
              },
              description => {
                  get_meth => sub { shift->get_description() },
                  get_args => [],
                  set_meth => sub { shift->set_description(@_) },
                  set_args => [],
                  name     => 'description',
                  disp     => 'Description',
                  len      => 256,
                  req      => 0,
                  type     => 'short',
                  props    => {
                      type => 'textarea',
                      cols => 40,
                      rows => 4,
                  },
              },
              max_length => {
                  name     => 'max_length',
                  get_meth => sub { shift->get_max_length() },
                  get_args => [],
                  set_meth => sub { shift->set_max_length(@_) },
                  set_args => [],
                  disp     => 'Max length',
                  search   => 1,
                  len      => 8,
                  type     => 'short',
                  props    => {
                      type      => 'text',
                      length    => 8,
                      maxlength => 8,
                  },
              },
              required => {
                  name     => 'required',
                  get_meth => sub { shift->get_required() },
                  get_args => [],
                  set_meth => sub {
                      my ($self, $req) = @_;
                      $req = (defined $req && $req) ? 1 : 0;
                      $self->set_required($req);
                  },
                  set_args => [],
                  disp     => 'Required',
                  search   => 1,
                  len      => 1,
                  type     => 'short',
                  props    => {
                      type      => 'checkbox',
                  },
              },
              quantifier => {
                  name     => 'quantifier',
                  get_meth => sub { shift->get_quantifier() },
                  get_args => [],
                  set_meth => sub {
                      # note: $rep is boolean
                      my ($self, $rep) = @_;
                      $rep = (defined $rep && $rep) ? 1 : 0;
                      $self->set_quantifier($rep);
                  },
                  set_args => [],
                  disp     => 'Repeatable',
                  len      => 1,
                  type     => 'short',
                  props    => {
                      type      => 'checkbox',
                  },
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
                  props    => {
                      type => 'checkbox',
                  },
              },
          };

    if ($ord) {
        return wantarray ? @{$METHS}{&ORD} : [@{$METHS}{&ORD}];
    } elsif ($ident) {
        return wantarray ? $METHS->{name} : [$METHS->{name}];
    } else {
        return $METHS;
    }
}

##############################################################################

=item ($ids || @ids) = Bric::Biz::AssetType::Parts::Field->list_ids($params)

Returns the ids of the field objects that match the given criteria in the
C<$params> hash reference. See C<list()> for a list of supported parameters.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub list_ids {
    my $class = shift;
    my ($param) = @_;
    _do_list($class, $param, 1);
}

##############################################################################

=back

=head2 Public Instance Methods

=over 4

=item $field = $field->set_publishable( 1 || undef)

Sets the flag for if this is a publishable field

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

#------------------------------------------------------------------------------#

=item (undef || 1) = $field->get_publishable()

Returns if this is a publishable field

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

#------------------------------------------------------------------------------#

=item set_name

B<Notes:> This method no longer exists. Use set_key_name instead.

=cut

sub set_name {
    my ($pkg,$file,$line) = caller;
    my $msg = "ERROR: [$file:$line] called the removed method 'set_name'";
    throw_gen(error => $msg);
}

=item get_name

B<Notes:> This method no longer exists. Use get_key_name instead.

=cut

sub get_name {
    my ($pkg,$file,$line) = caller;
    my $msg = "ERROR: [$file:$line] called the removed method 'get_name'";
    throw_gen(error => $msg);
}

=item $field = $field->set_key_name( $name )

Sets the key name for this field.  The display name is stored in the 'disp'
attribute.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

#------------------------------------------------------------------------------#

=item $name = $field->get_key_name()

Returns the key name.  The display name is stored in the 'disp' attribute

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

#------------------------------------------------------------------------------#

=item $field = $field->set_description($description)

Sets the human readable descripton for this field

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

#------------------------------------------------------------------------------#

=item $description = $field->get_description()

Return the human readable description field

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

#------------------------------------------------------------------------------#

=item $field = $field->set_max_length( $max_length)

Set the max length in chars for this field

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

#------------------------------------------------------------------------------#

=item $max_length $field->get_max_length()

Return the max length that has been registered

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

#------------------------------------------------------------------------------#

=item $field = $field->set_required(1 || undef)

Set the flag to make this field required ( default is not)

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

#------------------------------------------------------------------------------#

=item (1 || undef) = $field->get_required()

Return the required flag for this field

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

#------------------------------------------------------------------------------#

=item $field = $field->set_quantifier( $reperatable )

Set the repeatability of this field options are (*, +, (0 || 1), 1).  Might 
want to make this more friendly

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

#------------------------------------------------------------------------------#

=item $quantifier = $field->get_quantifier()

Return the repeatablity flag

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

#------------------------------------------------------------------------------#

=item $field = $field->set_data_type()

Returns the database datatype

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

#------------------------------------------------------------------------------#

=item $data_type = $field->set_data_type()

Returns the database datatype

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

#------------------------------------------------------------------------------#

=item $id = $field->get_id()

Returns the database id of the field object.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_element__id  { shift->get_element_type_id      }
sub set_element__id  { shift->set_element_type_id(@_)  }
sub get_element_id   { shift->get_element_type_id      }
sub set_element_id   { shift->set_element_type_id(@_)  }
sub get_map_type__id { shift->get_map_type_id          }
sub set_map_type__id { shift->set_map_type_id(@_)      }

#------------------------------------------------------------------------------#

=item $val = $data->set_attr($name, $value);

=item $val = $data->get_attr($name);

Get/Set attributes on this asset type.

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
    my $attr_obj = $self->_get_attr_obj;
    my $attr     = $self->_get('_attr', '_attr_obj');

    if ($attr_obj) {
        $attr_obj->set_attr({'name'     => $name,
                             'sql_type' => 'short',
                             'value'    => $val});
    } else {
        $attr->{$name} = $val;

        $self->_set(['_attr'], [$attr]);
    }

    return $val;
}

sub get_attr {
    my $self = shift;
    my ($name) = @_;
    my $attr_obj = $self->_get_attr_obj;
    my $attr     = $self->_get('_attr', '_attr_obj');

    # If we aren't saved yet, return anything we have cached.
    unless ($attr_obj) {
        return $attr->{$name};
    }

    return $attr_obj->get_attr({'name' => $name});
}

sub all_attr {
    my $self = shift;
    my $attr_obj = $self->_get_attr_obj;
    my $attr     = $self->_get('_attr');

    unless ($attr_obj) {
        return $attr;
    }

    return $attr_obj->get_attr_hash();
}

#------------------------------------------------------------------------------#

=item $val = $data->set_meta($name, $field, $value);

=item $val = $data->get_meta($name, $field);

=item $val = $data->get_meta($name);

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

    return $val;
}

sub get_meta {
    my $self = shift;
    my ($name, $field) = @_;
    my $attr_obj = $self->_get_attr_obj;

    unless ($attr_obj) {
        my $meta = $self->_get('_meta');
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
        my $meta = $attr_obj->get_meta({'name' => $name});

        return { map { $_ => $meta->{$_}->{'value'} } keys %$meta };
    }
}

#------------------------------------------------------------------------------#

=item $field = $field->activate()

Makes the field object active

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub activate { $_[0]->_set(['active'], [1]) }

#------------------------------------------------------------------------------#

=item $field = $field->deactivate()
 
Makes the object inactive

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub deactivate { $_[0]->_set(['active'], [0]) }

#------------------------------------------------------------------------------#

=item (undef || 1) = $field->is_active()

Returns 1 if active or undef otherwise

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub is_active { return $_[0]->_get('active') ? $_[0] : undef }

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

    return unless $id;

    my $sql = 'DELETE FROM '.TABLE.' WHERE id=?';

    my $sth = prepare_c($sql, undef);
    execute($sth, $id);

    return $self;
}

#------------------------------------------------------------------------------#

=item $field = $field->save()

Saves the changes made to the database

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub save {
    my $self = shift;

    if ($self->_get('id')) {
        $self->_update_data;
    } else {
        $self->_insert_data;
    }

    # Save the attribute information.
    $self->_save_attr;

    # Call our parents save method.
    $self->SUPER::save;
}

#==============================================================================#

=back

=head1 PRIVATE

=head2 Private Class Methods

=over 4

=item _do_list

called by list and list ids this does the brunt of their work

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _do_list {
    my $class = shift;
    my ($param, $ids, $href) = @_;
    my (@where, @bind);
    my %ints = (
        element_type_id => 'element__id',
        element_id      => 'element__id',
        element__id     => 'element__id',
        map_type__id    => 'map_type__id',
        map_type_id     => 'map_type__id',
        max_length      => 'max_length',
        place           => 'place',
    );

    my %bools = (
        publishable   => 'publishable',
        required      => 'required',
        quantifier    => 'quantifier',
        autopopulated => 'autopopulated',
        active        => 'active',
    );

    my %strings = (
        key_name    => 'key_name',
        description => 'description',
        sql_type    => 'sql_type',
    );

    my $sql = 'SELECT id, ' . join(', ', COLS) . ' FROM ' . TABLE;
    while (my ($k, $v) = each %$param) {
        if ($ints{$k}) {
            push @where, any_where($v, "$ints{$k} = ?", \@bind);
        }
        elsif ($strings{$k}) {
            push @where, any_where(
                $v,
                "LOWER($strings{$k}) LIKE LOWER(?)",
                \@bind
            );
        }
        elsif ($bools{$k}) {
            push @where, "$bools{$k} = ?";
            push @bind,  $v ? 1 : 0;
        }
        else {
            # Fail silently.
        }
    }

    # Add the where clause if there is one.
    $sql .= ' WHERE '.join(' AND ', @where) if @where;

    # Add the ORDER BY clause if there is one.
    $sql .= " ORDER BY $param->{order_by}" if $param->{order_by};
    my $select = prepare_ca($sql, undef);

    if ($ids) {
        # called from list_ids give em what they want
        my $return = col_aref($select, @bind);
        return wantarray ? @$return : $return;

    } else {
        # this must have been called from list so give objects
        my (@d, @objs, %objs);
        execute($select, @bind);
        bind_columns($select, \@d[0..(scalar COLS)]);

        while (fetch($select)) {
            my $self = bless {}, $class;

            $self->_set(['id', ATTRS], [@d]);

            my $id = $self->get_id;
            my $a_obj = Bric::Util::Attribute::AssetTypeData->new
              ({ 'object_id' => $id,
                 'subsys'    => "id_$id"});
            $self->_set(['_attr_obj'], [$a_obj]);
            $href ? $objs{$d[0]} = $self->cache_me :
              push @objs, $self->cache_me;
        }
        return \%objs if $href;
        return wantarray ? @objs : \@objs;
    }
}

#--------------------------------------#

=back

=head2 Private Instance Methods

Needing to be documented.

=over

=item _get_attr_obj

=cut

sub _get_attr_obj {
    my $self = shift;
    my $attr_obj = $self->_get('_attr_obj');
    my $id = $self->get_id;

    unless ($attr_obj || not defined($id)) {
        $attr_obj = Bric::Util::Attribute::AssetTypeData->new(
                                     {'object_id' => $id,
                                      'subsys'    => "id_$id"});
        $self->_set(['_attr_obj'], [$attr_obj]);
    }

    return $attr_obj;
}

sub _save_attr {
    my $self = shift;
    my $a_obj = $self->_get_attr_obj;
    my ($attr, $meta) = $self->_get('_attr', '_meta');
    my $id   = $self->get_id;

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

    $a_obj->save;
}

#------------------------------------------------------------------------------#

=item _select_data

Select rows from the element_data table.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _select_data {
    my $self = shift;
    my ($id) = @_;
    my @d;
    my $sql = 'SELECT '.join(',',COLS).' FROM '.TABLE.
              ' WHERE id = ?';

    my $sth = prepare_ca($sql, undef);
    execute($sth, $id);
    bind_columns($sth, \@d[0..(scalar COLS - 1)]);
    fetch($sth);
    finish($sth);

    # Set the columns selected as well as the passed ID.
    $self->_set([ATTRS, 'id'], [@d, $id]);
    $self->cache_me;
}

#------------------------------------------------------------------------------#

=item _update_data

Update the element_data table.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _update_data {
    my $self = shift;
    my $sql = 'UPDATE '.TABLE.
              ' SET '.join(', ', map {"$_ = ?"} COLS).' WHERE id=?';


    my $sth = prepare_c($sql, undef);
    execute($sth, $self->_get(ATTRS), $self->get_id);
    return 1;
}

#------------------------------------------------------------------------------#

=item _insert_data

Insert rows into the element_data table.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _insert_data {
    my $self = shift;
    my $nextval = next_key(TABLE);

    # Create the insert statement.
    my $sql = 'INSERT INTO '.TABLE.' (id, '.join(', ', COLS).") ".
              "VALUES ($nextval,".join(', ', ('?') x COLS).')';

    my $sth = prepare_c($sql, undef);
    execute($sth, $self->_get(ATTRS));

    # Set the ID of this object.
    $self->_set(['id'],[last_key(TABLE)]);

    return 1;
}

#--------------------------------------#

=back

=head2 Private Functions

NONE

=cut

1;

__END__

=head1 NOTES

NONE

=head1 AUTHOR

michael soderstrom ( miraso@pacbell.net )

=head1 SEE ALSO

L<perl>,L<Bric>,L<Bric::Biz::Asset::Business::Story>,L<Bric::Biz::AssetType>,

=cut
