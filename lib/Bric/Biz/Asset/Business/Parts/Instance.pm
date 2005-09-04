package Bric::Biz::Asset::Business::Parts::Instance;
###############################################################################

=head1 NAME

Bric::Biz::Asset::Business::Parts::Instance - Bricolage Document Instance base class

=head1 VERSION

$LastChangedRevision$

=cut

require Bric; our $VERSION = Bric->VERSION;

=head1 DATE

$LastChangedDate: 2004-09-13 20:48:55 -0400 (Mon, 13 Sep 2004) $

=head1 DESCRIPTION

This class defines the common structure of story instances.   Each version of a
story has a separate instance for each input channel associated with that story.
When a story is checked out, the instances are all cloned.

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
use Bric::Util::Fault qw(:all);
use Bric::Biz::Asset::Business::Parts::Tile::Data;
use Bric::Biz::Asset::Business::Parts::Tile::Container;
use Bric::Config qw(:uri :ui);

#==============================================================================#
# Inheritance                          #
#======================================#
use base qw(Bric);

#=============================================================================#
# Function Prototypes                  #
#======================================#

# None

#==============================================================================#
# Constants                            #
#======================================#

use constant DEBUG => 0;

#==============================================================================#
# Fields                               #
#======================================#

#--------------------------------------#
# Public Class Fields
# None.

#--------------------------------------#
# Private Class Fields
my ($METHS, @ORD);

#--------------------------------------#
# Instance Fields

