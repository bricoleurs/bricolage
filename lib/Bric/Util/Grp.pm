package Bric::Util::Grp;

###############################################################################

=head1 Name

Bric::Util::Grp - A class for associating Bricolage objects

=cut

require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

  # Constructors.
  my $grp = Bric::Util::Grp->new($init);
  $grp = Bric::Util::Grp->lookup({ id => $id });
  my @grps = Bric::Util::Grp->list($params);

  # Class methods.
  my @grp_ids = Bric::Util::Grp->list_ids($params)
  my $class_id = Bric::Util::Grp->get_class_id;
  my $supported_classes = Bric::Util::Grp->get_supported_classes;
  my $class_keys_href = Bric::Util::Grp->href_grp_class_keys;
  my $secret = Bric::Util::Grp->get_secret;
  my $class = Bric::Util::Grp->my_class;
  my $member_class = Bric::Util::Grp->member_class;
  my $obj_class_id = Bric::Util::Grp->get_object_class_id;
  my @member_ids = Bric::Util::Grp->get_member_ids($grp_id);
  my $meths = Bric::Util::Grp->my_meths;

  # Instance methods.
  $id = $grp->get_id;
  my $name = $grp->get_name;
  $grp = $grp->set_name($name)
  my $desc = $grp->get_description;
  $grp = $grp->set_description($desc);
  my $parent_id = $grp->get_parent_id;
  $grp = $grp->set_parent_id($parent_id);
  my $class_id = $grp->get_class_id;
  my $perm = $grp->get_permanent;
  my $secret = $grp->is_secret;
  my @parent_ids = $grp->get_all_parent_ids;

  $grp = $grp->activate;
  $grp = $grp->deactivate;
  $grp = $grp->is_active;

  # Instance methods for managing members.
  my @members = $grp->get_members;
  my @member_objs = $grp->get_objects;
  $grp->add_member(\%member_spec);
  $grp->add_members(\@member_specs);
  $grp = $grp->delete_member(\%member_spec);
  $grp = $grp->delete_members(\@member_specs);
  my $member = $grp->has_member({ obj => $obj });

  # Instance methods for managing member attributes.
  $grp = $grp->set_member_attr($params);
  $grp = $grp->delete_member_attr($params);
  $grp = $grp->set_member_attrs(\@attr_specs);
  $grp = $grp->set_member_meta($params);
  my $meta = $grp->get_member_meta($params);
  $grp = $grp->delete_member_meta($params);
  my $attrs = $grp->all_for_member_subsys($subsys)
  my $attr = $grp->get_member_attr($params);
  my $attr_href = $grp->get_member_attr_hash($params);
  my @attrs = $grp->get_member_attrs(\@params);

  # Instance methods for managing group attributes.
  @attrs = $grp->get_group_attrs(\@params);
  $grp = $grp->set_group_attr($params);
  $attr = $grp->get_group_attr($params);
  $grp = $grp->delete_group_attr($params);
  $grp = $grp->set_group_attrs(\@params);
  $grp = $grp->set_group_meta($meta)
  $meta = $grp->get_group_meta($params);
  $grp = $grp->set_group_meta($params);
  $grp = $grp->delete_group_meta($params);
  $attr_href = $grp->get_group_attr_hash;
  $attrs = $grp->all_for_group_subsys($subsys);

  # Save the changes to the database
  $grp = $grp->save;

=head1 Description

Grp is a class that associates Bricolages objects. Attributes can be assigned
to the group as a whole, or to the members of the group. In the latter case,
the attribute values may be changed for individual members.

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
use Bric::Util::Fault qw(throw_gen throw_dp);
use Bric::Util::Class;
use Bric::Util::Coll::Member;

#==============================================================================#
# Inheritance                          #
#======================================#
use base qw(Bric);

#=============================================================================#
# Function Prototypes                  #
#======================================#
my $get_memb_coll;

#==============================================================================#
# Constants                            #
#======================================#

use constant DEBUG => 0;

use constant TABLE  => 'grp';
use constant COLS   => qw(parent_id class__id name description secret permanent
                        active);
use constant FIELDS => qw(parent_id class_id name description secret permanent
                          _active);
use constant ORD    => qw(name description parent_id class_id member_type active);

use constant GRP_SUBSYS        => '_GRP_SUBSYS';
use constant MEMBER_SUBSYS     => Bric::Util::Grp::Parts::Member::MEMBER_SUBSYS;
use constant INSTANCE_GROUP_ID => 35;
use constant GROUP_PACKAGE     => 'Bric::Util::Grp::Grp';
use constant SECRET_GRP => 1;
use constant NONSECRET_GRP => 0;

#==============================================================================#
# Fields                               #
#======================================#

#--------------------------------------#
# Public Class Fields
# None.

#--------------------------------------#
# Private Class Fields
my ($meths, $class, $mem_class);
my $sel_cols = 'g.id, g.parent_id, g.class__id, g.name, g.description, ' .
  'g.secret, g.permanent, g.active, m.grp__id';
my @sel_props = qw(id parent_id class_id name description secret permanent
                   _active grp_ids);

#--------------------------------------#
# Instance Fields
# NONE

# This method of Bricolage will call 'use fields' for you and set some permissions.
BEGIN {
    Bric::register_fields
        ({ id             => Bric::FIELD_READ,
           name           => Bric::FIELD_RDWR,
           description    => Bric::FIELD_RDWR,
           class_id       => Bric::FIELD_READ,
           parent_id      => Bric::FIELD_RDWR,
           secret         => Bric::FIELD_NONE, # Handled by is_secret().
           permanent      => Bric::FIELD_READ,
           grp_ids        => Bric::FIELD_READ,

           # Private Fields
           _memb_coll     => Bric::FIELD_NONE,
           _memb_hash     => Bric::FIELD_NONE,
           _new_memb_hash => Bric::FIELD_NONE,
           _queried       => Bric::FIELD_NONE,
           _parent_obj    => Bric::FIELD_NONE,
           _attr_obj      => Bric::FIELD_NONE,
           _attr_cache    => Bric::FIELD_NONE,
           _meta_cache    => Bric::FIELD_NONE,
           _update_attrs  => Bric::FIELD_NONE,
           _parents       => Bric::FIELD_NONE,
           _active        => Bric::FIELD_NONE

        });
}

# This runs after this package has compiled, but before the program runs.

require Bric::Util::Grp::Grp;

#==============================================================================#
# Interface Methods                    #
#======================================#

=head1 Interface

=head2 Constructors

=over 4

=item $grp = Bric::Util::Grp->new($init)

