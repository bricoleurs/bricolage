package Bric::Biz::ElementType::Parts::FieldType;

###############################################################################

=head1 Name

Bric::Biz::ElementType::Parts::FieldType - Bricolage Field Type management

=cut

require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

 $field = Bric::Biz::ElementType::Parts::FieldType->new( $initial_state )

 $field = Bric::Biz::ElementType::Parts::FieldType->lookup( { id => $id } )

 ($field_list || @fields) = Bric::Biz::ElementType::Parts::FieldType->list($criteria)

 ($ids || @ids) = Bric::Biz::ElementType::Parts::FieldType->list_ids($criteria)


 $id    = $field->get_id()

 # Get/Set the name of this field.
 $field = $field->set_key_name($name)
 $name  = $field->get_key_name()

 # Get/set the description for this field.
 $field = $field->set_description($description)
 $desc  = $field->get_description()

 # Get/Set the maximum length for the data in this field.
 $field = $field->set_max_length($max_length)
 $max   = $field->get_max_length()

 # (deprecated) Get/Set whether this field is required or not.
 $field       = $field->set_required(1 || undef)
 (1 || undef) = $field->get_required()

 # (deprecated) Get/Set the quantifier flag.
 $field      = $field->set_quantifier( $quantifier )
 $quantifier = $field->get_quantifier()

 # Get/Set min occurrence specification limit
 $field = $field->set_min_occurrence($amount)
 $min = $field->get_min_occurrence()

 # Get/Set max occurrence specification limit
 $field = $field->set_max_occurrence($amount)
 $max = $field->get_max_occurrence()

 # Get/Set the data type (or SQL type) of this field.
 $field    = $field->set_sql_type();
 $sql_type = $field->get_sql_type()

 # Set the active flag for this field.
 $field       = $field->activate()
 $field       = $field->deactivate()
 (undef || 1) = $field->is_active()

 (undef || $self) = $field->remove()

 $field = $field->save()

=head1 Description

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
use Bric::Util::Attribute::FieldType;
use Bric::Config qw(ENABLE_WYSIWYG);
use Bric::Util::Time;
use Bric::Util::Fault qw(throw_gen throw_da throw_dp);

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

use constant TABLE => 'field_type';
my @COLS = qw(
    element_type__id
    name
    key_name
    description
    place
    min_occurrence
    max_occurrence
    autopopulated
    max_length
    sql_type
    widget_type
    "precision"
    cols
    rows
    length
    vals
    multiple
    default_val
    active
);

my @ATTRS = qw(
    element_type_id
    name
    key_name
    description
    place
    min_occurrence
    max_occurrence
    autopopulated
    max_length
    sql_type
    widget_type
    precision
    cols
    rows
    length
    vals
    multiple
    default_val
    active
);

use constant ORD => qw(
    key_name
    name
    description
    max_length
    min_occurrence
    max_occurrence
    widget_type
    "precision"
    default_val
    length
    cols
    rows
    vals
    multiple
    active
);

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
        id              => Bric::FIELD_READ,
        element_type_id => Bric::FIELD_RDWR,
        name            => Bric::FIELD_RDWR,
        key_name        => Bric::FIELD_RDWR,
        description     => Bric::FIELD_RDWR,
        place           => Bric::FIELD_RDWR,
        max_length      => Bric::FIELD_RDWR,
        sql_type        => Bric::FIELD_RDWR,
        widget_type     => Bric::FIELD_RDWR,
        precision       => Bric::FIELD_RDWR,
        cols            => Bric::FIELD_RDWR,
        rows            => Bric::FIELD_RDWR,
        length          => Bric::FIELD_RDWR,
        vals            => Bric::FIELD_RDWR,
        multiple        => Bric::FIELD_RDWR,
        default_val     => Bric::FIELD_RDWR,
        autopopulated   => Bric::FIELD_READ,
        active          => Bric::FIELD_READ,
        max_occurrence    => Bric::FIELD_RDWR,
        min_occurrence    => Bric::FIELD_RDWR,
        _attr           => Bric::FIELD_NONE,
        _meta           => Bric::FIELD_NONE,
        _attr_obj       => Bric::FIELD_NONE,
    });
}

