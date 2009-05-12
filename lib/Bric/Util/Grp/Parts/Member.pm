package Bric::Util::Grp::Parts::Member;

###############################################################################

=head1 Name

Bric::Util::Grp::Parts::Member - A Class for associating Members of a
Group with attribute with in the group

=cut

require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

  # Constructors.
  my $member = Bric::Util::Grp::Parts::Member->new( $initial_state );
  $member = Bric::Util::Grp::Parts::Member->lookup( { id => $id} );
  my ($member_list||@members) = Bric::Util::Grp::Parts::Member->list($params);
  my $member_href = Bric::Util::Grp::Parts::Member->href($params);

  # Class methods.
  ($ids || @ids ) = Bric::Util::Grp::Parts::Member->list_ids({grp => $grp })

  # Instances methods.
  my $id = $member->get_id;
  $member = $member->activate;
  $member = $member->deactivate;

  # Attribute methods.
  $member = $member->set_attrs( [name=> $name,subsys=> $subsys,val => $val}]);
  ($val_list||@vals) = $member->get_attrs([ {name=> $name,subsys=> $subsys}]);

  # Retrieve the underlying Bric object.
  $object = $member->get_object;

=head1 Description

A Member is a container for an object and any properties that it may have with
in the group it is associated with that it would not have by its self.

=cut

#==============================================================================#
# Dependencies                         #
#======================================#

#--------------------------------------#
# Standard Dependencies
use strict;

#--------------------------------------#
# Programatic Dependencies
use Bric::Util::Class;
use Bric::Util::DBI qw(:all);
use Bric::Util::Attribute::Member;
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

use constant DEBUG                => 0;
use constant MEMBER_SUBSYS        => '_MEMBER_SUBSYS';
use constant ORD                  => qw(id name obj_id active);
use constant TABLE                => 'member';
use constant MEMBER_COLS          => qw(grp__id class__id active);
use constant MEMBER_FIELDS        => qw(grp_id _object_class_id _active);
use constant OBJECT_MEMBER_COLS   => qw(object_id member__id);
use constant OBJECT_MEMBER_FIELDS => qw(obj_id id);

# flag for checking attributes
use constant GROUP_AND_PARENTS => 1;

# flag for checking attributes
use constant GROUP => 2;

#==============================================================================#
# Fields                               #
#======================================#

#--------------------------------------#
# Public Class Fields
# None.

#--------------------------------------#
# Private Class Fields
my $meths;

#--------------------------------------#
# Instance Fields
# None

