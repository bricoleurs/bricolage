package Bric::Biz::Person;

=head1 Name

Bric::Biz::Person - Interface to Bricolage Person Objects

=cut

# Grab the Version Number.
require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

  use Bric::Biz::Person;
  # Constructors.
  my $p = Bric::Biz::Person->new($init);
  my $p = Bric::Biz::Person->lookup({ id => $id });
  my @p = Bric::Biz::Person->list($params);

  # Class Methods.
  my @pids = Bric::Biz::Person->list_ids($params);
  my $methds = Bric::Biz::Person->my_meths;

  # Instance Methods.
  my $id = $p->get_id;
  my $lname = $p->get_lname;
  $p = $p->set_lname($lname);
  my $fname = $p->get_fname;
  $p = $p->set_fname($fname);
  my $mname = $p->get_mname;
  $p = $p->set_mname($mname);
  my $prefix = $p->get_prefix;
  $p = $p->set_prefix($prefix);
  my $suffix = $p->get_suffix;
  $p = $p->set_suffix($suffix);
  my $name = $p->format_name($format);

  $p = $p->activate;
  $p = $p->deactivate;
  $p = $p->is_active;

  my @contacts = $p->get_contacts;
  my $contact = $p->new_contact;
  $p->add_new_contacts(@contacts);
  $p = $p->del_contacts;

  my @gids = $p->get_grp_ids;
  my @groups = $p->get_grps;

  my @oids = $p->get_org_ids;
  my @orgs = $p->get_orgs;

  $p = $p->save;

=head1 Description

This Class provides the basic interface to all people in Bricolage. A
Bric::Biz::Person object may be thought of as a person who plays any kind of role
in the application. A person may be a user, a writer, a producer, an editor, or
act in any number of interactive and non-interactive roles. Only those people
who are added to the Bric::Biz::Person::User subclass, however, may actually
interact with the application.

Bric::Biz::Person objects can do little other than be associated with
organizations or store contact information unless they are associated with
groups. The interface for managing groups of Bric::Biz::Person objects is
Bric::Util::Grp::Person. Attributes on persons will be associated with
Bric::Biz::Person objects by reference to their membership in certain groups. The
Bric::Util::Grp::Person class documents how these groups may be created,
associated with other objects (e.g., associate members of group "Writers" with
Bric::Biz::Asset::Business::Story objects), and attributes assigned. If a
Bric::Biz::Person object is a member of a Bric::Util::Grp::Person group that
defines attributes for its individual members, those attributes can be accessed
from the Bric::Biz::Person object.

=cut

################################################################################
# Dependencies
################################################################################
# Standard Dependencies
use strict;

################################################################################
# Programmatic Dependences
use Bric::Util::DBI qw(:standard col_aref);
use Bric::Util::Grp::Person;
use Bric::Biz::Org::Person;
use Bric::Util::Coll::Contact;
use Bric::Util::Pref;
use Bric::Util::Fault qw(throw_dp);

################################################################################
# Inheritance
################################################################################
use base qw(Bric);

################################################################################
# Function and Closure Prototypes
################################################################################
my ($get_em, $get_cont_coll, $meths);

################################################################################
# Constants
################################################################################
use constant DEBUG => 0;
use constant GROUP_PACKAGE => 'Bric::Util::Grp::Person';
use constant INSTANCE_GROUP_ID => 1;

################################################################################
# Fields
################################################################################
# Public Class Fields

################################################################################
# Private Class Fields
# Identifies databse columns and object keys.
my @cols = qw(id prefix fname mname lname suffix active);
my @props = qw(id prefix fname mname lname suffix _active);

my @sel_cols = qw(p.id p.prefix p.fname p.mname p.lname p.suffix p.active
                  m.grp__id);
my @sel_props = qw(id prefix fname mname lname suffix _active grp_ids);
my @ord = qw(prefix fname mname lname suffix name active);
my $table = 'person';
my $mem_table = 'member';
my $map_table = $table . "_$mem_table";

