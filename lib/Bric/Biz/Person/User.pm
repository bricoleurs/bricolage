package Bric::Biz::Person::User;

=pod

=head1 Name

Bric::Biz::Person::User - Interface to Bricolage User Objects

=cut

# Grab the Version Number.
require Bric; our $VERSION = Bric->VERSION;

=pod

=head1 Synopsis

  use Bric::Biz::Person::User;

  # Constructors.
  my $u = Bric::Biz::Person::User->new;
  my $u = Bric::Biz::Person::User->lookup({ id => $id })
  my $u = Bric::Biz::Person::User->lookup({ login => $login })
  my @users = Bric::Biz::Person::User->list($search_href)

  # Class Methods.
  my @uids = Bric::Biz::Person::User->list_ids($search_href)

  # Instance Methods - in addition to those inherited from Bric::Biz::Person.
  my $login = $u->get_login;
  $u = $login->set_login($login);
  $u = $u->set_password($password);
  $u = $u->chk_password($password);

  $u = $u->can_do($obj, READ);
  $u = $u->no_can_do($obj, CREATE);

  $u = $u->activate;
  $u = $u->deactivate;
  $u = $u->is_active;

  my @gids = $u->get_grp_ids;
  my @groups = $u->get_grps;

  $u = $u->save;

=head1 Description

This Class provides the basic interface to all Bricolage and
users. Bric::Biz::Person::User objects are special Bric::Biz::Person objects
that represent members of the Bric::Util::Group::Person group "User". Only
members of this group can actually I<use> the application. All other
Bric::Biz::Person objects cannot use Bricolage, although they can be
associated with Bricolage objects (e.g., writers can be associated with
stories).

Bric::Biz::Person::User extends the Bric::Biz::Person interface to allow the
setting and checking of passwords, the setting of login names, and the
activation or deactivation of the person as a user. It also offers methods by
which to set permissions for individual users, although these permissions
really should be assigned via membership in other groups. (For example, put
editors in an editors group, and allow members of that group to edit
stories. See Bric::Util::Group::Person for more information.)

=cut

################################################################################
# Dependencies
################################################################################
# Standard Dependencies
use strict;
use List::Util qw(first);

################################################################################
# Programmatic Dependences
use Bric::App::Cache;
use Bric::Util::DBI qw(:standard row_aref prepare_ca col_aref);
use Bric::Util::Grp::User;
use Bric::Config qw(:admin :auth);
use Bric::Util::Fault qw(throw_dp throw_gen);
use Bric::Util::Priv;
use Bric::Util::Priv::Parts::Const qw(:all);
use Bric::Util::Time qw(db_date);
use Bric::Util::UserPref;

# Load Authentication engines.
use Bric::Util::AuthInternal;
BEGIN { eval "require $_" or die $@ for AUTH_ENGINES }

################################################################################
# Inheritance
################################################################################
use base qw(Bric::Biz::Person);

################################################################################
# Function and Closure Prototypes
################################################################################
my ($get_em);

################################################################################
# Constants
################################################################################
use constant DEBUG => 0;
use constant GROUP_PACKAGE => 'Bric::Util::Grp::User';
use constant INSTANCE_GROUP_ID => 2;

################################################################################
# Fields
################################################################################
# Public Class Fields

################################################################################
# Private Class Fields
my @ucols = qw(id login password active);
my @uprops = qw(id login password _active);

my @pcols = qw(p.prefix p.fname p.mname p.lname p.suffix p.active);
my @pprops = qw(prefix fname mname lname suffix _p_active);

my $sel_cols = "u.id, u.login, u.password, u.active, " . join(', ', @pcols) .
  ", m.grp__id, 1";
my @props = (@uprops, @pprops, qw(grp_ids _inserted));
my ($meths, @ord);

################################################################################

