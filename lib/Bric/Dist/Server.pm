package Bric::Dist::Server;

=head1 Name

Bric::Dist::Server - Interface for managing servers to which content will be
distributed.

=cut

# Grab the Version Number.
require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

  use Bric::Dist::Server;

  # Constructors.
  # Create a new object.
  my $server = Bric::Dist::Server->new;
  # Look up an existing object.
  $server = Bric::Dist::Server->lookup({ id => 1 });
  # Get a list of server objects.
  my @servers = Bric::Dist::Server->list({ server_type_id => 2 });
  # Get an anonymous hash of server objects.
  my $servers_href = Bric::Dist::Server->href({ home_path => '/home/www' });

  # Class methods.
  # Get a list of object IDs.
  my @server_ids = Bric::Dist::Server->list_ids({ server_type_id => 2 });
  # Get an introspection hashref.
  my $int = Bric::Dist::Server->my_meths;

  # Instance Methods.
  my $id = $server->get_id;
  my $server_type_id = $server->get_server_type_id;
  $server = $server->set_server_type_id($server_type_id);
  my $host_name = $server->get_host_name;
  $server = $server->set_host_name($host_name);
  my $doc_root = $server->get_doc_root;
  $server = $server->set_doc_root($doc_root);
  my $login = $server->get_login;
  $server = $server->set_login($login);
  my $password = $server->get_password;
  $server = $server->set_password($password);
  my $cookie = $server->get_cookie;
  $server = $server->set_cookie($cookie);

  # Save it.
  $server->save;

  # Delete it.
  $server->del;
  $server->save;

=head1 Description

This class manages server objects. Servers are individual instances of a type
defined by Bric::Dist::ServerType. They are provide accessors to values that are
unique to each server, such as host name, login, password, cookie, etc. Thus,
when a job is scheduled to move files to the servers of a given server type,
they can be successfully moved using the unique properties of each server.

=cut

################################################################################
# Dependencies
################################################################################
# Standard Dependencies
use strict;

################################################################################
# Programmatic Dependences
use Bric::Util::DBI qw(:all);
use Bric::Util::Fault qw(throw_dp throw_gen);
use Bric::Dist::ServerType;

################################################################################
# Inheritance
################################################################################
use base qw(Bric);

################################################################################
# Function and Closure Prototypes
################################################################################
my ($get_em);

################################################################################
# Constants
################################################################################
use constant DEBUG => 0;

################################################################################
# Fields
################################################################################
# Public Class Fields
our %OS = (Mac   => 'File::Spec::Mac',
           OS2   => 'File::Spec::OS2',
           Unix  => 'File::Spec::Unix',
           VMS   => 'File::Spec::VMS',
           Win32 => 'File::Spec::Win32');

################################################################################
# Private Class Fields
my $def_os = do {
    my $o = lc $^O;
    $OS{$^O} && $^O
      || $o eq 'macos' && 'Mac'
      || $o eq 'mswin32' && 'Win32'
      || $o eq 'os2' && 'OS2'
      || 'Unix';
};

my @cols = qw(id server_type__id host_name os doc_root login password cookie
              active);
my @props = qw(id server_type_id host_name os doc_root login password cookie
               _active);
my @ord = qw(host_name os doc_root login password cookie active);
my $meths;

################################################################################

################################################################################
# Instance Fields
BEGIN {
    Bric::register_fields({
                         # Public Fields
                         id => Bric::FIELD_READ,
                         server_type_id => Bric::FIELD_RDWR,
                         host_name => Bric::FIELD_RDWR,
                         os => Bric::FIELD_READ,
                         doc_root => Bric::FIELD_RDWR,
                         login => Bric::FIELD_RDWR,
                         password => Bric::FIELD_RDWR,
                         cookie => Bric::FIELD_RDWR,

                         # Private Fields
                         _active => Bric::FIELD_NONE,
                         _del => Bric::FIELD_NONE
                        });
}

