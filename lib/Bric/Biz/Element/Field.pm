package Bric::Biz::Element::Field;

###############################################################################

=head1 Name

Bric::Biz::Element::Field - Data (Field) Element

=cut

require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

  # Creation of New Objects
  $data = Bric::Biz::Element::Field->new($params);
  $data = Bric::Biz::Element::Field->lookup({ id => $id });
  @data = Bric::Biz::Element::Field->list($params);

  # Retrieval of Object IDs
  @ids = = Bric::Biz::Element::Field->list_ids($params);

  # Manipulation of Data Field
  $data = $data->set_value( $data_value );
  $data_value = $data->get_value;

=head1 Description

This class contains the contents of field elements, also known as data
elements. These are the objects that hold the values of story element fields.
This class inherits from
L<Bric::Biz::Element|Bric::Biz::Element>.

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
use Bric::Util::Time qw(:all);
use Bric::Util::Fault qw(throw_gen throw_da);
use Bric::Biz::ElementType::Parts::FieldType;

#==============================================================================#
# Inheritance                          #
#======================================#

# The parent module should have a 'use' line if you need to import from it.
# use Bric;
use base qw(Bric::Biz::Element);

#=============================================================================#
# Function Prototypes                  #
#======================================#

# None

#==============================================================================#
# Constants                            #
#======================================#

use constant DEBUG => 0;

use constant S_TABLE => 'story_field';
use constant M_TABLE => 'media_field';

my @SEL_COLS = qw(
    f.id
    ft.name
    ft.key_name
    ft.description
    ft.autopopulated
    ft.multiple
    ft.max_length
    ft.sql_type
    ft.widget_type
    f.field_type__id
    f.object_instance_id
    f.parent_id
    f.place
    f.object_order
    f.hold_val
    f.date_val
    f.short_val
    f.blob_val
    f.active
);

my @SEL_FIELDS = qw(
    id
    name
    key_name
    description
    _autopopulated
    _multiple
    max_length
    sql_type
    widget_type
    field_type_id
    object_instance_id
    parent_id
    place
    object_order
    _hold_val
    _date_val
    _short_val
    _blob_val
    _active
);

my @COLS = qw(
    field_type__id
    object_instance_id
    parent_id
    place
    object_order
    hold_val
    date_val
    short_val
    blob_val
    active
);

my @FIELDS = qw(
    field_type_id
    object_instance_id
    parent_id
    place
    object_order
    _hold_val
    _date_val
    _short_val
    _blob_val
    _active
);

#==============================================================================#
# Fields                               #
#======================================#

#--------------------------------------#
# Public Class Fields
# None.

#--------------------------------------#
# Private Class Fields
# None.

#--------------------------------------#
# Instance Fields

# This method of Bricolage will call 'use fields' for you and set some permissions.
BEGIN {
    Bric::register_fields({
        field_type_id   => Bric::FIELD_RDWR,
        sql_type        => Bric::FIELD_READ,
        widget_type     => Bric::FIELD_READ,
        max_length      => Bric::FIELD_READ,
        _autopopulated  => Bric::FIELD_NONE,
        _multiple       => Bric::FIELD_NONE,
        _hold_val       => Bric::FIELD_NONE,
        _active         => Bric::FIELD_NONE,
        _date_val       => Bric::FIELD_NONE,
        _short_val      => Bric::FIELD_NONE,
        _blob_val       => Bric::FIELD_NONE,
        _field_type    => Bric::FIELD_NONE,
    });
}

#==============================================================================#
# Interface Methods                    #
#======================================#

=head1 Interface

=head2 Constructors

=over 4

=item my $data = Bric::Biz::Element::Field->new($init)

Construct a new data element object. The supported initial attributes are:

=over 4

=item object_type

A string identifying the type of document the new data element is associated
with. It's value can be "story " or "media".

=item object_instance_id

The ID of the story or media document the new data element is associated with.

=item place

The order of this element relative to the other subelements of the parent
element.

=item field_type

=item element_data