This will create a new group object with optional initial state.

Supported Keys:

=over 4

=item name

=item description

=item permanent

=item secret

=back

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub new {
    my ($self, $init) = @_;
    $self = bless {}, $self unless ref $self;
    $init->{_active} = exists $init->{active} ? 0 : 1;
    $init->{permanent} = exists $init->{permanent} && $init->{permanent} ? 1 : 0;
    push @{$init->{grp_ids}}, INSTANCE_GROUP_ID;
    $init->{secret} = ! exists $init->{secret} ? $self->get_secret :
      $init->{secret} ? 1 : 0;
    $init->{class_id} = $self->get_class_id;
    # pass the defined initial state to the super's new method
    # this should set them in register fields
    $self->SUPER::new($init);
    $self->_set({ '_queried' => 1} );
    return $self;
}

##############################################################################

=item $grp = Bric::Util::Grp->lookup({ id => $id })

This will lookup an existing group based on the given ID.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:>

If COLS var changes index of class ID must change.

=cut

sub lookup {
    my ($class, $params) = @_;
    my $grp = $class->cache_lookup($params);
    return $grp if $grp;

    # Make sure we don't exclude secret groups.
    $params->{all} = 1;
    $grp = _do_list($class, $params);
    # We want @$grp to have only one value.
    throw_dp(error => 'Too many ' . __PACKAGE__ . ' objects found.')
      if @$grp > 1;
    return @$grp ? $grp->[0] : undef;
}

##############################################################################

=item my (@grps || $grps_aref) = Bric::Util::Grp->list($params);

Returns a list or anonymous array of Bric::Util::Grp objects. The supported
keys in the C<$params> hash reference are:

=over 4

=item obj

A Bricolage object. The groups returned will have member objects for this
object. May use C<ANY> for a list of possible values, but objects just all be
of the same class.

=item package

A Bricolage class name. Use in combination with C<obj_id> to have C<list()>
return group objects with member objects representing a particular Bricolage
object.

=item obj_id

A Bricolage object ID. Use in combination with C<package> to have C<list()>
return group objects with member objects representing a particular Bricolage
object. May use C<ANY> for a list of possible values.

=item parent_id

A group parent ID. May use C<ANY> for a list of possible values.

=item active

Pass in a true value to return only active groups (the default) or 0 to return
only inactive groups. Pass C<undef> to get a list of active and inactive
groups.

=item inactive

Inactive groups will be returned if this parameter is true.

=item secret

Pass in a true value to return only secret groups. False by default.

=item all

Both secret and non-secret groups will be returned if this parameter is true.
Otherwise only non-secret groups will be returned.

=item name

The name of a group. May use C<ANY> for a list of possible values.

=item description

A group description. May use C<ANY> for a list of possible values.

=item permananent

A boolean to return permanent or non-permanent groups.

=item grp_id

A Bric::Util::Grp::Grp group ID. All groups that are members of the
corresponding Bric::Util::Grp::Grp object will be returned. May use C<ANY> for
a list of possible values.

=item Order

A property name to order by.

=item OrderDirection

The direction in which to order the records, either "ASC" for ascending (the
default) or "DESC" for descending.

=back

B<Throws:>

=over 4

=item *

Unable to connect to database.

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

=back

B<Side Effects:> NONE.

B<Notes:> If the C<obj> or C<obj_id> & C<package> parameters are used, then
this method must be called from a subclass.

Also, the Grp subclasses aren't loaded by this class, so when using
the Bric API outside of Bricolage, you need to require the object
class on the fly; for example:

  use Bric::Util::Grp::Grp;
  my $supported = Bric::Util::Grp::Grp->get_supported_classes();
  foreach my $grpclass (keys %$supported) {
      eval "require $grpclass";
  }
  my $grps = Bric::Util::Grp->list();

=cut

sub list { _do_list(@_) }

##############################################################################

=back

=head2 Destructors

=over 4

=item $self->DESTROY

Dummy method to prevent wasting time trying to AUTOLOAD DESTROY

=cut

sub DESTROY {
    # This method should be here even if its empty so that we don't waste time
    # making Bricolage's autoload method try to find it.
}

##############################################################################

=back

=head2 Public Class Methods

=over 4

=item my (@grp_ids || $grp_ids_aref) = Bric::Util::Grp->list_ids($params);

Returns a list or anonymous array of Bric::Util::Grp IDs. The supported keys
in the C<$params> hash reference are the same as for the C<list()> method.

B<Throws:>

=over 4

=item *

Unable to connect to database.

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

=back

B<Side Effects:> NONE.

B<Notes:> If the C<obj> or C<obj_id> & C<package> parameters are used, then
this method must be called from a subclass.

=cut

sub list_ids { _do_list(@_, 1) }

##############################################################################

=item $class_id = Bric::Util::Grp->get_class_id

Returns the class ID representing the Bricolage class that this group is
associated with.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:>

Subclasses should override this method.

=cut

sub get_class_id { 6 }

##############################################################################

=item $supported_classes = Bric::Util::Grp->get_supported_classes

Returns a hash reference of the supported classes in the group as keys with
the short name as a value. The short name is used to construct the member
table names and the foreign key in the table.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:>

Subclasses should override this method.

=cut

sub get_supported_classes { undef }

##############################################################################

=item my @list_classes = Bric::Util::Grp->get_list_classes

Returns a list or anonymous array of the supported classes in the group that
can have their C<list()> methods called in succession to assemble a list of
member objects. This data varies from that stored in the keys in the hash
reference returned by C<get_supported_classes> in that some classes' C<list()>
methods may inherit from others, and we don't want the same C<list()> method
executed more than once. A good example of such a case is the various Media
subclasses managed by Bric::Util::Grp::Asset.

B<Throws:> NONE.

B<Side Effects:> This method is used internally by C<get_objects()>.

B<Notes:>

Subclasses should override this method.

=cut

sub get_list_classes { () }

##############################################################################

=item (1 || undef) = Bric::Util::Grp->get_secret

Returns true if by default groups of this class are not available for end user
management. Secret groups are used by Bricolage only for internal purposes.
This class method sets the default value for new group objects, unless a
C<secret> parameter is passed to C<new()>.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_secret { SECRET_GRP }

##############################################################################

=item my (%class_keys || $class_keys_href) =
Bric::Util::Grp->href_grp_class_keys

=item my (%class_keys || $class_keys_href) =
Bric::Util::Grp->href_grp_class_keys(1)

