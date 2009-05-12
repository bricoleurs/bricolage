package Bric::Util::Attribute;

###############################################################################

=head1 Name

Bric::Util::Attribute - A module to manage attributes for various objects.

=cut

require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

 # Object creation methods
 $attr_obj = new($init);

 ##-- Methods that apply to the object to which these attributes apply --##
 $id       = $attr_obj->get_object_id();
 $id       = $attr_obj->set_object_id();

 # Return an abbrievated name for the object these attributes represent.
 $short    = $attr_obj->short_object_type();


 ##-- Subsystem methods --##
 $subsys   = $attr_obj->get_subsys();
 $success  = $attr_obj->set_subsys($subsys);

 # Return a list of subsystem names for this object.
 @names    = $attr_obj->subsys_names($subsys);

 # All attributes and metadata for a given subsys.
 $all      = $attr_obj->all_for_subsys($subsys);

 # Get the sql_type of a value.
 $sqltype  = $attr_obj->get_sqltype($param);


 ##-- Single attribute methods --##
 $value    = $attr_obj->get_attr($param);
 $id       = $attr_obj->get_attr_id($param);

 $success  = $attr_obj->set_attr($param);

 $success  = $attr_obj->deactivate_attr($param);
 $success  = $attr_obj->delete_attr($param);

 ##-- Methods that act on multiple attribute values --##
 $values   = $attr_obj->get_attr_hash($param);
 $attr_val = $attr_obj->search_attr($param);


 ##-- Manipulate metadata about an attribute --##
 $success  = $attr_obj->add_meta($param);

 $value    = $attr_obj->get_meta($param);

 $success  = $attr_obj->delete_meta($param);

 ##-- Other methods --##
 $success  = $attr_obj->save();

=head1 Description

The attribute module allows key/value pairs to be associated with an
object. Attributes apply to a specific object of a specific type. Attributes
keys can also have metadata associated with them. This is data that helps
define additional information about an attribute key, but says nothing about
the attribute value. Finally, attributes keys can be grouped into
'subsystems'. A subsystem simply holds a group of related
attributes. Specifying subsystems or metadata is not necessary for using the
attribute class.

Attribute values can be one of three types, 'short', 'date' and 'blob'. This
is called the 'sql_type'. Each of these types has a different storabe type in
the database. If an attribute value is a 'short' value its data is limited to
a length of 1024 characters. If an attribute value is a 'date' value, it must
be in a database date format. If an attribute value is a 'blob' value its
length is limited only by disk space and database performance.

Metadata on an attribute key can give more context to the attribute key, or
simply be a storage space for information associated with that key. Metadata
is a field name and a value. For instance, an attribute for a user class might
be 'notify_email' with values set to 'yes' or 'no'. A metadata field name for
the 'notify_email' key might be 'description' and a value might be 'Should the
user be notified via email of new announcements'. There is no limit to the
number of metadata fields for a given attribute.

A subsystem is a way to organize attributes. Every attribute lives within a
subsystem. If an attribute is not given a subsystem explicitly, it will
automatically be placed inside of a default subsystem. Most methods in the
attribute class can be passed a subsystem name, but will use the default name
if one is not passed.

You can think about the attribute system like a perl hash:

  $attribute = {'subsystem1' =>
                   {'attr_key1' =>
                       {'metadata' =>
                           {'meta_field1' => 'meta_data1',
                            'meta_field2' => 'meta_data2',
                            ...
                           },
                        'value'    => 'attribute_value1'
                       },
                    'attr_key2' =>
                       {'metadata' =>
                           {...
                           },
                        'value'    => 'attribute_value2'
                       },
                    ...
                   },
                'subsystem2' =>
                    {'attr_key1' => {...},
                     'attr_key2' => {...},
                     'attr_key3' => {...},
                    },
                ...
               }

where everything ending with a number is data that you as the attribute user
sets, and everything else (ie 'metadata' and 'value') is there just to give
you and idea of the relationships. The '...' denotes possible additional
values following the same pattern.

So, to set value 'attribute_value1', one would call:

  $attr_obj->set_attr({'subsys'   => 'subsystem1',
                       'name'     => 'attr_key1',
                       'sql_type' => 'short',
                       'value'    => 'attribute_value1'});

To set 'meta_data2', one would call:

  $attr_obj->set_meta({'subsys' => 'subsystem1',
                       'name'   => 'attr_key1',
                       'field'  => 'meta_field2',
                       'value'  => 'meta_data2'});

