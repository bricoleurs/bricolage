package Bric::Util::Priv;

=head1 Name

Bric::Util::Priv - Individual Privileges

=cut

# Grab the Version Number.
require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

  use Bric::Util::Priv;
  use Bric::Util::Priv::Parts::Const qw(:all);

  my $priv = Bric::Util::Priv->new($init);
  $priv = Bric::Util::Priv->lookup($params);
  my @privs = Bric::Util::Priv->list($params);
  my $privs_href = Bric::Util::Priv->href($params);
  my @priv_ids = Bric:::Util::Priv->list_ids($params);
  my $acl = Bric::Util::Priv->get_acl($user);
  my $vals_href = Bric::Util::Priv->vals_href;
  my $meths = Bric::Util::Priv->my_meths;
  my @meths = Bric::Util::Priv->my_meths(1);

  my $grp = $priv->get_usr_grp;
  my $grp_id = $priv->get_usr_grp_id;
  my $obj = $priv->get_obj_grp;
  my $obj_id = $priv->get_obj_grp_id;
  my $value = $priv->get_value;
  $priv = $priv->set_value(READ);
  $priv = $priv->del;
  $priv = $priv->save;

=head1 Description

Objects of the Bric::Util::Priv class represent single privileges granted to a
user or user group. The idea is to be able to manage individual privileges in
an object-oriented fashion. Thus, this class will be used by the interface of
Bric::Biz::Person::User and Bric::Util::Grp::User.

=cut

################################################################################
# Dependencies
################################################################################
# Standard Dependencies
use strict;

################################################################################
# Programmatic Dependences
use Bric::Util::DBI qw(:standard prepare prepare_ca);
use Bric::Util::Time qw(:all);
use Bric::Util::Priv::Parts::Const qw(:all);
use Bric::Util::Fault qw(throw_ap throw_dp);
use Bric::Util::Grp;
use Bric::Util::Grp::User;

################################################################################
# Inheritance
################################################################################
use base qw(Bric);

################################################################################
# Function & Closure Prototypes
################################################################################
my ($get_em);

################################################################################
# Constants
################################################################################
use constant DEBUG  => 0;

################################################################################
# Fields
################################################################################
# Public Class Fields

################################################################################
# Private Class Fields
my @priv_cols = qw(id grp__id value mtime);
my @priv_props = qw(id usr_grp_id value mtime);
my @cols = (qw(p.id p.grp__id p.value p.mtime), 'g.grp__id');
my @props = (@priv_props, 'obj_grp_id');

# This hash is for checking the legitimacy of value settings.
my %vals = (1 => 1, 2 => 1, 3 => 1, 4 => 1, 5 => 1, 255 => 1);
my $meths;

################################################################################

################################################################################
# Instance Fields
BEGIN {
    Bric::register_fields({
                         # Public Fields
                         id => Bric::FIELD_READ,         # Priv ID.
                         usr_grp_id => Bric::FIELD_READ, # Group granted the priv.
                         obj_grp_id => Bric::FIELD_READ, # Group for which priv granted.
                         mtime => Bric::FIELD_READ,      # Last modified time.
                         value => Bric::FIELD_RDWR,      # The Priv granted.

                         # Private Fields
                         _del => Bric::FIELD_NONE
                        });
}

################################################################################
# Class Methods
################################################################################

=head1 Interface

=head2 Constructors

=over 4

=item my $priv = Bric::Util::Priv->new($init)

Creates a new privilege for a user or group. Expects a single anonymous hash
argument consisting of the following keys:

=over 4

=item *

usr_grp - The Bric::Util::Grp::User object or ID for which to set the privilege.
Required.

=item *

obj_grp - The Bric::Util::Grp object or ID for whose members the privilege is
granted. Required.

=item *