Returns an anonymous hash representing the subclasses of Bric::Util::Grp. The
hash keys are the key_names of those classes, and the hash values are their
plural display names. By default, it will return only those classes whose
group instances are not secret. To get B<all> group subclasses, pass in a true
value.

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

{
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
            }, undef);
            execute($sel);
            my ($key, $name, $pkg_name);
            bind_columns($sel, \$key, \$name, \$pkg_name);
            while (fetch($sel)) {
                next if $key eq 'ce';
                $all_class_keys->{$key} = $name;
                $class_keys->{$key} = $name unless $pkg_name->get_secret;
            }
        }
        my $ret = $all ? $all_class_keys : $class_keys;
        return wantarray ? %$ret : $ret;
    }
}

##############################################################################

=item my $class = Bric::Util::Grp->my_class

Returns a Bric::Util::Class object describing this class.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> Uses Bric::Util::Class->lookup() internally.

=cut

sub my_class {
    $class ||= Bric::Util::Class->lookup({ id => 6 });
    return $class;
}

##############################################################################

=item my $class = Bric::Util::Grp->member_class

Returns a Bric::Util::Class object describing the members of this group.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> Uses Bric::Util::Class->lookup() internally.

=cut

sub member_class {
    $mem_class ||= Bric::Util::Class->lookup({ id => 0 });
    return $mem_class;
}

##############################################################################

=item $obj_class_id = Bric::Util::Grp->get_object_class_id;

If this method returns a value, then all members of the group will be assumed
to be a member of the class for which the value is the ID.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_object_class_id { undef }

##############################################################################

=item ($member_ids || @member_ids) = Bric::Util::Grp->get_member_ids($grp_id)

Returns a list of the IDs representing the objects underlying the
Bric::Util::Grp::Parts::Member objects that are members of the grp represented
by C<$grp_id>.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> This method must be called from a subclass of Bric::Util::Grp.

=cut

sub get_member_ids {
    my ($class, $grp_id) = @_;
    my $short;
    if (my $cid = $class->get_object_class_id) {
        my $pkg = Bric::Util::Class->lookup({ id => $cid })->get_pkg_name;
        $short = $class->get_supported_classes->{$pkg};
    } else {
        # Assuming that there is only one class here because otherwise
        # allowing this method would be daft!
        my $sc = $class->get_supported_classes;
        $short = (values %$sc)[-1];
    }
    return Bric::Util::Grp::Parts::Member->get_all_object_ids($grp_id, $short);
}

##############################################################################

=item my $meths = Bric::Util::Grp->my_meths

=item my (@meths || $meths_aref) = Bric::Util::Grp->my_meths(TRUE)

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
    my ($pkg, $ord, $ident) = @_;
    return if $ident;

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

##############################################################################

=back

=head2 Public Instance Methods

=over 4

=item $id = $grp->get_id

Returns the database ID of the group object

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:>

Returns C<undef> if the ID the group is new and its C<save()> method has not
yet been called.

=item my $name = $grp->get_name

Returns the name of the group.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $grp = $grp->set_name($name)

Sets the name of the group.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $desc = $grp->get_description

Returns the description of the group.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $grp = $grp->set_description($desc)

Sets the description of the group.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $parent_id = $grp->get_parent_id

Returns the ID of this group's parent, and C<undef> if this is the root group.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $grp = $grp->set_parent_id($parent_id)

Sets the ID for the parent of this group.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $class_id = $grp->get_class_id

Returns the ID of Bric::Util::Class object representing the members of this
group.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $perm = $grp->get_permanent

Returns true if the group is permanent, and false if it's not. Permanant
groups cannot be deleted.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $secret = $grp->is_secret

Returns true if the group is a secret group, and false if it's not. Secret
groups are used internally by the API, and are not designed to be managed by
users via the UI.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub is_secret { $_[0]->_get('secret') ? $_[0] : undef }

##############################################################################

=item my (@pids || $pids_aref) = $grp->get_all_parent_ids

Returns a list of all of this group's parent group IDs.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_all_parent_ids {
    my ($self) = @_;
    my $dirty = $self->_get__dirty;
    my $parents = $self->_get('_parents');

    unless ($parents) {
        my ($pid, $id) = $self->_get('parent_id', 'id');
        @$parents = $self->_get_all_parent_ids($pid, $id);
        unshift @$parents, $pid;
        $self->_set(['_parents'], [$parents]);
        # This is a set that does not need to be saved in 'save'
        $self->_set__dirty($dirty);
    }

    return wantarray ? @$parents : $parents;
}

##############################################################################

=item $grp = $grp->activate

Sets the active flag for the object

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub activate { $_[0]->_set(['_active'], [1]) }

##############################################################################

=item $grp = $grp->deactivate

Sets the active flag to inactive

B<Throws:>

=over 4

=item *

Cannot deactivate permanent group.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub deactivate {
    my $self = shift;
    my ($id, $perm) = $self->_get(qw(id permanent));
        if ($perm || $id == ADMIN_GRP_ID) {
            throw_gen(error => 'Cannot deactivate permanent group.');
        }
    $self->_set( { '_active' => 0 } );
    return $self;
}

##############################################################################

=item ($grp || undef) = $grp->is_active

Returns self if the object is active undef otherwise

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub is_active {
    my $self = shift;
    return $self->_get('_active') ? $self : undef;
}

##############################################################################

=item my $member = $grp->add_member({ obj => $obj, attr => $attributes });

Adds an object to the group. The supported parameters are:

=over 4

=item obj

The object to be added as a member of the group.

=item package

The package name of the class to which the object to be added as a member of
the group belongs. Use in combination with the C<id> parameter.

=item id

The ID of the object to be added as a member of the group. Use in combination
with the C<package> parameter.

=item attrs

Attributes to be associated with the new member object.

=item no_check

If true, C<add_member()> will not check to see if the object being added to
the group is already a member. Defaults to false.

=back

Either the C<obj> parameter or both the C<package> and C<id> parameters are
required.

B<Throws:>

=over 4

=item *

Missing required parameters 'obj' or 'id' & 'package'

=item *