To retrieve 'attribute_value2', one would call:

  $attr_obj->get_meta({'subsys' => 'subsystem1',
                       'name'   => $attr_key2});

Note that specifying an 'sql_type' is only necessary when setting values, to
let the module know how to store them. When a value is retrieved, the
attribute module can tell what type of data is stored.

One final note. The examples do not explicitly show this, but any metadata set
on a particular attribute name will be available to all objects of the same
type if they use the same attribute name. For instance, if a user object with
id = 5 sets metadata field 'cereal' on attribute name 'breakfast' to 'cracklin
oat bran', then all user objects that set attribute 'breakfast' will have a
metadata field 'cereal' with value 'cracklin oat bran'. This is intentional
and is meant to promote attribute reusablility.

=cut

#==============================================================================#
# Dependencies                         #
#======================================#

#--------------------------------------#
# Standard Dependencies
use strict;

#--------------------------------------#
# Programatic Dependencies
use Bric::Util::DBI qw(:standard prepare_ca);
use Bric::Util::Fault qw(throw_gen throw_mni);

use Storable;

#==============================================================================#
# Inheritance                          #
#======================================#

use base qw(Bric);

#=============================================================================#
# Function Prototypes                  #
#======================================#



#==============================================================================#
# Constants                            #
#======================================#

# The name of the default subsystem.
use constant DEFAULT_SUBSYS => '_DEFAULT';

# Constants for getting the table name
use constant ATTR_TABLE     => sub { return 'attr_'.$_[0] };
use constant VAL_TABLE      => sub { return 'attr_'.$_[0].'_val' };
use constant META_TABLE     => sub { return 'attr_'.$_[0].'_meta' };

# Constants for getting the list of column names
use constant ATTR_COLS      => qw( subsys name sql_type active );
use constant VAL_COLS       => qw( object__id attr__id date_val short_val
                                   blob_val serial active );
use constant META_COLS      => qw( attr__id name value active );

# Tie table names to column lists
use constant TABLES => {'attr' => {'name' => ATTR_TABLE,
                                   'abbr' => 'a',
                                   'cols' => [ATTR_COLS]},
                        'meta' => {'name' => META_TABLE,
                                   'abbr' => 'm',
                                   'cols' => [META_COLS]},
                        'val'  => {'name' => VAL_TABLE,
                                   'abbr' => 'v',
                                   'cols' => [VAL_COLS]}};

#==============================================================================#
# Fields                               #
#======================================#

#--------------------------------------#
# Public Class Fields
my %ATTR_ID_CACHE;
my %ATTR_NAME_CACHE;

#--------------------------------------#
# Private Class Fields


#--------------------------------------#
# Instance Fields
# This method of Bricolage will call 'use fields' for you and set some permissions.
BEGIN {
    Bric::register_fields({
                         # Public Fields
                         # This is the current subsystem being used.
                         'subsys'        => Bric::FIELD_RDWR,
                         # The ID of the object whos attributes we're changing.
                         'object_id'     => Bric::FIELD_READ,

                         # Private Fields
                         '_attr'         => Bric::FIELD_NONE,
                        });
}

#==============================================================================#
# Interface Methods                    #
#======================================#

=head1 Interface

=head2 Public Methods

=over 4

=cut

#--------------------------------------#
# Constructors
#------------------------------------------------------------------------------#

=item $obj = new Bric::Util::Attribute($init);

Creates a new attribute object for an object type with ID given by argument
'id'.

Keys of $init are:

=over 4

=item *

subsys

The subsystem to use by default for all subsequent method calls requiring a
subsystem. If this is not given the package default subsytem, DEFAULT_SUBSYS,
will be used. Any method requiring a subsystem will use the value passed here
by default if a subsystem is not passed to that method.

This field is optional

=item *

object_id

The object ID for which this attribute applies. Attributes values are specific
to the objects that set them.

** This is a required field **

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

    # Create the object via fields which returns a blessed object.
    my $self = bless {}, $class;

    # Call the parent's constructor.
    $self->SUPER::new();

    $self->set_subsys($init->{'subsys'} || DEFAULT_SUBSYS);

    my $id = defined $init->{'object_id'} ? $init->{'object_id'}
                                          : $init->{'id'};

    $self->_set(['object_id', '_attr'], [$id, {}]);

    # Return the object.
    return $self;
}

#------------------------------------------------------------------------------#