value - The privilege to grant to the user or group. Required. Must be one of the
following constants (which may be imported by
C<use Bric::Util::Priv::Parts::Const qw(:all)>:

=over 4

=item *

READ => 1

=item *

EDIT => 2

=item *

RECALL => 3

=item *

CREATE => 4

=item *

PUBLISH => 5

=item *

DENY => 255

=back

=back

B<Throws:>

=over 4

=item *

Must pass user group and object group.

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub new {
    my ($pkg, $init) = @_;
    throw_ap(error => "Must pass user group and object group to "
             .__PACKAGE__."::new()")
      unless $init->{usr_grp} && $init->{obj_grp};

    # Grab the object group ID.
    $init->{obj_grp_id} = ref $init->{obj_grp} ? $init->{obj_grp}->get_id
      : $init->{obj_grp};

    # Grab the user group ID.
    $init->{usr_grp_id} = ref $init->{usr_grp} ? $init->{usr_grp}->get_id
      : $init->{usr_grp};

    # Delete the unwanted fields.
    delete @{$init}{qw(obj_grp usr_grp)};

    # Intantiate the object.
    my $self = bless {}, ref $pkg || $pkg;
    $self->SUPER::new($init);
}

################################################################################

=item my $priv = Bric::Util::Priv->lookup({ id => $id })

Looks up and instantiates a Bric::Util::Priv object based on the Bric::Util::Priv
object ID passed. If $id is not found in the database, lookup() returns undef.

B<Throws:>

=over

=item *

Too many Bric::Util::Priv objects found.

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

B<Side Effects:> If $id is found, populates the new Bric::Util::Priv object with
data from the database before returning it.

B<Notes:> NONE.

=cut

sub lookup {
    my $pkg = shift;
    my $priv = $pkg->cache_lookup(@_);
    return $priv if $priv;

    $priv = $get_em->($pkg, @_);
    # We want @$priv to have only one value.
    throw_dp(error => 'Too many Bric::Util::Priv objects found.')
      if @$priv > 1;
    return @$priv ? $priv->[0] : undef;
}

################################################################################

=item (@privs || $privs_aref) = Bric::Util::Priv->list($params)

Returns a list or anonymous array of Bric::Util::Priv objects. Supported search
keys include:

=over 4

=item id

permission ID. May use C<ANY> for a list of possible values.

=item usr_grp_id

A Bric::Util::Grp::User object ID to which privileges have been granted. May
use C<ANY> for a list of possible values.

=item obj_grp_id

A Bric::Util::Grp object ID for which privileges have been granted. May use
C<ANY> for a list of possible values.

=item value

A privilege value. This could return a *lot* of records, so you're probably
not going to want to do this. May use C<ANY> for a list of possible values.

=back

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

sub list { wantarray ? @{ &$get_em(@_) } : &$get_em(@_) }

################################################################################

################################################################################

=item my $privs_href = Bric::Util::Priv->href($parms)

Works the same as list(), with the same arguments, except it returns a hash or
hashref of Bric::Util::Priv objects, where the keys are the contact IDs, and the
values are the contact objects.

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

B<Side Effects:> Populates each Bric::Util::Priv object with data from the
database before returning them all.

B<Notes:> NONE.

=cut

sub href { &$get_em(@_, 0, 1) }

################################################################################

=back

=head2 Destructors

=over 4

=item $priv->DESTROY

Dummy method to prevent wasting time trying to AUTOLOAD DESTROY.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=back

=cut

sub DESTROY {}

################################################################################

=head2 Public Class Methods

=over 4

=item (@priv_ids || $priv_ids_aref) = Bric::Util::Priv->list_ids($params)

Returns a list or anonymous array of Bric::Util::Priv objects. Interface is the
same as for list() above.

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

sub list_ids { wantarray ? @{ &$get_em(@_, 1) } : &$get_em(@_, 1) }

################################################################################

=item my $acl = Bric::Util::Priv->get_acl($user)

Returns an access control list of privilege settings for a given user. An ACL
is simply a hash reference with all keys but one being object group IDs for
groups B<to which> the user has been granted permission, where the value for
each key is the relevant permission. One key is not a group ID, but "mtime",
and it stands for that most recent time any of the permissions was modified.
It is used for expiring an ACL.

B<Throws:>

=over 4

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=item *

Unable to execute SQL statement.

=item *

Unable to bind to columns to statement handle.

=item *

Unable to fetch row from statement handle.

=back

B<Side Effects:> NONE.

B<Notes:> Support for parent groups is not supported. Thus, if a user is in a
group that does not have a permission set, and that group has a parent where
the permission B<is> set, that permission will not be included in the ACL.
This inheritance of permissions may be implemented in the future, and at that
time the permissions of child groups will override the permissions of their
parents.

=cut

sub get_acl {
    my ($pkg, $user) = @_;
    my $sel = prepare_c(qq{
        SELECT gm.grp__id, gp.value, gp.mtime
        FROM   grp_priv gp, grp_priv__grp_member gm, grp g, member m,
               user_member mo, grp gg
        WHERE  gp.id = gm.grp_priv__id
               AND g.id = m.grp__id
               AND gp.grp__id = g.id
               AND g.active = '1'
               AND gm.grp__id = gg.id
               AND gg.active = '1'
               AND m.id = mo.member__id
               AND m.active = '1'
               AND mo.object_id = ?
       ORDER BY gm.grp__id, gp.value
    }, undef);

    execute($sel, ref $user ? $user->get_id : $user);
    my ($gid, $priv, $mtime, $acl);
    bind_columns($sel, \$gid, \$priv, \$mtime);
    while (fetch($sel)) {
        # Be sure to save the most recent modified time.
        $acl->{mtime} = !$acl->{mtime} ? $mtime : $acl->{mtime} gt $mtime ?
          $acl->{mtime} : $mtime;
        # Grab the priv for this group ID.
        $acl->{$gid} = $priv;
    }
    finish($sel);
    return $acl;
}

################################################################################

=item my $mtime = Bric::Util::Priv->get_acl_mtime($user)

Returns the last modified time for the privileges set for groups of which $user
is a member.

B<Throws:>

=over 4

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=item *

Unable to fetch row from statement handle.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_acl_mtime {
    my ($pkg, $user) = @_;
    my $sel = prepare_ca(qq{
        SELECT MAX(gp.mtime)
        FROM   grp_priv gp, grp_priv__grp_member gm, grp g, member m,
               user_member mo, grp gg
        WHERE  gp.id = gm.grp_priv__id
               AND gp.grp__id = g.id
               AND g.active = '1'
               AND gm.grp__id = gg.id
               AND gg.active = '1'
               AND g.id = m.grp__id
               AND m.id = mo.member__id
               AND m.active = '1'
               AND mo.object_id = ?
    }, undef);
    return row_aref($sel, ref $user ? $user->get_id : $user)->[0];
}

################################################################################

=item my $vals_href = Bric::Util::Priv->vals_href

=item my $vals_aref = Bric::Util::Priv->vals_aref

Returns an anonymous hash or anonymous array of the possible values for a
privilege object. The vals_href() method returns an anonymous array in which the
privilege values are the keys and their corresponding names are the values:

    { &READ    => 'READ',
      &EDIT    => 'EDIT',
      &RECALL  => 'RECALL',
      &CREATE  => 'CREATE',
      &PUBLISH => 'PUBLISH',
      &DENY    => 'DENY'
    }

The vals_aref() method returns an anonymous array of anonymous arrays. The first
value of each embedded anonymous array is the privilege value, whereas the
second value is the name for that value:

    [ [ &READ    => 'READ'    ],
      [ &EDIT    => 'EDIT'    ],
      [ &RECALL  => 'RECALL'  ],
      [ &CREATE  => 'CREATE'  ],
      [ &PUBLISH => 'PUBLISH' ],
      [ &DENY    => 'DENY'    ]
    ]

B<Throws:> NONE.

B<Side Effects:> Use Bric::Util::Priv::Pargs::Const internally to import the value
constants.

B<Notes:> NONE.

=cut

sub vals_href {
    return { &READ    => 'READ',
             &EDIT    => 'EDIT',
             &RECALL  => 'RECALL',
             &CREATE  => 'CREATE',
             &PUBLISH => 'PUBLISH',
             &DENY    => 'DENY'
           }
}

sub vals_aref {
    return [ [ &READ    => 'READ'    ],
             [ &EDIT    => 'EDIT'    ],
             [ &RECALL  => 'RECALL'  ],
             [ &CREATE  => 'CREATE'  ],
             [ &PUBLISH => 'PUBLISH' ],
             [ &DENY    => 'DENY'    ]
           ]
}

################################################################################

=item $meths = Bric::Util::Priv->my_meths

=item (@meths || $meths_aref) = Bric::Util::Priv->my_meths(TRUE)

=item my (@meths || $meths_aref) = Bric::Util::Priv->my_meths(0, TRUE)

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
    return !$ord ? $meths : wantarray ? @{$meths}{@props} : [@{$meths}{@props}]
      if $meths;

    # We don't got 'em. So get 'em!
    $meths = {
              id         => {
                              name     => 'id',
                              get_meth => sub { shift->get_id(@_) },
                              get_args => [],
                              disp     => 'ID',
                              len      => 10,
                              type     => 'short',
                             },
              usr_grp_id => {
                             name     => 'usr_grp_id',
                             get_meth => sub { shift->get_usr_grp_id(@_) },
                             get_args => [],
                             set_meth => sub { shift->set_usr_grp_id(@_) },
                             set_args => [],
                             disp     => 'User Group ID',
                             len      => 10,
                             req      => 1,
                             type     => 'short',
                             props    => {   type       => 'text',
                                             length     => 10,
                                             maxlength => 10
                                         }
                            },
              obj_grp_id => {
                             name     => 'obj_grp_id',
                             get_meth => sub { shift->get_obj_grp_id(@_) },
                             get_args => [],
                             set_meth => sub { shift->set_obj_grp_id(@_) },
                             set_args => [],
                             disp     => 'Object Group ID',
                             len      => 10,
                             req      => 1,
                             type     => 'short',
                             props    => {   type       => 'text',
                                             length     => 10,
                                             maxlength => 10
                                         }
                            },
              value      => {
                             name     => 'value',
                             get_meth => sub { shift->get_value(@_) },
                             get_args => [],
                             set_meth => sub { shift->set_value(@_) },
                             set_args => [],
                             disp     => 'Value',
                             len      => 3,
                             req      => 1,
                             type     => 'short',
                             props    => {   type => 'radio',
                                             vals => vals_aref(),
                                         }
                            },
              mtime      => {
                             name     => 'mtime',
                             get_meth => sub { shift->get_mtime(@_) },
                             get_args => [],
                             set_meth => sub { shift->set_mtime(@_) },
                             set_args => [],
                             disp     => 'Modified Time',
                             len      => 64,
                             req      => 0,
                             type     => 'short',
                             props    => { type      => 'date' }
                            }
             };
    return !$ord ? $meths : wantarray ? @{$meths}{@props} : [@{$meths}{@props}];
}