# This method of Bricolage will call 'use fields' for you and set some permissions.
BEGIN {
    Bric::register_fields( {

            # Public Fields

            # the data base id 
            'id' => Bric::FIELD_READ,

            # group is here
            'grp' => Bric::FIELD_RDWR,

            'grp_id' => Bric::FIELD_RDWR,

            # object 
            'obj' => Bric::FIELD_RDWR,

            'obj_id' => Bric::FIELD_RDWR,

            'object_package' => Bric::FIELD_RDWR,

            # Private Fields

            # The active Flag
            '_object_class_id' => Bric::FIELD_NONE,

            '_update_attr' => Bric::FIELD_NONE,

            '_active' => Bric::FIELD_NONE,

            '_table' => Bric::FIELD_NONE,

            '_short' => Bric::FIELD_NONE,

            # the attr object
            '_attr_obj' => Bric::FIELD_NONE,

            # the cache of attributes before we can get an attr object
            '_attr_cache' => Bric::FIELD_NONE,

            # a cache of attribute meta before we can get a meta object
            '_meta_cache' => Bric::FIELD_NONE,

            '_delete' => Bric::FIELD_NONE,

            '_class_info' => Bric::FIELD_NONE
        }
    );
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

=item $member = Bric::Util::Grp::Parts::Member->new( $initial_state )

This will create a new member object with the defined initial state

Supported Keys:

=over 4

=item object_class_id

=item object_package

=item grp

=item active

=back

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub new {
    my ( $class, $init ) = @_;
    # bless the object
    my $self = bless {}, $class;

    if ( $init->{object_class_id} ) {
        $init->{_object_class_id} = delete $init->{object_class_id};
    } else {
        # figure out the class id
        $init->{_object_class_id} =
          $self->_get_class_id( $init->{object_package} );
    }

    $init->{_active} = 1;
    $self->SUPER::new($init);
    $self->set_attrs( $init->{attr} ) if $init->{attr};
    $self->_set__dirty(1);
    return $self;
}

=item $member = Bric::Util::Grp::Parts::Member->lookup({ id => $id });

Looks up a member object for a given ID.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub lookup {
    my ( $class, $param ) = @_;
    my $self = $class->cache_lookup($param);
    return $self if $self;

    $self = bless {}, ref $class || $class;
    my $sql =
      'SELECT id, '
      . join ( ', ', MEMBER_COLS ) . ' FROM ' . TABLE
      . ' WHERE id=? ';

    my @d;
    my $sth = prepare_c( $sql, undef );
    my $rows = execute( $sth, $param->{'id'} );
    bind_columns( $sth, \@d[ 0 .. ( scalar MEMBER_COLS ) ] );
    fetch($sth);
    finish($sth);

    $self->_set( [ 'id', MEMBER_FIELDS ], [@d] );
    return if $rows eq 'OEO';
    my $member_table = $self->_get_map_table_name();

    $sql =
      'SELECT id, '
      . join ( ', ', OBJECT_MEMBER_COLS ) . ' FROM '
      . $member_table
      . ' WHERE member__id=? ';

    my @d2;
    $sth = prepare_c( $sql, undef );
    $rows = execute( $sth, $self->_get('id') );
    bind_columns( $sth, \@d2[ 0 .. ( scalar OBJECT_MEMBER_COLS ) ] );
    fetch($sth);
    finish($sth);

    $self->_set( [ 'id', OBJECT_MEMBER_FIELDS ], [@d2] );

    # Clear the dirty bit and return.
    $self->_set__dirty(0);
    return $self->cache_me;
}

##############################################################################

=item ($mbr_list||@mbrs) = Bric::Util::Grp::Parts::Member->list($params);

This will return a list or list ref of blessed Member objects that are a
member of said a group. The C<$params> hash reference supports the following
keys:

=over 4

=item grp

A Bric::Util::Grp object, the members of which are to be returned.

=item grp_package

The package name of a Bric::Util::Grp subclass, the members of which are to be
returned.

=item object

A Bric object for which a list of group memberships will be returned.

=item object_package

The package name of a Bric object for which a list of group memberships will
be returned. Use in combination with the C<object_id> parameter.

=item object_id

The ID of a Bric object for which a list of group memberships will
be returned. Use in combination with the C<object_package> parameter.

=back

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub list {
    my ($class, $params) = @_;
    $class->_do_list($params);
}

=item my $memb_href = Bric::Util::Grp::Parts::Member->href($params);

Returns an anonymous hash of group members. The hash values are
Bric::Util::Grp::Parts::Member objects. Takes the same arguments as the
C<list()> method, although either the C<grp> or C<grp_package> parameter is
required. If the group class method C<get_object_class_id()> returns a value,
then the hash keys will be the IDs of the objecs represented by the members.
Otherwise, the keys will be the IDs of the member objects themselves.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub href {
    my ($class, $params) = @_;
    $class->_do_list($params, undef, 1);
}

#--------------------------------------#

=back

=head2 Destructors

=over 4

=item $contrib->DESTROY

Dummy method to prevent wasting time trying to AUTOLOAD DESTROY.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=back

=cut

sub DESTROY {

    # This method should be here even if its empty so that we don't waste time
    # making Bricolage's autoload method try to find it.
}

#--------------------------------------#

=head2 Public Class Methods

=over 4

=item ($ids||@ids ) = Bric::Util::Grp::Parts::Member->list_ids($params);

Return a list or anonymous array of Member object ids. The supported keys
in the C<$params> hash reference are the same as for the C<list()> method.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub list_ids {
    my ($class, $params) = @_;
    $class->_do_list($params, 1);
}

################################################################################

=item $meths = Bric::Util::Grp::Parts::Member->my_meths

=item (@meths || $meths_aref) = Bric::Util::Grp::Parts::Member->my_meths(TRUE)

=item my (@meths || $meths_aref) = Bric::Util::Grp->my_meths(0, TRUE)

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

An anonymous hash of properties used to display the property or attribute.
Possible keys include:

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
    my ($pkg, $ord, $ident) = @_;
    return if $ident;

    # Return 'em if we got em.
    return !$ord ? $meths : wantarray ? @{$meths}{&ORD} : [ @{$meths}{&ORD} ]
      if $meths;

    # We don't got 'em. So get 'em!
    $meths = {
        id => {
            name     => 'id',
            get_meth => sub { shift->get_id(@_) },
            get_args => [],
            disp     => 'ID',
            type     => 'short',
            len      => 10,
        },
        name => {
            name     => 'name',
            get_meth => sub { shift->get_object->get_name(@_) },
            get_args => [],
            disp     => 'Name',
            search   => 1,
            len      => 256,
            type     => 'short',
        },
        obj_id => {
            name     => 'obj_id',
            get_meth => sub { shift->get_obj_id(@_) },
            get_args => [],
            disp     => 'Member Object ID',
            len      => 10,
            req      => 0,
            type     => 'short',
        },
        active => {
            name     => 'active',
            get_meth => sub { shift->is_active(@_) ? 1 : 0 },
            get_args => [],
            set_meth => sub {
                $_[1] ? shift->activate(@_) : shift->deactivate(@_);
            },
            set_args => [],
            disp     => 'Active',
            len      => 1,
            req      => 1,
            type     => 'short',
            props    => { type => 'checkbox' }
        }
    };
    return !$ord ? $meths : wantarray ? @{$meths}{&ORD} : [ @{$meths}{&ORD} ];
}