sub lookup {
   # This is just a placeholder. There is no obvious use for a lookup function
   # here.
   throw_mni(error => "lookup method not implemented");
}

#------------------------------------------------------------------------------#

sub list {
   # This is just a placeholder. There is no obvious use for a list function
   # here.
   throw_mni(error => "list method not implemented");
}


#--------------------------------------#
# Destructors

sub DESTROY {
    # This method should be here even if its empty so that we don't waste time
    # making Bricolage's autoload method try to find it.
}

#--------------------------------------#
# Public Class Methods
#------------------------------------------------------------------------------#

=item $type = Bric::Util::Attribute::short_object_type();

Returns the short object type name used to construct the attribute table name
where the attributes for this class type are stored. This should be overridden
in all subclasses of Attribute. Oh, did I mention that the Attribute class
should never be used directly? It is an abstract class and only subclasses of
Attribute should be instantiated.

This method is used internally by the Attribute object.

B<Throws:>

=over 4

=item *

Short object type not defined

Thrown when the short object type name has not been defined by the programmer.

=back

B<Side Effects:>

NONE

B<Notes:>

Values for this method look like 'grp' given a full object type of
'Bric::Util::Grp'

=cut

sub short_object_type {
    throw_mni(error => "Short object type not defined");
}

#--------------------------------------#
# Public Instance Methods
#------------------------------------------------------------------------------#

=item $id = $attr_obj->get_subsys();

Return the current default subsys name. This subsys is used for any query
requiring a subsys when the user has not supplied a subsys.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

=cut

#------------------------------------------------------------------------------#

=item $id = $attr_obj->set_subsys();

Sets the default subsys name.  This subsys is used for any query requiring a
subsys when the user has not supplied a subsys.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

=cut

#------------------------------------------------------------------------------#

=item @names = $attr_obj->subsys_names($inactive);

Returns a list of subsystem names for this object. If argument 'inactive' is
true, then inactive subsystem names will be returned. Otherwise only active
subsys names will be returned.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

=cut

sub subsys_names {
    my $self = shift;
    my ($inactive) = @_;
    my $name = $self->short_object_type;
    my ($attr_tbl) = _table_info('attr', $name);
    my ($val_tbl)  = _table_info('val', $name);
    my ($d, @names);

    my $sql = "SELECT DISTINCT a.subsys FROM $attr_tbl a, $val_tbl v ".
              "WHERE a.active=? AND a.id=v.attr__id AND v.object__id=?";

    # Execute the SQL
    my $sth = prepare_c($sql, undef);
    execute($sth, (not $inactive), $self->get_object_id);
    bind_columns($sth, \$d);

    while (fetch($sth)) {
        push @names, $d;
    }

    return wantarray ? @names : \@names;
}

#------------------------------------------------------------------------------#

=item $id = $attr_obj->get_object_id();

Return the object ID for this attribute object. This is the object to which
these attributes apply.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

=cut

#------------------------------------------------------------------------------#

=item $attr_obj = $attr_obj->set_object_id($id);

Set the object ID for this attribute object. This is the object to which these
attributes apply. The object ID can be set only once.

B<Throws:>

=over 4

=item *

Cannot assign new object ID.

=back

B<Side Effects:>

NONE

B<Notes:>

=cut

sub set_object_id {
    my ($self, $obj_id) = @_;
    throw_gen(error => "Cannot assign new object ID")
      if defined $self->_get('object_id');
    $self->_set(['object_id'], [$obj_id]);
}

#------------------------------------------------------------------------------#

=item $sqltype = $attr_obj->get_sqltype($param);

Keys of $param are:

=over 4

=item *

name

The name of the attribute

=item *

subsys

The subsystem to use.

=item *

attr_id

The attribute type to use, given instead of a 'name'/'subsys' pair.

=back

Returns the sqltype (the datatype) for the value of this attribute.

If no subsystem is given, it will use the default subsystem passed to the new
constructor or via the 'set_subsys' method.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

=cut

sub get_sqltype {
    my $self = shift;
    my ($param) = @_;

    my $val = $self->_get_val($param);

    return $val->{'sql_type'}
}

#------------------------------------------------------------------------------#

=item $attr_val = $attr_obj->get_attr($param);

Keys of $param are:

=over 4

=item *

name

The attribute name

=item *

subsys

The subsystem to use.

=item *

attr_id

The attribute type ID to use rather than use the 'name'/'subsys' combination.

=back

Returns the value of the attribute for the given attribute type.