################################################################################
# Instance Fields
BEGIN {
    Bric::register_fields({
                         # Public Fields
                         id => Bric::FIELD_READ,
                         login => Bric::FIELD_RDWR,
                         password => Bric::FIELD_NONE,
                         grp_ids => Bric::FIELD_READ,

                         # Private Fields
                         _active => Bric::FIELD_NONE,
                         _inserted => Bric::FIELD_NONE,
                         _p_active => Bric::FIELD_NONE,
                         _is_admin => Bric::FIELD_NONE,
                         _acl => Bric::FIELD_NONE      # Stores ACL.
                        });
}

################################################################################
# Class Methods
################################################################################

=head1 Interface

=head2 Constructors

=over 4

=item my $u = Bric::Biz::Person::User->new($init)

Instantiates a Bric::Biz::Person::User object. An anonymous hash of intial values
may be passed. The supported intial hash keys are:

=over 4

=item *

lname

=item *

fname

=item *

mname

=item *

prefix

=item *

suffix

=item *

login

=back

Call $u->save() to save the new object.

B<Throws:>

=over 4

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
    my $self = bless {}, ref $pkg || $pkg;
    @{$init}{qw(_active _inserted)} = (1, 0);
    push @{$init->{grp_ids}}, INSTANCE_GROUP_ID;
    # Call the parent's constructor.
    $self->SUPER::new($init);
}

################################################################################

=item my $p = Bric::Biz::Person->lookup($params)

Looks up and instantiates a new Bric::Biz::Person::User object based on the
Bric::Biz::Person::User object ID or login name. If the existing object is not
found in the database, C<lookup()> returns C<undef>. The two possible lookup
parameters are:

=over 4

=item *

id - Returns the User with that ID, if it exists.

=item *

login - Returns the active User with that login, if it exists. Inactive users
with that login will be ignored.

=back

B<Throws:>

=over 4

=item *

Too many Bric::Biz::Person::User objects found.

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

B<Side Effects:> If id or login name is found, populates the new
Bric::Biz::Person object with data from the database before returning it.

B<Notes:> This method is overriding the lookup() method of the
Bric::Biz::Person object, including all of its SQL. Thus, the
Bric::Biz::Person::lookup method will not be called here, and it's SQL queries
will not be executed.

=cut

sub lookup {
    my $pkg = shift;
    my $user = $pkg->cache_lookup(@_);
    return $user if $user;

    $user = $get_em->($pkg, @_);
    # We want @$user to have only one value.
    throw_dp(error => 'Too many ' . __PACKAGE__ . ' objects found.')
      if @$user > 1;
    return @$user ? $user->[0] : undef;
}

################################################################################

=item my (@users || $users_aref) = Bric::Biz::Person::User->list($params)

Returns a list or anonymous array of Bric::Biz::Person::User objects based on
the search criteria passed via an anonymous hash. The supported lookup keys
are:

=over 4

=item id

User ID. May use C<ANY> for a list of possible values.

=item prefix

A name prefix, such as "Mr."  May use C<ANY> for a list of possible values.

=item lname

Last name or surname. May use C<ANY> for a list of possible values.

=item fname

First name or given name. May use C<ANY> for a list of possible values.

=item mname

Middle name or second name. May use C<ANY> for a list of possible values.

=item suffix

Name suffix, such as "Jr." May use C<ANY> for a list of possible values.

=item grp_id

The ID of a Bric::Util::Grp object of which person objects may be a member.
May use C<ANY> for a list of possible values.

=item login

The user's username. May use C<ANY> for a list of possible values.

=back

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

B<Side Effects:> Populates each Bric::Biz::Person::User object with data from the
database before returning them all.

B<Notes:> This method is overriding the list() method of the Bric::Biz::Person
object, including all of its SQL. Thus, the Bric::Biz::Person::list method will
not be called here, and it's SQL queries will not be executed.

=cut

sub list { wantarray ? @{ &$get_em(@_) } : &$get_em(@_) }

################################################################################

=back

=head2 Destructors

=over 4

=item $p->DESTROY

Dummy method to prevent wasting time trying to AUTOLOAD DESTROY.

Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub DESTROY {}

################################################################################

=back

=head2 Public Class Methods

=over 4

=item my (@uids || $uids_aref) = Bric::Biz::Person::User->list_ids($params)