################################################################################

=back

=head2 Public Instance Methods

=over 4

=item my $id = $priv->get_id

Returns the ID of the Bric::Util::Priv object.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'id' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> If the Bric::Util::Priv object has been instantiated via the new()
constructor and has not yet been C<save>d, the object will not yet have an ID,
so this method call will return undef.

=item my $usr_grp = $priv->get_usr_grp

Returns the Bric::Util::Grp::User object to which the privilege has been granted.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=item *

Too many Bric::Util::Grp::User objects found.

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

B<Side Effects:> Calls Bric::Util::Grp::User->new internally.

B<Notes:> NONE.

=cut

sub get_usr_grp {
    my $self = shift;
    Bric::Util::Grp::User->lookup({id => $self->get_usr_grp_id});
}

################################################################################

=item my $usr_grp_id = $priv->get_usr_grp_id

Returns the ID of the Bric::Util::Grp::User object to which the privilege has been
granted.

B<Throws:>

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'usr_grp_id' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $obj_grp = $priv->get_obj_grp

Returns the group object for whose members the privilege has been granted.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=item *

Too many Bric::Util::Grp objects found.

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

B<Side Effects:> Calls Bric::Util::Grp->new internally.

B<Notes:> NONE.

=cut

sub get_obj_grp {
    my $self = shift;
    Bric::Util::Grp->lookup({id => $self->get_obj_grp_id});
}