If no subsystem is given, but a name is given it will use the default
subsystem passed to the new constructor or via the 'set_subsys' method.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

=cut

sub get_attr {
    my $self = shift;
    my ($param) = @_;

    my $val = $self->_get_val($param);

    return $val->{'value'};
}

#------------------------------------------------------------------------------#

=item $attr_id = $attr_obj->get_attr_id($subsys, $name);

Returns an ID for an attribute type which uniquely identifies a subsystem name
pair. This ID can be used in place of an attribute name and subsystem for
methods that require those values.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_attr_id {
    my $self = shift;
    my ($param) = @_;

    my $val = $self->_get_val($param);

    return $val->{'_attr_id'};
}

#------------------------------------------------------------------------------#

=item $attr_val = $attr_obj->get_attr_hash($param);

Keys of $param are:

=over 4

=item *

name

The name of the attribute

=item *

subsys

The subsystem to use.

=item *

attr_id

The type ID to use rather than use the 'name'/'subsys' combination.

=item *

ret_set_only

Only return attribute names when that name has a corresponding row in one of
the value tables if set to 1. Default is setting this to 0 and all attribute
names will be returned, even if no value is set (undef will be returned as the
value)

=item *

inactive

If true, inactive attributes will be returned.

=back

Returns a hash of key/values for the given parameters.

If no subsystem is given, but a name is given it will use the default
subsystem passed to the new constructor or via the 'set_subsys' method.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

=cut

sub get_attr_hash {
    my $self = shift;
    my ($param) = @_;

    my $val = $self->_get_val($param);

    return {
        map  { $_ => $val->{$_}->{value} }
        grep { !$val->{$_}->{_delete} }
        keys %$val
    };
}

#------------------------------------------------------------------------------#

=item $all = $attr_obj->all_for_subsys($subsys);

Return all attribute/value pairs AND metadata for a given subsystem. If
$subsys is not passed the default subsys will be used. Format of the return
value is:

  $all = {'attr_name' => {'value' => 'attr_value',
                          'meta'  => {'attr_meta_field1' => 'attr_meta_value1',
                                      ...,
                                     },
                         },
          ...,
         };

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

=cut

sub all_for_subsys {
    my $self = shift;
    my ($subsys) = @_;
    my $all;

    my $val = $self->_get_val({'subsys' => $subsys});

    foreach my $name (keys %$val) {
        my $meta = $self->_get_meta({'subsys' => $subsys,
                                     'name'   => $name});
        my $m = { map { $_ => $meta->{$_}->{'value'} } keys %$meta };
        $all->{$name} = {'value' => $val->{$name}->{'value'},
                         'meta'  => $m};
    }

    return $all;
}

#------------------------------------------------------------------------------#

=item $attr_val = $attr_obj->search_attr($param);

Keys of $param are:

=over 4

=item *

name

A name substring to search for in the attribute system.

=item *

subsys

The subsystem in which to search.

=back

Returns a hash of key/values for the given parameters.

If no subsystem is given, but a name is given it will use the default
subsystem passed to the new constructor or via the 'set_subsys' method.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

=cut

sub search_attr {
    my $self = shift;
    my ($param) = @_;
    my ($attr_id) = $param->{'attr_id'};
    my (@where, @bind);
    my %ret;

    # Set this via the default subsys if they didn't pass anything.
    $param->{'subsys'} ||= $self->get_subsys;

    push @where, ('a.subsys=?', 'a.name LIKE ?', 
                  'a.id = v.attr__id', 'v.active=?');
    push @bind, (@{$param}{'subsys','name'}, not $param->{'inactive'});

    my $d = $self->_select_table(['attr', 'val'], \@where, \@bind);

    foreach (@$d) {
        my $sqltype = $_->{'attr'}->{'sql_type'};
        $ret{$_->{'attr'}->{'name'}} = $_->{'val'}->{"${sqltype}_val"};
    }

    return \%ret;
}

#------------------------------------------------------------------------------#

=item %attr = $attr_obj->set_attr($param);

Keys of $param are:

=over 4

=item *

name

The name of the attribute

=item *

subsys

The subsystem to use.

=item *

sql_type

The storage type of this attribute.

=item *

attr_id

The type ID to use rather than use the 'name'/'subsys' combination.

=back

Sets the value of a particular attribute.

If no subsys is given, it will use the default subsystem passed to the new
constructor or via the 'set_subsys' method.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

=cut