Object not allowed in group.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub add_member {
    my ($self, $param ) = @_;
    my $dirty = $self->_get__dirty;

    # Get the package and ids
    my ($package, $id);
    if ($param->{obj}) {
        $package = ref $param->{obj};
        $id      = $param->{obj}->get_id;
    } elsif (defined $param->{id} && $param->{package}) {
        $package = $param->{package};
        $id      = $param->{id};
    } else {
        my $msg = "Missing required parameters 'obj' or 'id' & 'package'";
        throw_gen(error => $msg);
    }

    # Grab the member collection and then see if it already has the new
    # object, unless no_check is true.
    my $memb_coll = $get_memb_coll->($self);
    unless ($param->{no_check}) {
        return $self if $self->has_member($param);
    }

    # Make sure that we can add these kinds of objects to the group
    my $supported = $self->get_supported_classes;
    if ($supported && (not exists $supported->{$package})) {
        my $msg = "$package object not allowed in Group '" .
          $self->_get('name') . "'";
        throw_gen(error => $msg);
    }

    # Create a new member object for this object.
    my $member = $memb_coll->new_obj
      ({ object          => $param->{obj},
         obj_id          => $id,
         object_class_id => $self->get_object_class_id,
         object_package  => $package,
         grp             => $self,
         grp_id          => $self->_get('id'),
         attr            => $param->{attrs}
    });

    # This doesn't warrant an object update.
    $self->_set__dirty($dirty);
    return $member;
}

##############################################################################

=item $grp = $grp->add_members(\@member_params);

Convenience method that calls C<< $grp->add_member >> on each in an array
reference of new member object parameters. See C<add_member()> for
documentation of the valid parameters.

B<Throws:>

=over 4

=item *

Missing required parameters 'obj' or 'id' & 'package'

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub add_members {
    my ($self, $membs) = @_;
    $self->add_member($_) for @$membs;
    return $self;
}

##############################################################################

=item (@members || $member_aref) = $grp->get_members

Returns a list or a anonymous array of the member objects that are in the
group.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_members {
    my $self = shift;
    my $memb_coll = $get_memb_coll->($self);
    return $memb_coll->get_objs;
}

##############################################################################

=item my (@objs || $objs_aref) = $grp->get_objects

Returns a list or anonymous arry of all of the Bricolage objects underlying
the member objects in the group. Only returns object if the group object has
been saved and has an ID.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> This method gets a list of classes from C<get_list_classes()> and
calls C<list()> on each, passing in the required C<grp_id> parameter. Thus
this method will not reflect any changes made to group membership unless
C<save()> has been called on the group object.

Also, the object class isn't loaded by the group class, so when using
the Bric API outside of Bricolage, you need to require the object
class on the fly; for example:

  foreach my $c ($grp->get_list_classes()) {
      eval "require $c";
  }
  my $objs = $grp->get_objects();

=cut

sub get_objects {
    my $self = shift;
    my $id = $self->_get('id') or return;
    my @objs = map { $_->list({ grp_id => $id }) } $self->get_list_classes;
    return wantarray ? @objs : \@objs;
}

##############################################################################

=item $grp = $grp->delete_member($member);

=item $grp = $grp->delete_member($object);

=item $grp = $grp->delete_member($param);

Removes a member object from the group. If the argument to this method is a
Bric::Util::Grp::Parts::Member object, then that object will be removed from
the group. If the argument to this method is any other Bricolage object, the
member object representing that object will be constructed and removed from
this group. If the argument to this method is a hash reference, the supported
parameter are the same as for the C<has_member()> method.

B<Throws:>

=over

=item *

Parameters 'id' and/or 'package' not passed to delete_member().

=back

B<Side Effects:>

Will delete members for the database ( ie. not make them inactive)

<Notes:> NONE.

=cut

sub delete_member {
    my ($self, $params) = @_;

    # See if they have passed a member object
    my ($mem, $obj);
    if (substr(ref $params, 0, 28) eq 'Bric::Util::Grp::Parts::Memb') {
        # Member object has been passed
        $mem = $params;
        $obj = $mem->get_object;
    } elsif (ref $params eq 'HASH') {
        # Parameters have been passed.
        $mem = $self->has_member($params) or return;
        $obj = $params->{obj} || $mem->get_object;
    } else {
        # An object has been passed.
        $obj = $params;
        $mem = $self->has_member({ obj => $obj }) or return;
    }

    # Remove the member object and return.
    my $memb_coll = $get_memb_coll->($self);
    $self->get_object_class_id ? $memb_coll->del_mem_obj($obj, $mem) :
      $memb_coll->del_objs($mem);
    return $self;
}

##############################################################################

=item $grp = $grp->delete_members($members);

Convenience method that takes a reference to an array of objects or their
unique identifiers and removes them from the group.

B<Throws:>

=over

=item *

Parameters 'id' and/or 'package' not passed to delete_member().

=back

B<Side Effects:> Calls C<delete_member()> on every item in the array reference
passed as the argument.

B<Notes:> NONE.

=cut

sub delete_members {
    my ($self, $membs) = @_;
    $self->delete_member($_) for @$membs;
    return $self;
}

##############################################################################

=item ($member || undef) = $grp->has_member($params);

Returns a Bric::Util::Grp::Parts::Member object representing the membership in
the group of a Bricolage object if the object is a member, and undef if it's
not a member. The C<$params> hash reference accepts the following keys:

=over 4

=item obj

The object that may be a member of the group.

=item id

The ID of the object that may be a member of the group. Use in combination
with C<package>.

=item package

The class package name of the object that may be a member of the group. Use in
combination with C<id>.

=item attr

An attribute of the member object. The member object will only be returned if
it contains this attribute. Optional.

=back

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> This method I<may> return false if a member has been added via
C<add_member()> but the Grp object hasn't been saved. The upshot is that one
should always call has_member() on a fully saved Grp object.

=cut

