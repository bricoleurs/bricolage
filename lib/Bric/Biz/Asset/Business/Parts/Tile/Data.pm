package Bric::Biz::Asset::Business::Parts::Tile::Data;
###############################################################################

=head1 NAME

Bric::Biz::Asset::Business::Parts::Tile::Data - Data (Field) Element

=head1 VERSION

$LastChangedRevision$

=cut

require Bric; our $VERSION = Bric->VERSION;

=head1 DATE

$LastChangedDate$

=head1 SYNOPSIS

  # Creation of New Objects
  $data = Bric::Biz::Asset::Business::Parts::Tile::Data->new($params);
  $data = Bric::Biz::Asset::Business::Parts::Tile::Data->lookup({ id => $id });
  @data = Bric::Biz::Asset::Business::Parts::Tile::Data->list($params);

  # Retrieval of Object IDs
  @ids = = Bric::Biz::Asset::Business::Parts::Tile::Data->list_ids($params);

  # Manipulation of Data Field
  $data = $data->set_data( $data_value );
  $data_value = $data->get_data;

=head1 DESCRIPTION

This class contains the contents of field elements, also known as data
elements. These are the objects that hold the values of story element fields.
This class inherits from
L<Bric::Biz::Asset::Business::Parts::Tile|Bric::Biz::Asset::Business::Parts::Tile>.

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
use Bric::Util::Fault qw(throw_gen);
use Bric::Biz::AssetType::Parts::Data;

#==============================================================================#
# Inheritance                          #
#======================================#

# The parent module should have a 'use' line if you need to import from it.
# use Bric;
use base qw(Bric::Biz::Asset::Business::Parts::Tile);

#=============================================================================#
# Function Prototypes                  #
#======================================#

# None

#==============================================================================#
# Constants                            #
#======================================#

use constant DEBUG => 0;

use constant S_TABLE => 'story_data_tile';
use constant M_TABLE => 'media_data_tile';

use constant COLS   => qw(name
                          key_name
                          description
                          element_data__id
                          object_instance_id
                          parent_id
                          place
                          object_order
                          hold_val
                          date_val
                          short_val
                          blob_val
                          active);

use constant FIELDS => qw(name
                          key_name
                          description
                          element_data_id
                          object_instance_id
                          parent_id
                          place
                          object_order
                          _hold_val
                          _date_val
                          _short_val
                          _blob_val
                          _active);

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
    Bric::register_fields(
          {
           # Public Fields

           # reference to the asset type data object
           element_data_id    => Bric::FIELD_RDWR,

           # Private Fields
           _hold_val          => Bric::FIELD_NONE,
           _active            => Bric::FIELD_NONE,
           _date_val          => Bric::FIELD_NONE,
           _short_val         => Bric::FIELD_NONE,
           _blob_val          => Bric::FIELD_NONE,
           _element_obj       => Bric::FIELD_NONE,
           _sql_type          => Bric::FIELD_NONE,
          });
}

#==============================================================================#
# Interface Methods                    #
#======================================#

=head1 INTERFACE

=head2 Constructors

=over 4

=item my $data = Bric::Biz::Asset::Business::Parts::Tile::Data->new($init)

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

=item element_data_id