sub set_attr {
    my $self = shift;
    my ($param) = @_;

    $self->_set_val($param);

    return $param->{'value'};
}

#------------------------------------------------------------------------------#

=item $success = $attr_obj->deactivate_attr($param);

Deactivates an attribute value. This means that the value is still in the
database, but it has been made inactive. Inactive values will not be retrieved
unless specifically sought after.

The keys of $param are:

=over 4

=item *

name

The name of the attribute to clear.

=item *

subsys

The subsystem to use.

=item *

attr_id

The type of object (represents a name/subsys pair).

=back

If no subsys is given, it will use the default subsystem passed to the new
constructor or via the 'set_subsys' method.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

=cut

sub deactivate_attr {
    my $self = shift;
    my ($param) = @_ ;

    my $val = $self->_get_val($param);

    $val->{'active'} = 0;
    $val->{'_dirty'} = 1;
}

#------------------------------------------------------------------------------#

=item $success = $attr_obj->delete_attr($param);

Deletes an attribute value from the database...permanently!

The keys of $param are:

=over 4

=item *

name

The name of the attribute to clear.

=item *

subsys

The subsystem to use.

=item *

attr_id

The type of object (represents a name/subsys pair).

=back

If no subsys is given, it will use the default subsystem passed to the new
constructor or via the 'set_subsys' method.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

=cut

sub delete_attr {
    my $self = shift;
    my ($param) = @_ ;

    my $val = $self->_get_val($param);

    $val->{'_delete'} = 1;

    return $self;
}

#------------------------------------------------------------------------------#

=item $success  = $attr_obj->add_meta($param);

The keys for $param are:

=over 4

=item *

name

The name of the attribute for which to add metadata.

=item *

subsys

The subsystem to use.

=item *

attr_id

The type of attribute (a substitute for a name and subsys)

=item *

field

The name of the metadata field.

=item *

value

The metadata value.

=item *

metadata

A hash ref of field/value metadata pairs.

=back

Adds metadata about a particular attribute name/subsys pair. Metadata can be
things such as attribute descriptions, default values, etc.

If no subsys is given, it will use the default subsystem passed to the new
constructor or via the 'set_subsys' method.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

=cut

sub add_meta {
    my $self = shift;
    my ($param) = @_;

    $self->_set_meta($param);

    return $param->{'field'};
}

#------------------------------------------------------------------------------#

=item $value  = $attr_obj->get_meta($param);

The keys for $param are:

=over 4

=item *

name

The name of the attribute for which to retrieve metadata.

=item *

subsys

The subsystem to use.

=item *

attr_id

The type of attribute (represents a name/subsys)

=item *

field

The name of the metadata field.

=back

Either 'name' and optional 'subsys' (if not given the current default will be
used) must be given, or an 'attr_id' must be given. If a field name is given,
the metadata associated with that field will be returned. If no field name is
given, then all metadata for the name/subsys or attr_id will be returned in a
hash.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

=cut

sub get_meta {
    my $self = shift;
    my ($param) = @_;

    my $meta = $self->_get_meta($param);

    return unless $meta;

    if ($param->{'field'}) {
        # If there was a field passed, then $meta is just the metadata for that
        # field.
        return $meta->{'value'};
    } else {
        # If they didn't request a specific field, return it all.
        return $meta;
    }
}

#------------------------------------------------------------------------------#

=item $success  = $attr_obj->delete_meta($param);

The keys for $param are:

=over 4

=item *

attr_id

The attribute ID to which this metadata applies.

=item *

name

The name of the attribute for which to clear metadata.

=item *

subsys

The subsystem to use.

=item *

field

The name of the metadata field.

=back

These keys can be used in the following combinations:

=over

=item 1

An 'attr_id' and a 'field'

=item 2

A 'subsys', 'name' and a 'field'

=back

Deletes a metadata entry for a given metadata name and attribute name/subsys
pair.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

=cut

sub delete_meta {
    my ($self, $param) = @_;
    my $meta = $self->_get_meta($param);
    $meta->{_delete} = 1;
    return $self;
}

#------------------------------------------------------------------------------#

=item $success  = $attr_obj->save();

Saves the information set on this object to the database.

B<Throws:>
NONE

B<Side Effects:>
NONE

B<Notes:>

=cut