=item (@ids || $ids) = Bric::Util::Grp::Parts::Member->get_all_object_ids($grp_id)

Returns a list of the object ids that this object is a member of

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_all_object_ids {
    my ( $class, $grp_id, $short ) = @_;

    my $table = $short . '_member';

    my $sql =
      "SELECT o.object_id "
      . " FROM member m, $table o "
      . " WHERE m.grp__id=? AND "
      . " o.member__id = m.id ";

    my $sth = prepare_c( $sql, undef );
    my $return = col_aref( $sth, $grp_id );
    return wantarray ? @$return : $return;
}

#--------------------------------------#

=back

=head2 Public Instance Methods

=over 4

=item $package = $member->get_object_package();

returns the package of the object that is the member

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_object_package {
    my ($self) = @_;
    my $package = $self->_get('object_package');
    return $package if $package;
    $package = $self->_get_package( $self->_get('_object_class_id') );
    return $package;
}

=item $object = $member->get_object()

Return the object that this member reflects

B<Notes:>

The object class isn't loaded by the group class, so when using
the Bric API outside of Bricolage, you need to require the object
class on the fly; for example:

  my @members = $grp->get_members();
  foreach my $m (@members) {
      my $pkg = $m->get_object_package();
      eval "require $pkg";
      my $object = $m->get_object();
  }

B<Throws:>
NONE

B<Side Effects:>
NONE

=cut

sub get_object {
    my ($self) = @_;
    my $dirty = $self->_get__dirty;

    # Package name was set based upon the table that the
    # select populated rows from

    my ( $obj, $id ) = $self->_get(qw(obj obj_id));
    my $package = $self->get_object_package();
    unless ($obj) {
        $obj = $package->lookup( { id => $id } );
        $self->_set( ['obj'], [$obj] );

        # Clear the dirty bit.
        $self->_set__dirty($dirty);
    }
    return $obj;
}

=item $member = $member->set_attr($param)

Sets an individual attribute on this member

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub set_attr {
    my ( $self, $param ) = @_;

    # default the subsystem if one has not been provided
    $param->{'subsys'} ||= MEMBER_SUBSYS;

    # default the sql type
    $param->{'sql_type'} ||= 'short';

    # send to internal method
    $self->_set_attr($param);
    return $self;
}

=item $member = $member->delete_attr();

Deletes attributes from this member

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub delete_attr {
    my ( $self, $param ) = @_;

    # default the subsystem if one has not been provided
    $param->{'subsys'} ||= MEMBER_SUBSYS;
    $self->_delete_attr($param);
    return $self;
}

=item $member = $member->set_attrs( [ $param] )

Takes a list of attributes and sets them upon the member object.  

B<Throws:>

NONE

B<Side Effects:>

Sets a value on the attribute object

B<Notes:>

NONE

=cut

sub set_attrs {
    my ( $self, $param ) = @_;
    foreach (@$param) {

        # set a default subsystem
        $_->{'subsys'} ||= MEMBER_SUBSYS;

        # set a default sql type unless one has been provided
        $_->{'sql_type'} ||= 'short';
        $self->_set_attr($_);
    }
    return $self;
}

=item (@subsys, $subsys) = $mbr->subsys_names()

returns a list of the subsystems in use

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub subsys_names { $_[0]->_subsys_names }

=item $val = $mbr->get_attr({ name => $attr })

Returns a single attribute for the member.

B<Throws:>

NONE

B<Side Effects:>

Returns value from the attribute object

B<Notes:>

NONE

=cut

sub get_attr {
    my ( $self, $param ) = @_;

    # set a default subsystem if none was passed
    $param->{'subsys'} ||= MEMBER_SUBSYS;

    # get the value, check group if not there, check groups parents 
    # if not there
    my $val = $self->_get_attr( $param, GROUP_AND_PARENTS );
    return $val;
}

=item ($attrs || @attrs) = $member->get_attrs( [ $param ])

Returns the attributes defined for this member object.

B<Throws:>

NONE

B<Side Effects:>

Returns value from the attribute object

B<Notes:>

NONE

=cut