sub has_member {
    my ($self, $params) = @_;
    my $memb_coll = $get_memb_coll->($self);
    my $mem;
  MEMCHK: {
        my $oid = defined $params->{id} ? $params->{id} :
          $params->{obj}->get_id;
        if ($memb_coll->is_populated) {
            # Just use the set.
            if ($self->get_object_class_id) {
                # It's in one class. Do an easy grab.
                ($mem) = $memb_coll->get_objs($oid);
                last MEMCHK if $mem;
                # Try to get it from the new members.
                if (my $new_memb = $memb_coll->get_new_objs) {
                    foreach my $m (@$new_memb) {
                        $mem = $m and last MEMCHK if $m->get_obj_id == $oid;
                    }
                }
            } else {
                # Ugh, we need to convert it to a special hash. See if we have it
                # already.
                my $memb_hash = $self->_get('_memb_hash');
                unless ($memb_hash) {
                    # We must build it.
                    foreach my $m ($memb_coll->get_objs) {
                        $memb_hash->{$m->get_object_package}{$m->get_obj_id} = $m;
                    }
                    $self->_set(['_memb_hash'], [$memb_hash]);
                }
                my $pkg = $params->{package} || ref $params->{obj};
                $mem = $memb_hash->{$pkg}{$oid} and last MEMCHK;
            }
        } else {
            # Check to see if the object has been added, but not yet saved.
            if (my $new_memb = $memb_coll->get_new_objs) {
                if ($self->get_object_class_id) {
                    # It's in one class. Just look for the object ID.
                    foreach my $m (@$new_memb) {
                        $mem = $m and last MEMCHK if $m->get_obj_id == $oid;
                    }
                } else {
                    # Ugh, we need to convert it to a special hash.
                    my $memb_hash;
                    foreach my $m (@$new_memb) {
                        $memb_hash->{$m->get_object_package}{$m->get_obj_id} = $m;
                    }
                    my $pkg = $params->{package} || ref $params->{obj};
                    $mem = $memb_hash->{$pkg}{$oid} and last MEMCHK;
                }
            }

            # If we get here, just look it up. This will fail if a member has
            # been added, but the group hasn't been saved.
            my %args = $params->{obj} ? ( object => $params->{obj} ) :
              ( object_package => $params->{package}, object_id => $params->{id});
            $args{grp} = $self;
            ($mem) = Bric::Util::Grp::Parts::Member->list(\%args);
            return unless $mem;
        }
    } #MEMCHK:

    # Return the member only if it has the attributes in $attr
    return $mem->has_attrs($params->{attr}) if $params->{attr};
    # Otherwise just return the member.
    return $mem;
}

##############################################################################

=item $grp = $grp->set_member_attr($params)

Sets an individual attribute for the members of this group

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub set_member_attr {
    my ($self, $param) = @_;
    # set a default subsys if one has not been passed
    $param->{subsys}   ||= MEMBER_SUBSYS;
    # set the sql_type as short if it was not passed in
    $param->{sql_type} ||= 'short';
    # set attribute
    $self->_set_attr($param);
    return $self;
}

##############################################################################

=item $grp = $grp->delete_member_attr($params)

Deletes attributes that apply to members

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub delete_member_attr {
    my ($self, $param) = @_;
    # set a default subsys if one has not been passed
    $param->{subsys} ||= MEMBER_SUBSYS;
    $self->_delete_attr($param,1);
    return $self;
}

##############################################################################

=item $grp = $grp->set_member_attrs(
        [ { name => $name, subsys => $subsys, value => $value,
                sql_type =>$sql_type, new => 1 } ] )

Takes a list of attributes and sets them to apply to the members

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub set_member_attrs {
    my ($self, $attrs) = @_;
    foreach (@$attrs) {
        # set to the member defualt unless passed in
        $_->{subsys}   ||= MEMBER_SUBSYS;
        # set a default sql type
        $_->{sql_type} ||= 'short';
        # set the attr
        $self->_set_attr($_);
    }
    return $self;
}

##############################################################################

=item $grp = $grp->set_member_meta($params)

Sets meta information on member attributes

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub set_member_meta {
    my ($self, $param) = @_;
    # set a defualt member subsys unless one was passed in
    $param->{subsys} ||= MEMBER_SUBSYS;
    # set the meta info
    $self->_set_meta($param);
    return $self;
}

##############################################################################

=item $meta = $grp->get_member_meta($params)

Returns the member meta attributes

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_member_meta {
    my ($self, $param) = @_;
    # set defualt subsys unless one was passed in
    $param->{subsys} ||= MEMBER_SUBSYS;
    # get the meta info pass the flag to return parental defaults
    my $meta = $self->_get_meta($param, 1);
    return $meta;
}

##############################################################################

=item $grp = $grp->delete_member_meta($params)

Deletes the meta information for these attributes.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub delete_member_meta {
    my ($self, $param) = @_;
    # set defualt subsys unless one was passed in
    $param->{subsys} ||= MEMBER_SUBSYS;
    $self->_delete_meta($param, 1);
    return $self;
}

##############################################################################

=item $attrs = $grp->all_for_member_subsys($subsys)

Returns all the attrs as a hashref for a given member subsystem

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub all_for_member_subsys {
    my ($self, $subsys) = @_;
    my $all;

    # get all the attrs for this subsystem
    my $attr = $self->get_member_attr_hash({ subsys => $subsys});

    # now get the meta for all the attributes
    foreach my $name (keys %$attr) {
        # call the get meta function for this name
        my $meta = $self->get_member_meta({ subsys => $subsys,
                                            name   => $name });
        # add it to the return data structure
        $all->{$name} = { value => $attr->{$name},
                          meta  => $meta };
    }
    return $all;
}

##############################################################################

=item $attr = $grp->get_member_attr($params)

Returns an individual attribute for given parameters

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_member_attr {
    my ($self, $param) = @_;
    # set a defualt subsystem if none was passed
    $param->{subsys} ||= MEMBER_SUBSYS;
    # get the value
    my $val = $self->_get_attr($param);
    return $val;
}

##############################################################################

=item $attr = $grp->get_member_attr_sql_type($params)

Returns the SQL type of an individual attribute.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_member_attr_sql_type {
    my ($self, $param) = @_;
    $param->{subsys} ||= MEMBER_SUBSYS;
    return $self->_get_attr_obj->get_sqltype($param);
}

##############################################################################

=item $hash = $grp->get_member_attr_hash($params)

Returns a hash of the attributes for a given subsys

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_member_attr_hash {
    my ($self, $param) = @_;
    # add a default subsys if none was passed
    $param->{subsys} ||= MEMBER_SUBSYS;
    my $attrs = $self->_get_attr_hash($param, 1);
    return $attrs;
}

##############################################################################

=item (@vals || $val_aref) = $grp->get_member_attrs(\@params)

Retrieves the value of the attribute that has been assigned as a default for
members that has the given name and subsystem

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_member_attrs {
    my ($self, $param) = @_;
    # return values
    my @values;
    foreach (@$param) {
        # set a defualt subsystem if one was not passed in
        $_->{subsys} ||= GRP_SUBSYS;
        # push the value onto the return array check the parent for defualts
        push @values, $self->_get_attr($_, 1);
    }
    return wantarray ? @values : \@values;
}

##############################################################################

=item (@vals || $val_aref) = $grp->get_group_attrs(\@params)

Get attributes that describe the group but do not apply to members. This
retrieves the value in the attribute object from a special subsystem which
contains these. This will be returned as a list of values

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_group_attrs {
    my ($self, $param) = @_;
    my @values;
    foreach (@$param) {
        # set the subsystem for group attrs
        $_->{subsys} = GRP_SUBSYS;
        # push the return value onto the return array check parents as well
        push @values, $self->_get_attr( $_, 1 );
    }
    return wantarray ? @values : \@values;
}