sub save {
    my $self = shift;
    my $attr = $self->_get('_attr');

    while (my ($sub, $subval) = each %$attr) {
        while (my ($name, $nameval) = each %$subval) {
            my $sql_type = $nameval->{'sql_type'};
            my $val_id   = $nameval->{'_val_id'};

            # Create this attribute if it doesn't exist.
            unless ($nameval->{'_attr_id'}) {
                my $id = $self->_insert_table('attr', {'subsys'   => $sub,
                                                       'name'     => $name,
                                                       'sql_type' => $sql_type,
                                                       'active'   => 1});

                $nameval->{'_attr_id'} = $id;
            }

            # Delete this attribute if necessary
            if ($nameval->{'_delete'}) {
                $self->_delete_from_table('val', ['id = ?'], [$val_id]);
                next;
            }

            # Update the attribute value if its dirty
            if ($nameval->{'_dirty'}) {
                my $dat = {'object__id'     => $self->get_object_id,
                           'attr__id'       => $nameval->{'_attr_id'},
                           $sql_type.'_val' => $nameval->{'value'},
                           'active'         => $nameval->{'active'}};

                if ($val_id) {
                    $dat->{'id'} = $val_id;
                    $self->_update_table('val', ['id=?'], $dat);
                } else {
                    $val_id = $self->_insert_table('val', $dat);
                    $nameval->{'_val_id'} = $val_id;
                }
            }

            # Update the metadata values
            while (my ($meta, $metaval) = each %{$nameval->{'_meta'}}) {
                my $meta_id =  $metaval->{'_meta_id'};

                # Delete this attribute if necessary
                if ($metaval->{'_delete'}) {
                    $self->_delete_from_table('meta', ['id = ?'], [$meta_id]);
                    next;
                }

                # Only update if this metadata point is dirty.
                if ($metaval->{'_dirty'}) {
                    my $dat = {'attr__id' => $nameval->{'_attr_id'},
                               'name'     => $meta,
                               'value'    => $metaval->{'value'},
                               'active'   => $metaval->{'active'}};

                    if ($meta_id) {
                        $dat->{'id'} = $meta_id;
                        $self->_update_table('meta', ['id=?'], $dat);
                    } else {
                        $meta_id = $self->_insert_table('meta', $dat);
                        $metaval->{'_meta_id'} = $meta_id;
                    }
                }
            }
        }
    }

    return $self;
}



#==============================================================================#
# Private Methods                      #
#======================================#

=back

=head2 Private Methods

=over 4

=item _table_info

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _table_info {
    my ($type, $name) = @_;

    # Throw an error if we don't get an argument we expect.
    throw_gen(error => 'Bad arguments') unless exists TABLES->{$type};

    return (TABLES->{$type}->{'name'}->($name),
            TABLES->{$type}->{'abbr'},
            TABLES->{$type}->{'cols'});
}

#--------------------------------------#
# Private Instance Methods
#------------------------------------------------------------------------------#

=item $self = $self->_get_meta($param)

Returns an attribute metadata value.  Keys to $param are:

=over 4

=item subsys

The subsystem to use, overriding the default. (optional)

=item name

The name of the attribute upon which to set metadata.

=item field

The name of the metadata data point.

=back

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _get_meta {
    my $self = shift;
    my ($param) = @_;
    my ($attr) = $self->_get('_attr');
    my $subsys = $param->{'subsys'};

    $subsys ||= $self->get_subsys;

    # Load the entire subsystem if its not in our cache.
    $self->_load_subsys($subsys) unless exists $attr->{$subsys};

    my ($name, $field) = @$param{'name', 'field'};

    # Make sure there is metadata and that a value has been set.
    return unless (exists $attr->{$subsys}->{$name}->{'_meta'}) &&
                  (exists $attr->{$subsys}->{$name}->{'value'});

    if ($field) {
        # Return the individual value
        return $attr->{$subsys}->{$name}->{'_meta'}->{$field};
    } else {
        # Return a hash of values.
        return $attr->{$subsys}->{$name}->{'_meta'};
    }
}

=item $self = $self->_get_val($param)

Returns an attribute value.  Keys to $param are:

=over 4

=item subsys

The subsystem to use, overriding the default. (optional)

=item name

The name of the attribute to set. (optional)

=back