sub get_attrs {
    my ( $self, $param ) = @_;

    my @values;
    foreach (@$param) {

        # set a subsys if one was not passed in
        $_->{'subsys'} ||= MEMBER_SUBSYS;
        push @values, $self->_get_attr( $_, GROUP_AND_PARENTS );
    }
    return wantarray ? @values : \@values;
}

=item $member = $member->set_meta($param)

Sets meta information on the attributes

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub set_meta {
    my ( $self, $param ) = @_;

    # set a default subsystem if none was passed
    $param->{'subsys'} ||= MEMBER_SUBSYS;
    $self->_set_meta($param);
    return $self;
}

=item $member = $member->delete_meta($param)

Deletes meta information for this member

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub delete_meta {
    my ( $self, $param ) = @_;

    # set a default subsystem if none was passed
    $param->{'subsys'} ||= MEMBER_SUBSYS;
    $self->_delete_meta($param);
    return $self;
}

=item $meta = $member->get_meta($param)

Returns the meta information 

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_meta {
    my ( $self, $param ) = @_;

    # set the member subsys unless one was passed in
    $param->{'subsys'} ||= MEMBER_SUBSYS;
    my $meta = $self->_get_meta( $param, GROUP_AND_PARENTS );
    return $meta;
}

=item $all = $member->all_for_subsys( $subsys )

Returns a hash ref of all

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub all_for_subsys {
    my ( $self, $subsys ) = @_;

    # set a default subsys
    $subsys ||= MEMBER_SUBSYS;

    # get all the attributes
    my $attr = $self->get_attr_hash( { 'subsys' => $subsys } );

    # return variable
    my $all;
    foreach my $name ( keys %$attr ) {

        # get the meta for each of the name fields
        my $meta = $self->get_meta(
            {
                'subsys' => $subsys,
                'name'   => $name
            }
        );
        $all->{$name} = {
            'value' => $attr->{$name},
            'meta'  => $meta
        };
    }

    return $all;
}

=item $attrs = $member->get_attr_hash( $param )

returns a hash ref of the attrs

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_attr_hash {
    my ( $self, $param ) = @_;
    $param->{'subsys'} ||= MEMBER_SUBSYS;
    my $attrs = $self->_get_attr_hash( $param, GROUP_AND_PARENTS );
    return $attrs;
}

=item $id = $member->get_id()

This will return the id for the object

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

=item $member = $member->activate()

Activated a member object that has been deactivated

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub activate {
    my ($self) = @_;
    $self->_set( { '_active' => 1 } );
    return $self;
}

=item $member = $member->deactivate()

Make this member object inactive

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub deactivate {
    my ($self) = @_;
    $self->_set( { '_active' => 0 } );
    return $self;
}

=item (undef || 1) $member->is_active()

This will return undef if the member has been deactivated and one otherwise.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub is_active {
    my ($self) = @_;
    return $self->_get('_active') ? $self : undef;
}

=item $member = $member->remove()

This will delete the member from the database (as opposed to deactivating)

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub remove {
    my ($self) = @_;
    $self->_set( { '_delete' => 1 } );
}

=item $member = $member->save()

Saves changes to the data base

B<Throws:>

=over 4

=item *

The grp_id or grp property is required.

=back

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub save {
    my ($self) = @_;

    if ( $self->_get__dirty ) {
        my ($id, $gid, $grp, $del) = $self->_get(qw(id grp_id grp _delete));
        unless (defined $gid) {
            $gid = $grp->get_id if $grp;
            throw_gen(error => 'The grp_id or grp property is required')
              unless defined $gid;
            $self->_set(['grp_id'], [$gid]);
        }
        if ($id) {
            $del ? return $self->_do_delete : $self->_do_update;
        } else {
            $del ? return $self : $self->_do_insert;
        }
    }

    $self->_sync_attributes;
    $self->_set__dirty(0);
    return $self;
}

#==============================================================================#

=back

=head1 Private

=head2 Private Class Methods

=over 4

=item $results = _do_list($criteria);