#==============================================================================#
# Interface Methods                    #
#======================================#

=head1 Interface

=head2 Constructors

=over 4

=cut

#--------------------------------------#
# Constructors
#------------------------------------------------------------------------------#

=item  $field = Bric::Biz::ElementType::Parts::FieldType->new( $initial_state )

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

active

=item *

max_occurrence

=item *

min_occurrence

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

    $init->{active} = exists $init->{active} ? $init->{active} : 1;
    $init->{$_} = $init->{$_} ? 1 : 0 for qw(autopopulated multiple);
    $init->{$_} ||= 0 for qw(min_occurrence max_occurrence);
    $init->{element_type_id} ||=
          exists $init->{element_id}  ? delete $init->{element_id}
        : exists $init->{element__id} ? delete $init->{element__id}
                                      : $init->{element_type_id}
        ;
    $init->{$_} ||= 0 for qw(max_length length place cols rows length place);
    $init->{widget_type} ||= 'text';
    $init->{sql_type}    ||= 'short';

    delete $init->{meta_object};
    return $class->SUPER::new($init);
}

#------------------------------------------------------------------------------#

=item  $field = $field->copy($at_id);

Makes a copy of itself and passes back a new object. The only argument is an
element type ID. This needs to be passed since a field of one name cannot be
inserted twice into the same element type.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub copy {
    my ($self, $at_id) = @_;
    return unless $at_id && $self;
    my $copy = ref($self)->SUPER::new($self);
    return $copy->_set([qw(id element_type_id)] => [undef, $at_id]);
}

#------------------------------------------------------------------------------#

=item $field = Bric::Biz::ElementType::Parts::FieldType->lookup({ id => $id })

Returns an existing element type field object that has the id that was given
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

    my $fields = _do_list($class, $param) or return;
    # Throw an exception if we looked up more than one site.
    throw_da "Too many $class objects found" if @$fields > 1;
    return $fields->[0];
}

#------------------------------------------------------------------------------#

=item ($parts || @parts) = Bric::Biz::ElementType::Parts::FieldType->list($params)

Returns a list or array refeference of field objects that match the criteria
in the C<$params> hash reference. Supported criteria are:

=over 4

=item id

Field ID. May use C<ANY> for a list of possible values.

=item element_type_id

The ID of the Bric::Biz::ElementType object with which the field is associated.
May use C<ANY> for a list of possible values.

=item key_name

The field key name. May use C<ANY> for a list of possible values.

=item name

The field name. May use C<ANY> for a list of possible values.

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

=item max_length

The maximum length of the field. May use C<ANY> for a list of possible values.

=item required

Boolean value indicating whether or not the field is always included in an
element.

=item sql_type

Indicates how the field value should be stored in the database. Possible
values are "short", "blob", and "date". May use C<ANY> for a list of possible
values.

=item widget_type

A string indicating what widget should be used to display the field in user
interfaces. May use C<ANY> for a list of possible values.

=item precision

An inteteger indicating the precision of the field's value. Should be set only
when the C<widget_type> is set to "date". May use C<ANY> for a list of
possible values.

=item cols

The number of columns to use to display the field. Should only be set when the
C<widget_type> is set to "textarea" or "wysiwyg". May use C<ANY> for a list of
possible values.

=item rows

The number of rows to use to display the field. Should only be set when the
C<widget_type> is set to "textarea" or "wysiwyg". May use C<ANY> for a list of
possible values.

=item length

The length to use in the display of the field. Should only be set when the
C<widget_type> is set to "text". May use C<ANY> for a list of possible values.

=item multiple

A boolean value indicating whether or not the field may store multiple values.
Should only be set to a true value when the C<widget_type> is set to "select".

=item default_val

A string indicating the default value for the field. May use C<ANY> for a list
of possible values.

=item active

Boolean valule indicating whether or not the field is active.

=item max_occurrence

Specifies an upper limit to how many instances there may be of this field type.
0 represents unlimited.

