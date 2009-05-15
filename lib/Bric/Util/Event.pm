package Bric::Util::Event;

=head1 Name

Bric::Util::Event - Interface to Bricolage Events

=cut

# Grab the Version Number.
require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

  # Constructors.
  my $event = Bric::Util::Event->new($init);
  my $event = Bric::Util::Event->lookup({id => $id});
  my @events = Bric::Util::Event->list(params)

  # Class Methods.
  my @eids = Bric::Util::Event->list_ids($params)

  # Instance Methods.
  my $id = $event->get_id;
  my $et = $event->get_event_type;
  my $et_id = $event->get_event_type_id;
  my $user = $event->get_user;
  my $user_id = $event->get_user_id;
  my $obj = $event->get_obj;
  my $obj_id = $event->get_obj_id;
  my $time = $event->get_timestamp;
  my $key_name = $event->get_key_name; # Same as returned by $et.
  my $name = $event->get_name;         # Same as returned by $et.
  my $desc = $event->get_description;  # Same as returned by $et.
  my $class = $event->get_class;       # Same as returned by $et.

=head1 Description

Bric::Util::Event provides an interface to individual Bricolage events. It is
used primarily to create a list of events relative to a particular Bricolage
object. Events can only be de logged for a pre-specified list of event types as
defined by Bric::Util::EventType. In fact, I recommend that you use the
log_event() method on an Bric::Util::EventType object to log individual events,
rather than creating them here with the new() method. Either way, the event will
be logged and all necessary alerts defined via the Bric::Util::AlertType class
will be sent.

While the primary purpose of this class is to create lists of events, I have
provided a number of methods to make it as flexible an API as possible. These
include the ability to automatically instantiate the object for which an event
was logged, or the Bric::Biz::Person::User object representing the user who
triggered the event.

=cut

##############################################################################
# Dependencies
##############################################################################
# Standard Dependencies
use strict;

##############################################################################
# Programmatic Dependences
use Bric::Util::DBI qw(:all);
use Bric::Util::Time qw(:all);
use Bric::Util::EventType;
use Bric::Util::AlertType;
#use Bric::Util::Grp::Event;
use Bric::Biz::Person::User;
use Bric::Util::Fault qw(throw_dp);
use Scalar::Util qw(blessed);

##############################################################################
# Inheritance
##############################################################################
use base qw(Bric);

##############################################################################
# Function and Closure Prototypes
##############################################################################
my ($get_em, $save, $save_attr, $get_et);

##############################################################################
# Constants
##############################################################################
use constant DEBUG => 0;

##############################################################################
# Fields
##############################################################################
# Public Class Fields

##############################################################################
# Private Class Fields
my $SEL_COLS = 'e.id, t.id, e.usr__id, e.obj_id, e.timestamp, t.key_name, ' .
  't.name, t.description, c.pkg_name, CASE WHEN e.id IN ' .
  '(SELECT event__id FROM alert) THEN 1 ELSE 0 END, ta.name, ea.value'; #, m.grp_id';

my @SEL_PROPS = qw(id event_type_id user_id obj_id timestamp key_name name
                   description class _alert); # grp_ids);

my @PROPS = (@SEL_PROPS, 'attr');

my @ECOLS = qw(id event_type__id usr__id obj_id);
my @EPROPS = qw(id event_type_id user_id obj_id);

my @ORD = qw(name key_name description trig_id trig class timestamp);
my $METHS;

my %NUM_MAP = (
    id            => 'e.id',
    event_type_id => 't.id',
    user_id       => 'e.usr__id',
    obj_id        => 'e.obj_id',
    class_id      => 't.class__id'
);

my %TXT_MAP = (
    key_name      => 't.key_name',
    name          => 't.name',
    description   => 't.description',
    class         => 'c.pkg_name',
    value         => 'ea.value',
);