Executes the query for the list constructors

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _do_list {
    my ( $class, $param, $ids, $href ) = @_;

    # set up the supported param
    # process Grp info
    my ( $supported, $force, $grp_id );
    if ( $param->{grp} ) {

        # group object passed in
        $supported = $param->{grp}->get_supported_classes;
        $force     = $param->{grp}->get_object_class_id;
        $grp_id    = $param->{grp}->get_id;
        $param->{grp_package} = ref $param->{grp};
    }
    elsif ( $param->{grp_package} ) {
        $supported = $param->{grp_package}->get_supported_classes;
        $force     = $param->{grp_package}->get_object_class_id;
    }

    my ( $object_id, $package, $object_class_id );
    if ( $param->{object} ) {
        $package   = ref $param->{object};
        $object_id = $param->{object}->get_id;
        # If the group class can contain objects of more than one class, we
        # need to look up the member object for that class only.
        $force = $class->_get_class_id($package)
          unless $param->{grp_package}
          and $param->{grp_package}->get_object_class_id;
    } elsif ( $param->{object_id} && $param->{object_package} ) {
        $object_id = $param->{object_id};
        $package   = $param->{object_package};
        # If the group class can contain objects of more than one class, we
        # need to look up the member object for that class only.
        $object_class_id = $class->_get_class_id($package)
          unless $param->{grp_package}
          and $param->{grp_package}->get_object_class_id;
    }

    my @objs;
    if ($supported) {
        # we can create a joined query!
        if ($force) {
            # All members are in one member table
            my $member_table =
              _get_member_table({ grp_pkg => $param->{grp_package},
                                  id => $force });
            push @objs,
              _do_joined_select( $class, $member_table, $grp_id, $object_id,
                                 $object_class_id, $param->{all}, $ids );
        }
        else {
            foreach ( keys %$supported ) {
                my $member_table =
                  _get_member_table({ grp_pkg => $param->{grp_package},
                                      pkg_name => $_ });

                push @objs,
                  _do_joined_select($class, $member_table, $grp_id, $object_id,
                                    $object_class_id, $param->{all}, $ids);
            }
        }

    }
    else {
        if ( $package && $object_id ) {
            my $member_table =
              _get_member_table({ grp_pkg => $param->{grp_package},
                                  pkg_name => $package });

            push @objs,
              _do_joined_select( $class, $member_table, $grp_id, $object_id,
                                 $object_class_id, $param->{all}, $ids );
        }
        else {
            # HACK. I changed "_do_select" to "_do_joined_select" because
            # there is no "_do_select". So this probably doesn't work at all,
            # but it most likely isn't called at all or we would have noticed
            # it by now.
            push @objs, _do_joined_select( $class, undef, $grp_id, $object_id,
                                           $object_class_id, $param->{all}, $ids );
        }
    }

    # HACK: This should probably be added to the _do_joined_select and
    # _do_select funtions so as to avoid going through the list of objects
    # twice. But it will do for now.
    if ($href) {
        my %objs;
        if ($param->{grp_package}->get_object_class_id) {
            # It's just one class of object. Use the object IDs.
            map { $objs{$_->get_obj_id} = $_ } @objs;
        } else {
            # Use the member ID.
            map { $objs{$_->get_id} = $_ } @objs;
        }
        return \%objs;
    }

    return wantarray ? @objs : \@objs;
}

sub _get_member_table {
    my $params = shift;
    my $grp_pkg = delete $params->{grp_pkg};
    my $pkg = $params->{pkg_name} ||
      Bric::Util::Class->lookup($params)->get_pkg_name;
    my $short = $grp_pkg->get_supported_classes->{$pkg};
    return $short . '_member';
}

sub _do_joined_select {
    my ( $class, $member_table, $grp_id, $object_id, $object_class_id,
         $all, $ids ) = @_;
    my $cols = $ids ? 'm.id' :
      'm.id, m.grp__id, m.class__id, m.active, o.id, o.object_id, o.member__id';
    my $sql =
      " SELECT $cols FROM " . TABLE . " m, $member_table o ";

    my ( @param, @bind );
    if ($grp_id) {
        push @param, ' m.grp__id=? ';
        push @bind,  $grp_id;
    }
    if ($object_id) {
        push @param, ' o.object_id=? ';
        push @bind,  $object_id;
    }
    if ($object_class_id) {
        push @param, ' m.class__id = ? ';
        push @bind,  $object_class_id;
    }
    unless ($all) {
        push @param, " m.active = '1' ";
    }
    push @param, ' m.id=o.member__id ';
    $sql .= ' WHERE ' . join ( ' AND ', @param );

    my $sth = prepare_c( $sql, undef );

    # Just return the IDs, if they're what's wanted.
    return @{ col_aref($sth, @bind) } if $ids;

    # Otherwise, execute and process.
    execute( $sth, @bind );

    my @objs;
    while ( my $row = fetch($sth) ) {
        my $self = bless {}, $class;

        $self->_set(
            {
                'id'               => $row->[0],
                'grp_id'           => $row->[1],
                '_object_class_id' => $row->[2],
                '_active'          => $row->[3],
                'obj_id'           => $row->[5]
            }
        );

        # Clear the dirty bit.
        $self->_set__dirty(0);

        push @objs, $self->cache_me;
    }

    finish($sth);

    return @objs;
}

#--------------------------------------#

=back

=head2 Private Instance Methods

=over 4

=item $class_id = $self->_get_class_id($package)

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _get_class_id {
    my ( $self, $pkg ) = @_;
    my $class_id = Bric::Util::Class->lookup( { pkg_name => lc $pkg } )->get_id;
    throw_gen(error => "Not a Supported Bricolage Class")
      unless $class_id;
    return $class_id;
}