################################################################################
################################################################################
# Instance Fields
BEGIN {
    Bric::register_fields({
                         # Public Fields
                         id      => Bric::FIELD_READ,
                         prefix  => Bric::FIELD_RDWR,
                         lname   => Bric::FIELD_RDWR,
                         fname   => Bric::FIELD_RDWR,
                         mname   => Bric::FIELD_RDWR,
                         suffix  => Bric::FIELD_RDWR,
                         grp_ids => Bric::FIELD_READ,

                         # Private Fields
                         _active => Bric::FIELD_NONE,
                         _cont => Bric::FIELD_NONE  # Holds Contacts.
                        });
}

################################################################################
# Class Methods
################################################################################

=head1 Interface

=head2 Constructors

=over 4

=item my $p = Bric::Biz::Person->new($init)

Instantiates a Bric::Biz::Person object. An anonymous hash of initial values may be
passed. The supported initial value keys are:

=over 4

=item *

prefix

=item *

lname

=item *

fname

=item *

mname

=item *

suffix

=back

The active property will be set to true by default. Call $p->save() to save the
new object.

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
    $init->{_active} = 1;
    push @{$init->{grp_ids}}, INSTANCE_GROUP_ID;
    $self->SUPER::new($init);
}

################################################################################

=item my $p = Bric::Biz::Person->lookup({ id => $id })

Looks up and instantiates a new Bric::Biz::Person object based on the
Bric::Biz::Person object ID passed. If $id is not found in the database, lookup()
returns undef.

B<Throws:>

=over

=item *

Too many Bric::Biz::Person objects found.

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

B<Side Effects:> If $id is found, populates the new Bric::Biz::Person object with
data from the database before returning it.

B<Notes:> This method is overridden by the lookup() method of
Bric::Biz::Person::User. That class does not call Bric::Biz::Person's lookup()
method.

=cut

sub lookup {
    my $pkg = shift;
    my $person = $pkg->cache_lookup(@_);
    return $person if $person;

    $person = $get_em->($pkg, @_);
    # We want @$person to have only one value.
    throw_dp(error => 'Too many ' . __PACKAGE__ . ' objects found.')
      if @$person > 1;
    return @$person ? $person->[0] : undef;
}

################################################################################

=item my (@people || $person_aref) = Bric::Biz::Person->list($params)

Returns a list or anonymous array of Bric::Biz::Person objects based on the search
parameters passed via an anonymous hash. The supported lookup keys are:

=over 4

=item id

Person ID. May use C<ANY> for a list of possible values.

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

B<Side Effects:> Populates each Bric::Biz::Person object with data from the
database before returning them all.

B<Notes:> This method is overridden by the list() method of
Bric::Biz::Person::User. That class does not call Bric::Biz::Person's list()
method.

=cut

sub list { wantarray ? @{ &$get_em(@_) } : &$get_em(@_) }

################################################################################

=back

=head2 Destructors

=over 4

=item $p->DESTROY

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

=item my (@person_ids || $person_ids_aref) = Bric::Biz::Person->list_ids($params)

Returns a list or anonymous array of Bric::Biz::Person object IDs based on the
search criteria passed via an anonymous hash. The supported lookup keys are the
same as those for list().

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

B<Notes:> This method is overridden by the list_ids() method of
Bric::Biz::Person::User. That class does not call Bric::Biz::Person's list_ids()
method.

=cut

sub list_ids { wantarray ? @{ &$get_em(@_, 1) } : &$get_em(@_, 1) }

################################################################################

=item $meths = Bric::Biz::Person->my_meths

=item (@meths || $meths_aref) = Bric::Biz::Person->my_meths(TRUE)