##############################################################################

=item $grp = $grp->set_group_attr($params)

Sets a single attribute on this group

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub set_group_attr {
    my ($self, $param) = @_;
    # set the subsystem to the special group subsystem
    $param->{subsys} = GRP_SUBSYS;
    # allow a default sql type as convience
    $param->{sql_type} ||= 'short';
    # send to the internal method that will do the bulk of the work
    $self->_set_attr( $param );
    return $self;
}

##############################################################################

=item $attr = $grp->get_group_attr($params)

Returns a single attribute that pretains to the group

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_group_attr {
    my ($self, $param) = @_;
    # set the group subsys
    $param->{subsys} = GRP_SUBSYS;
    # set a default sql type in case one has not been passed
    $param->{sql_type} ||= 'short';
    # return result from internal method
    # pass a flag to check the parent for attributes as well
    my $attr = $self->_get_attr( $param, 1 );
    return $attr;
}

##############################################################################

=item $grp = $grp->delete_group_attr

Deletes the attributes from the group

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub delete_group_attr {
    my ($self, $param) = @_;
    # set the group subsys
    $param->{subsys} = GRP_SUBSYS;
    $self->_delete_attr($param);
    return $self;
}

##############################################################################

=item $grp = $grp->set_group_attrs(\@params)

Sets attributes that describe the group but do not apply to members. This sets
the value in the attribute object to a special subsystem which contains these

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub set_group_attrs {
    my ($self, $param) = @_;
    foreach (@$param) {
        # set the group subsystem
        $_->{subsys} = GRP_SUBSYS;
        # set a default sql_type if one is not already there
        $_->{sql_type} ||= 'short';
        $self->_set_attr( $_ );
    }
    return $self;
}

##############################################################################

=item $grp = $grp->set_group_meta($meta)

Sets meta information on group attributes

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub set_group_meta {
    my ($self, $param) = @_;
    # set the subsystem for groups
    $param->{subsys} = GRP_SUBSYS;
    # set the meta info
    $self->_set_meta( $param );
    return $self;
}

##############################################################################

=item $meta = $grp->get_group_meta($params)

Returns group meta information

B<Throws:> NONE.

B<Side Effects:> NONE.

B<notes:> NONE.

=cut

sub get_group_meta {
    my ($self, $param) = @_;
    # set the subsystem for groups
    $param->{subsys} = GRP_SUBSYS;
    # get the meta info to return
    my $meta = $self->_get_meta( $param, 1);
    return $meta;
}

##############################################################################

=item $grp = $grp->delete_group_meta($params)

deletes meta information that pretains to this here group.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub delete_group_meta {
    my ($self, $param) = @_;
    # set the subsystem for groups
    $param->{subsys} = GRP_SUBSYS;
    $self->_delete_meta($param);
    return $self;
}

##############################################################################

=item $attr_hash = $grp->get_group_attr_hash

Returns all of the group attrs as a hash ref

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_group_attr_hash {
    my ($self) = @_;
    # args to pass to _get_attr_hash
    my $param = {};
    $param->{subsys} = GRP_SUBSYS;
    my $attrs = $self->_get_attr_hash($param, 1);
    return $attrs;
}

##############################################################################

=item $attrs = $grp->all_for_group_subsys

Returns all the attributes and their meta information for the group subsys

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub all_for_group_subsys {
    my $self = shift;
    my $all;
    # get all the attributes
    my $attr = $self->get_group_attr_hash();

    foreach my $name (keys %$attr) {
        # get the meta information
        my $meta = $self->_get_meta({ subsys => GRP_SUBSYS,
                                     name   => $name });

        # add it to the return data structure
        $all->{$name} = { value => $attr->{$name},
                          meta  => $meta };
    }
    return $all;
}

##############################################################################

=item $grp = $grp->save

Updates the database to reflect the changes made to the object

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub save {
    my $self = shift;

    # Don't save unless the object has changed.
    if ($self->_get__dirty) {
        $self->_get('id') ? $self->_do_update : $self->_do_insert;
    }

    # Save the members and attributes, then git!
    $get_memb_coll->($self)->save($self);
    $self->_sync_attributes;
    return $self->SUPER::save;
}

#==============================================================================#
# Private Methods                      #
#======================================#

=back

=head1 Private

=head2 Private Class Methods

NONE.

=cut

##############################################################################

=head2 Private Instance Methods

=over 4

=item my $memb_coll = $get_memb_coll->($self)

Returns the collection of members for this group. The collection is a
L<Bric::Util::Coll::Member|Bric::Util::Coll::Member> object. See that class
and its parent, L<Bric::Util::Coll|Bric::Util::Coll>, for interface details.

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

$get_memb_coll = sub {
    my $self = shift;
    my $dirt = $self->_get__dirty;
    my ($id, $memb_coll) = $self->_get('id', '_memb_coll');
    return $memb_coll if $memb_coll;
    $memb_coll = Bric::Util::Coll::Member->new
      (defined $id ? {grp => $self} : undef);
    $self->_set(['_memb_coll'], [$memb_coll]);
    $self->_set__dirty($dirt); # Reset the dirty flag.
    return $memb_coll;
};

##############################################################################

=item $attribute_obj = $self->_get_attribute_obj

Will return the attribute object. Methods that need it should check to see if
they have it and if not then get it from here. If there is an ID defined then
it will look up based on it otherwise it will create a new one.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _get_attr_obj {
    my $self = shift;
    my $dirty    = $self->_get__dirty;
    my $attr_obj = $self->_get('_attr_obj');

    unless ($attr_obj) {
        # Let's Create a new one if one does not exist
        $attr_obj = Bric::Util::Attribute::Grp->new({ id => $self->get_id });
        $self->_set(['_attr_obj'], [$attr_obj]);
        # This is a change that doesn't need to be saved.
        $self->_set__dirty($dirty);
    }
    return $attr_obj;
}

##############################################################################

=item $self = $self->_set_attr($param)

Internal method which either sets the attribute upon the attribute object, or
if we cannot get one yet into a cached area.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _set_attr {
    my ($self, $param) = @_;
    my $dirty = $self->_get__dirty;

    # check to see if we have an id, get attr obj if we do otherwise put it
    # into a cache
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

##############################################################################

=item $self = $self->_delete_attr($param)

Deletes the attributes from this group and its members

B<Throws:> NONE.

B<Side Effects:> Deletes from all the members as well.

B<Notes:> NONE.

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
        foreach ($self->get_members) {
            $_->delete_attr($param);
        }
    }

    $self->_set(['_update_attrs'], [1]);
    # This is a change that doesn't need to be saved.
    $self->_set__dirty($dirty);
    return $self;
}