If 'name' is not passed a data structure of all attributes in 'subsys' (or the
default subsys) are returned. If name is passed, then a data structure for
that attribute alone is returned.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _get_val {
    my $self = shift;
    my ($param) = @_;
    my ($attr) = $self->_get('_attr');
    my ($subsys, $name) = @$param{'subsys','name'};

    $subsys ||= $self->get_subsys;

    # Load the entire subsystem if its not in our cache.
    $self->_load_subsys($subsys) unless exists $attr->{$subsys};

    if ($name) {
        # Make sure that a value has been set.
        return unless exists $attr->{$subsys}->{$name}->{'value'};

        # Return the individual value
        return $attr->{$subsys}->{$name};
    } else {
        # Return a hash of values that are set.
        return { map { $_ => $attr->{$subsys}->{$_} }
                     grep(exists($attr->{$subsys}->{$_}->{'value'}),
                          keys %{$attr->{$subsys}}) };
    }
}

#------------------------------------------------------------------------------#

=item $self = $self->_set_meta($param)

Sets an attribute metadata value.  Keys to $param are:

=over 4

=item subsys

The subsystem to use, overriding the default. (optional)

=item name

The name of the attribute upon which to set metadata.

=item field

The name of the metadata data point.

=item value

The value of the metadata data point.

=back

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _set_meta {
    my $self = shift;
    my ($param) = @_;
    my ($attr) = $self->_get('_attr');
    my $subsys = $param->{'subsys'};
    my ($name, $field, $value) = @$param{'name', 'field', 'value'};

    $subsys ||= $self->get_subsys;

    # Load the entire subsystem if its not in our cache.
    $self->_load_subsys($subsys) unless exists $attr->{$subsys};

    my $named_attr = $attr->{$subsys}->{$name};

    # Setup the attribute if its not already there.
    unless ($named_attr) {
        $named_attr = $attr->{$subsys}->{$name} = {'sql_type'  => 'short',
                                                   'value'     => undef,
                                                   'active'    => 1,
                                                   '_dirty'    => 1}
    }

    my $meta = $named_attr->{'_meta'}->{$field} ||= {};

    unless (defined($meta->{'value'}) and ($meta->{'value'} eq $value)) {
        $meta->{'value'}  = $value;
        $meta->{'active'} = 1;
        $meta->{'_dirty'} = 1;
    }
}

#------------------------------------------------------------------------------#

=item $self = $self->_set_val($param)

Sets an attribute value.  Keys to $param are:

=over 4

=item subsys

The subsystem to use, overriding the default. (optional)

=item name

The name of the attribute to set.

=item value

The value of the attribute

=item sql_type

The sql_type of the value (optional if updating an existing value)

=back

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _set_val {
    my $self = shift;
    my ($param) = @_;
    my $attr               = $self->_get('_attr');
    my ($subsys, $name)    = @$param{'subsys','name'};
    my ($value, $sql_type) = @$param{'value','sql_type'};

    $subsys ||= $self->get_subsys;

    # Load the entire subsystem if its not in our cache.
    $self->_load_subsys($subsys) unless exists $attr->{$subsys};

    my $named_attr = $attr->{$subsys}->{$name} ||= {};

    $sql_type ||= $named_attr->{'sql_type'};

    # Only update this value if it changes.
    unless (defined($named_attr->{'value'}) and
            ($named_attr->{'value'} eq $value)) {
        $named_attr->{'value'}    = $value;
        $named_attr->{'sql_type'} = $sql_type;
        $named_attr->{'active'}   = 1;
        $named_attr->{'_dirty'}   = 1;
    }
}

#------------------------------------------------------------------------------#

=item $self = $self->_load_subsys($subsys);

Loads all the attributes and attribute metadata for the given subsystem.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _load_subsys {
    my $self = shift;
    my ($subsys) = @_;
    my $attr = $self->_get('_attr');
    my $sub = $attr->{$subsys} ||= {};

    # Select all the attributes first
    my @where = ('a.subsys=?');
    my @bind  = ($subsys);

    my $d = $self->_select_table(['attr'], \@where, \@bind);

    foreach (@$d) {
        my $a = $_->{'attr'};

        $sub->{$a->{'name'}} = {'sql_type' => $a->{'sql_type'},
                                '_attr_id' => $a->{'id'},
                                '_dirty'   => 0};
    }

    # Next select the values
    @where = ('a.subsys=?', 'a.id=v.attr__id', 'v.object__id=?');
    @bind  = ($subsys, $self->get_object_id);

    $d = $self->_select_table(['attr', 'val'], \@where, \@bind);

    foreach (@$d) {
        my ($a, $v)  = ($_->{'attr'}, $_->{'val'});
        my $sql_type = $a->{'sql_type'};
        my $value    = $v->{$sql_type.'_val'};

        $sub->{$a->{'name'}}->{'value'}   = $value;
        $sub->{$a->{'name'}}->{'active'}  = $v->{'active'};
        $sub->{$a->{'name'}}->{'_val_id'} = $v->{'id'};
        $sub->{$a->{'name'}}->{'_dirty'}  = 0;
    }


    # Now select all the metadata (this can be an outer join later)
    @where = ('a.subsys=?', 'a.id=m.attr__id');
    @bind  = ($subsys);

    $d = $self->_select_table(['attr', 'meta'], \@where, \@bind);

    foreach (@$d) {
        my ($a, $m) = ($_->{'attr'}, $_->{'meta'});

        $sub->{$a->{'name'}}->{'_meta'}->{$m->{'name'}} =
                                               {'value'    => $m->{'value'},
                                                'active'   => $m->{'active'},
                                                '_meta_id' => $m->{'id'},
                                                '_dirty'   => 0};
    }
}

