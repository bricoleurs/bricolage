package Bric::Biz::Asset::Business::Parts::Tile::Data;
###############################################################################

=head1 NAME

Bric::Biz::Asset::Business::Parts::Tile::Data - The tile class that contains
the business data.

=head1 VERSION

$Revision: 1.12.2.2 $

=cut

our $VERSION = (qw$Revision: 1.12.2.2 $ )[-1];

=head1 DATE

$Date: 2003-03-05 18:48:08 $

=head1 SYNOPSIS

  # Creation of New Objects
  $tile = Bric::Biz::Asset::Business::Parts::Tile::Data->new($params);
  $tile = Bric::Biz::Asset::Business::Parts::Tile::Data->lookup({ id => $id });
  @tiles = Bric::Biz::Asset::Business::Parts::Tile::Data->list($params);

  # Retrieval of Object IDs
  @ids = = Bric::Biz::Asset::Business::Parts::Tile::Data->list_ids($params);

  # Manipulation of Data Field
  $tile = $tile->set_data( $data_asset );
  $data_asset = $tile->get_data;

=head1 DESCRIPTION

This class holds the Business Asset Parts Data objects in a tile

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
use Bric::Util::Fault::Exception::GEN;
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

           # association with formatting asset is inheriated
           # as will be the association with an asset
           name               => Bric::FIELD_RDWR,
           key_name           => Bric::FIELD_RDWR,
           description        => Bric::FIELD_RDWR,

           # reference to the asset type data object
           element_data_id    => Bric::FIELD_RDWR,
           object_instance_id => Bric::FIELD_RDWR,
           parent_id          => Bric::FIELD_RDWR,

           # This item's place in the list of tiles
           place              => Bric::FIELD_RDWR,

           # This item's sequence among items of the same name
           object_order       => Bric::FIELD_RDWR,
           object_type        => Bric::FIELD_READ,

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

=item $tile = Bric::Biz::Asset::Business::Parts::Tile::Data->new($init)

This will create a new tile object with the given state defined by the
optional initial state argument

Supported Keys:

=over 4

=item *

active

=item *

obj_type (story || media)

=item *

obj_id

=item *

place

=item *

element_data_id

=item *

parent_id

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
            die Bric::Util::Fault::Exception::GEN->new({msg => $err_msg});
        }
    }

    if ($init->{'element_data'}) {
        my $atd = delete $init->{'element_data'};

        $init->{'element_data_id'} = $atd->get_id();
        $init->{'name'}            = $atd->get_meta('html_info', 'disp');
        $init->{'key_name'}        = $atd->get_key_name();
        $init->{'description'}     = $atd->get_description();
        $init->{'_element_obj'}    = $atd;
    }

    unless ($init->{'object_type'}) {
        my $err_msg = "Required parameter 'object_type' missing";
        die Bric::Util::Fault::Exception::GEN->new({msg => $err_msg});
    }

    $self = bless {}, $self unless ref $self;
    $self->SUPER::new($init);

    $self->_set__dirty(1);

    return $self;
}

################################################################################

=item $tile = Bric::Biz::Asset::Business::Parts::Tile::Data->lookup
  ({ id => $id})

This will return an existing tile object that is defined by the data tile ID.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub lookup {
    my ($class, $param) = @_;
    my $self = $class->cache_lookup($param);
    return $self if $self;

    unless ($param->{'id'} && ($param->{'obj'} ||$param->{'object_type'})) {
        my $err_msg = 'Improper criteria passed to lookup';
        die Bric::Util::Fault::Exception::GEN->new({msg => $err_msg});
    }

    # Determine the short name for this object.
    my $short;
    if ($param->{'obj'}) {
        my $obj_class = ref $param->{'obj'};

        if ($obj_class eq 'Bric::Biz::Asset::Business::Story') {
            $short = 'story';
        } elsif ($obj_class eq 'Bric::Biz::Asset::Business::Media') {
            $short = 'media';
        }
    } else {
        $short = $param->{'object_type'};
    }

    # Determine the table name given the short name for this object.
    my $table = _get_table_name($short);

    my @d;
    my $sql    = 'SELECT '.join(', ', 'id', COLS)." FROM $table WHERE id=?";
    my $select = prepare_ca($sql, undef, DEBUG);

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

=item (@ts||$ts) = Bric::Biz::Assets::Business::Parts::Tile::Data->list($params)

This will return a list or list ref of tiles that match the given criteria

Supported Keys:

=over 4

=item *

active

=item *

obj

=item *

obj_type

=item *

obj_id

=item *

ref_type

=item *

ref_id

=item *

place *

=item *

element_data_id

=item *

parent_id

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

=item $self->DESTROY

a dummy method to save auto load some time

=cut

sub DESTROY {
    # This method should be here even if its empty so that we don't waste time
    # making Bricolage's autoload method try to find it.
}

#--------------------------------------#

=back

=head2 Public Class Methods

=over 4

=item (@ids || $ids) = Bric::Biz::Assets::Business::Parts::Tile::Data->list_ids($p)

This will return a list or list ref of tile ids that match the given criteria

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

=over 4

=item $atd = $data->get_element_data_obj()

Returns the asset type data object associated with this data tile

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

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

=item $name = $data->get_element_name()

Returns the name of the element

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_element_name {
    my ($self) = @_;

    return $self->get_name;
}

################################################################################

=item $tile = $tile->set_data($value)

This will create the attribute on the business asset and store it in this
tile.

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

    no warnings;
    unless ($self->_get('_'.$sql_type.'_val') eq $value) {
        $self->_set(['_'.$sql_type.'_val'], [$value]);
    }

    return $self;
}