################################################################################

=item my $obj_grp_id = $priv->get_obj_grp_id

Returns the ID of the group object for whose members the privilege has been
granted.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'obj_grp_id' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $mtime = $priv->get_mtime

=item my $mtime = $priv->get_mtime($format)

Returns the time the privilege was last modified. Pass in a strftime formatting
string to get the time back in that format.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=item *

Unable to unpack date.

=item *

Unable to format date.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_mtime { local_date($_[0]->_get('mtime'), $_[1]) }

=item my $value = $priv->get_value

Returns the privilege setting for this Bric::Util::Priv object. Returns a value
corresponding to the constants defined above for new().
C<use Bric::Util::Priv::Parts::Const qw(:all)> for convenience constants.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'value' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $self = $priv->set_value($value)

Sets the privilege value for this Bric::Util::Priv object. The value must be
equivalent to one of the privileges exported by Bric::Util::Priv::Parts::Const.

B<Throws:>

=over 4

=item *

Not a valid privilege value.

=item *

Incorrect number of args to _set.

=item *

Bric::_set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub set_value {
    my $self = shift;
    my $val = shift;
    throw_ap(error => "Not a valid privilege value")
      unless $vals{$val};
    $self->_set(['value'], [$val]);
}

################################################################################

=item $self = $priv->del

Deletes the privilege. The privilege won't actually be deleted until $priv->save
is called.

B<Throws:>

=over 4

=item *

Incorrect number of args to _set.

=item *

Bric::_set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub del {
    my $self = shift;
    $self->_set(['_del'], [1]);
}

=item $self = $priv->save

Saves the privilege to the database.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=item *