################################################################################
# Class Methods
################################################################################

=head1 Interface

=head2 Constructors

=over 4

=item my $server = Bric::Dist::Server->new($init)

Instantiates a Bric::Dist::Server object. An anonymous hash of initial values may
be passed. The supported initial value keys are:

=over 4

=item *

host_name

=item *

os

=item *

doc_root

=item *

login

=item *

password

=item *

cookie

=item *

server_type_id

=back

The active property will be set to true by default. Call $server->save() to save
the new object.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub new {
    my ($pkg, $init) = @_;
    my $class = ref $pkg || $pkg;
    $init->{host_name} = lc $init->{host_name} if $init->{host_name};
    my $os = delete $init->{os} || $def_os;
    $init->{_active} = 1;
    my $self = $class->SUPER::new($init);
    $self->set_os($os);
}

################################################################################

=item my $server = Bric::Dist::Server->lookup({ id => $id })

Looks up and instantiates a new Bric::Dist::Server object based on the
Bric::Dist::Server object ID passed. If $id is not found in the database, lookup()
returns undef.

B<Throws:>

=over 4

=item *

Too many Bric::Dist::Server objects found.

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

B<Side Effects:> If $id is found, populates the new Bric::Dist::Server object with
data from the database before returning it.

B<Notes:> NONE.

=cut

sub lookup {
    my $pkg = shift;
    my $server = $pkg->cache_lookup(@_);
    return $server if $server;

    $server = $get_em->($pkg, @_);
    # We want @$server to have only one value.
    throw_dp(error => 'Too many Bric::Dist::Server objects found.')
      if @$server > 1;
    return @$server ? $server->[0] : undef;
}

################################################################################

=item my (@servers || $servers_aref) = Bric::Dist::Server->list($params)

Returns a list or anonymous array of Bric::Dist::Server objects based on the
search parameters passed via an anonymous hash. The supported lookup keys are:

=over 4

=item id

Server ID. May use C<ANY> for a list of possible values.

=item host_name

The server host name. May use C<ANY> for a list of possible values.

=item os

The server operating system. May use C<ANY> for a list of possible values.

=item doc_root

The document root to distribute to. May use C<ANY> for a list of possible
values.

=item login

The login username for the server. May use C<ANY> for a list of possible
values.

=item password

The login password for the server. May use C<ANY> for a list of possible
values.

=item cookie

The cookie to use to connect to the server. May use C<ANY> for a list of
possible values.

=item server_type_id

The destination (Bric::Dist::ServerType) ID with which a server may be
associated. May use C<ANY> for a list of possible values.

=item active

Boolean value indicating whether the server object is active.

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

B<Side Effects:> Populates each Bric::Dist::Server object with data from the
database before returning them all.

B<Notes:> NONE.

=cut

sub list { wantarray ? @{ &$get_em(@_) } : &$get_em(@_) }

################################################################################

=item my $servers_href = Bric::Dist::Server->href($params)

Returns an anonymous hash of Bric::Dist::Server objects, where the keys are the
object IDs and the values are the objects themselves, based on the search
parameters passed via an anonymous hash. The supported lookup keys are the same
as for list().

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

B<Side Effects:> Populates each Bric::Dist::Server object with data from the
database before returning them all.

B<Notes:> NONE.

=cut

sub href { &$get_em(@_, 0, 1) }

################################################################################

=back

=head2 Destructors

=over 4

=item $server->DESTROY

Dummy method to prevent wasting time trying to AUTOLOAD DESTROY.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=back

=cut

sub DESTROY {}

################################################################################

=head2 Public Class Methods

=over

=item my (@server_ids || $server_ids_aref) = Bric::Dist::Server->list_ids($params)

Returns a list or anonymous array of Bric::Dist::Server object IDs based on the
search criteria passed via an anonymous hash. The supported lookup keys are the
same as those for list().

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