Returns a list or anonymous array of Bric::Biz::Person::User object IDs based
on the search criteria passed via an anonymous hash. The supported lookup keys
are the same as those for list().

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

B<Notes:> This method is overriding the list_ids() method of the Bric::Biz::Person
object, including all of its SQL. Thus, the Bric::Biz::Person::list_ids method will
not be called here, and it's SQL queries will not be executed.

=cut

sub list_ids { wantarray ? @{ &$get_em(@_, 1) } : &$get_em(@_, 1) }

################################################################################

=item $self = $u->login_avail($login)

Returns true if $login is not already in use by an active user, and undef if it
is. Use this method to make ensure that a login is available for use before
actually using it. A login is considered available even if a deactivated user
has the same login.

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

sub login_avail {
    my ($pkg, $login) = @_;
    my $sel = prepare_ca(qq{
        SELECT 1
        FROM   usr
        WHERE  LOWER(login) = ?
               AND active = '1'
    }, undef);

    return 1 unless @{ row_aref($sel, lc $login) || [] };
    return;
}

################################################################################

=item $meths = Bric::Biz::Person::User->my_meths

=item (@meths || $meths_aref) = Bric::Biz::Person::User->my_meths(TRUE)

=item my (@meths || $meths_aref) = Bric::Biz::Person::User->my_meths(0, TRUE)

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

    unless ($meths) {
        # We don't got 'em. So get 'em!
        foreach my $meth (Bric::Biz::Person::User->SUPER::my_meths(1)) {
            $meths->{$meth->{name}} = $meth;
            push @ord, $meth->{name};
        }
        push @ord, qw(login password), pop @ord;
        $meths->{login}    = {
                              get_meth => sub { shift->get_login(@_) },
                              get_args => [],
                              set_meth => sub { shift->set_login(@_) },
                              set_args => [],
                              name     => 'login',
                              disp     => 'Login',
                              len      => 128,
                              req      => 1,
                              type     => 'short',
                              props    => { type      => 'text',
                                            length    => 32,
                                            maxlength => 128
                                          }
                             };
        $meths->{password} = {
                              get_meth => undef,
                              get_args => undef,
                              set_meth => sub { shift->set_password(@_) },
                              set_args => [],
                              name     => 'password',
                              disp     => 'Password',
                              len      => 1024,
                              req      => 1,
                              type     => 'short',
                              props    => { type      => 'password',
                                            length    => 32,
                                            maxlength => 1024
                                          }
                             };
    }

    if ($ord) {
        return wantarray ? @{$meths}{@ord} : [@{$meths}{@ord}];
    } elsif ($ident) {
        return wantarray ? $meths->{login} : [$meths->{login}];
    } else {
        return $meths;
    }
}

################################################################################

=back

=head2 Public Instance Methods

Bric::Biz::Person::User inherits from Bric::Biz::Person and makes available all
Bric::Biz::Person instance methods. See the Bric::Biz::Person documentation for a
description of those methods. Additional methods available for
Bric::Biz::Person::User objects only are documented here.

=over 4

=item my $id = $u->get_id

Returns the ID of the Bric::Biz::Person::User object.

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

B<Notes:> If the Bric::Biz::Person::User object has been instantiated via the new()
constructor and has not yet been C<save>d, the object will not yet have an ID,
so this method call will return undef.

=item $self = $u->set_person($person)

Sets the ID representing Bric::Biz::Person object from which the
Bric::Biz::Person::User object inherits.

B<Throws:>

=over 4

=item *

Cannot change ID of existing user.

=item *

Bric::_get() - Problems retrieving fields.

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub set_person {
    my ($self, $p) = @_;
    throw_dp(error => "Cannot change ID of existing user.")
      if $self->_get('_inserted');
    $self->_set([ qw(id lname fname mname prefix suffix) ],
                [ $p->_get( qw(id lname fname mname prefix suffix) ) ]);
}

=item my $login = $u->get_login

Returns the login name of the user.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'login' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $self = $u->set_login($login)