The Bric::Biz::ElementType::Parts::FieldType object that defines the structure of the
new data element.

=item field_type_id

=item element_data_id

The ID of the Bric::Biz::ElementType::Parts::FieldType object that defines the
structure of the new data element.

=item parent_id

The ID of the container element that is the parent of the new data element.

=item active

A boolean value indicating whether the container element is active or
inactive.

=back

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub new {
    my ($class, $init) = @_;

    # check active and object
    $init->{_active} = !exists $init->{active} ? 1
      : delete $init->{active} ? 1 : 0;
    $init->{_hold_val} = delete $init->{hold_val} ? 1 : 0;
    $init->{place} ||= 0;

    if (my $doc = delete $init->{object}) {
        $init->{object_instance_id} = $doc->get_version_id;
        $init->{object_type}        = $doc->key_name;
    } else {
        throw_gen 'Cannot create without object type.'
            unless $init->{object_type}
    }

    my $atd = delete $init->{field_type} || delete $init->{element_data};
    if (!$atd && $init->{field_type_id} || $init->{element_data_id}) {
        $atd = Bric::Biz::ElementType::Parts::FieldType->lookup({
            id => $init->{field_type} ||= delete $init->{element_data}
        });
    }

    if ($atd) {
        $init->{field_type_id}  = $atd->get_id;
        $init->{name}           = $atd->get_name;
        $init->{key_name}       = $atd->get_key_name;
        $init->{description}    = $atd->get_description;
        $init->{sql_type}       = $atd->get_sql_type;
        $init->{widget_type}    = $atd->get_widget_type;
        $init->{_autopopulated} = $atd->get_autopopulated;
        $init->{_multiple}      = $atd->get_multiple;
        $init->{max_length}     = $atd->get_max_length;
        $init->{_field_type}    = $atd;
    }

    my $self = $class->SUPER::new($init);
    $self->set_value($atd->get_default_val) if $atd;
    return $self;
}

################################################################################

=item my $data = Bric::Biz::Element::Field->lookup($params)

Looks up a data element in the database by its ID and returns it. The lookup
parameters are:

=over 4

=item id

The ID of the data element to lookup. Required.

=item object

A story or media document object with which the data element is
associated. Required unless C<object_type> is specified.

=item object_type

The type of document object with which the data element is associated. Must
be either "media" or "story". Required unless C<object> is specified.

=back

B<Throws:>

=over 4

=item Missing required Parameter 'id'.

=item Missing required Parameter 'object_type' or 'object'.

=item Improper type of object passed to lookup.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub lookup {
    my ($class, $param) = @_;
    my $self = $class->cache_lookup($param);
    return $self if $self;

    # Check for the proper args
    throw_gen 'Missing required parameter "object" or "id" and "object_type"'
        unless $param->{object} || $param->{obj}
            || ($param->{id} || $param->{object_type});

    my $elems = _do_list($class, $param, undef);

    # Throw an exception if we looked up more than one site.
    throw_da "Too many $class objects found" if @$elems > 1;
    return $elems->[0];
}

################################################################################

=item my @data = Bric::Biz::Element::Field->list($params)

Searches for and returns a list or anonymous array of data element objects. The
supported parameters that can be searched are:

=over 4

=item object

A story or media object with which the data elements are associated. Required
unless C<object_type> is specified.

=item object_type

The type of document with which the data elements are associated. Required
unless C<object> is specified.

=item object_instance_id

The ID of a story or data object with wich the data elements are associated.
Can only be used if C<object_type> is also specified and C<object> is not
specified. May use C<ANY> for a list of possible values.

=item name

The name of the data elements. Since the SQL C<LIKE> operator is used with
this search parameter, SQL wildcards can be used. May use C<ANY> for a list of
possible values.

=item key_name

The key name of the data elements. Since the SQL C<LIKE> operator is used with
this search parameter, SQL wildcards can be used. May use C<ANY> for a list of
possible values.

=item parent_id

The ID of the container element that is the parent element of the data
elements. May use C<ANY> for a list of possible values.

=item field_type_id