##############################################################################

=item $attr = $self->_get_attr( $param )

Internal Method to return attributes from the object or the cache

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

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
        # param should have been passed in a valid format send directly to the
        # attr object
        $attr = $attr_obj->get_attr( $param );
    } else {
        # get the cache if it exists or create if it does not
        my $attr_cache = $self->_get('_attr_cache') || {};
        # get the data to return
        $attr = $attr_cache->{$param->{subsys}}->{$param->{name}}->{value};
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

##############################################################################

=item $attrs = $self->_get_attr_hash( $param, $parent)

returns all attrs for a given subsystem

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

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
        foreach (keys %{ $attr_cache->{$param->{subsys}} } ) {
            $attrs->{$_} = $attr_cache->{$param->{subsys}}->{$_}->{value};
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

##############################################################################

=item $self = $self->_set_meta( $param )

Sets the meta information for this group on the attr object or caches it for
later storage

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _set_meta {
    my ($self, $param) = @_;
    my $dirty = $self->_get__dirty;

    # Determine if we get the object or cache the data
    if ($self->_get('id')) {
        # get the attr object
        my $attr_obj = $self->_get_attr_obj();
        # set the meta information as it was given with the arg
        $attr_obj->add_meta( $param );
    } else {
        # get the meta info's cache
        my $mc = $self->_get('_meta_cache') || {};
        # set the information into the cache
        $mc->{$param->{subsys}}->{$param->{name}}->{$param->{field}} =
          $param->{value};
        # store the cache for future use
        $self->_set({ '_meta_cache' => $mc });
    }
    $self->_set(['_update_attrs'], [1]);
    # This is a change that doesn't need to be saved.
    $self->_set__dirty($dirty);
    return $self;
}

##############################################################################

=item $self = $self->_delete_meta( $param, $mem);

Deletes the meta info from the group and possibly its members

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _delete_meta {
    my ($self, $param, $mem) = @_;
    my $dirty = $self->_get__dirty;

    if ($self->_get('id')) {
        my $attr_obj = $self->_get_attr_obj;
        $attr_obj->delete_meta( $param );
    } else {
        my $meta_cache = $self->_get('meta_cache') || {};
        delete
          $meta_cache->{$param->{subsys}}->{$param->{name}}->{$param->{field}};
        }

    if ($mem) {
        foreach ($self->get_members) {
            $_->delete_meta($param);
        }
    }
    $self->_set(['_update_attrs'], [1]);
    # This is a change that doesn't need to be saved.
    $self->_set__dirty($dirty);
    return $self;
}

##############################################################################

=item $meta = $self->_get_meta( $param )

Returns stored meta information from the attr object or the attribute cache

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

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
        if (defined $param->{field}) {
            $meta =
              $mc->{$param->{subsys}}->{$param->{name}}->{$param->{field}};
        } else {
            $meta = $mc->{$param->{subsys}};
        }
    }

    # determine if we need to check the parent for anything
    if ($parent) {
        # see if we asked for a hash or a scalar
        if ($param->{field}) {
            unless ($meta) {
                # get parent object
                my $parent_obj = $self->_get_parent_object;
                if ($parent_obj) {
                    $meta = $parent->get_meta($param);
                } # end if parent
            } # end unless meta
        } else {
            # get the hash to be merged
            my $parent_obj = $self->_get_parent_object;
            if ($parent_obj) {
                my $meta2 = $parent_obj->get_meta($param);
                %$meta = (%$meta2, %$meta);
            }
        } # end if else field block
    } # end if parent block
    return $meta;
}

##############################################################################

=item $parent_obj = $self->_get_parent_object

Will return the group that is this groups' parent if one has been defined

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

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

##############################################################################

=item my $pids_aref = $self->_get_all_parent_ids

Internal method that recursivly calls itself to determine all of its parents.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _get_all_parent_ids {
    my ($self, $parent, $child) = @_;
    my @ids;

    my $sth = prepare_c(q{
        SELECT p.parent_id, p.id
        FROM   grp p, grp c
        WHERE  c.parent_id = ?
               AND c.id = ?
               AND p.id = c.parent_id
    }, undef);

    execute($sth, $parent, $child);
    while (my $row = fetch($sth)) {
        if (defined $row->[0]) {
            push @ids, $row->[0];
            push @ids, $self->_get_all_parent_ids(@$row);
        }
    }
    finish($sth);
    return @ids;
}

##############################################################################

=item $grp = $grp->_do_insert

Called from save it will do the insert for the grp object

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _do_insert {
    my $self = shift;

    # Build insert statement
    my $sql = "INSERT INTO " . TABLE .
      " (id, " . join(', ', COLS) . ") " .
      "VALUES (${\next_key(TABLE)}," .
      join(',',('?') x COLS) .") ";

    my $sth = prepare_c($sql, undef);
    execute($sth, $self->_get( FIELDS ) );

    # Now get the id that was created
    $self->_set(['id'] => [last_key(TABLE)]);
    # Add the group to the 'All Groups' group.
    $self->register_instance(INSTANCE_GROUP_ID, GROUP_PACKAGE);
    return $self;
}

##############################################################################

=item $self = $self->_do_update

Called by the save method, this will update the record

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _do_update {
    my $self = shift;

    my $sql = 'UPDATE '.TABLE .
      ' SET ' . join(', ', map { "$_=?" } COLS) .
      ' WHERE id=? ';

    my $sth = prepare_c($sql, undef);
    execute($sth,($self->_get( FIELDS )), $self->_get('id'));
    return $self;
}

##############################################################################

=item $self = $self->_sync_attributes