The ID of the Bric::Biz::AssetType::Parts::Data object that defines the
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
    my ($self, $init) = @_;

    # check active and object
    $init->{_active} = !exists $init->{active} ? 1
      : delete $init->{active} ? 1 : 0;
    $init->{_hold_val} = delete $init->{hold_val} ? 1 : 0;

    $init->{'place'} ||= 0;

    my $obj = delete $init->{'object'};
    if ($obj) {
        $init->{'object_instance_id'} = $obj->get_id();
        my $class = ref $obj;

        if ($class eq 'Bric::Biz::Asset::Business::Media') {
            $init->{'object_type'} = 'media';
        } elsif ($class eq 'Bric::Biz::Asset::Business::Story') {
            $init->{'object_type'} = 'story';
        } else {
            my $err_msg = 'Object of type $class not allowed';
            throw_gen(error => $err_msg);
        }
    }

    if ($init->{'element_data'}) {
        my $atd = delete $init->{'element_data'};

        $init->{'element_data_id'} = $atd->get_id();
        $init->{'name'}            = $atd->get_meta('html_info', 'disp')
          || $atd->get_key_name;
        $init->{'key_name'}        = $atd->get_key_name();
        $init->{'description'}     = $atd->get_description();
        $init->{'_element_obj'}    = $atd;
    }

    unless ($init->{'object_type'}) {
        my $err_msg = "Required parameter 'object_type' missing";
        throw_gen(error => $err_msg);
    }

    $self = bless {}, $self unless ref $self;
    $self->SUPER::new($init);

    $self->_set__dirty(1);

    return $self;
}

################################################################################

=item my $data = Bric::Biz::Asset::Business::Parts::Tile::Data->lookup($params)

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
    throw_gen "Missing required Parameter 'id'"
        unless defined $param->{'id'};
    throw_gen "Missing required Parameter 'object_type' or 'object'"
        unless $param->{'object'} || $param->{obj} || $param->{'object_type'};

    # Determine the short name for this object.
    my $short;
    if (my $obj = $param->{'obj'} || $param->{object}) {
        my $obj_class = ref $obj;

        if ($obj_class eq 'Bric::Biz::Asset::Business::Story') {
            $short = 'story';
        } elsif ($obj_class eq 'Bric::Biz::Asset::Business::Media') {
            $short = 'media';
        } else {
            throw_gen 'Improper type of object passed to lookup';
        }
    } else {
        $short = $param->{'object_type'};
    }

    # Determine the table name given the short name for this object.
    my $table = _get_table_name($short);

    my @d;
    my $sql    = 'SELECT '.join(', ', 'id', COLS)." FROM $table WHERE id=?";
    my $select = prepare_ca($sql, undef);

    execute($select, $param->{'id'});
    bind_columns($select, \@d[0 .. (scalar COLS)]);
    fetch($select);

    $self = bless {}, $class;

    $self->_set(['id', FIELDS], [@d]);
    $self->SUPER::new;

    # Make sure the object type is set.
    $self->_set(['object_type'], [$short]);

    $self->_set__dirty(0);

    return $self->cache_me;
}

################################################################################

=item my @data = Bric::Biz::Assets::Business::Parts::Tile::Data->list($params)

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
specified.

=item name

The name of the data elements. Since the SQL C<LIKE> operator is used with
this search parameter, SQL wildcards can be used.

=item key_name

The key name of the data elements. Since the SQL C<LIKE> operator is used with
this search parameter, SQL wildcards can be used.

=item parent_id

The ID of the container element that is the parent element of the data
elements.

=item element_data_id

The ID of the Bric::Biz::AssetType::Parts::Data object that specifies the
structure of the data elements.

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

#--------------------------------------#

=back

=head2 Public Class Methods

=over 4

=item my @ids = Bric::Biz::Assets::Business::Parts::Tile::Data->list_ids($params)

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
L<Bric::Biz::Asset::Business::Parts::Tile|Bric::Biz::Asset::Business::Parts::Tile>,
from which Bric::Biz::Asset::Business::Parts::Tile::Data inherits.

=over 4

=item my $element_data_id = $data->get_element_data_id

Returns the ID of the Bric::Biz::AssetType::Parts::Data object that describes
this element.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $data->set_element_data_id($element_data_id)

Sets the ID of the Bric::Biz::AssetType::Parts::Data object that describes
this element.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $atd = $data->get_element_data_obj

Returns the Bric::Biz::AssetType::Parts::Data object that defines the
structure of this data element.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_element_data_obj {
    my ($self) = @_;
    my $dirty = $self->_get__dirty;
    my $atd   = $self->_get('_element_obj');

    unless ($atd) {
        my $atd_id = $self->_get('element_data_id');
        $atd = Bric::Biz::AssetType::Parts::Data->lookup({id => $atd_id});

        $self->_set(['_element_obj'], [$atd]);
        $self->_set__dirty($dirty);
    }

    return $atd;
}

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