Unable to execute SQL statement.

=item *

Unable to select row.

=item *

Incorrect number of args to _set.

=item *

Bric::_set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub save {
    my $self = shift;
    return $self unless $self->_get__dirty;
    my ($id, $del) = $self->_get('id', '_del');
    my $time = db_date(undef, 1);
    $self->_set(['mtime'], [$time]);
    if ($del && defined $id) {
        # It's an existing privilege to be deleted.
        my $del1 = prepare_c(qq{
            DELETE FROM grp_priv__grp_member
            WHERE  grp_priv__id = ?
        }, undef);
        my $del2 = prepare_c(qq{
            DELETE FROM grp_priv
            WHERE  id = ?
        }, undef);

        # Really $del2 should cover $del1 via cascading delete, but I'm playing
        # it safe.
        execute($del1, $id);
        execute($del2, $id);

    } elsif (defined $id) {
        # It's an existing privilege. Update it.
        my $upd = prepare_c(qq{
            UPDATE grp_priv
            SET    value = ?,
                   mtime = ?
            WHERE  id = ?
        }, undef);
        execute($upd, $self->_get('value'), $time, $id);
    } else {
        # It's a new privilege. Insert it.
        local $" = ', ';
        my $fields = join ', ', next_key('priv'), ('?') x $#priv_cols;
        my $ins = prepare_c(qq{
            INSERT INTO grp_priv (@priv_cols)
            VALUES ($fields)
        }, undef);
        # Don't try to set ID - it will fail!
        execute($ins, $self->_get(@priv_props[1..$#priv_props]));
        # Now grab the ID.
        $id = last_key('priv');
        $self->_set({id => $id});

        # Now be create an object grp association.
        my $ins2 = prepare_c(qq{
            INSERT INTO grp_priv__grp_member (grp_priv__id, grp__id)
            VALUES (?, ?)
        }, undef);
        execute($ins2, $id, $self->_get('obj_grp_id'));
    }
    $self->SUPER::save;
    return $self;
}

################################################################################

=back

=head1 Private

=head2 Private Class Methods

NONE.

=head2 Private Instance Methods

NONE.

=head2 Private Functions

=over 4

=item my $privs_aref = &$get_em( $pkg, $search_href )

=item my $privs_ids_aref = &$get_em( $pkg, $search_href, 1 )

Function used by lookup() and list() to return a list of Bric::Util::Priv objects
or, if called with an optional third argument, returns a list of Bric::Util::Priv
object IDs (used by list_ids()).

B<Throws:>

=over 4

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

B<Notes:> NONE.

=cut

$get_em = sub {
    my ($pkg, $params, $ids, $href) = @_;
    my (@wheres, @params);
    while (my ($k, $v) = each %$params) {
        my $search = '';
        if ($k eq 'obj_grp') {
            $search = "g.$k";
        } elsif ($k eq 'usr_grp_id') {
            $search = "p.grp__id";
        } elsif ($k eq 'obj_grp_id') {
            $search = "g.grp__id";
        } else {
            $search = "p.$k";
        }
        push @wheres, any_where $v, "$search = ?", \@params;
    }

    my $where = @wheres ? 'AND ' . join(' AND ', @wheres) : '';

    my $qry_cols = $ids ? 'p.id' : join ', ', @cols;
    my $sel = prepare_c(qq{
        SELECT $qry_cols
        FROM   grp_priv p, grp_priv__grp_member g
        WHERE  p.id = g.grp_priv__id
               $where
    }, undef);

    # Just return the IDs, if they're what's wanted.
    return col_aref($sel, @params) if $ids;

    execute($sel, @params);
    my (@d, @privs, %privs);
    bind_columns($sel, \@d[0..$#cols]);
    $pkg = ref $pkg || $pkg;
    while (fetch($sel)) {
        my $self = bless {}, $pkg;
        $self->SUPER::new;
        $self->_set(\@props, \@d);
        $self->_set__dirty; # Disables dirty flag.
        $href ? $privs{$d[0]} = $self->cache_me :
          push @privs, $self->cache_me;
    }
    finish($sel);
    return $href ? \%privs : \@privs;
};

1;
__END__

=back

=head1 Notes

NONE.

=head1 Author

David Wheeler <david@justatheory.com>

=head1 See Also

L<Bric|Bric>,
L<Bric::Biz::Person|Bric::Biz::Person>,
L<Bric::Biz::Person::User|Bric::Biz::Person::User>,
L<Bric::Util::Grp::User|Bric::Util::Grp::User>

=cut