=item $table_name = $self->_get_map_table_name();

Will return the proper mapping table name

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _get_map_table_name {
    my $self = shift;
    my ($cid, $pkg, $grp) =
      $self->_get(qw(_object_class_id object_package grp));
    my $short = $grp->get_supported_classes->{$pkg};
    return $short . '_member';
}

=item $package = $self->_get_package($class_id)

Returns the package name for a given class id

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _get_package {
    my ( $self, $cid ) = @_;
    return Bric::Util::Class->lookup( { id => $cid } )->get_pkg_name;
}

=item $group = $self->_get_group_obj()

Returns the group that this is a member of

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _get_group_obj {
    my ($self) = @_;
    my $dirty = $self->_get__dirty;
    my $grp   = $self->_get('grp');

    unless ($grp) {
        $grp = Bric::Util::Grp->lookup( { id => $self->_get('grp_id') } );

        $self->_set( { grp => $grp } );

        # We don't need to save this change.
        $self->_set__dirty($dirty);
    }

    return $grp;
}

=item $self = $self->_subsys_names()

Returns a list or listref of subsys names

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _subsys_names {
    my ($self) = @_;

    if ( $self->_get('id') ) {
        my $attr_obj = $self->_get_attr_obj();
        return $attr_obj->subsys_names();
    }
    else {
        my $attr_cache = $self->_get('_attr_cache') || {};
        my @subsi;
        foreach ( keys %$attr_cache ) {
            push @subsi, $_;
        }
        return @subsi;
    }
}

=item $self = $self->_set_attr( $param)

Will set an attribute on this member

B<Throws:>

NONE

B<Side Effects>

NONE

B<Notes:>

NONE

=cut

sub _set_attr {
    my ( $self, $param ) = @_;
    my $dirty = $self->_get__dirty;

    # check to see if we have an id, get attr obj if we do
    # otherwise put it into a cache
    if ( $self->_get('id') ) {
        my $attr_obj = $self->_get_attr_obj();

        # param should have been passed in an acceptable manner
        # send it straight to the attr obj
        $attr_obj->set_attr($param);
    }
    else {

        # get the cache or create a new one if necessary
        my $attr_cache = $self->_get('_attr_cache') || {};

        # the value for this subsys/name combo
        $attr_cache->{ $param->{'subsys'} }->{ $param->{'name'} }->{'value'} =
          $param->{'value'};

        # the sql type
        $attr_cache->{ $param->{'subsys'} }->{ $param->{'name'} }->{'type'} =
          $param->{'sql_type'};

        # store the cache so we can access it later
        $self->_set( { '_attr_cache' => $attr_cache } );
    }

    $self->_set( { '_update_attrs' => 1 } );

    # We don't need to save the member object itself for this.
    $self->_set__dirty($dirty);

    return $self;
}

=item $attr = $self->_get_attr($param, $group)

check for attributes on the member, will check the group and the 
group's parents if the flags are passed

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _get_attr {
    my ( $self, $param, $group ) = @_;

    # the data that will be returned
    my $attr;

    # check for an id to see if we need to access the cache or
    # the attribute object
    if ( $self->_get('id') ) {

        # we have an id so get the attribute object
        my $attr_obj = $self->_get_attr_obj();

        # param should have been passed in a valid format
        # send directly to the attr object
        $attr = $attr_obj->get_attr($param);

    }
    else {

        # get the cache if it exists or create if it does not
        my $attr_cache = $self->_get('_attr_cache') || {};

        # get the data to return
        $attr =
          $attr_cache->{ $param->{'subsys'} }->{ $param->{'name'} }->{'value'};
    }

    # check if we should look at the group and maybe even its parents
    if ( $group && !$attr ) {
        my $group_obj = $self->_get_group_obj();
        if ( $group == GROUP ) {
            # XXX Yow!
            $attr = $group_obj->METHOD_NAME_HERE();
        }
        elsif ( $group == GROUP_AND_PARENTS ) {
            $param->{subsys} = MEMBER_SUBSYS;
            $attr = $group_obj->get_member_attr($param);
        }
    }

    return $attr;
}

=item $self = $self->_delete_meta()

Deletes meta information from the attribute object or the cache

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _delete_meta {
    my ( $self, $param ) = @_;

    if ( $self->_get('id') ) {
        my $attr_obj = $self->_get_attr_obj();
        $attr_obj->delete_meta($param);
    }
    else {
        my $meta_cache = $self->_get('meta_cache') || {};
        delete $meta_cache->{ $param->{'subsys'} }->{ $param->{'name'} }
          ->{ $param->{'field'} };
    }

    return $self;
}