=item my (@meths || $meths_aref) = Bric::Biz::Person->my_meths(0, TRUE)

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
              prefix     => {
                             name     => 'prefix',
                             get_meth => sub { shift->get_prefix(@_) },
                             get_args => [],
                             set_meth => sub { shift->set_prefix(@_) },
                             set_args => [],
                             disp     => 'Prefix',
                             type     => 'short',
                             len      => 32,
                             req      => 0,
                             props    => {   type       => 'text',
                                             length     => 32,
                                             maxlength => 32
                                         }
                            },
              fname      => {
                             name     => 'fname',
                             get_meth => sub { shift->get_fname(@_) },
                             get_args => [],
                             set_meth => sub { shift->set_fname(@_) },
                             set_args => [],
                             disp     => 'First',
                             len      => 64,
                             req      => 0,
                             type     => 'short',
                             props    => {   type       => 'text',
                                             length     => 32,
                                             maxlength => 64
                                         }
                            },
              mname      => {
                             name     => 'mname',
                             get_meth => sub { shift->get_mname(@_) },
                             get_args => [],
                             set_meth => sub { shift->set_mname(@_) },
                             set_args => [],
                             disp     => 'Middle',
                             len      => 64,
                             req      => 0,
                             type     => 'short',
                             props    => {   type       => 'text',
                                             length     => 32,
                                             maxlength => 64
                                         }
                            },
              lname      => {
                             name     => 'lname',
                             get_meth => sub { shift->get_lname(@_) },
                             get_args => [],
                             set_meth => sub { shift->set_lname(@_) },
                             set_args => [],
                             disp     => 'Last',
                             search   => 1,
                             len      => 64,
                             req      => 0,
                             type     => 'short',
                             props    => {   type       => 'text',
                                             length     => 32,
                                             maxlength => 64
                                         }
                            },
              suffix     => {
                             name     => 'suffix',
                             get_meth => sub { shift->get_suffix(@_) },
                             get_args => [],
                             set_meth => sub { shift->set_suffix(@_) },
                             set_args => [],
                             disp     => 'Suffix',
                             len      => 32,
                             req      => 0,
                             type     => 'short',
                             props    => {   type       => 'text',
                                             length     => 32,
                                             maxlength => 32
                                         }
                            },
              name       => {
                             name     => 'name',
                             get_meth => sub { shift->format_name(@_) },
                             get_args => [],
                             set_meth => undef,
                             set_args => undef,
                             disp     => 'Full Name',
                             len      => 128,
                             req      => 0,
                             type     => 'short',
                             props    => {   type       => 'text',
                                             length     => 128,
                                             maxlength => 256
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
                             len      => 1,
                             req      => 1,
                             type     => 'short',
                             props    => { type => 'checkbox' }
                            },
             };
    return !$ord ? $meths : wantarray ? @{$meths}{@ord} : [@{$meths}{@ord}];
}

################################################################################

=back

=head2 Public Instance Methods

=over 4

=item my $id = $p->get_id

Returns the ID of the Bric::Biz::Person object.

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

B<Notes:> If the Bric::Biz::Person object has been instantiated via the new()
constructor and has not yet been C<save>d, the object will not yet have an ID,
so this method call will return undef.

=item my $prefix = $p->get_prefix

Returns the name prefix for the Bric::Biz::Person object.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'prefix' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $self = $p->set_prefix($prefix)

Sets the prefix (e.g., 'Mr.', 'Ms.', 'Sr.', etc.) of the Bric::Biz::Person object.
Returns $self on success and undef on failure.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: WRITE access for field 'prefix' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $fname = $p->get_fname

Returns the first name for the Bric::Biz::Person object.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'fname' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $self = $p->set_fname($fname)

Sets the first name of the Bric::Biz::Person object. Returns $self on success and
undef on failure

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: WRITE access for field 'fname' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $mname = $p->get_mname

Returns the middle name for the Bric::Biz::Person object.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'mname' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $self = $p->set_mname($mname)

Sets the middle name of the Bric::Biz::Person object. Returns $self on success and
undef on failure.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: WRITE access for field 'mname' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $lname =  $p->get_lname

Returns the last name for the Bric::Biz::Person object.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'lname' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $self = $p->set_lname($lname)