Internal method that stores the attributes and meta information from a save

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _sync_attributes {
    my $self = shift;

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
                $attr_obj->set_attr
                  ({ subsys   => $subsys,
                     name     => $name,
                     sql_type => $attr_cache->{$subsys}->{$name}->{type},
                     value    => $attr_cache->{$subsys}->{$name}->{value}
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
                    $attr_obj->add_meta
                      ( { subsys => $subsys,
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
    $self->_set({ '_update_attrs' => undef });
    # call save on the attribute object
    $attr_obj->save;
    return $self;
}

##############################################################################

=back

=head2 Private Functions

=over 4

=item my (@grps || $grps_aref) = _do_list($params);

=item my (@grp_ids || $grp_ids_aref) = _do_list($params, 1);

Returns the results of a query for Bric::Util::Grp objects. See the
documentation for the list() method for a list of the supported parameters.

B<Throws:>

=over 4

=item *

Unable to connect to database.

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

=back

B<Side Effects:> NONE.

B<Notes:> If the C<obj> or C<obj_id> & C<package> parameters are used, then
this function must be called from a subclass.

=cut

sub _do_list {
    my ($class, $criteria, $ids, @params) = @_;
    my @wheres = ('g.id = c.object_id', 'c.member__id = m.id',
                  "m.active = '1'");
    my $tables = "grp g, member m, grp_member c";
    if ($criteria->{obj} || ($criteria->{package} && $criteria->{obj_id})) {
        my ($pkg, $obj_id);
        if ($criteria->{obj}) {
            $pkg = ref $criteria->{obj};
            if ($pkg eq 'Bric::Util::DBI::ANY') {
                # Assume they're all of the same class.
                $pkg = ref $criteria->{obj}[0];
                my @ids = grep { defined } map { $_->get_id } @{$criteria->{obj}};
                # If no object has an ID, they will not yet be in any groups.
                return unless @ids;
                $obj_id = ANY(@ids);
            } else {
                # Figure out what table this needs to be joined to.
                $pkg = ref $criteria->{obj};
                # Get the object id.
                $obj_id = $criteria->{obj}->get_id;
                # If the object has no ID, it's not yet in any groups.
                return unless defined $obj_id;
            }
        } else {
            $pkg = $criteria->{package};
            $obj_id = $criteria->{obj_id};
        }

        # Proceed only if we have an Object ID.
        if (defined $obj_id) {
            # Now construct the member table name.
            my $motable = $class->get_supported_classes->{$pkg} . '_member';

            # build the query
            $tables .= ", member mm, $motable mo";
            push @wheres, ( 'mo.member__id = mm.id',
                            'mm.grp__id = g.id', "mm.active = '1'");
            push @wheres, any_where($obj_id, "mo.object_id = ?", \@params);

            # If an active param has been passed in add it here remember that
            # groups cannot be deactivated.
            push @wheres, 'mm.active = ?';
            push @params, exists $criteria->{active} ?
              $criteria->{active} ? 1 : 0 : 1;
        }
    }

    # Add other parameters to the query
    push @wheres, any_where($criteria->{id}, "g.id = ?", \@params)
      if defined $criteria->{id};

    push @wheres, any_where($criteria->{parent_id}, "g.parent_id = ?", \@params)
      if defined $criteria->{parent_id};

    if ( $criteria->{inactive} ) {
        push @wheres, 'g.active = ?';
        push @params, 0;
    } elsif (! defined $criteria->{id} && !exists $criteria->{active}) {
        push @wheres, 'g.active = ?';
        push @params, 1;
    } elsif (exists $criteria->{active} && defined $criteria->{active} ) {
        # Undef active means return all active and inactive groups.
        push @wheres, 'g.active = ?';
        push @params, $criteria->{active} ? 1 : 0;
    }

    unless ( $criteria->{all} ) {
        if (exists $criteria->{secret}) {
            push @wheres, 'g.secret = ?';
            push @params, $criteria->{secret} ? 1 : 0;
        } else {
            push @wheres, 'g.secret = ?';
            push @params, 0;
        }
    }

    my $cid = $class->get_class_id;
    if ( $cid != __PACKAGE__->get_class_id ) {
        push @wheres, 'g.class__id = ?';
        push @params, $cid;
    }

    push @wheres, any_where($criteria->{name}, 'LOWER(g.name) LIKE LOWER(?)',
                            \@params)
      if $criteria->{name};

    push @wheres, any_where($criteria->{description},
                            'LOWER(g.description) LIKE LOWER(?)',
                            \@params)
      if $criteria->{description};

    if ( exists $criteria->{permanent} ) {
        push @wheres, 'g.permanent = ?';
        push @params, $criteria->{permanent} ? 1 : 0;
    }

    if (exists $criteria->{grp_id}) {
        $tables .= ", member m2, grp_member c2";
        push @wheres, ("g.id = c2.object_id", "c2.member__id = m2.id",
                       "m2.active = '1'");
        push @wheres, any_where($criteria->{grp_id}, "m2.grp__id = ?",
                                \@params);
    }

    my $where = join ' AND ', @wheres;
    my $ord = $ids ? 'g.id' : $criteria->{Order} ?
      $criteria->{Order}  . ', g.id' : 'g.name, g.id';
    my $direction = $criteria->{OrderDirection} || '';
    my $qry_cols = $ids? \'DISTINCT g.id' : \$sel_cols;
    my $select = prepare_c(qq{
        SELECT $$qry_cols
        FROM   $tables
        WHERE  $where
        ORDER BY $ord $direction
    }, undef);

    # Just return the IDs, if they're what's wanted.
    return wantarray ? @{col_aref($select, @params)} :
      col_aref($select, @params) if $ids;

    execute($select, @params);
    my (@d, @grps, %classes, $grp_ids);
    my $last = -1;
    bind_columns($select, \@d[0..$#sel_props]);
    $class = ref $class || $class;
    my $not_grp_class = $class->get_class_id != get_class_id();
    while (fetch($select)) {
        if ($d[0] != $last) {
            $last = $d[0];
            # Figure out what class to bless it into.
            my $bless_class = $class;
            unless ($not_grp_class) {
                if (exists $classes{$d[2]}) {
                    $bless_class = $classes{$d[2]};
                } else {
                    $classes{$d[2]} = $bless_class =
                      Bric::Util::Class->lookup({ id => $d[2] })->get_pkg_name;
                }
            }
            # Create a new Grp object.
            my $self = bless {}, $bless_class;
            $self->SUPER::new;
            $grp_ids = $d[$#d] = [$d[$#d]];
            $self->_set(\@sel_props, \@d);
            $self->_set__dirty; # Disable the dirty flag.
            push @grps, $self->cache_me;
        } else {
            # Append the ID.
            push @$grp_ids, $d[$#d];
        }
    }

    return wantarray ? @grps : \@grps;
}

1;
__END__

=back

=head1 Notes

Need to add parentage info and a possible method to list children and maybe
their children and so on as well

=head1 Author

Michael Soderstrom <miraso@pacbell.net>. Member management and documentation
by David Wheeler <david@justatheory.com>.

=head1 See Also:

L<Bric.pm>, L<Bric::Util::Grp::Parts::Member>

=cut