Sets the login name of the user. Be sure to call $u->save to save the change to
the database. Returns $self on success and undef on failure.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $self = $u->set_password($password)

Sets the user's password. The internal authentication engine uses a double
MD-5 hash algorithm to encrypt it. Be sure to call $u->save to save the change
to the database. Returns $self on success and C<undef> on failure.

B<Throws:>

=over 4

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub set_password {
    my ($self, $pwd) = @_;
    $_->set_password($self, $pwd) for AUTH_ENGINES;
    Bric::Util::AuthInternal->set_password($self, $pwd)
        unless first { $_ eq 'Bric::Util::AuthInternal' } AUTH_ENGINES;
    return $self;
}

=item $self = $u->chk_password($password)

Returns true if $password matches the password stored for this user. Returns
undef if they don't match. Uses a double MD-5 hash algorithm to encrypt
$password and then compare it to the value stored in the database. Returns $self
on success and undef on failure.

B<Throws:>

=over 4

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> See notes for set_password().

=cut

sub chk_password {
    my ($self, $pwd) = @_;
    for my $engine (AUTH_ENGINES) {
        return $self if $engine->authenticate($self, $pwd);
    }
    return;
}

################################################################################

=item $priv = $u->what_can($obj || $pkg)

=item $priv = $u->what_can(($obj || $pkg), @group_ids)

Takes an object $obj or package name $pkg and  returns the permission (as
exported by Bric::Util::Priv::Parts::Const) that the user object has to
$obj, or to the "All" group in $pkg. A false value is no permission.

Pass in a list of group IDs and they will be treated as if they are groups to
which $obj is a member. Thus you can affect the permission returned by $obj by
passing in the IDs of groups it's not necessarily a member of. The reason to do
this is to check, for example, a user's permission to a workflow or a desk
before an asset is created and put on that desk.

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

=back

B<Side Effects:> NONE.

B<Notes:> In the future, the implementation of this method may use caching,
where the first time this or another privilege method is called, the entire ACL
is either fetched from cache or recomputed from the database and then cached.

For now, however, getting the ACL is one simple query, which probably is not any
slower than caching, since it also takes a single query to get the last modified
time for a user's ACL and compare it to the last modified time of the cached
copy of the ACL. But it may become necessary to do the caching if we create a
more complex privilege system that requires many or very complex queries to
create an ACL.

=cut

sub what_can {
    my ($self, $obj, @gids) = @_;
    my ($id, $acl, $is_admin) = $self->_get(qw(id _acl _is_admin));

    # Set $is_admin, if necessary.
    unless (defined $is_admin) {
        $is_admin = grep { $_ == ADMIN_GRP_ID }  $self->get_grp_ids;
        $self->_set(['_is_admin'], [$is_admin]);
    }

    # Administrators can do anything.
    return PUBLISH if $is_admin;

    # Set $acl, if necessary.
    unless ($acl) {
        $acl = Bric::Util::Priv->get_acl($id) || {};
        $self->_set(['_acl'], [$acl]);
    }

    # Gather up all of the group IDs.
    push @gids, $obj->get_grp_ids if $obj;

    # Get the permission.
    my $priv = 0;
    if (ref $obj eq __PACKAGE__) {
        my $chk_admin = 0;
        for my $gid (@gids) {
            # Make a note of the user being in the global admins
            # group.
            $chk_admin ||= $gid == ADMIN_GRP_ID;
            # Grab the greatest permission.
            $priv = $acl->{$gid} if exists $acl->{$gid} && $acl->{$gid} > $priv;
        }
        # If they're in the global admins group, allow no greater access than
        # READ access.
        $priv = $acl->{&ADMIN_GRP_ID} || READ if $chk_admin && $priv &&
          $priv != DENY;
    } else {
        # Grab the greatest permission.
        for my $gid (@gids) {
            $priv = $acl->{$gid} if exists $acl->{$gid} && $acl->{$gid} > $priv;
        }
    }
    return $priv;
}

=item $self = $u->can_do($obj, $priv)