################################################################################

=item $data = $tile->get_data

=item $data = $tile->get_data($format)

Returns the given business data from the tile. If the SQL type of the data
object is "date", then $format will be used to format the date, if it is
passed. Otherwise, the format set in the preferences will be used.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_data {
    my ($self, $format) = @_;
    my $sql_type = $self->_get_sql_type or return;
    return $sql_type eq 'date' ?
      local_date($self->_get('_date_val'), $format) :
      $self->_get('_'.$sql_type.'_val');
}

################################################################################

=item $self = $self->prepare_clone()

Business Data has to clone its self from time to time.   Since tiles store
the business data, this method prepares them to be cloned.   It will set the
id to undef and will be updated with new info come save time

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub prepare_clone {
    my ($self) = @_;
    $self->_set(['id'], [undef]);
    return $self;
}

################################################################################

=item undef = $tile->is_container()

Returns the fact that this is not a container tile

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub is_container { return }

###############################################################################

=item ($self || $data) = $self->is_autopopulated()

Tells if this is an autopopulated tile

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub is_autopopulated {
    my ($self) = @_;
    my $at = $self->_get_element_object();
    return $self if $at->get_autopopulated();
}

###############################################################################

=item $tile = $tile->lock_val()

For tiles that are autopopulated, this will prevent the value from being
autopopulated.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub lock_val {
    my ($self) = @_;
    $self->_set(['_hold_val'], [1]);
    return $self;
}

###############################################################################

=item $tile = $tile->unlock_val()

Unsets the lock val flag.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub unlock_val {
    my ($self) = @_;
    $self->_set(['_hold_val'], [0]);
    return $self;
}

###############################################################################

=item ($tile || undef) = $tile->is_locked();

Returns if the tile has been locked

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub is_locked {
    my ($self) = @_;
    return $self if $self->_get('_hold_val');
}

###############################################################################

=item $tile = $tile->save()

Saves the chenges made to the database

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

    return $self;
}

################################################################################

#==============================================================================#
# Private Methods                      #
#======================================#

=back

=head1 PRIVATE

=head2 Private Class Methods

=over 4

=item _do_list($class, $param, $ids)

Called by list or list_ids this returns either a list of ids or a list of
objects, depending on the caller.

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
        die Bric::Util::Fault::Exception::GEN->new({msg => $err_msg});
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
    foreach my $f (qw(object_instance_id active element_data_id name
                      parent_id)) {
        next unless exists $param->{$f};
        push @where, "$f=?";
        push @bind, $param->{$f};
    }

    my $sql = 'SELECT id';

    # Add the rest of the columns unless we just want IDs
    $sql .= ','.join(',', COLS) unless $ids;

    $sql .= " FROM $table";
    $sql .= ' WHERE '.join(' AND ', @where) if @where;

    ## PREPARE AND EXECUTE THE SQL ##
    my $select = prepare_ca($sql, undef, DEBUG);
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

=item _do_insert()

inserts the row into the database

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

    my $insert = prepare_c($sql, undef, DEBUG);
    execute($insert, ($self->_get(FIELDS)));

    $self->_set(['id'], [last_key($table)]);

    return $self;
}

################################################################################

=item $self = $self->_do_update()

Updates the row in the database.

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
    my $update = prepare_c($sql, undef, DEBUG);

    execute($update, ($self->_get( FIELDS )), $self->_get('id') );

    return $self;
}

################################################################################

=item $at_obj = $self->_get_element_object()

Returns the asset type data object

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _get_element_object {
    my ($self) = @_;
    my $dirty = $self->_get__dirty;
    my $at_obj = $self->_get('_element_obj');

    unless ($at_obj) {
        my $at_id = $self->_get('element_data_id');
        $at_obj = Bric::Biz::AssetType::Parts::Data->lookup({id => $at_id});

        $self->_set(['_element_obj'], [$at_obj]);
        $self->_set__dirty($dirty);
    }

    return $at_obj;
}

################################################################################

=item $attr_obj = $self->_get_sql_type()

Returns the sql type for this object.

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

Returns the name of the table this object uses.  This method can act as a class
or instance method depending on how its called.

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
        die Bric::Util::Fault::Exception::GEN->new({msg => $err_msg});
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