=item element_data_id

The ID of the Bric::Biz::ElementType::Parts::FieldType object that specifies the
structure of the data elements. May use C<ANY> for a list of possible values.

=item active

A boolean value indicating whether the returned data elements are active or
inactive.

=back

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub list {
    my ($class, $param) = @_;
    _do_list($class, $param, undef);
}

################################################################################

=back

=head2 Destructors

=over 4

=item $data->DESTROY

Dummy method to prevent wasting time trying to AUTOLOAD DESTROY.

=cut

sub DESTROY {
    # This method should be here even if its empty so that we don't waste time
    # making Bricolage's autoload method try to find it.
}

##############################################################################

=back

=head2 Public Class Methods

=over 4

=item my @ids = Bric::Biz::Element::Field->list_ids($params)

Returns a list or anonymous array of data element IDs. The search parameters
are the same as for C<list()>.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub list_ids {
    my ($class, $param) = @_;
    _do_list($class, $param, 1);
}

################################################################################

=back

=head2 Public Instance Methods

See also
L<Bric::Biz::Element|Bric::Biz::Element>,
from which Bric::Biz::Element::Field inherits.

=over 4

=item my $field_type_id = $data->get_field_type_id

=item my $field_type_id = $data->get_element_data_id

Returns the ID of the Bric::Biz::ElementType::Parts::FieldType object that describes
this element.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $data->set_field_type_id($field_type_id)

=item $data->set_element_data_id($field_type_id)

Sets the ID of the Bric::Biz::ElementType::Parts::FieldType object that describes
this element.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

# Compatibility accessors.
sub get_element_data_id { shift->get_field_type_id     }
sub set_element_data_id { shift->set_field_type_id(@_) }

=item $field_type = $data->get_field_type

=item $field_type = $data->get_field_type

Returns the Bric::Biz::ElementType::Parts::FieldType object that defines the
structure of this field.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> C<get_element_data_obj> is the deprecated form.

=cut

sub get_field_type {
    my $self = shift;
    my $atd   = $self->_get('_field_type');
    return $atd if $atd;

    my $dirty = $self->_get__dirty;
    my $atd_id = $self->_get('field_type_id');
    $atd = Bric::Biz::ElementType::Parts::FieldType->lookup({id => $atd_id});
    $self->_set(['_field_type'], [$atd]);
    $self->_set__dirty($dirty);
    return $atd;
}

sub get_element_data_obj { shift->get_field_type }

################################################################################

=item $name = $data->get_element_name

An alias for C<< $data->get_name >>.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_element_name { $_[0]->get_name }

################################################################################

=item $key_name = $data->get_element_key_name

An alias for C<< $data->get_key_name >>.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_element_key_name { $_[0]->get_key_name }

################################################################################

=item $data->set_value($value)

=item $data->set_data($value)