##############################################################################
# Instance Fields
BEGIN {
    Bric::register_fields({
                         # Public Fields
                         id => Bric::FIELD_READ,
                         event_type_id => Bric::FIELD_READ,
                         user_id => Bric::FIELD_READ,
                         obj_id => Bric::FIELD_READ,
                         timestamp => Bric::FIELD_READ,
                         key_name => Bric::FIELD_READ,
                         name => Bric::FIELD_READ,
                         description => Bric::FIELD_READ,
                         class => Bric::FIELD_READ,
                         attr => Bric::FIELD_READ,
#                         grp_ids => Bric::FIELD_READ,

                         # Private Fields
                         _et => Bric::FIELD_NONE,
                         _alert => Bric::FIELD_READ,
                        });
}

##############################################################################
# Class Methods
##############################################################################

=head1 Interface

=head2 Constructors

=over 4

=item my $event = Bric::Util::Event->new($init)

Instantiates and saves a Bric::Util::Event object. Returns the new event
object on success and undef on failure. An anonymous hash of initial values
must be passed with the following keys:

=over 4

=item *

et - A Bric::Util::EventType object, which defines what type of event to
log. If you happen to have already instantiated a Bric::Util::EventType
object, use that object rather than its ID to avoid creating a second
instantiation of the same object inernally.

=item *

et_id - A Bric::Util::EventType object ID. May be passed instead of et. A
Bric::Util::EventType object ID will be instantiated internally.

=item *

key_name - A Bric::Util::EventType object key name. May be passed instead of
et or et_id. A Bric::Util::EventType object ID will be instantiated
internally.

=item *

obj - The object for which the event will be logged.

=item *

user - The Bric::Biz::Person::User object representing the user who triggered
the event.

=item *

attr - An anonymous hash representing the attributes required to log the event.
All must have values or they'll throw an error.

=item *

timestamp - The event's time. Optional.

=back

B<Throws:>

=over 4

=item *

No Bric::Util::EventType object, ID, or name passed to new().

=item *

Too many Bric::Util::EventType objects found.

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

=item *

Bric::Util::Event::new() expects an object of type $class.

=item *

No Bric::Biz::Person::User object passed to Bric::Util::Event::new().

=back

B<Side Effects:> Creates the new event and saves it to the database.

B<Notes:> Use new() only to create a completely new event object. It will
automatically be saved before returning the new event object. Use lookup() or
list() to fetch pre-existing event objects.

In the future, attributes may not need to be passed for all attribute
logging. That is, if the attributes can be collected direct from the object of
this event via accessors, they need not be passed in via this anonymous
hash. The accessors must be named 'get_' plus the name of the attribute to be
fetched (such as 'get_slug') in order for the method-call approach to
collecting atrributes to work. But this is not yet implemented.

=cut

sub new {
    my ($pkg, $init) = @_;
    my $self = bless {}, ref $pkg || $pkg;

    # Make sure we've got full EventType object.
    my $et = $init->{et};
    unless ($et) {
        if (defined $init->{et_id}) {
            $et = Bric::Util::EventType->lookup({ id => $init->{et_id} });
        } elsif (my $kn = $init->{key_name}) {
            $et = Bric::Util::EventType->lookup({ key_name => $kn })
                or throw_dp qq{No event type found for key_name "$kn"};
        } else {
            throw_dp(error => "No Bric::Util::EventType object, ID, or "
                     . "key_name passed to " .  __PACKAGE__ . '::new()');
        }
    }

    my ($class, $et_id) = ($et->_get('class', 'id'));
    # Die if the object we're logging against isn't in the right class.
    my $obj = $init->{obj};
    $obj->isa($class)
      || throw_dp(error => "Event type '" . $et->get_key_name . "' expects an object " .
                  "of type $class");

    # Die if no user has been passed.
    my $user = $init->{user};
    $user->isa('Bric::Biz::Person::User') ||
      throw_dp(error => "No Bric::Biz::Person::User object passed to " .
               __PACKAGE__ . '::new()');

    # Inititialize the standard Bric::Util::Event properties.
    $self->SUPER::new({event_type_id => $et_id,
                       user_id       => $user->get_id,
                       obj_id        => $obj->get_id,
                       timestamp     => db_date($init->{timestamp}, 1),
                       name          => $et->get_name,
                       key_name      => $et->get_key_name,
                       description   => $et->get_description,
                       class         => $et->get_class,
                       _et           => $et
                      });

    my $id = &$save($self);             # Save this event to the database.

    # Now save any attributes.
    $self->_set(['attr'], [&$save_attr($id, $et, $init->{attr})])
      if $init->{attr};

    # Send out any alerts specified for this event.
    $init->{event} = $self;
    for my $at (Bric::Util::AlertType->list({ event_type_id => $et_id,
                                              active        => 1 })) {
        $at->send_alerts($init);
    }
    return $self;
}