=item $self = $self->_delete_attr($param);

Deletes attributes from the attribute object or its cache

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _delete_attr {
    my ( $self, $param ) = @_;
    my $dirty = $self->_get__dirty;

    if ( $self->_get('id') ) {
        my $attr_obj = $self->_get_attr_obj();
        $attr_obj->delete_attr($param);
    }
    else {
        my $attr_cache = $self->_get('_attr_cache');
        delete $attr_cache->{ $param->{'subsys'} }->{ $param->{'name'} };
        $self->_set( { '_attr_cache' => $attr_cache } );
        $self->_set__dirty($dirty);
    }
    return $self;
}

=item $attr_hash = $self->_get_attr_hash( $param, $group)

Returns a hash of the attributes that match the parameters. It will also
return default values from the group if the C<$group> argument is passed.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _get_attr_hash {
    my ( $self, $param, $group ) = @_;
    my $attrs;
    # figure out if we can get the attr_obj
    if ( $self->_get('id') ) {

        # get the attr_obj
        my $attr_obj = $self->_get_attr_obj();
        $attrs = $attr_obj->get_attr_hash($param);
    }
    else {
        # grab the cache
        my $attr_cache = $self->_get('_attr_cache');
        # get the desired info
        foreach ( keys %${ $attr_cache->{ $param->{'subsys'} } } ) {
            $attrs->{$_} = $attr_cache->{ $param->{'subsys'} }->{$_}->{'value'};
        }
    }

    # see if we should check the group
    if ($group) {
        my $group_obj = $self->_get_group_obj();
        my $attrs2    = {};
        if ( $group == GROUP ) {
            # XXXX Yow!
            $attrs2 = $group_obj->METHOD_NAME_HERE($param);
        }
        elsif ( $group == GROUP_AND_PARENTS ) {
            $param->{subsys} = MEMBER_SUBSYS;
            $attrs2 = $group_obj->get_member_attr_hash($param);
        }

        # merge the two
        %$attrs = ( %$attrs2, %$attrs );
    }
    return $attrs;
}

=item $self = $self->_set_meta($param)

Sets meta information on the member attributes

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _set_meta {
    my ( $self, $param ) = @_;
    my $dirty = $self->_get__dirty;

    # determin if we get the object or cache the data
    if ( $self->_get('id') ) {

        # get the attr object
        my $attr_obj = $self->_get_attr_obj();

        # set the meta information as it was given with the 
        # arg
        $attr_obj->add_meta($param);
    }
    else {

        # get the meta info's cache
        my $meta_cache = $self->_get('meta_cache') || {};

        # set the information into the cache
        $meta_cache->{ $param->{'subsys'} }->{ $param->{'name'} }
          ->{ $param->{'field'} } = $param->{'value'};

        # store the cache for future use
        $self->_set( { '_meta_cache' => $meta_cache } );
    }

    $self->_set( { '_update_attrs' => 1 } );
    $self->_set__dirty($dirty);
    return $self;
}

=item $meta = $self->_get_meta($param, $group, $group_parents)

Returns meta information for a given attribute.   Will check the group
and the groups parents for defaults if the flags have been passed.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _get_meta {
    my ( $self, $param, $group ) = @_;
    my $meta = {};
    if ( $self->_get('id') ) {

        # we can have an attribute object so get it
        my $attr_obj = $self->_get_attr_obj();
        $meta = $attr_obj->get_meta($param);
    }
    else {

        # get the cache if we have one
        my $meta_cache = $self->_get('meta_cache') || {};

        # see if they want just a field or it all
        if ( defined $param->{'field'} ) {
            $meta = $meta_cache->{ $param->{'subsys'} }->{ $param->{'field'} };
        }
        else {
            $meta = $meta_cache->{ $param->{'subsys'} };
        }
    }
    if ( $group == GROUP ) {
        # XXX Yow!
        # get from group but not its parents
        if ( $param->{'field'} ) {
            unless ($meta) {
                my $group = $self->_get_group_obj();

                # STILL NEED TO WRITE METHOD IN GROUP!
            }
        }
        else {
            my $group = $self->_get_group_obj();
            my $meta2 = {};    # STILL NEED TO WRITE METHOD IN GROUP!
            %$meta = ( %$meta2, %$meta );
        }

    }
    elsif ( $group == GROUP_AND_PARENTS ) {

        # from group and its parents
        if ( $param->{'field'} ) {
            unless ($meta) {

                # get the group object
                my $group = $self->_get_group_obj();
                $meta = $group->get_meta($param);
            }
        }
        else {

            # get the group's hash and merge them
            my $group = $self->_get_group_obj();
            my $meta2 = $group->get_member_meta($param);
            $meta  = {} unless $meta;
            $meta2 = {} unless $meta2;
            %$meta = ( %$meta2, %$meta );
        }
    }

    return $meta;
}