=item $meths = Bric::Dist::Server->my_meths

=item (@meths || $meths_aref) = Bric::Dist::Server->my_meths(TRUE)

=item my (@meths || $meths_aref) = Bric::Dist::Server->my_meths(0, TRUE)

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
    return !$ord ? $meths : wantarray ? @{$meths}{@ord} : [@{$meths}{@ord}]
      if $meths;

    # We don't got 'em. So get 'em!
    $meths = {
              host_name   => {
                              name     => 'host_name',
                              get_meth => sub { shift->get_host_name(@_) },
                              get_args => [],
                              set_meth => sub { shift->set_host_name(@_) },
                              set_args => [],
                              disp     => 'Host Name',
                              search   => 1,
                              len      => 128,
                              req      => 1,
                              type     => 'short',
                              props    => {   type       => 'text',
                                              length     => 32,
                                              maxlength => 128
                                          }
                             },
              os          => {
                              get_meth => sub { shift->get_os(@_) },
                              get_args => [],
                              set_meth => sub { shift->set_os(@_) },
                              set_args => [],
                              name     => 'os',
                              disp     => 'OS',
                              len      => 1,
                              req      => 1,
                              type     => 'short',
                              props    => { type => 'select',
                                            vals => [ sort keys %OS ],
                                          }
                             },
              doc_root    => {
                              name     => 'doc_root',
                              get_meth => sub { shift->get_doc_root(@_) },
                              get_args => [],
                              set_meth => sub { shift->set_doc_root(@_) },
                              set_args => [],
                              disp     => 'Document Root',
                              len      => 128,
                              req      => 1,
                              type     => 'short',
                              props    => {   type       => 'text',
                                              length     => 32,
                                              maxlength => 128
                                          }
                             },
              login       => {
                              name     => 'login',
                              get_meth => sub { shift->get_login(@_) },
                              get_args => [],
                              set_meth => sub { shift->set_login(@_) },
                              set_args => [],
                              disp     => 'Login',
                              len      => 64,
                              req      => 0,
                              type     => 'short',
                              props    => {   type       => 'text',
                                              length     => 32,
                                              maxlength => 64
                                          }
                             },
              password    => {
                              name     => 'password',
                              get_meth => sub { shift->get_password(@_) },
                              get_args => [],
                              set_meth => sub { shift->set_password(@_) },
                              set_args => [],
                              disp     => 'Password',
                              len      => 64,
                              req      => 0,
                              type     => 'short',
                              props    => {   type       => 'password',
                                              length     => 32,
                                              maxlength => 64
                                          }
                             },
              cookie      => {
                              name     => 'cookie',
                              get_meth => sub { shift->get_cookie(@_) },
                              get_args => [],
                              set_meth => sub { shift->set_cookie(@_) },
                              set_args => [],
                              disp     => 'Cookie',
                              len      => 512,
                              req      => 0,
                              type     => 'short',
                              props    => { type => 'textarea',
                                            cols => 40,
                                            rows => 4
                                          }
                             },
              active     => {
                             name     => 'active',
                             get_meth => sub { shift->is_active(@_) ? 1 : 0 },
                             get_args => [],
                             set_meth => sub { $_[1] ? shift->activate(@_)
                                                 : shift->deactivate(@_) },
                             set_args => [],
                             disp     => 'Active',
                             search   => 0,
                             len      => 1,
                             req      => 1,
                             type     => 'short',
                             props    => { type => 'checkbox' }
                            },
             };
    return !$ord ? $meths : wantarray ? @{$meths}{@ord} : [@{$meths}{@ord}];
}

################################################################################

=item my (@oses || $oses_aref) = Bric::Dist::Server->list_oses

Returns a list of supported server operating systems.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub list_oses { sort keys %OS }

=back

=head2 Public Instance Methods

=over 4

=item my $id = $server->get_id