##############################################################################

=item my $event = Bric::Util::Event->lookup({id => $id})

Looks up and instantiates a new Bric::Util::Event object based on the
Bric::Util::Event object ID. If the existing object is not found in the
database, lookup() returns undef. If the ID or name is found more than once,
lookup() returns zero (0). This should not happen.

B<Throws:>

=over

=item *

Too many Bric::Util::Event objects found.

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

B<Side Effects:> If C<$id> is found, populates the new Bric::Biz::Person
object with data from the database before returning it.

B<Notes:> NONE.

=cut

sub lookup {
    my $pkg = shift;
    my $event = $pkg->cache_lookup(@_);
    return $event if $event;

    $event = $get_em->($pkg, @_);
    # We want @$event to have only one value.
    throw_dp(error => 'Too many Bric::Util::Event objects found.')
      if @$event > 1;
    return @$event ? $event->[0] : undef;
}

##############################################################################

=item my (@events || $events_aref) = Bric::Util::Event->list($params)

Returns a list of Bric::Util::Event objects in reverse chronological order
based on the search parameters passed via an anonymous hash. The supported
lookup keys are:

=over 4

=item id

Event ID. May use C<ANY> for a list of possible values.

=item event_type_id

Event type ID. May use C<ANY> for a list of possible values.

=item user_id

User ID for user who may have triggered events. May use C<ANY> for a list of
possible values.

=item class_id

ID of the class of object on which events have been logged. May use C<ANY> for
a list of possible values.

=item class

The package name of a class, the objects of which may have had events logged
against them. May use C<ANY> for a list of possible values.

=item key_name

Event type key name. May use C<ANY> for a list of possible values.

=item name

Event name. May use C<ANY> for a list of possible values.

=item description

Event description. May use C<ANY> for a list of possible values.

=item obj_id

ID of a Bricolage object for which events may have been logged. May use C<ANY>
for a list of possible values.

=item timestamp

Time at which events have been logged.If passed as a scalar, events that
occurred at that exact time will be returned. If passed as an anonymous array,
the first two values will be assumed to represent a range of dates between
which to retrieve Bric::Util::Event objects. May also use C<ANY> for a list of
possible values.

=item value

The value of an event attribute. May use C<ANY> for a list of possible values.

=begin comment

=item *

grp_id

=end comment

=item Order

An attribute name to order by.

=item OrderDirection

The direction in which to order the records, either "ASC" for ascending (the
default) or "DESC" for descending. This value is applied to the property
specified by the C<Order> parameter. Defaults to ascending.

=item Limit

A maximum number of objects to return. If not specified, all objects that
match the query will be returned.

=item Offset

The number of objects to skip before listing the remaining objcts or the
number of objects specified by C<Limit>.

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

##############################################################################

=item $meths = Bric::Util::Event->my_meths

=item (@meths || $meths_aref) = Bric::Util::Event->my_meths(TRUE)