=item $data->set_data($value)

Sets the value of the data element.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub set_data {
    my ($self, $value) = @_;
    my $element  = $self->get_element_data_obj;

    # OK this is just an attribute
    my $sql_type  = $self->_get_sql_type;
    $value = db_date($value) if $sql_type eq 'date';

    my $old_val = $self->_get('_'.$sql_type.'_val');
    return $self unless (defined $value && not defined $old_val)
      || (not defined $value && defined $old_val)
      || ($value ne $old_val);

    $self->_set(['_'.$sql_type.'_val'] => [$value]);
}

################################################################################

=item my $value = $data->get_data

=item my $value = $data->get_data($format)

Returns the value of this data element. If the SQL type of the data object is
"date", then C<$format>, if it is passed, will be used to format the date.
Otherwise, the format set in the preferences will be used.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:>

For data fields that can return multiple values, you currently have to parse
the data string like this:

   my $str = $element->get_data('blah');
   my @opts = split /__OPT__/, $str;

This behavior might be changed so that the string is automatically split for
you.

=cut

sub get_data {
    my ($self, $format) = @_;
    my $sql_type = $self->_get_sql_type or return undef;
    return $sql_type eq 'date'
           ? local_date(scalar $self->_get('_date_val'), $format)
           : scalar $self->_get('_'.$sql_type.'_val');
}

################################################################################

=item $data->prepare_clone

Prepares the data element to be cloned, such as when a new version of a
document is created, or when a document itself is cloned.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub prepare_clone {
    my ($self) = @_;
    $self->_set(['id'], [undef]);
    return $self;
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

=item my $is_autopopulated = $data->is_autopopulated

Returns true if this data element's value is autopopulated.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub is_autopopulated {
    my ($self) = @_;
    my $at = $self->get_element_data_obj;
    return $self if $at->get_autopopulated;
}

###############################################################################

=item $data->lock_val

For autopopulated data elements, this method prevents the value from being
autopopulated.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub lock_val {
    my ($self) = @_;
    $self->_set(['_hold_val'], [1]);
}

###############################################################################

=item $data = $data->unlock_val

Allows auotpopulated data elements to be autopopulated.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub unlock_val {
    my ($self) = @_;
    $self->_set(['_hold_val'], [0]);
}

###############################################################################

=item my $is_locked = $data->is_locked

Returns true if the tile has been locked.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub is_locked {
    my ($self) = @_;
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
        $self->_do_update();
    } else {
        $self->_do_insert();
    }

    $self->_set__dirty(0);
}

################################################################################

#==============================================================================#
# Private Methods                      #
#======================================#

=back

=head1 PRIVATE

=head2 Private Class Methods

=over 4

=item Bric::Biz::Asset::Business::Parts::Tile::Data->_do_list($class, $param, $ids)

Called by C<list()> or C<list_ids()>, this method returns either a list of ids
or a list of objects, depending on the third argument.

B<Throws:>

=over 4

=item *

Object of type $obj_class not allowed to be tiled.

=item *