=item min_occurrence

Specifies a lower limit to how many instances there may be of this field type.
0 indicates that it is not required.

=back

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub list {
    my $class = shift;
    my ($param) = @_;
    _do_list($class, $param);
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

=item $meths = Bric::Biz::ElementType->my_meths

=item (@meths || $meths_aref) = Bric::Biz::ElementType->my_meths(TRUE)

=item my (@meths || $meths_aref) = Bric::Biz::ElementType->my_meths(0, TRUE)

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
              key_name    => {
                  name     => 'key_name',
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
                      maxlength => 32,
                  },
              },
              name        => {
                  name     => 'name',
                  get_meth => sub { shift->get_name() },
                  get_args => [],
                  set_meth => sub { shift->set_name(@_) },
                  set_args => [],
                  disp     => 'Name',
                  search   => 1,
                  len      => 64,
                  req      => 1,
                  type     => 'short',
                  props    => {
                      type      => 'text',
                      length    => 32,
                      maxlength => 32,
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
              widget_type  => {
                  get_meth => sub { shift->get_widget_type(@_) },
                  get_args => [],
                  set_meth => sub { shift->set_widget_type(@_) },
                  set_args => [],
                  name     => 'widget_type',
                  disp     => 'Widget Type',
                  len      => 80,
                  req      => 1,
                  type     => 'short',
                  props    => {
                      type => 'select',
                      vals => {
                          text       => 'Text',
                          textarea   => 'Textarea',
                          select     => 'Select',
                          pulldown   => 'Pulldown',
                          radio      => 'Radio',
                          checkbox   => 'Checkbox',
                          codeselect => 'Code Select',
                          date       => 'Date',
                          ( ENABLE_WYSIWYG
                            ? ( wysiwyg    => 'WYSIWYG' )
                            : ()
                          ),
                      }
                  }
              },
              precision  => {
                  get_meth => sub { shift->get_precision(@_) },
                  get_args => [],
                  set_meth => sub { shift->set_precision(@_) },
                  set_args => [],
                  name     => 'precision',
                  disp     => 'Precision',
                  len      => 80,
                  req      => 1,
                  type     => 'short',
                  props    => {
                      type => 'select',
                      vals => Bric::Util::Time::PRECISIONS,
                  }
              },
              length => {
                  name     => 'length',
                  get_meth => sub { shift->get_length() },
                  get_args => [],
                  set_meth => sub { shift->set_length(@_) },
                  set_args => [],
                  disp     => 'Field Length',
                  len      => 8,
                  type     => 'short',
                  props    => {
                      type      => 'text',
                      length    => 8,
                      maxlength => 8,
                  },
              },
              cols => {
                  name     => 'cols',
                  get_meth => sub { shift->get_cols() },
                  get_args => [],
                  set_meth => sub { shift->set_cols(@_) },
                  set_args => [],
                  disp     => 'Columns',
                  len      => 8,
                  type     => 'short',
                  props    => {
                      type      => 'text',
                      length    => 8,
                      maxlength => 8,
                  },
              },
              rows => {
                  name     => 'rows',
                  get_meth => sub { shift->get_rows() },
                  get_args => [],
                  set_meth => sub { shift->set_rows(@_) },
                  set_args => [],
                  disp     => 'Rows',
                  len      => 8,
                  type     => 'short',
                  props    => {
                      type      => 'text',
                      length    => 8,
                      maxlength => 8,
                  },
              },
              multiple => {
                  name     => 'multiple',
                  get_meth => sub { shift->get_multiple() },
                  get_args => [],
                  set_meth => sub {
                      my ($self, $req) = @_;
                      $req = (defined $req && $req) ? 1 : 0;
                      $self->set_multiple($req);
                  },
                  set_args => [],
                  disp     => 'Multiple',
                  search   => 1,
                  len      => 1,
                  type     => 'short',
                  props    => {
                      type      => 'checkbox',
                  },
              },
              default_val => {
                  get_meth => sub { shift->get_default_val() },
                  get_args => [],
                  set_meth => sub { shift->set_default_val(@_) },
                  set_args => [],
                  name     => 'default_val',
                  disp     => 'Default Value',
                  len      => 256,
                  req      => 0,
                  type     => 'short',
                  props    => {
                      type => 'textarea',
                      cols => 40,
                      rows => 4,
                  },
              },
              vals => {
                  get_meth => sub { shift->get_vals() },
                  get_args => [],
                  set_meth => sub { shift->set_vals(@_) },
                  set_args => [],
                  name     => 'vals',
                  disp     => 'Value Options',
                  len      => 0,
                  req      => 0,
                  type     => 'short',
                  props    => {
                      type => 'textarea',
                      cols => 40,
                      rows => 6,
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
              max_occurrence    => {
                  name      => 'max_occurrence',
                  get_meth  => sub { shift->get_max_occurrence() },
                  get_args  => [],
                  set_meth  => sub { shift->set_max_occurrence(@_) },
                  set_args  => [],
                  disp      => 'Maximum Occurrence',
                  search    => 1,
                  len       => 8,
                  type      => 'short',
                  props     => {
                      type      => 'text',
                      length    => 8,
                      maxlength => 8,
                  },
              },
              min_occurrence    => {
                  name      => 'min_occurrence',
                  get_meth  => sub { shift->get_min_occurrence() },
                  get_args  => [],
                  set_meth  => sub { shift->set_min_occurrence(@_) },
                  set_args  => [],
                  disp      => 'Minimum Occurrence',
                  search    => 1,
                  len       => 8,
                  type      => 'short',
                  props     => {
                      type      => 'text',
                      length    => 8,
                      maxlength => 8,
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

=item ($ids || @ids) = Bric::Biz::ElementType::Parts::Field->list_ids($params)

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

=item $id = $field->get_id()

Returns the database id of the field object.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $name = $field->get_name()

Gets the name of the field.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $field = $field->set_name($name)

Sets the name of the field.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $key_name = $field->get_key_name()

Returns the key name.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $field = $field->set_key_name($key_name)

Sets the key name for this field.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $description = $field->get_description()

Return the human readable description field

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $field = $field->set_description($description)

Sets the human readable descripton for this field, first converting any
non-Unix line endings.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub set_description {
    my ($self, $val) = @_;
    $val =~ s/\r\n?/\n/g if defined $val;
    $self->_set( [ 'description' ] => [ $val ]);
}

=item $max_length $field->get_max_length()

Return the max length that has been registered

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $field = $field->set_max_length($max_length)

Set the max length in chars for this field

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $required = $field->get_required()

Return the required flag for this field

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $field = $field->set_required($required)

Set the flag to make this field required ( default is not)

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $repeatable = $field->get_quantifier()

Return the repeatablity flag

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $field = $field->set_quantifier($repeatable)

Sets the boolean attribute that indicates whether or not the field is
repeatable within the element.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $max = $field->get_max_occurrence()

Return the maximum occurrence

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $field = $field->set_max_occurrence($max)

Sets the maximum occurrence this field type may occur.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $min = $field->get_min_occurrence()

Return the minimum occurrence

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $field = $field->set_min_occurrence($min)

Sets the minimum occurrence this field type may occur.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $data_type = $field->get_data_type()

Returns the database datatype

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $field = $field->set_data_type($data_type)

Returns the database datatype

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $widget_type = $field->get_widget_type()

Returns a string indicating how to display the field in a UI.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $field = $field->set_widget_type($widget_type)

Sets the attribute indicating how to display the field in a UI. Possible
values are:

=over

=item text

=item textarea

=item select

=item pulldown

=item radio

=item checkbox

=item codeselect

=item wysiwyg

=item date

=back

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $precision = $field->get_precision()

Returns an inteteger indicating the precision of the field's value. Should be
set only when the C<widget_type> is set to "date".

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $field = $field->set_precision($precision)

Sets the precision for C<widget_type> "date". See
L<Bric::Util::Time|Bric::Util::Time> for documentation of the available
precisions.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $field = $field->set_cols($cols)

Sets the number of columns to use in displaying the field in a UI. Should only
be set to a non-zero value if the C<widget_type> attribute is set to
"textarea" or "wysiwyg".

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $cols = $field->set_cols()

Returns the number of columns to use in display the field in a UI.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $field = $field->set_rows($rows)

Sets the number of rows to use in displaying the field in a UI. Should only be
set to a non-zero value if the C<widget_type> attribute is set to "textarea"
or "wysiwyg".

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $rows = $field->set_rows()

Returns the number of rows to use in display the field in a UI.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $field = $field->set_length($length)

Sets the length to use in displaying the field in a UI. Should only be set to
a non-zero value if the C<widget_type> attribute is set to "text".

B<Thlength:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $length = $field->set_length()

Returns the number of length to use in display the field in a UI.

B<Thlength:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $multiple = $field->get_multiple()

Returns boolean value indicating whether the field can have multiple values.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $field = $field->set_multiple($multiple)

Sets boolean value indicating whether the field can have multiple values.
Should only be set to a true value if the C<widget_type> is "select".

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $default_val = $field->get_default_val()

Returns the default value for the field.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $field = $field->set_default_val($default_val)

Sets the default value for the field.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $vals = $field->get_vals()

Returns a string representing the possible values for the field.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $field = $field->set_vals($vals)

Sets a list of values that can be used for the field. Each potential value
should be listed on a single line, with a label following the value, separated
by a comma and optional whitespace. Commas in the value or the label should be
escaped. For example:

  larry,  Wall\, Larry
  damian, Conway\, Damian
  chip,   Salzenberg\, Chip

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

# Backwards Compatible accessors.
sub get_element__id  { shift->get_element_type_id      }
sub set_element__id  { shift->set_element_type_id(@_)  }
sub get_element_id   { shift->get_element_type_id      }
sub set_element_id   { shift->set_element_type_id(@_)  }

sub set_map_type__id { shift }
sub get_map_type__id { 0 }
sub set_publishable  { shift }
sub get_publishable  { 0 }

# Boolean accessors.
sub set_autopopulated { shift->_set(['autopopulated'] => [shift() ? 1 : 0] ) }
sub set_multiple      { shift->_set(['multiple']      => [shift() ? 1 : 0] ) }

#------------------------------------------------------------------------------#

=item $val = $data->set_attr($name, $value);

=item $val = $data->get_attr($name);

Get/Set attributes on this element type.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub set_attr {
    my ($self, $name, $val) = @_;

    if (my $attr_obj = $self->_get_attr_obj) {
        $attr_obj->set_attr({
            name     => $name,
            sql_type => 'short',
            value    => $val
        });
    } else {
        my $attr = $self->_get('_attr');
        $self->_set(['_attr'], [$attr = {}])
            unless $attr;
        $attr->{$name} = $val;
    }

    return $val;
}

sub get_attr {
    my ($self, $name) = @_;

    if (my $attr_obj = $self->_get_attr_obj) {
        return $attr_obj->get_attr({name => $name});
    }

    my $attr = $self->_get('_attr') or return;
    return $attr->{$name};
}

sub all_attr {
    my $self = shift;

    if (my $attr_obj = $self->_get_attr_obj) {
        return $attr_obj->get_attr_hash;
    }

    return $self->_get('_attr');
}

#------------------------------------------------------------------------------#

=item $val = $data->set_meta($name, $field, $value);

=item $val = $data->get_meta($name, $field);

=item $val = $data->get_meta($name);

Get/Set attribute metadata on this element type.  Calling the 'get_meta' method
without '$field' returns all metadata names and values as a hash.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub set_meta {
    my ($self, $name, $field, $val) = @_;
    if (my $attr_obj = $self->_get_attr_obj) {
        $attr_obj->add_meta({
            name  => $name,
            field => $field,
            value => $val,
        });
    } else {
        my $meta = $self->_get('_meta');
        $self->_set(['_meta'], [$meta = {}])
            unless $meta;
        $meta->{$name}->{$field} = $val;
    }

    return $val;
}

sub get_meta {
    my ($self, $name, $field) = @_;

    if (my $attr_obj = $self->_get_attr_obj) {
        return $attr_obj->get_meta({
            name  => $name,
            field => $field
        }) if defined $field;
        my $meta = $attr_obj->get_meta({name => $name});
        return { map { $_ => $meta->{$_}->{value} } keys %$meta };
    }

    my $meta = $self->_get('_meta') || return;
    return $meta->{$name}->{$field} if $field;
    return $meta->{$name};
}

#------------------------------------------------------------------------------#

=item $field = $field->activate()

Activates the field type object.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub activate { return shift->_set(['active'] => [1]) }

#------------------------------------------------------------------------------#

=item $field = $field->deactivate()

Deactivates the field type object.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub deactivate { return shift->_set(['active'] => [0]) }

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

Removes this object completely from the DB. Returns true if active or false
otherwise.

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

=head1 Private

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
        id              => 'id',
        element_type_id => 'element_type__id',
        element_id      => 'element_type__id',
        element__id     => 'element_type__id',
        max_length      => 'max_length',
        place           => 'place',
        cols            => 'cols',
        rows            => 'cols',
        length          => 'length',
        max_occurrence  => 'max_occurrence',
        min_occurrence  => 'min_occurrence',
    );

    my %bools = (
        autopopulated => 'autopopulated',
        active        => 'active',
        multiple      => 'multiple',
    );

    my %strings = (
        key_name    => 'key_name',
        name        => 'name',
        description => 'description',
        sql_type    => 'sql_type',
        vals        => 'vals',
        default_val => 'default_val',
        widget_type => 'widget_type',
    );

    my $sql = 'SELECT id, ' . join(', ', @COLS) . ' FROM ' . TABLE;
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
        bind_columns($select, \@d[0..(scalar @COLS)]);

        while (fetch($select)) {
            my $self = bless {}, $class;

            $self->_set(['id', @ATTRS], [@d]);

            my $id = $self->get_id;
            my $a_obj = Bric::Util::Attribute::FieldType->new
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
    my ($id, $attr_obj) = $self->_get(qw(id _attr_obj));

    unless ($attr_obj || not defined $id) {
        $attr_obj = Bric::Util::Attribute::FieldType->new({
            object_id => $id,
            subsys    => "id_$id"
        });
        $self->_set(['_attr_obj'] => [$attr_obj]);
    }

    return $attr_obj;
}

sub _save_attr {
    my $self = shift;
    my ($id, $attr_obj, $attr, $meta) = $self->_get(qw(id _attr_obj _attr _meta));
    return unless $attr_obj || $attr;

    if ($attr) {
        while (my ($k,$v) = each %$attr) {
            $attr_obj->set_attr({
                name     => $k,
                sql_type => 'short',
                value    => $v
            });
        }
    }

    if ($meta) {
        foreach my $k (keys %$meta) {
            while (my ($f, $v) = each %{$meta->{$k}}) {
                $attr_obj->add_meta({
                    name  => $k,
                    field => $f,
                    value => $v
                });
            }
        }
    }

    $attr_obj->save;
}

#------------------------------------------------------------------------------#

=item _update_data

Update the field_type table.

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
              ' SET '.join(', ', map {"$_ = ?"} @COLS).' WHERE id=?';

    my $sth = prepare_c($sql, undef);
    execute($sth, $self->_get(@ATTRS), $self->get_id);
    return 1;
}

#------------------------------------------------------------------------------#

=item _insert_data

Insert rows into the field_type table.

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
    my $sql = 'INSERT INTO '.TABLE.' (id, '.join(', ', @COLS).") ".
              "VALUES ($nextval, ".join(', ', ('?') x @COLS).')';

    my $sth = prepare_c($sql, undef);
    execute($sth, $self->_get(@ATTRS));

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

=head1 Notes

NONE

=head1 Author

michael soderstrom ( miraso@pacbell.net )

=head1 See Also

L<perl>,L<Bric>,L<Bric::Biz::Asset::Business::Story>,L<Bric::Biz::ElementType>,

=cut