=item my (@meths || $meths_aref) = Bric::Util::Grp::Event->my_meths(0, TRUE)

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
    return !$ord ? $METHS : wantarray ? @{$METHS}{@ORD} : [@{$METHS}{@ORD}]
      if $METHS;

    # We don't got 'em. So get 'em!
    $METHS = {
              name      => {
                             name     => 'name',
                             get_meth => sub { shift->get_name(@_) },
                             get_args => [],
                             disp     => 'Name',
                             len      => 64,
                            },
              description      => {
                             name     => 'description',
                             get_meth => sub { shift->get_description(@_) },
                             get_args => [],
                             disp     => 'Description',
                             len      => 256,
                            },
              class      => {
                             name     => 'class',
                             get_meth => sub { shift->get_class(@_) },
                             get_args => [],
                             disp     => 'Class',
                             len      => 128,
                            },
              timestamp  => {
                             name     => 'timestamp',
                             get_meth => sub { shift->get_timestamp(@_) },
                             get_args => [],
                             disp     => 'Timestamp',
                             search   => 1,
                             len      => 128,
                            },
              user_id  => {
                             name     => 'user_id',
                             get_meth => sub { shift->get_user_id(@_) },
                             get_args => [],
                             disp     => 'Triggered By',
                             len      => 256,
                            },
              trig  => {
                             name     => 'trig',
                             get_meth => sub { shift->get_user(@_)->get_name },
                             get_args => [],
                             disp     => 'Triggered By',
                             len      => 256,
                            },
              attr       => {
                             name     => 'attr',
                             get_meth => sub { shift->get_attr(@_) },
                             get_args => [],
                             disp     => 'Attributes',
                             len      => 128,
                            },
             };
    return !$ord ? $METHS : wantarray ? @{$METHS}{@ORD} : [@{$METHS}{@ORD}];
}

##############################################################################

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

##############################################################################

=head2 Public Class Methods

=over 4

=item my (@eids || $eids_aref) = Bric::Biz::Person->list_ids($params)

Functionally identical to list(), but returns Bric::Util::Event object IDs
rather than objects. See list() for a description of its interface.

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

##############################################################################

=back

=head2 Public Instance Methods

=over 4

=item my $id = $event->get_id

Returns the event object ID.

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

B<Notes:> NONE.

=item my $et = $event->get_event_type

Returns the event type object defining the event.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=item *

Too many Bric::Util::EventType objects found.

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

Incorrect number of args to _set.

=item *

Bric::_set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_event_type { &$get_et(shift) }

=item my $et_id = $event->get_event_type_id

Returns the ID of the event type object defining the event.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'event_type_id' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $u = $event->get_user

Returns the Bric::Biz::Person::User object representing the person who
triggered the event.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

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

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_user { Bric::Biz::Person::User->lookup({ id => $_[0]->_get('user_id') }) }

=item my $uid = $event->get_user_id

Returns the ID of the Bric::Biz::Person::User object representing the person
who triggered the event.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'user_id' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $obj = $event->get_obj

Returns the object for which this event was logged. The class of the object
may be fetched from $event->get_class.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=item *

Too many objects found.

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

Incorrect number of args to _set.

=item *

Bric::_set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_obj {
    my $self = shift;
    my $class = $self->_get('class');
    return $class->lookup({ id => $self->_get('obj_id') });
}

=item my $obj_id = $event->get_obj_id

Returns the ID of the object for which this event was logged. The class of the
object may be fetched from $event->get_class.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'obj_id' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $timestamp = $event->get_timestamp

Returns the time at which the event was triggered.

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

sub get_timestamp { local_date($_[0]->_get('timestamp'), $_[1]) }

##############################################################################

=item my $key_name = $event->get_key_name

Returns the event key name. Same as the key name specified for the event type
defining this event.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'key_name' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $name = $event->get_name

Returns the event name. Same as the name specified for the event type defining
this event.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'key_name' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $description = $event->get_description

Returns the event description. Same as the name specified for the event type
defining this event.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'key_name' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $class = $event->get_class

Returns name of the class of object for which the event was logged.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'key_name' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $attr_href = $event->get_attr

Returns an anonymous hash of the attributes of the event.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'attr' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> Uses Bric::Util::Attribute::Event internally.