Improper args for list.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _do_list {
    my ($class, $param, $ids) = @_;

    unless ($param->{'object'} || $param->{'object_type'}) {
        my $err_msg = "Improper arguments for method 'list'";
        throw_gen(error => $err_msg);
    }

    # Get the object type and object ID.
    my ($obj_type,$obj_id);
    if ($param->{'object'}) {
        my $obj_class = ref $param->{'object'};

        # Get the object type.
        if ($obj_class eq 'Bric::Biz::Asset::Business::Story') {
            $obj_type = 'story';
        } elsif ($obj_class eq 'Bric::Biz::Asset::Business::Media') {
            $obj_type = 'media';
        }

        $param->{'object_instance_id'} = $param->{'object'}->get_version_id();
    } else {
        $obj_type = $param->{'object_type'};
    }

    # Get the table name
    my $table = _get_table_name($obj_type);

    # Build up a where clause if necessary.
    my (@where, @bind);
    foreach my $f (qw(object_instance_id active name parent_id)) {
        next unless exists $param->{$f};
        push @where, "$f = ?";
        push @bind, $param->{$f};
    }

    foreach my $f (qw(name key_name)) {
        next unless exists $param->{$f};
        push @where, "$f LIKE ?";
        push @bind, lc $param->{$f};
    }

    if (exists $param->{element_data_id}) {
        push @where, "element_data__id = ?";
        push @bind, $param->{element_data_id};
    }

    my $sql = 'SELECT id';

    # Add the rest of the columns unless we just want IDs
    $sql .= ','.join(',', COLS) unless $ids;

    $sql .= " FROM $table";
    $sql .= ' WHERE '.join(' AND ', @where) if @where;

    ## PREPARE AND EXECUTE THE SQL ##
    my $select = prepare_ca($sql, undef);
    if ($ids) {
        my $return = col_aref($select, @bind);
        return wantarray ? @{ $return } : $return;
    } else {
        my @objs;
        execute($select, @bind);
        my @d;
        bind_columns($select,\@d[0 .. scalar(COLS)]);
        while (fetch($select)) {
            my $self = bless {}, $class;
            $self->_set(['id', FIELDS, 'object_type'], [@d, $obj_type]);
            $self->_set__dirty(0);
            push @objs, $self->cache_me;
        }
        return wantarray ? @objs : \@objs;
    }
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

Object must be a media or story to add tiles.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _do_insert {
    my $self = shift;
    my $table        = $self->_get_table_name;
    my $next_key_sql = next_key($table);

    my $sql = "INSERT INTO $table (id,".join(',', COLS) . ') '.
              "VALUES ($next_key_sql,".join(',', ('?') x COLS).')';

    my $insert = prepare_c($sql, undef);
    execute($insert, ($self->_get(FIELDS)));

    $self->_set(['id'], [last_key($table)]);

    return $self;
}

################################################################################

=item $data->_do_update

Called by C<save()>, this method updates the data element into the database.

B<Throws:>

=over 4

=item *

Object must be a media or story to add tiles.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _do_update {
    my ($self) = @_;
    my $table = $self->_get_table_name;

    my $sql = "UPDATE $table SET ".join(',', map {"$_=?"} COLS).' WHERE id=?';
    my $update = prepare_c($sql, undef);

    execute($update, ($self->_get( FIELDS )), $self->_get('id') );

    return $self;
}

################################################################################

=item $attr_obj = $self->_get_sql_type

Returns the sql type for the value of this data element.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _get_sql_type {
    my $self = shift;
    my $dirty    = $self->_get__dirty;
    my $sql_type = $self->_get('_sql_type');

    unless ($sql_type) {
        my $at    = $self->get_element_data_obj();
        $sql_type = $at->get_sql_type();

        $self->_set(['_sql_type'], [$sql_type]);
        $self->_set__dirty($dirty);
    }

    return $sql_type;
}

################################################################################

=item $name = $self->_get_table_name()

=item $name = _get_table_name($object_type);

Returns the name of the table this data element uses. This method can act as a
class or instance method depending on how it's called.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _get_table_name {
    my $self = shift;
    my $type = ref $self ? $self->get_object_type : $self;

    if ($type eq 'story') {
        return S_TABLE;
    } elsif ($type eq 'media') {
        return M_TABLE;
    } else {
        my $err_msg = "Object of type '$type' not allowed";
        throw_gen(error => $err_msg);
    }
}

################################################################################

1;
__END__

=back

=head1 NOTES

NONE

=head1 AUTHOR

Michael Soderstrom <miraso@pacbell.net>

=head1 SEE ALSO

L<perl>, L<Bric>, L<Bric::Biz::Asset>, L<Bric::Biz::Asset::Business>,
L<Bric::Biz::Asset::Business::Parts::Tile>

=cut