#------------------------------------------------------------------------------#

=item $self = $self->_select_table($type, $where, $bind);

Select rows from a table in the database.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _select_table {
    my $self = shift;
    my ($type, $where, $bind, $crit) = @_;
    my $name = $self->short_object_type;
    my (@sel, @from);
    my ($sql, $sth, @d, @ret);

    # Collect all the columns and tables.
    foreach my $t (@$type) {
        my ($table, $abbr, $cols) = _table_info($t, $name);
        push @sel, map { "$abbr.$_" } ('id', @$cols);
        push @from, "$table $abbr";
    }

    # Create the SQL statement.
    $sql  = 'SELECT '.join(',', @sel).' '.
            'FROM '.  join(',', @from).' ';
    $sql .= 'WHERE '. join(' AND ', @$where) if $where;

    # Execute the SQL
    $sth = prepare_c($sql, undef);
    execute($sth, $bind ? @$bind : ());
    bind_columns($sth, \@d[0..$#sel]);

    # Grab the results.
    while (fetch($sth)) {
        my $set;
        my @tmp = @d;

        foreach my $t (@$type) {
            my ($cols) = (_table_info($t, $name))[2];
            $set->{$t} = {map { ("$_" => shift @tmp) } ('id', @$cols)};
        }

        push @ret, $set;
    }

    # Finish the query.
    Bric::Util::DBI::finish($sth);

    return \@ret;
}

#------------------------------------------------------------------------------#

=item $self = $self->_insert_table($type, $bind);

Insert a row into a table in the database.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _insert_table {
    my $self = shift;
    my ($type, $bind) = @_;
    my $name = $self->short_object_type;
    my ($table, $abbr, $cols) = _table_info($type, $name);
    my $nextval = next_key($table);

    my $sql = "INSERT INTO $table (id,".join(',',@$cols).') '.
              "VALUES ($nextval,".join(',', ('?') x @$cols).')';

    my $sth = prepare_c($sql, undef);
    execute($sth, map { $bind->{$_} } @$cols);

    # Get the ID of this object.
    return last_key($table);
}

#------------------------------------------------------------------------------#

=item $self = $self->_update_table($type, $where, $bind);

Update a table in the database.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _update_table {
    my $self = shift;
    my ($type, $where, $bind) = @_;
    my $name = $self->short_object_type;
    my ($table, $abbr, $cols) = _table_info($type, $name);

    my $sql = "UPDATE $table SET ".join(',', map {"$_=?"} @$cols);

    # Add the where clause.
    $sql .= ' WHERE '.join(' AND ', @$where);

    my $sth = prepare_c($sql, undef);

    execute($sth, map { $bind->{$_} } (@$cols, 'id'));

    return $self;
}

#------------------------------------------------------------------------------#

=item $self = $self->_delete_from_table($type, $where, $bind);

Update a table in the database.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _delete_from_table {
    my $self = shift;
    my ($type, $where, $bind) = @_;
    my $name = $self->short_object_type;
    my ($table, $abbr, $cols) = _table_info($type, $name);

    # Do not continue with this delete unless a where clause has been supplied.
    return unless $where;

    my $sql = "DELETE FROM $table WHERE ".join(' AND ', @$where);
    my $sth = prepare_c($sql, undef);

    execute($sth, @$bind);

    return $self;
}

1;
__END__

=back

=head1 Notes

NONE

=head1 Author

Garth Webb <garth@perijove.com>

=head1 See Also

L<perl>, L<Bric>, L<Bric::Util::Group>

=cut