Checks to see if the user has the privilege to perform an action. $obj is the
object for which the user's privilege must be checked and $priv is the privilege
required to perform the action. Returns $self if the user has the privilege and
undef it the user does not. Intended primarily to be used by other API calls to
check that the user triggering the API call actually has the privileges to do
so.

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

=back

B<Side Effects:> NONE.

B<Notes:> See what_can() above.

=cut

sub can_do {
    my ($self, $obj, $has_priv) = @_;
    my $priv = what_can($self, $obj);
    # Take care of denies first.
    return undef if $priv == DENY;
    return $priv >= $has_priv ? $self : undef;
}

################################################################################

=item $self = $u->no_can_do($obj, $priv)

Exactly the same as $u->can_do, except that it returns $self if the user does
B<not> have the permission on the object, and undef if the user does have the
permission on the object.

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

=back

B<Side Effects:> NONE.

B<Notes:> Just does !can_do() internally. ;-)

=cut

sub no_can_do { return can_do(@_) ? undef : $_[0] }

################################################################################

=item $self = $u->activate

Flags the Bric::Biz::Person::User object as an active user in Bricolage. Be sure
to call $u->save to save the change to the database. Returns $self on success
and undef on failure.

B<Throws:>

=over 4

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> Inherited from Bric::Biz::Person, but uses the active value
specific to the user, rather than the person.

B<Notes:> The activate(), deactivate(), and is_active() methods differ from
those found in Bric::Biz::Person. In Bric::Biz::Person, they determine whether a
person is active in the entire database, across groups. In Bric::Biz::Person::User,
they determine only whether the person is an active user of the system. A person
may be an inactive user but still an active person. Returns $self on success and
undef on failure.

=cut

sub activate {
    my $self = shift;
    # Just return success if we're already active.
    return $self if $self->_get('_active');
    # Okay, we're reactivating an inactive login. Let's make sure the login
    # is available.
    my $login = $self->_get('login');
    throw_gen(error => "Cannot activate user - login '$login' already in use.")
      unless $self->login_avail($login);

    # If we get here, we can reactivate it.
    $self->_set(['_active'], [1]);
}

=item $self = $u->deactivate

Flags the Bric::Biz::Person::User object as an inactive user in Bricolage. Be
sure to call $u->save to save the change to the database. Returns $self on
success and undef on failure.

B<Throws:>

=over 4

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

B<Side Effects:> Inherited from Bric::Biz::Person, but uses the active value
specific to the user, rather than the person.

B<Notes:> See the notes for the activate() method above.

=item $self = $u->is_active

Returns $self if the Bric::Biz::Person::User object is active, and undef if it
is not.

B<Throws:> NONE.

B<Side Effects:> Inherited from Bric::Biz::Person, but uses the active value
specific to the user, rather than the person.

B<Notes:> See the notes for the activate() method above.

################################################################################

=item my (@gids || $gids_aref) = $u->get_grp_ids

=item my (@gids || $gids_aref) = Bric::Biz::Person::User->get_grp_ids

Returns a list or anonymous array of Bric::Biz::Group object ids representing the
groups of which this Bric::Biz::Person::User object is a member.

B<Throws:> See Bric::Util::Grp::list().

B<Side Effects:> NONE.

B<Notes:> This method returns the group IDs for the current object both as a
Bric::Biz::Person object and as a Bric::Biz::Person::User object. [Actually, I've
commented this out for now, since it seems more likely at this point that we'll
want only the user group IDs, not also the person IDs. We can uncomment this
later if we decide we need it, though.]

=cut

#sub get_grp_ids {
#    my $self = shift;
#    my @ids = $self->SUPER::get_grp_ids;
#    my $super = $ISA[0];
#    my $class = $super->GROUP_PACKAGE;
#    my $id = ref $self ? $self->_get('id') : undef;
#    push @ids, defined $id ?
#      $class->list_ids({ package => $super,
#                        obj_id  => $id })
#      : $super->INSTANCE_GROUP_ID;
#    return wantarray ? @ids : \@ids;
#}

################################################################################

=item my (@groups || $groups_aref) = $u->get_grps