=item $attr_obj = $self->_get_attr_obj()

Returns the correct attribute object for this member

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
        $attr_obj =
          Bric::Util::Attribute::Member->new( { id => $self->get_id } );
        $self->_set( ['_attr_obj'], [$attr_obj] );
        $self->_set__dirty($dirty);
    }
    return $attr_obj;
}

=item $self = $self->_sync_attributes()

Called by save this preforms all the updates for the attribute object

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _sync_attributes {
    my ($self) = @_;
    my $dirty = $self->_get__dirty;

    # check to see if anything needs to be done
    return $self unless $self->_get('_update_attrs');

    # get the attribute object
    my $attr_obj = $self->_get_attr_obj();

    # see if we have attr in the cache to be stored...
    my $attr_cache = $self->_get('_attr_cache');
    if ($attr_cache) {

        # retrieve cache and store it on the attribute object
        foreach my $subsys ( keys %$attr_cache ) {
            foreach my $name ( keys %{ $attr_cache->{$subsys} } ) {
                # set the attribute
                $attr_obj->set_attr(
                    {
                        subsys   => $subsys,
                        name     => $name,
                        sql_type => $attr_cache->{$subsys}->{$name}->{'type'},
                        value    => $attr_cache->{$subsys}->{$name}->{'value'}
                    }
                );
            }
        }

        # clear the attribute cache
        $self->_set( { '_attr_cache' => undef } );
    }

    # see if we have a meta cache to store
    my $meta_cache = $self->_get('_meta_cache');
    if ($meta_cache) {

        # retrieve meta cache and set it upon the attribute object
        foreach my $subsys ( keys %$meta_cache ) {
            foreach my $name ( keys %{ $meta_cache->{$subsys} } ) {
                foreach my $field ( keys %{ $meta_cache->{$subsys}->{$name} } )
                {
                    $attr_obj->add_meta(
                        {
                            subsys => $subsys,
                            name   => $name,
                            field  => $field,
                            value  => $meta_cache->{$subsys}->{$name}->{$field}
                        }
                    );
                }    # end foreach field
            }    # end foreach name
        }    # end foreach subsys

        $self->_set( { '_meta_cache' => undef } );
    }

    # call save on the attribute object
    $attr_obj->save();

    # clear the update flag
    $self->_set( { '_update_attrs' => undef } );
    $self->_set__dirty($dirty);
    return $self;
}

=item $self = $self->_do_delete

Handles the sql to prefore a delete from the database

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _do_delete {
    my ($self) = @_;
    my $delete = prepare_c( qq{
                DELETE FROM
                        member
                WHERE
                        id=?
                }, undef
    );

    execute( $delete, $self->_get('id') );
    return $self;
}

=item $self = $self->_do_update()

Preforms an update to the database

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Side Effects:>

NONE

=cut

sub _do_update {
    my ($self) = @_;

    # update the member table
    my $sql =
      'UPDATE ' . TABLE . ' SET '
      . join ( ', ', map { "$_=?" } MEMBER_COLS )
      . ' WHERE id=? ';

    my $sth = prepare_c( $sql, undef );
    execute( $sth, ( $self->_get( MEMBER_FIELDS, 'id' ) ) );
    return $self;
}

=item $self = $self->_do_insert()

Preforms the sql for an insert into the member tables

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _do_insert {
    my ($self) = @_;

    # First Create a row in the member table
    my $sql =
      "INSERT INTO " . TABLE . " (id, "
      . join ( ', ', MEMBER_COLS ) . ")"
      . " VALUES (${\next_key(TABLE)},"
      . join ( ',', ('?') x MEMBER_COLS ) . ")";

    my $sth = prepare_c( $sql, undef );
    execute( $sth, $self->_get(MEMBER_FIELDS) );

    # Get the id that was created
    $self->_set( { 'id' => last_key(TABLE) } );

    # Now insert into the mapping table for the proper class
    my $map_table = $self->_get_map_table_name();

    $sql =
      "INSERT INTO "
      . $map_table . "(id, "
      . join ( ', ', OBJECT_MEMBER_COLS ) . ")"
      . " VALUES (${\next_key($map_table)}, "
      . join ( ',', ('?') x OBJECT_MEMBER_COLS ) . ")";

    $sth = prepare_c( $sql, undef );
    execute( $sth, $self->_get(OBJECT_MEMBER_FIELDS) );
    return $self;
}

1;
__END__

=back

=head1 Notes

NONE

=head1 Author

michael soderstrom ( miraso@pacbell.net )

=head1 See Also

L<Bric>, L<Bric::Util::Grp>, L<Bric::Util::Attribute>

=cut