Returns the ID of the Bric::Dist::Server object.

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

B<Notes:> If the Bric::Dist::Server object has been instantiated via the new()
constructor and has not yet been C<save>d, the object will not yet have an ID,
so this method call will return undef.

=item my $server_type_id = $server->get_server_type_id

Returns the ID of the Bric::Dist::ServerType object with which this server is
associated.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'server_type_id' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $self = $server->set_server_type_id($server_type_id)

Sets the ID of the Bric::Dist::ServerType object with which this server is
associated.

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

=item my $host_name = $server->get_host_name

=item my $host_name = $server->get_name

Returns the server's host name.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'host_name' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

*get_name = sub { shift->get_host_name };

=item $self = $server->set_host_name($host_name)

Sets the server's host name. The host name will be converted to lower case.

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

sub set_host_name { $_[0]->_set(['host_name'], [lc $_[1]]) }

=item my $os = $server->get_os

Returns the server's operating system.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'os' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $self = $server->set_os($os)

Sets the server's operating system. Retreive a list of supported OSes from
list_oses().

B<Throws:>

=over 4

=item *

Not a supported operating system.

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub set_os {
    my ($self, $os) = @_;
    throw_gen(error => "Not a supported operating system: $os")
      unless $OS{$os};
    $self->_set(['os'], [$os]);
}

=item my $doc_root = $server->get_doc_root

Returns the server's home path. This is the path that will serve as the root
directory for all PUTs to the server.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'doc_root' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $self = $server->set_doc_root($doc_root)

Sets the server's home path. This is the path that will serve as the root
directory for all PUTs to the server.

B<Throws:>

=over 4

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> In the future, we may want to add platform-independent methods of
handling paths.

=cut

sub set_doc_root {
    my ($self, $path) = @_;
    # Chop off trailing '/'. May need to change this later to be platform
    # independent.
    $path = substr($path, 0, -1) if substr($path, -1) eq '/';
    $self->_set(['doc_root'], [$path]);
}

=item my $login = $server->get_login

Returns the server's login name, which will be used with the password property
to interact with the server via FTP and other protocols that require a login and
password.

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

=item $self = $server->set_login($login)

Sets the server's login name, which will be used with the password property to
interact with the server via FTP and other protocols that require a login and
password.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: WRITE access for field 'login' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $password = $server->get_password

Returns the server's password, which will be used with the login to interact
with the server via FTP and other protocols that require a login and password.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'password' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> The password is stored in clear text in the database.

=item $self = $server->set_password($password)

Sets the server's password, which will be used with the login to interact
with the server via FTP and other protocols that require a login and password.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: WRITE access for field 'password' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> The password is stored in clear text in the database.

=item my $cookie = $server->get_cookie

Returns the cookie that can be used by transfer protocols that require a cookie
for authentication, such as WebDAV.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'cookie' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $self = $server->set_cookie($cookie)

Sets the cookie that can be used by transfer protocols that require a cookie
for authentication, such as WebDAV. Converts non-Unix line endings.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub set_cookie {
    my ($self, $val) = @_;
    $val =~ s/\r\n?/\n/g if defined $val;
    $self->_set( [ 'cookie' ] => [ $val ]);
}

################################################################################

=item $server = $server->del

Marks the Bric::Dist::Server object to be deleted from the database. Call
$server->save to actually finish it off.

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

sub del { $_[0]->_set(['_del'], [1]) }

################################################################################

=item $self = $server->activate

Activates the Bric::Dist::Server object. Call $server->save to make the change
persistent. Bric::Dist::Server objects instantiated by new() are active by
default.

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

sub activate {
    my $self = shift;
    $self->_set({_active => 1 });
}

=item $self = $server->deactivate

Deactivates (deletes) the Bric::Dist::Server object. Call $server->save to make
the change persistent.

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

sub deactivate {
    my $self = shift;
    $self->_set({_active => 0 });
}