Returns a list or anonymous array of Bric::Biz::Group::User objects representing
the groups of which this Bric::Biz::Person::User object is a member.

Use the Bric::Biz::Group::User instance method calls add_members() and
delete_members() to associate and dissociate Bric::Biz::Person::User objects with
any given Bric::Biz::Group::Person::User object.

B<Throws:> See Bric::Util::Grp::Person::list().

B<Side Effects:> Uses Bric::Util::Grp::User internally.

B<Notes:> This method differs from the Bric::Biz::Person->get_grps() method in
that it returns only those groups of which the person is a member as a user,
rather than as a person.

=cut

sub get_grps { Bric::Util::Grp::User->list({ obj => $_[0], all => 1 }) }

=item my $pref_value = $u->get_pref($pref_name)

Given a preference name, such as "Language" or "Time Zone", this
method returns the corresponding value, for this user.  It first
checks to see if the user has overridden the global value for this
preference.  If not, the global setting is returned.

Preference values are cached after the first lookup.

B<Throws:> I do not have a clue

=cut

sub get_pref {
    my $self = shift;
    my $pref_name = shift;

    return $self->{prefs}{$pref_name}
        if exists $self->{prefs}{$pref_name};

    my $value;

    my $pref;
    unless($pref = Bric::Util::Pref->lookup({ name => $pref_name })) {
        throw_dp(error => qq{Can't find preference "$pref_name"});
    }
    if ($pref->get_can_be_overridden) {
        my $user_pref = Bric::Util::UserPref->lookup({ pref_id => $pref->get_id,
                                                       user_id => $self->get_id });

        $self->{prefs}{$pref_name} = $user_pref->get_value if $user_pref;
    }

    $self->{prefs}{$pref_name} = $pref->get_value unless defined $self->{prefs}{$pref_name};

    $self->{prefs}{$pref_name};
}

=item $self = $u->save

Saves the properties of the Bric::Biz::Person::User object to the database,
including all changes made via the methods inherited from
Bric::Biz::Person. Returns $self on success and undef on failure.

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

B<Side Effects:> Also calls Bric::Biz::Person save() method.

B<Notes:> See also Bric::Biz::Person save() method documentation.

=cut

sub save {
    my $self = shift;
    return $self->SUPER::save unless $self->_get__dirty;
    my ($id, $act, $done) = $self->_get(qw(id _active _inserted));

    if ($done) {
        # It's an existing user. Update it.
        $self->_set(['_active'], [$self->_get('_p_active')]);
        $self->SUPER::save;
        $self->_set(['_active'], [$act]);
        local $" = ' = ?, '; # Simple way to create placeholders with an array.
        my $upd = prepare_c(qq{
            UPDATE usr
            SET    @ucols = ?
            WHERE  id = ?
        }, undef);
        execute($upd, $self->_get(@uprops, 'id'));
        unless ($act) {
            # Deactivate all group memberships if we've deactivated the user.
            foreach my $grp (Bric::Util::Grp::User->list
                             ({ obj => $self, permanent => 0 })) {
                foreach my $mem ($grp->has_member({ obj => $self })) {
                    next unless $mem;
                    $mem->deactivate;
                    $mem->save;
                }
            }
        }
    } else {
        # It's a new user. Insert it.
        $self->SUPER::save;
        my $login = $self->_get('login');
        unless ($login) {
            # Make the login the same as the Primary Email Address by default.
            foreach my $c ($self->get_contacts) {
                next unless $c->get_type eq 'Primary Email';
                $login = $c->get_value;
                last;
            }
            throw_dp(error => 'User must have a login or primary email address '
                     . 'before saving') unless $login;
            $self->_set(['login'], [$login]);
        }
        local $" = ', ';
        my $fields = join ', ', ('?') x ($#ucols + 1);
        my $ins = prepare_c(qq{
            INSERT INTO usr (@ucols)
            VALUES ($fields)
        }, undef);

        execute($ins, $self->_get(@uprops));

        # And finally, register this user in the "All Users" group.
        $self->register_instance(INSTANCE_GROUP_ID, GROUP_PACKAGE);
    }
    return $self;
}

=back

=head1 Private

=head2 Private Class Methods

NONE.

=head2 Private Instance Methods

NONE.

=head2 Private Functions

=over 4

=item my $users_aref = &$get_em( $pkg, $search_href )

=item my $user_ids_aref = &$get_em( $pkg, $search_href, 1 )

Function used by lookup() and list() to return a list of Bric::Biz::Person::User
objects or, if called with an optional third argument, returns a list of
Bric::Biz::Person::User object IDs (used by list_ids()).

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

B<Notes:> SQL in this function overrides the SQL used in the same function in
Bric::Biz::Person.

=cut

$get_em = sub {
    my ($pkg, $args, $ids) = @_;
    my $tables = 'person p, usr u, member m, user_member c';
    my $wheres = 'p.id = u.id AND u.id = c.object_id AND ' .
      "c.member__id = m.id AND m.active = '1'";
    my @params;
    while (my ($k, $v) = each %$args) {
        if ($k eq 'id') {
            $wheres .= ' AND ' . any_where $v, "u.$k = ?", \@params;
        } elsif ($k eq 'login') {
            $wheres .= ' AND '
                    . any_where $v, "LOWER(u.login) LIKE LOWER(?)", \@params;
        } elsif ($k eq 'grp_id') {
            $tables .= ", member m2, user_member c2";
            $wheres .= " AND u.id = c2.object_id AND c2.member__id = m2.id"
              . " AND m2.active = '1' AND "
              . any_where $v, 'm2.grp__id = ?', \@params;
        } elsif ($k eq 'active') {
            $wheres .= " AND u.$k = ?";
            push @params, $v ? 1 : 0;
        } else {
            $wheres .= ' AND '
                    . any_where $v, "LOWER(p.$k) LIKE LOWER(?)", \@params;
        }
    }

    $wheres .= " AND u.active = '1'" unless defined $args->{id}
      or exists $args->{active};
    my ($qry_cols, $order) = $ids ? (\'DISTINCT u.id', 'u.id') :
      (\$sel_cols, 'LOWER(p.lname), LOWER(p.fname), LOWER(p.mname), u.id');

    my $sel = prepare_c(qq{
        SELECT $$qry_cols
        FROM   $tables
        WHERE  $wheres
        ORDER BY $order
    }, undef);

    # Just return the IDs, if they're what's wanted.
    return col_aref($sel, @params) if $ids;

    execute($sel, @params);
    my (@d, @users, $grp_ids);
    my $gids_idx = $#props - 1;
    bind_columns($sel, \@d[0..$#props]);
    my $last = -1;
    $d[$#props] = 1; # Sets the inserted flag.
    $pkg = ref $pkg || $pkg;
    while (fetch($sel)) {
        if ($d[0] != $last) {
            $last = $d[0];
            # Create a new User object.
            my $self = bless {}, $pkg;
            $self->SUPER::new;
            $grp_ids = $d[$gids_idx] = [$d[$gids_idx]];
            $self->_set(\@props, \@d);
            $self->_set__dirty; # Disables dirty flag.
            push @users, $self->cache_me;
        } else {
            push @$grp_ids, $d[$gids_idx];
        }
    }
    return \@users;
};

=begin comment

Not actually using this function, but may need to later.

=item my $priv = &$get_priv(@privs);

Takes an array of privileges for a given action and returns the privilege that
wins. The values of various privileges and what they mean are defined as
constants. Determination of whether an action can be performed may be
ascertained by calling the has_priv() method. Use the add_priv() and del_priv()
methods to add and delete privileges.

#=cut

$get_priv = sub {
    local $" = ' | '; # Unary OR
    eval "@_";        # will return highest value. XXX Is this safe?
};

=end comment

=cut

1;
__END__

=back

=head1 Notes

NONE.

=head1 Author

David Wheeler <david@justatheory.com>

=head1 See Also

L<Bric|Bric>,
L<Bric::Biz::Person|Bric::Biz::Person>

=cut