BEGIN {
    Bric::register_fields(
               {
                # Public Fields
                'id'                      => Bric::FIELD_READ,
                'title'                   => Bric::FIELD_RDWR,
                'name'                    => Bric::FIELD_RDWR,
                'description'             => Bric::FIELD_RDWR,
                'input_channel_id'        => Bric::FIELD_READ,
                'element__id'             => Bric::FIELD_RDWR,
                
                # Private Fields
                _tile                     => Bric::FIELD_NONE,
                _element_object           => Bric::FIELD_NONE,

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

=item $story = Bric::Biz::Asset::Business::Parts::Instance->new( $initial_state )

This will create a new story instance with an optionally defined initial state

Supported Keys:

=over 4

=item *

title - same as name

=item *

name - Will be overridden by title

=item *

description

=item *

slug

=back

=cut

sub new {
    my ($self, $init) = @_;
    $self = bless {}, $self unless ref $self;
    my $class = ref $self or throw_mni "Method not implemented";
    $init->{name} = delete $init->{title} if exists $init->{title};
    
    throw_dp "Cannot create an asset without an element"
      unless $init->{element__id} || $init->{element};

    if ($init->{alias_id}) {
        my $alias_target = $class->lookup({ id => $init->{alias_id} });
    }

    # Get the element object.
    if ($init->{element}) {
        $init->{element__id} = $init->{element}->get_id;
    } else {
        $init->{element} =
          Bric::Biz::AssetType->lookup({ id => $init->{element__id}});
    }
    
    # Let's create the new tile as well.
    my $tile = Bric::Biz::Asset::Business::Parts::Tile::Container->new
      ({ object     => $self,
         element_id => $init->{element__id},
         element    => $init->{element}
       });
       
    $self->_set({ _tile => $tile,
                  element__id => $init->{element__id},
                  _element_object => $init->{element}
               });
    
    $self->SUPER::new($init);
}

################################################################################

=item $asset = Bric::Biz::Asset::Business::Story->lookup({ id => $id })

=item $asset = Bric::Biz::Asset::Business::Media->lookup({ id => $id })

=item $asset = Bric::Biz::Asset::Formatting->lookup({ id => $id })

This will return an asset that matches the ID provided.

B<Throws:>

"Missing required parameter 'id'"

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub lookup {
    my ($pkg, $param) = @_;
    $pkg = ref $pkg || $pkg;
    throw_gen(error => "Missing Required Parameter id")
      unless $param->{id};
    # Check the cache.
    my $obj = $pkg->cache_lookup($param);
    return $obj if $obj;

    $param->{'primary_ic'} = (exists $param->{'primary_ic'} ? $param->{'primary_ic'} : 1)
        unless $param->{'id'} || $param->{'primary_ic_id'} || $param->{'input_channel_id'};
    $param->{Order} = $pkg->DEFAULT_ORDER unless $param->{Order};
    
    my $tables =  tables($pkg, $param);
    my ($where, $args) = where_clause($pkg, $param);
    my $order = order_by($pkg, $param);
    my $grp_by = group_by($pkg, $param);
    my $sql = build_query($pkg, $pkg->COLUMNS, $grp_by,
                          $tables, $where, $order, @{$param}{qw(Limit Offset)});
    my $fields = [ 'id', $pkg->FIELDS, $pkg->STORY_FIELDS, 'grp_ids' ];
    my @obj = fetch_objects($pkg, $sql, $fields, 0, $args);
    return unless $obj[0];
    return $obj[0];
}

################################################################################

=item (@stories || $stories) = Bric::Biz::Asset::Business::Story->list($params)

=item (@media_objs || $media) = Bric::Biz::Asset::Business::Media->list($params)

=item (@template_objs || $templates) = Bric::Biz::Asset::Business::Formatting->list($params)

B<See Also:>

=over 4

=item Bric::Biz::Asset::Business::Story->list()

=item Bric::Biz::Asset::Business::Media->list()

=item Bric::Biz::Asset::Business::Formatting->list()

=back

=cut

sub list {
    my ($pkg, $param) = @_;
    $pkg = ref $pkg || $pkg;

    $param->{Order} = $pkg->DEFAULT_ORDER unless $param->{Order};
    
    my $tables = tables($pkg, $param);
    my ($where, $args) = where_clause($pkg, $param);
    my $order = order_by($pkg, $param);
    my $grp_by = group_by($pkg, $param);
    my $sql = build_query($pkg, $pkg->COLUMNS, $grp_by,
                          $tables, $where, $order, @{$param}{qw(Limit Offset)});
    my $fields = [ 'id', $pkg->FIELDS, $pkg->STORY_FIELDS, 'grp_ids' ];
    my @objs = fetch_objects($pkg, $sql, $fields, 0, $args);
    return (wantarray ? @objs : \@objs);
}

=item (@ids||$ids) = Bric::Biz::Asset::Business::Story->list_ids($params)

=item (@ids||$ids) = Bric::Biz::Asset::Business::Media->list_ids($params)

=item (@ids||$ids) = Bric::Biz::Asset::Business::Formatting->list_ids($params)

B<See Also:>

=over 4

=item Bric::Biz::Asset::Business::Story->list_ids()

=item Bric::Biz::Asset::Business::Media->list_ids()

=item Bric::Biz::Asset::Business::Formatting->list_ids()

=back

=cut

sub list_ids {
    my ($pkg, $param) = @_;
    $pkg = ref $pkg || $pkg;

    $param->{'primary_ic'} = (exists $param->{'primary_ic'} ? $param->{'primary_ic'} : 1)
        unless $param->{'primary_ic_id'} || $param->{'input_channel_id'};
    $param->{Order} = $pkg->DEFAULT_ORDER unless $param->{Order};
    
    delete $param->{Order};
    my $cols = 'DISTINCT ' . $pkg->ID_COL;
    my $tables =  tables($pkg, $param);
    my ($where, $args) = where_clause($pkg, $param);
    my $order = order_by($pkg, $param);
    # choose the query type, without grp_ids is faster
    my $sql = build_query($pkg, $cols, '', $tables, $where, $order);
    my $select = prepare_ca($$sql, undef);
    my $return = col_aref($select, @$args);
    return wantarray ? @{ $return } : $return;
}

################################################################################

=item $inst_href = Bric::Biz::Asset::Business::Parts::Instance->href( $criteria )

Returns an anonymous hash of instance objects, where each hash key is an
instance ID, and each value is an instance object that corresponds to
that ID. Takes the same arguments as list().

B<Throws:>

=over 4

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=item *

Unable to select column into arrayref.

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

sub href {
    my $self = shift;
    my @insts = $self->list(@_);
    my %insts;
    foreach my $inst (@insts) {
        $insts{$inst->get_id} = $inst;
    }
    return \%insts;
}

#--------------------------------------#

=back

=head2 Destructors

=over 4

=item $element->DESTROY

Dummy method to prevent wasting time trying to AUTOLOAD DESTROY.

=cut

sub DESTROY {
    # This method should be here even if its empty so that we don't waste time
    # making Bricolage's autoload method try to find it.
}

###############################################################################

=item my $key_name = Bric::Biz::Asset::Business::Parts::Instance->key_name()

Returns the key name of this class.

=cut

sub key_name { 'instance' }

#--------------------------------------#

=back

=head2 Public Class Methods

=over 4

=item $meths = Bric::Biz::Asset::Business::Parts::Tile->my_meths

=item my @meths = Bric::Biz::Asset::BusinessParts::Tile->my_meths(TRUE)

=item my @meths = Bric::Biz:::Asset::BusinessParts::Tile->my_meths(0, TRUE)

Returns an anonymous hash of introspection data for this object. If called
with a true argument, it will return an ordered list or anonymous array of
introspection data. If a second true argument is passed instead of a first,
then a list or anonymous array of introspection data will be returned for
properties that uniquely identify an object (excluding C<id>, which is
assumed).

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

=item type

The display field type. Possible values are

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

=item *

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
    my ($pkg, $ord, $ident) = @_;
    return if $ident;

    # We don't got 'em. So get 'em!
    $METHS ||= {
                id          => { name     => 'id',
                                 get_meth => sub { shift->get_id(@_) },
                                 get_args => [],
                                 disp     => 'ID',
                                 len      => 10,
                                 type     => 'short',
                                },
                             
                name        => { name     => 'name',
                                 get_meth => sub { shift->get_name(@_) },
                                 get_args => [],
                                 set_meth => sub { shift->set_name(@_) },
                                 set_args => [],
                                 disp     => 'Name',
                                 type     => 'short',
                                 len      => 256,
                                 req      => 1,
                                 props    => {   type       => 'text',
                                                 length     => 32,
                                                 maxlength => 256
                                             }
                               },
                             
                description => { name     => 'description',
                                 get_meth => sub { shift->get_description(@_) },
                                 get_args => [],
                                 set_meth => sub { shift->set_description(@_) },
                                 set_args => [],
                                 disp     => 'Description',
                                 req      => 0,
                                 type     => 'short',
                                 props    => {   type => 'textarea',
                                                 maxlength => 1024,
                                                 cols => 40,
                                                 rows => 4
                                             }
                                },
               };

    return !$ord ? $METHS : wantarray ? @{$METHS}{@ORD} : [@{$METHS}{@ORD}];
}

################################################################################

=back

=head2 Public Instance Methods

=over 4

=item $id = $asset->get_id()

This returns the id that uniquely identifies this asset.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

################################################################################

=item $name = $self->get_name()

Returns the name field from Assets

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

################################################################################

=item $self = $self->set_name()

Sets the name field for Assets

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

################################################################################

=item $description = $self->get_description()

This returns the description for the asset

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

################################################################################

=item $self = $self->set_description()

This sets the description on the asset

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

################################################################################

=item $instance = $self->clone()

Creates an identical copy of this asset with a different id

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub clone {
    my ($self) = @_;
    # Uncache the story, so that the clone isn't returned when looking up
    # the original ID.
    $self->uncache_me;

    # Clone the element.
    my $element = $self->get_element();
    $element->prepare_clone;

    # Reset properties. Note that if we start to make use of the attribute
    # object other than for desks, we'll have to find a way to clone it, too.
    $self->_set({ id => undef });

    # Prepare to be saved.
    $self->_set__dirty(1);

    return $self;
}

################################################################################

=item $instance = $instance->save()

Updates the instance object in the database

B<Throws:>
NONE

B<Side Effects:>
NONE

B<Notes:>
NONE

=cut

sub save {
    my $self = shift;

    my $id = $self->_get('id');

    # Start a transaction.
    begin();
    eval {
        if ($id) {
            $self->_update_instance();
        } else {
            $self->_insert_instance();
        }
        commit();
    };
    
    
    if (my $tile = $self->_get('_tile')) {
        $tile->set_object_instance_id($self->_get('id'));
        $tile->save;
    }

    if (my $err = $@) {
        rollback();
        rethrow_exception($err);
    }

    return $self;
}

################################################################################

=item $element = $instance->get_element

 my $element = $instance->get_element;

Returns the top level element that contains content for this document.

=cut

sub get_element {
    my $self = shift;
    my $tile = $self->_get('_tile');
    unless ($tile) {
        ($tile) = Bric::Biz::Asset::Business::Parts::Tile::Container->list
          ({ object    => $self,
             parent_id => undef });
        $self->_set(['_tile'] => [$tile]);
    }
    return $tile;
}

sub get_tile { goto &get_element };

###############################################################################

=item $at_obj = $self->get_element_object()

Returns the asset type object that coresponds to this instance

=cut

sub get_element_object {
    my ($self) = @_;

    my $dirty = $self->_get__dirty();

    my ($at_id, $at_obj) = $self->_get(qw(element__id _element_object));
    return $at_obj if $at_obj;

    if (my $alias_obj = $self->_get_alias) {
        return $alias_obj->get_element_object;
    }

    $at_obj = Bric::Biz::AssetType->lookup({ id => $at_id });
    $self->_set(['_element_object'] => [$at_obj]);
    $self->_set__dirty($dirty);
    return $at_obj;
}

#==============================================================================#

=back

=head1 PRIVATE

NON

=head2 Private Class Methods

NONE

=head2 Private Instance Methods

=item $self = $self->_insert_instance()

Inserts an instance record into the database

=cut

sub _insert_instance {
    my ($self) = @_;

    my $sql = 'INSERT INTO '. $self->TABLE .
      ' (id, '.join(', ', $self->COLS) . ')'.
      "VALUES (${\next_key($self->TABLE)}, ".
      join(', ', ('?') x $self->COLS) . ')';

    my $sth = prepare_c($sql, undef);
    execute($sth, $self->_get($self->FIELDS));
    
    my $id = last_key($self->TABLE);
    
    $self->_set({ 'id' => $id });
    
    return $self;
}

################################################################################

=item $self = $self->_update_instance()

Updates the record for the story instance

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _update_instance {
    my ($self) = @_;
    return unless $self->_get__dirty();
    my $sql = 'UPDATE ' . $self->TABLE .
      ' SET ' . join(', ', map {"$_=?" } $self->COLS) .
      ' WHERE id=? ';

    my $sth = prepare_c($sql, undef);
    execute($sth, $self->_get($self->FIELDS), $self->_get('id'));
    return $self;
}

################################################################################

=item $self = $self->_delete_instance()

Removes the instance row from the database

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _delete_instance {
    my $self = shift;

    my $sql = 'DELETE FROM ' . $self->TABLE .
      ' WHERE id=? ';

    my $sth = prepare_c($sql, undef);
    execute($sth, $self->_get('id'));
    return $self;
}


sub _get_alias {
    my $self = shift;
    my ($alias_id, $alias_obj) = $self->_get(qw(alias_id _alias_obj));
    return unless $alias_id;
    unless ($alias_obj) {
        $alias_obj = ref($self)->lookup({ id => $alias_id });
        $self->_set(['_alias_obj'] => [$alias_obj]);
    }
    return $alias_obj;
}

1;
__END__

=head1 NOTES

NONE

=head1 AUTHOR

michael soderstrom <miraso@pacbell.net>

=head1 SEE ALSO

L<perl>, L<Bric>, L<Bric::Biz::Asset::Business::Story>,
L<Bric::Biz::Asset::Business::Media>, L<Bric::Biz::AssetType>,
L<Bric::Biz::Asset::Business::Parts::Tile::Container>,
L<Bric::Biz::Asset::Business::Parts::Tile::Tile>

=cut