Sets the last name of the Bric::Biz::Person object. Returns $self on success and
undef on failure.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: WRITE access for field 'lname' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $suffix = $p->get_suffix

Returns the name suffix (e.g., 'Jr.,' 'Ph.D., etc.) for the Bric::Biz::Person
object.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'suffix' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

=item $self = $p->set_suffix($suffix)

Sets the suffix property of the Bric::Biz::Person object. Returns $self on success
and undef on failure.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: WRITE access for field 'suffix' required.

=item *

No AUTOLOAD method.

=back

B<Notes:> NONE.

B<Side Effects:> NONE.

=item $self = $p->activate

Activates the Bric::Biz::Person object. Call $p->save to make the change
persistent. Bric::Biz::Person objects instantiated by new() are active by default.

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

=item $self = $p->deactivate

Deactivates (deletes) the Bric::Biz::Person object. Call $p->save to make the
change persistent.

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

=item $self = $p->is_active

Returns $self if the Bric::Biz::Person object is active, and undef if it is not.

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

=item my $name = $p->format_name($format)

Uses the formatting string passed in $format to format the person's name. The
formats are roughly based on the ideas behind sprintf formatting or strftime
formatting. Each format is denoted by a percent sign (%) and a single letter.
The letter represents the data that will be filled in to the string. Any
non-alphanumeric characters placed between the % and the conversion character
will be included in the string B<only if> the data represented by the conversion
character exists.

For example, if I wanted to get a full name, I would specify a format string
like so:

  my $format = "%f% m% l";

In which case, if the person object had a first name "William" and a last name
"Clinton", but no middle name, the method call

  $p->format_name($format);

would yield "William Clinton", appropriately omitting the middle name and the
space preceding it. But if the Bric::Biz::Person object also had the middle name
"Erin", the same method call would yeild "William Jefferson Clinton". Similarly,
you can add a comma where you need one, but only if you need one. For example,
if same person object had a prefix of "Mr." and a suffix of "MA", this method
call:

  $p->format_name("%p% f% M% l%, s");

would yield "Mr. William J. Clinton, MA", but if there is no suffix it yeilds
"Mr. William J. Clinton". Here are the supported formats:

  %l Last Name
  %f First Name
  %m Middle Name
  %p Prefix
  %s Suffix
  %L Last Name Initial with Period
  %F First Name Initial with Period
  %M Middle Name Initial with Period
  %T Last Name Initial
  %S First Name Initial
  %I Middle Name Initial

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=back

B<Side Effects:> NONE.

B<Notes:> The default format is determined by the "Name Format" preference.

=cut

sub format_name {
    my $self = shift;
    # The default format should be set as a user preference.
    my $format = shift || Bric::Util::Pref->lookup_val('Name Format');
    my @parts = $self->_get(qw(lname fname mname prefix suffix));
    my %things = ( '%' => '%' );

    foreach my $a (0..4) {
        my $def = defined $parts[$a] && $parts[$a] ne '';
        $things{qw(l f m p s)[$a]} = $def && $parts[$a];
        $things{qw(L F M _ _)[$a]} = $def && substr($parts[$a], 0, 1) . '.';
        $things{qw(T S I _ _)[$a]} = $def && substr($parts[$a], 0, 1);
    }

    $format =~ s/%([^lfmpsLFMTSI%]*)(.)/($_ = $things{$2}) && "$1$_"/ge;
    return $format;
}

################################################################################

=item my $name = $p->get_name($format)

This method is an alias for format_name().

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=back

B<Side Effects:> NONE.

B<Notes:> The default format is determined by the "Name Format" preference.

=cut

*get_name = *format_name;

=item my (@contacts || $contacts_aref) = $p->get_contacts

=item my (@contacts || $contacts_aref = $p->get_contacts(@contact_ids)

  foreach my $contact ($p->get_contacts) {
      print "Name:      ", $contact->get_name, "\n";
      print "Desc:      ", $contact->get_description, "\n";
      print "Value:     ", $contact->get_value, "\n";
      $contact->set_value($value);
  }
  $p->save;

Returns a list or anonymous array of Bric::Biz::Contact objects. If Contact IDs are
passed, it will return only those contacts. Any changes to individual
Bric::Biz::Contact objects will only persist after $p->save has been called.

Bric::Biz::Contact objects each represent a method by which the person represented
by the Bric::Biz::Person object can be contacted (e.g., email, pager, office phone,
mobile phone, Instant Messenger, etc.). See Bric::Biz::Contact for information on
its interface.

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

B<Side Effects:> Uses Bric::Util::Coll::Contact internally.

B<Notes:> NONE.

=cut

sub get_contacts {
    my $self = shift;
    my $cont_coll = &$get_cont_coll($self);
    $cont_coll->get_objs(@_);
}

################################################################################

=item my $contact = $p->add_contacts(@contacts)

  $p->add_contacts(@contacts);
  $p->save;

Adds a list of contacts to the contacts associated with this Person Object

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=back

B<Side Effects:> Uses Bric::Util::Coll::Contact internally.

B<Notes:> NONE.

=cut

sub add_new_contacts {
    my $self = shift;
    my $cont_coll = &$get_cont_coll($self);
    $self->_set__dirty(1);
    $cont_coll->add_new_objs(@_);
}

################################################################################

=item my $contact = $p->new_contact($contact_type_id)

=item my $contact = $p->new_contact($contact_type_id, $value)

  $p->new_contact($email_contact_type, $email_address);
  $p->save;

Returns a new Bric::Biz::Contact object associated with the Bric::Biz::Person object.
A list of contact type IDs can be retrieved from Bric::Biz::Contact->list_types().
If $value is passed, it will be saved to the contact object before returning the
object. Be sure to call $p->save to save this new contact. See Bric::Biz::Contact
for information on its interface.

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

B<Side Effects:> Uses Bric::Util::Coll::Contact internally.

B<Notes:> NONE.

=cut

sub new_contact {
    my $self = shift;
    my ($type, $value) = @_;
    my $cont_coll = &$get_cont_coll($self);
    $self->_set__dirty(1);
    $cont_coll->new_obj({ type => $type, value => $value });
}

################################################################################

=item $self = $p->del_contacts

=item $self = $p->del_contacts(@contacts)

=item $self = $p->del_contacts(@contact_ids)

  $p->del_contacts; # Delete all contacts.
  $p->save;         # Make the deletions persistent.

Deletes the Bric::Biz::Contact objects associated with the Bric::Biz::Person object.
If Bric::Biz::Contact objects or their IDs are passed, only those contacts will be
deleted. If no values are passed, all Bric::Biz::Contact objects associated with
the Bric::Biz::Person object will be deleted. The deletions will be reflected in
future calls to get_contacts() for the current Bric::Biz::Person instance, but will
not persist beyond the current instance until $p->save is called.

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

B<Side Effects:> Uses Bric::Util::Coll::Contact internally.

B<Notes:> NONE.

=cut

sub del_contacts {
    my $self = shift;
    my $cont_coll = &$get_cont_coll($self);
    $self->_set__dirty(1);
    $cont_coll->del_objs(@_);
}

################################################################################

=item my (@gids || $gids_aref) = $p->get_grp_ids

Returns a list or anonymous array of Bric::Util::Grp::Person object ids
representing the groups of which this Bric::Biz::Person object is a member.

B<Throws:> See Bric::Util::Grp::Person::list().

B<Side Effects:> NONE.

B<Notes:> NONE.

################################################################################

=item my (@groups || $groups_aref) = $p->get_grps

Returns a list or anonymous array of Bric::Util::Grp::Person objects representing
the groups of which this Bric::Biz::Person object is a member.

Use the Bric::Util::Grp::Person instance method calls add_members() and
delete_members() to associate and dissociate Bric::Biz::Person objects with any
given Bric::Util::Grp::Person object.

B<Throws:> See Bric::Util::Grp::Person::list().

B<Side Effects:> Uses Bric::Util::Grp::Person internally.

B<Notes:> NONE.

=cut

sub get_grps { Bric::Util::Grp::Person->list({ obj => $_[0] }) }

################################################################################

=item my (@orgs || $orgs_aref) = $p->get_orgs

Returns a list or anonymous array of Bric::Biz::Org::Person objects of which this
Bric::Biz::Person object is a member. The first Bric::Biz::Org::Person object returned
will be the default organization created when this Bric::Biz::Person object was
created. This Bric::Biz::Org::Person object will contain all the addresses for the
individual Bric::Biz::Person. All the other Bric::Biz::Org::Person objects represent
organizations (companies, etc.) with which this Bric::Biz::Person object is
associated. Use the get_addr() Bric::Biz::Org::Person method call to retrieve the
addresses associated with both the Bric::Biz::Org::Person object's parent and this
Bric::Biz::Person object specifically. See Bric::Biz::Org::Person for its API.

To add a Bric::Biz::Person object to an existing Bric::Biz::Org object, simply call
the Bric::Biz::Org add_object() method, passing it the Bric::Biz::Person object. This
method will return the resulting Bric::Biz::Org::Person object. See the documentation
for Bric::Biz::Org and Bric::Biz::Org::Person for more information.

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

B<Side Effects:> Internally calls the Bric::Biz::Org::Person->list() class method.

B<Notes:> NONE.

=cut

sub get_orgs {
    my $self = shift;
    Bric::Biz::Org::Person->list({ person_id => $self->get_id })
}

################################################################################

=item my (@oids || $oids_aref) = $p->get_org_ids

Returns a list or anonymous array of Bric::Biz::Org::Person object IDs representing
the Bric::Biz::Org::Person objects the Bric::Biz::Person object is associated with.
The first Bric::Biz::Org::Person ID will be the defalut organization created when
this Bric::Biz::Person object was created.

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

B<Side Effects:> Internally calls the Bric::Biz::Org::Person->list_ids() class
method.

B<Notes:> NONE.

=cut

sub get_org_ids { Bric::Biz::Org::Person->list_ids({person_id => $_[0]->get_id}) }

################################################################################

=item $self = $p->save

Saves any changes to the Bric::Biz::Person object, including changes to associated
contacts (Bric::Biz::Contact objects). Returns $self on success and undef on
failure.

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

B<Side Effects:> Uses Bric::Util::Coll::Contact internally.

B<Notes:> NONE.

=cut

sub save {
    my $self = shift;
    my ($c, $id) = $self->_get(qw(_cont id));

    if ($self->_get__dirty) {
        if (defined $id) {
            # It's an existing person. Update it.
            local $" = ' = ?, '; # Simple way to create placeholders with an array.
            my $upd = prepare_c(qq{
                UPDATE person
                SET   @cols = ?
                WHERE  id = ?
            }, undef);
            execute($upd, $self->_get(@props), $id);
            unless ($self->_get('_active')) {
                # Deactivate all group memberships if we've deactivated the person.
                foreach my $grp (Bric::Util::Grp::Person->list({
                                 obj => $self,
                                 permanent => 0 })) {
                    foreach my $mem ($grp->has_member({ obj => $self })) {
                        next unless $mem;
                        $mem->deactivate;
                        $mem->save;
                    }
                }
            }
        } else {
            # It's a new person. Insert it.
            local $" = ', ';
            my $fields = join ', ', next_key('person'), ('?') x $#cols;
            my $ins = prepare_c(qq{
                INSERT INTO person (@cols)
                VALUES ($fields)
            }, undef);
            # Don't try to set ID - it will fail!
            execute($ins, $self->_get(@props[1..$#props]));
            # Now grab the ID.
            $id = last_key('person');
            $self->_set(['id'], [$id]);

            # Now be sure to create a personal org for this person.
            my $org = Bric::Biz::Org::Person->new({
                name => $self->format_name(
                        Bric::Util::Pref->lookup_val('Name Format')
                        ),
                role => 'Personal',
                _personal => 1,
                person_id => $id
            });
            $org->save;

            # And finally, register this person in the "All Persons" group.
            $self->register_instance(INSTANCE_GROUP_ID, GROUP_PACKAGE);
        }
    }

    # Save the contacts.
    $c->save($self, $id) if $c;
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

=item my $people_aref = &$get_em( $pkg, $search_href )

=item my $people_ids_aref = &$get_em( $pkg, $search_href, 1 )

Function used by lookup() and list() to return a list of Bric::Biz::Person objects
or, if called with an optional third argument, returns a listof Bric::Biz::Person
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
    my ($pkg, $params, $ids) = @_;
    my (@wheres, @params);
    my $extra_tables = '';
    my $extra_wheres = '';
    while (my ($k, $v) = each %$params) {
        if ($k eq 'id') {
            push @wheres, any_where $v, "p.$k = ?", \@params;
        } elsif ($k eq 'grp_id') {
            $extra_tables = ", $mem_table m2, $map_table c2";
            $extra_wheres = "AND p.id = c2.object_id AND " .
              "m2.active = '1' AND c2.member__id = m2.id";
            push @wheres, any_where $v, "m2.grp__id = ?", \@params;
        } elsif ($k eq 'active') {
            push @wheres, 'p.active = ?';
            push @params, $v ? '1' : '0';
        } else {
            push @wheres, any_where $v, "LOWER(p.$k) LIKE LOWER(?)", \@params;
        }
    }

    my $where = defined $params->{id} ? '' : "p.active = '1'"
        unless exists $params->{active};
    $where .= ($where ? ' AND ' : '') . join(' AND ', @wheres) if @wheres;

    local $" = ', ';
    my ($qry_cols, $order) = $ids ? (['p.id'], 'p.id') :
      (\@sel_cols, 'LOWER(p.lname), LOWER(p.fname), LOWER(p.mname), p.id');
    my $sel = prepare_c(qq{
        SELECT @$qry_cols
        FROM   $table p, $mem_table m, $map_table c $extra_tables
        WHERE  p.id = c.object_id AND c.member__id = m.id and m.active = '1'
               $extra_wheres AND $where
        ORDER BY $order
    }, undef);

    # Just return the IDs, if they're what's wanted.
    return col_aref($sel, @params) if $ids;

    execute($sel, @params);
    my (@d, @people, $grp_ids);
    bind_columns($sel, \@d[0..$#sel_cols]);
    $pkg = ref $pkg || $pkg;
    my $last = -1;
    while (fetch($sel)) {
        if ($d[0] != $last) {
            $last = $d[0];
            # Create a new Person object.
            my $self = bless {}, $pkg;
            $self->SUPER::new;
            $grp_ids = $d[$#d] = [$d[$#d]];
            $self->_set(\@sel_props, \@d);
            $self->_set__dirty; # Disables dirty flag.
            push @people, $self->cache_me;
        } else {
            push @$grp_ids, $d[$#d];
        }
    }
    return \@people;
};

=item my $cont_coll = &$get_cont_coll($self)

Returns the collection of contacts for this organization. The collection is a
Bric::Util::Coll::Contact object. See that class and its parent, Bric::Util::Coll,
for interface details.

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

$get_cont_coll = sub {
    my $self = shift;
    my $dirt = $self->_get__dirty;
    my ($id, $cont_coll) = $self->_get('id', '_cont');
    return $cont_coll if $cont_coll;
    $cont_coll = Bric::Util::Coll::Contact->new
      (defined $id ? {person_id => $id} : undef);
    $self->_set(['_cont'], [$cont_coll]);
    $self->_set__dirty($dirt); # Reset the dirty flag.
    return $cont_coll;
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
L<Bric::Biz::Contact|Bric::Biz::Contact>,
L<Bric::Biz::Org|Bric::Biz::Org>,
L<Bric::Biz::Person::User|Bric::Biz::Person::User>

=cut