Sets the value of the field. Use C<set_values()> if multiple values are
allowed on the field (because the field type's C<multiple> attribute is true).

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> C<set_data()> is the deprecated form of this method.

=cut

sub set_value {
    my ($self, $value) = @_;

    # XXX Add code to validate values against options?

    # OK this is just an attribute
    my $sql_type  = $self->get_sql_type;
    $value = db_date($value) if $sql_type eq 'date';

    my $old_val = $self->_get("_$sql_type\_val");
    return $self unless (defined $value && not defined $old_val)
                     || (not defined $value && defined $old_val)
                     || ($value ne $old_val);

    return $self->_set(["_$sql_type\_val"] => [$value]);
}

sub set_data { shift->set_value(@_) }

##############################################################################

=item $data->set_values(@values)

Sets multiple values for the field. Useful for setting the values for
"multiple" fields such as multiple select lists.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub set_values { shift->set_value(join '__OPT__', @_) }

################################################################################

=item my $value = $value->get_value

=item my $value = $value->get_value($format)

=item my $value = $data->get_data

=item my $value = $data->get_data($format)

Returns the value of this data element. If the SQL type of the data object is
"date", then C<$format>, if it is passed, will be used to format the date.
Otherwise, the format set in the preferences will be used.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:>

C<set_data()> is the deprecated form of this method. For fields that can
contain multiple values, call C<get_values()>, instead.

=cut

sub get_value {
    my ($self, $format) = @_;
    my $sql_type = $self->get_sql_type or return undef;
    return $sql_type eq 'date'
           ? local_date(scalar $self->_get('_date_val'), $format)
           : scalar $self->_get("_$sql_type\_val");
}

sub get_data { shift->get_value(@_) }

################################################################################

=item $field->get_values()

  my @values      = $field->get_values;
     @values      = $field->get_values($format);
  my $fields_aref = $field->get_values;
     $fields_aref = $field->get_values($format);

Returns a list or array reference of all of the values associated with a
field. This method should be called in preference to C<get_value()> for fields
that can contain multiple values (i.e., C<is_multiple()> returns a true value.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_values {
    my $vals = shift->get_value(@_);
    return wantarray ?   split /__OPT__/, $vals
                     : [ split /__OPT__/, $vals ]
                     ;
}

##############################################################################

=item my $is_autopopulated = $data->is_autopopulated

Returns true if the field's value is autopopulate, and false if it is not.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub is_autopopulated {
    my $self = shift;
    return $self if $self->_get('_autopopulated');
    return;
}

##############################################################################

=item my $is_multiple = $data->is_multiple

Returns true if the field is allowed to have multiple values and false if it
is not.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub is_multiple {
    my $self = shift;
    return $self if $self->_get('_multiple');
    return;
}

##############################################################################

=item my $get_max_length = $data->get_max_length

Returns the maximum allowed length of the field's value.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

##############################################################################

=item my $sql_type = $data->get_sql_type

Returns the SQL type of the field. This value corresponds to the C<sql_type>
attribute of the Bric::Biz::ElementType::Parts::FieldType object on which the field
is based.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

##############################################################################

=item my $widget_type = $data->get_widget_type

Returns the string indicating the widget to use to display the field. This
value corresponds to the C<widget_type> attribute of the
Bric::Biz::ElementType::Parts::FieldType object on which the field is based.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

################################################################################

=item $data->prepare_clone

Prepares the data element to be cloned, such as when a new version of a
document is created, or when a document itself is cloned.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub prepare_clone {
    my $self = shift;
    $self->uncache_me;
    $self->_set(['id'], [undef]);
}

################################################################################

=item my $is_container = $data->is_container

Returns false, since data elements are not container elements.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub is_container { return }

###############################################################################

=item $data->lock_val

For autopopulated data elements, this method prevents the value from being
autopopulated.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub lock_val {
    shift->_set(['_hold_val'], [1]);
}

###############################################################################

=item $data = $data->unlock_val

Allows auotpopulated data elements to be autopopulated.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub unlock_val {
    shift->_set(['_hold_val'], [0]);
}

###############################################################################

=item my $is_locked = $data->is_locked

Returns true if the element has been locked.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub is_locked {
    my $self = shift;
    return unless $self->_get('_hold_val');
    return $self;
}

###############################################################################

=item $data = $data->save

Saves the changes to the data element to the database.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub save {
    my $self = shift;

    return unless $self->_get__dirty;

    if ($self->_get('id')) {
        $self->_do_update;
    } else {
        $self->_do_insert;
    }

    return $self->_set__dirty(0);
}

################################################################################

#==============================================================================#
# Private Methods                      #
#======================================#

=back

=head1 Private

=head2 Private Class Methods

=over 4

=item Bric::Biz::Element::Field->_do_list($class, $param, $ids)

Called by C<list()> or C<list_ids()>, this method returns either a list of ids
or a list of objects, depending on the third argument.

B<Throws:>

=over 4

=item *

Object of type $obj_class not allowed to have elements.

=item *

Improper args for list.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _do_list {
    my ($class, $params, $ids_only) = @_;

    my ($obj_type, @params);
    my @wheres = ('f.field_type__id = ft.id');

    while (my ($k, $v) = each %$params) {
        if ($k eq 'object') {
            $obj_type = $v->key_name;
            push @wheres,
                any_where $v->get_version_id, 'f.object_instance_id = ?', \@params;
        }

        elsif ($k eq 'object_type') {
            $obj_type = $v;
        }

        elsif ($k eq 'object_instance_id') {
            push @wheres, any_where $v, 'f.object_instance_id = ?', \@params;
        }

        elsif ($k eq 'id') {
            push @wheres, any_where $v, 'f.id = ?', \@params;
        }

        elsif ($k eq 'active') {
            push @wheres, 'f.active = ?';
            push @params, $v ? 1 : 0;
        }

        elsif ($k eq 'parent_id') {
            push @wheres,  any_where($v, 'f.parent_id = ?', \@params);
        }

        elsif ($k eq 'field_type_id' || $k eq 'element_data_id') {
            push @wheres, any_where $v, 'f.field_type__id = ?', \@params;
        }

        elsif ($k eq 'key_name' || $k eq 'name' || $k eq 'description') {
            push @wheres, any_where $v, "LOWER(ft.$k) LIKE LOWER(?)", \@params;
        }
    }

    throw_gen 'Missing required parameter "object" or "object_type"'
        unless $obj_type;

    my $tables = "$obj_type\_field f, field_type ft";

    my ($qry_cols, $order) = $ids_only
        ? ('DISTINCT f.id', 'f.id')
        : (join(', ', @SEL_COLS), 'f.object_instance_id, f.place');
    my $wheres = @wheres ? 'WHERE  ' . join(' AND ', @wheres) : '';


    my $sel = prepare_c(qq{
        SELECT $qry_cols
        FROM   $tables
        $wheres
        ORDER BY $order
    }, undef, DEBUG);

    # Just return the IDs, if they're what's wanted.
    if ($ids_only) {
        my $ids = col_aref($sel, @params);
        return wantarray ? @$ids : $ids;
    }

    my @objs;
    execute($sel, @params);
    my @d;
    bind_columns( $sel, \@d[ 0..$#SEL_COLS ] );
    while ( fetch($sel) ) {
        my $self = $class->SUPER::new;
        $self->_set( [ 'object_type', @SEL_FIELDS ] => [$obj_type, @d] );
        $self->_set__dirty(0);
        push @objs, $self->cache_me;
    }
    return wantarray ? @objs : \@objs;
}

################################################################################

=back

=head2 Private Instance Methods

=over 4

=item $data->_do_insert()

Called by C<save()>, this method inserts the data element into the database.

B<Throws:>

=over 4

=item *

Object must be a media or story to add elements.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _do_insert {
    my $self = shift;

    my $table = $self->get_object_type . '_field';

    my $value_cols = join ', ', ('?') x @COLS;
    my $ins_cols   = join ', ', @COLS;

    my $ins = prepare_c(qq{
        INSERT INTO $table ($ins_cols)
        VALUES ($value_cols)
    }, undef);
    execute($ins, $self->_get(@FIELDS) );

    return $self->_set( ['id'] => [last_key($table)] );
}

################################################################################

=item $data->_do_update

Called by C<save()>, this method updates the data element into the database.

B<Throws:>

=over 4

=item *

Object must be a media or story to add elements.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _do_update {
    my $self = shift;

    my $table    = $self->get_object_type . '_field';
    my $set_cols = join ' = ?, ', @COLS;

    my $upd = prepare_c(qq{
        UPDATE $table
        SET    $set_cols = ?
        WHERE  id = ?
    }, undef);

    execute($upd, $self->_get(@FIELDS, 'id'));
    return $self;
}

################################################################################

1;
__END__

=back

=head1 Notes

NONE

=head1 Authors

Michael Soderstrom <miraso@pacbell.net>

Refactored by David Wheeler <david@kineticode.com>

=head1 See Also

L<perl>, L<Bric>, L<Bric::Biz::Asset>, L<Bric::Biz::Asset::Business>,
L<Bric::Biz::Element>

=cut