B<Notes:> NONE.

=item $self = $event->has_alerts

Returns true if alerts are associated with the event, and false if no alerts
are associated with the event.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub has_alerts { $_[0]->_get('_alert') ? $_[0] : undef }

##############################################################################

=item $self = $event->save;

Dummy method for those who try to call save() without realizing that saving is
automatic. Returns $self, but otherwise does noththing.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub save { $_[0] }

##############################################################################

=back

=head1 Private

=head2 Private Class Methods

NONE.

=head2 Private Instance Methods

NONE.

=head2 Private Functions

=over 4

=item my $events_aref = &$get_em( $pkg, $search_href )

=item my $events_ids_aref = &$get_em( $pkg, $search_href, 1 )

Function used by lookup() and list() to return a list of Bric::Biz::Person
objects or, if called with an optional third argument, returns a listof
Bric::Biz::Person object IDs (used by list_ids()).

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
    my $tables = 'event e LEFT JOIN event_attr ea ON e.id = ea.event__id ' .
      'LEFT JOIN event_type_attr ta ON ea.event_type_attr__id = ta.id, ' .
      'class c, event_type t'; # .
#                 ', member m, event_member em';
    my $wheres = 'e.event_type__id = t.id AND t.class__id = c.id'; # .
#      ' AND e.id = em.object_id AND m.id = em.member__id';
    my (@params, @limits);

    # Handle query metadata.
    my $order_by = 'e.timestamp DESC, e.id DESC';
    if (my $ord = delete $params->{Order}) {
        $order_by = $ord eq 'timestamp' ? 'e.timestamp'
                                        : $TXT_MAP{$ord} || $NUM_MAP{$ord}
                                        ;
        if (my $dir = delete $params->{OrderDirection}) {
            $order_by .= lc $dir eq 'desc' ? ' DESC' : ' ASC';
        }
    }

    my $limit = '';
    if (exists $params->{Limit}) {
        push @limits, delete $params->{Limit};
        $limit = 'LIMIT ?';
    }
    my $offset = '';
    if (exists $params->{Offset}) {
        if (DBD_TYPE eq 'mysql' && !$limit) {
            # Fuck you, MySQL.
            push @limits, LIMIT_DEFAULT;
            $limit = 'LIMIT ?';
        }
        push @limits, delete $params->{Offset};
        $offset = 'OFFSET ?';
    }

    while (my ($k, $v) = each %$params) {
        if ($k eq 'timestamp') {
            # It's a date column.
            if (blessed $v) {
                # It's an ANY value.
                db_date($_) for @$v;
                $wheres .= ' AND ' . any_where $v, "e.$k = ?", \@params;
            }
            elsif (ref $v && !blessed $v) {
                # It's an arrayref of dates.
                $wheres .= " AND e.$k BETWEEN ? AND ?";
                push @params, (db_date($v->[0]), db_date($v->[1]));
            }
            else {
                # It's a single value.
                $wheres .= ' AND ' . any_where $v, "e.$k = ?", \@params;
            }
        }

        elsif ($NUM_MAP{$k}) {
            # It's a numeric column.
            $wheres .= ' AND ' . any_where $v, "$NUM_MAP{$k} = ?", \@params;
        }

        elsif ($TXT_MAP{$k}) {
            # It's a text-based column.
            $wheres .= ' AND '
                . any_where $v, "LOWER($TXT_MAP{$k}) LIKE LOWER(?)", \@params;
        }

# elsif ($k eq 'grp_id') {
#            # Add in the group tables a second time and join to them.
#            $tables .= ', member m2, event_member em2';
#            $wheres .= ' AND e.id = em2.object_id AND em2.member__id = m2.id'
#                . ' AND ' any_where $v, 'm2.grp__id = ?', \@params;
#        }

        else {
            # We're horked.
            throw_dp(error => "Invalid property '$k'.");
        }
    }

    my ($qry_cols, $order) = $ids ? (\'DISTINCT e.id', 'e.id')
                                  : (\$SEL_COLS, $order_by)
                                  ;

    my $sel = prepare_c(qq{
        SELECT $$qry_cols
        FROM   $tables
        WHERE  $wheres
        ORDER BY $order
        $limit $offset;
    }, undef);

    # Just return the IDs, if they're what's wanted.
    return col_aref($sel, @params) if $ids;

    execute($sel, @params, @limits);
    my (@d, @events, $attrs, $key, $val); # , $grp_ids, %seen
    $pkg = ref $pkg || $pkg;
    bind_columns($sel, \@d[0..$#SEL_PROPS], \$key, \$val);
    my $last = -1;
    while (fetch($sel)) {
        if ($d[0] != $last) {
            $last = $d[0];
            # Empty the grp_ids check hash.
#            %seen = ();
            # Get a reference to the array of group IDs and mark that we've
#            # seen this one.
#            $grp_ids = $d[$#d] = [$d[$#SEL_PROPS]];
#            $seen{$grp_ids->[0]} = 1;

            # Start the attribute hash and add it to the array.
            $attrs = $d[$#SEL_PROPS + 1] = $key ? { $key => $val } : undef;

            # Create a new event object.
            my $self = bless {}, $pkg;
            $self->SUPER::new;
            $self->_set(\@PROPS, \@d);
            $self->_set__dirty; # Disable the dirty flag.
            push @events, $self->cache_me;
        } else {
            # Add the current group ID to the array unless we've seen it
            # already.
#            push @$grp_ids, $d[$#SEL_PROPS] unless $seen{$d[$#SEL_PROPS]};
            # Mark that we've seen this group ID.
#            $seen{$d[$#SEL_PROPS]} = 1;
            # Grab the attribute and value for this row.
            $attrs->{$key} = $val if $key;
        }
    }
    return \@events;
};

##############################################################################

=item &$save($self)

Saves the contents of an event.

B<Throws:>

=over 4

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

$save = sub {
    my $self = shift;
    local $" = ', ';
    my $fields = join ', ', next_key('event'), ('?') x $#ECOLS;
    my $ins = prepare_c(qq{
        INSERT INTO event (@ECOLS)
        VALUES ($fields)
    }, undef);
    # Don't try to set ID - it will fail!
    execute($ins, $self->_get(@EPROPS[1..$#EPROPS]));
    # Now grab the ID.
    my $id = last_key('event');
    $self->_set({ id => $id });
    return $id;
};

##############################################################################

=item &$save_attr($event_id, $et, $attr)

Saves the attributes of an event.

B<Throws:>

=over 4

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

$save_attr = sub {
    my ($eid, $et, $attr) = @_;
    my $ins = prepare_c(qq{
        INSERT INTO event_attr (event__id, event_type_attr__id, value)
        VALUES (?, ?, ?)
    }, undef);

    my $ret;
    my $et_attr = $et->get_attr;
    while (my ($aid, $name) = each %$et_attr) {
        execute($ins, $eid, $aid, $attr->{$name} || $attr->{lc $name});
        $ret->{$name} = $attr->{$name};
    }
    return $ret;
};

##############################################################################

=item &$get_et($self)

Returns the Bric::Util::EventType object identifying the type of this
Bric::Util::Event object.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=item *

Too many Bric::Util::EventType objects found.

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

Incorrect number of args to _set.

=item *

Bric::_set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> Uses Bric::Util::EventType->lookup() internally and caches the
object.

=cut

$get_et = sub {
    my $self = shift;
    my $et = $self->_get('_et');
    return $et if $et;
    $et = Bric::Util::EventType->lookup({ id => $self->_get('event_type_id') });
    $self->_set(['_et'], [$et]);
    return $et;
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
L<Bric::Util::EventType|Bric::Util::EventType>,
L<Bric::Util::AlertType|Bric::Util::AlertType>,
L<Bric::Util::Alert|Bric::Util::Alert>

=cut