=item $self = $server->is_active

Returns $self if the Bric::Dist::Server object is active, and undef if it is not.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub is_active {
    my $self = shift;
    $self->_get('_active') ? $self : undef;
}

################################################################################

=item $self = $server->save

Saves any changes to the Bric::Dist::Server object. Returns $self on success and
undef on failure.

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
    return unless $self->_get__dirty;
    my ($id, $del) = $self->_get(qw(id _del));
    if (defined $id && $del) {
        # It has been marked for deletion. So do it!
        my $del = prepare_c(qq{
            DELETE FROM server
            WHERE  id = ?
        }, undef);
        execute($del, $id);
    } elsif (defined $id) {
        # Existing record. Update it.
        local $" = ' = ?, '; # Simple way to create placeholders with an array.
        my $upd = prepare_c(qq{
            UPDATE server
            SET    @cols = ?
            WHERE  id = ?
        }, undef);
        execute($upd, $self->_get(@props), $id);
    } else {
        # It's a new server. Insert it.
        local $" = ', ';
        my $fields = join ', ', next_key('server'), ('?') x $#cols;
        my $ins = prepare_c(qq{
            INSERT INTO server (@cols)
            VALUES ($fields)
        }, undef);
        # Don't try to set ID - it will fail!

        my @ps = $self->_get(@props[1..$#props]);
        execute($ins, $self->_get(@props[1..$#props]));
        # Now grab the ID.
        $id = last_key('server');
        $self->_set(['id'], [$id]);
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

=item my $server_aref = &$get_em( $pkg, $params )

=item my $server_ids_aref = &$get_em( $pkg, $params, 1 )

=item my $server_ids_href = &$get_em( $pkg, $params, 0, 1 )

Function used by lookup() and list() to return a list of Bric::Dist::Server
objects or, if called with an optional third argument, returns a listof
Bric::Dist::Server object IDs (used by list_ids()). If called with an optional
fourth argument, returns an anonymous hash where the keys are the object IDs and
the values are the objects themselves.

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

$get_em = sub {
    my ($pkg, $params, $ids, $href) = @_;
    my (@wheres, @params);
    while (my ($k, $v) = each %$params) {
        if ($k eq 'id' || $k eq 'os') {
            push @wheres, any_where $v, "$k = ?", \@params;
        } elsif ($k eq 'server_type_id') {
            push @wheres, any_where $v, 'server_type__id = ?', \@params;
        } elsif ($k eq 'active') {
            push @wheres, "active = ?";
            push @params, $v ? 1 : 0;
        } else {
            push @wheres, any_where $v, "LOWER($k) LIKE LOWER(?)", \@params;
        }
    }
    # Assemble the WHERE statement.
    my $where = @wheres
        ? "\n        WHERE " . join "\n               AND ", @wheres
        : '';

    # Assemble the query.
    my ($qry_cols, $order)
        = $ids ? ('DISTINCT id', 'id')
               : (join(', ', @cols), 'server_type__id, host_name');
    my $sel = prepare_ca(qq{
        SELECT $qry_cols
        FROM   server $where
        ORDER BY $order
    }, undef);

    # Just return the IDs, if they're what's wanted.
    return col_aref($sel, @params) if $ids;

    $pkg = ref $pkg || $pkg;
    execute($sel, @params);
    my (@d, @servers, %servers);
    bind_columns($sel, \@d[0..$#cols]);
    $pkg = ref $pkg || $pkg;
    while (fetch($sel)) {
        my $self = bless {}, $pkg;
        $self->SUPER::new;
        $self->_set(\@props, \@d);
        $self->_set__dirty; # Disables dirty flag.
        $href ? $servers{$d[0]} = $self->cache_me :
          push @servers, $self->cache_me;
    }
    return $href ? \%servers : \@servers;
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
L<Bric::Dist::ServerType|Bric::Dist::ServerType>

=cut
