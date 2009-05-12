package Bric::Util::AlertType;

=head1 Name

Bric::Util::AlertType - Interface for Managing Types of Alerts

=cut

# Grab the Version Number.
require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

  use Bric::Util::AlertType;

  # Constructors.
  my $at = Bric::Util::AlertType->new($init);
  my $at = Bric::Util::AlertType->lookup({ id => $id });
  my @ats = Bric::Util::AlertType->list($atarams);

  # Class Methods.
  my @pids = Bric::Util::AlertType->list_ids($atarams);
  # Check to see if a name is already used by a user.
  my $bool = Bric::Util::AlertType->name_used($name, $user);
  my $meths = Bric::Util::AlertType->my_meths;
  my @meths = Bric::Util::AlertType->my_meths(1);

  # Instance Methods.
  my $id = $at->get_id;

  # Event type accessors.
  my $et = $at->get_event_type;
  my $et_id = $at->get_event_type_id;
  $at = $at->set_event_type_id($et_id);

  # Owner (user) accessors.
  my $owner = $at->get_owner;
  my $owner_id = $at->get_owner_id;
  $at = $at->set_owner_id($owner_id);

  my $name = $at->get_name;
  $at = $at->set_name($name);
  my $subject = $at->get_subject;
  $at = $at->set_subject($subject);
  my $message = $at->get_message;
  $at = $at->set_message($message);

  $at = $at->activate;
  $at = $at->deactivate;
  $at = $at->remove;
  $at = $at->is_active;

  my @rules = $at->get_rules;
  my $rule = $at->new_rule;
  $at = $at->del_rules(@rule_ids);

  my @users = $at->get_users;
  my @uids = $at->get_user_ids;
  $at = $at->add_users(@users);
  $at = $at->del_users(@uids);

  my @grps = $at->get_grps;
  my @gids = $at->get_grp_ids;
  $at = $at->add_grps(@grps);
  $at = $at->del_grps(@gids);

  $at = $at->save;

=head1 Description

Bric::Util::AlertType provides an interface for creating, editing, and deleting
types of alerts. All alerts are based on types of events. These are defined as
Bric::Util::EvenType objects. Alerts have several important features.

First, users can create rules for their alerts. These rules will be examined
whenever an event the alert is based on is triggered, and the alert will only be
sent if all the rules are true for that particular event. Rules can be such as
"Send the alert only if the user who triggered the event has a certain email
login," or "Send the alert only if the Story's slug is "pooter". Rules can be
combined to refine when the alert is sent to a great degree, and there is no
limit on the number of rules an Bric::Util::AlertType object can have. The
interface for rules is Bric::Util::AlertType::Parts::Rule.

Second, users can use the same variables by which rules are created to customize
the alert message. By simply adding a reference to one of these variables, the
message will be filled in with data from the event or the object on which the
event is based before sending out the alert. See set_message() below for more
details on message customization.

Third, users can select multiple methods of dispatching alerts (email, pager,
instant message, etc.), and associate  users or groups of users with a method.

=cut

################################################################################
# Dependencies
################################################################################
# Standard Dependencies
use strict;

################################################################################
# Programmatic Dependences
use Bric::Util::DBI qw(:standard col_aref prepare_ca);
use Bric::Util::Fault qw(throw_dp);
use Bric::Biz::Person::User;
use Bric::Util::Event;
use Bric::Util::Coll::Rule;
use Bric::Util::Alert;
use Bric::Util::Grp::AlertType;
use Safe;

################################################################################
# Inheritance
################################################################################
use base qw(Bric);

################################################################################
# Function and Closure Prototypes
################################################################################
my ($get_em, $get_rules, $get_cont, $upd_cont);

################################################################################
# Constants
################################################################################
use constant DEBUG => 0;
use constant GROUP_PACKAGE => 'Bric::Util::Grp::AlertType';
use constant INSTANCE_GROUP_ID => 4;

################################################################################
# Fields
################################################################################
# Public Class Fields

################################################################################
# Private Class Fields
my @cols = qw(id event_type__id usr__id name subject message active del);
my @props = qw(id event_type_id owner_id name subject message _active _del);
my $sel_cols = "a.id, a.event_type__id, a.usr__id, a.name, a.subject, " .
  "a.message, a.active, a.del, m.grp__id";
my @sel_props = (@props, 'grp_ids');
my $table = 'alert_type';
my $mem_table = 'member';
my $map_table = $table . "_$mem_table";

my %map = (id            => 'id',
           active        => 'active',
           event_type_id => 'event_type__id',
           owner_id      => 'usr__id');
my $meths;
my @ord = qw(name event_type_id owner_id subject message active);

my $safe = Safe->new;
# If new operators get added to Bric::Util::AlertType::Parts::Rule, use
# `perl -MOpcode=opdump -e opdump` to find their ops and add them here.
# XXX Add regcmaybe, regcreset, pushre, or regcomp?
$safe->permit_only(qw(seq sne sgt slt sle sge le match not lc padany lineseq
                      const leaveeval qr regcreset));

################################################################################

################################################################################
# Instance Fields
BEGIN {
    Bric::register_fields({
                         # Public Fields
                         id =>  Bric::FIELD_READ,
                         event_type_id => Bric::FIELD_RDWR,
                         owner_id => Bric::FIELD_RDWR,
                         name => Bric::FIELD_RDWR,
                         subject => Bric::FIELD_RDWR,
                         message => Bric::FIELD_RDWR,

                         # Private Fields
                         _rules => Bric::FIELD_NONE,
                         _usr => Bric::FIELD_NONE,
                         _new_usr => Bric::FIELD_NONE,
                         _del_usr => Bric::FIELD_NONE,
                         _grp => Bric::FIELD_NONE,
                         _new_grp => Bric::FIELD_NONE,
                         _del_grp => Bric::FIELD_NONE,
                         _active => Bric::FIELD_NONE,
                         _del => Bric::FIELD_NONE,
                         _et => Bric::FIELD_NONE,
                        });
}

################################################################################
# Class Methods
################################################################################

=head1 Interface

=head2 Constructors

=over 4

=item my $c = Bric::Util::AlertType->new

=item my $c = Bric::Util::AlertType->new($init)

Instantiates a Bric::Util::AlertType object. An anonymous hash of initial values
may be passed. The supported initial value keys are:

=over 4

=item *

event_type_id

=item *

owner_id

=item *

name

=item *

subject

=item *

message

=back

The active property will be set to true by default. Call $at->save() to save the
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
    $init->{_del} = 0;
    push @{$init->{grp_ids}}, INSTANCE_GROUP_ID;
    $self->SUPER::new($init);
}

################################################################################

=item my $c = Bric::Util::AlertType->lookup({ id => $id })

Looks up and instantiates a new Bric::Util::AlertType object based on the
Bric::Util::AlertType object ID passed. If $id is not found in the database,
lookup() returns undef.

B<Throws:>

=over

=item *

Too many Bric::Util::AlertType objects found.

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

B<Side Effects:> If $id is found, populates the new Bric::Util::AlertType object
with data from the database before returning it.

B<Notes:> NONE.

=cut

sub lookup {
    my $pkg = shift;
    my $at = $pkg->cache_lookup(@_);
    return $at if $at;

    $at = $get_em->($pkg, @_);
    # We want @$at to have only one value.
    throw_dp(error => 'Too many Bric::Util::AlertType objects found.')
      if @$at > 1;
    return @$at ? $at->[0] : undef;
}

################################################################################

=item my (@ats || $ats_aref) = Bric::Util::AlertType->list($params)

Returns a list or anonymous array of Bric::Util::AlertType objects based on the
search parameters passed via an anonymous hash. The supported lookup keys are:

=over 4

=item id

Alert type ID. May use C<ANY> for a list of possible values.

=item event_type_id

Event type ID. May use C<ANY> for a list of possible values.

=item owner_id

User id for user who owns alert types. May use C<ANY> for a list of possible
values.

=item name

Alert type name. May use C<ANY> for a list of possible values.

=item subject

Alert type subject. May use C<ANY> for a list of possible values.

=item message

Alert type message. May use C<ANY> for a list of possible values.

=item active

Boolean value indicating whether or not an alert type is active.

=item grp_id

ID of a Bric::Util::Grp with which alert types may be associated. May use
C<ANY> for a list of possible values.

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

B<Side Effects:> Populates each Bric::Util::AlertType object with data from the
database before returning them all.

B<Notes:> NONE.

=cut

sub list { wantarray ? @{ &$get_em(@_) } : &$get_em(@_) }

################################################################################

=back

=head2 Destructors

=over 4

=item $at->DESTROY

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

=item my (@at_ids || $at_ids_aref) = Bric::Util::AlertType->list_ids($params)

Returns a list or anonymous array of Bric::Util::AlertType object IDs based on the
search parameters passed via an anonymous hash. The supported lookup keys are
the same as those for list().

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

=item Bric::Util::AlertType->name_used($name, $user);

All Bric::Util::AlertType objects owned by a single user must have a unique name.
Different users can have alert types with the same name, but one user cannot
have two or more alerts with the same name.

This class method will check for the existence of a name/owner combination in
the database. If it returns true, then the owner will have to change or the name
will have to change before a new Bric::Util::AlertType object can be created with
those values. If it returns false (undef), then the name/owner combination is
available to be created.

B<Throws:>

=over 4

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=item *

Unable to select column into arrayref.

=back

B<Side Effects:> NONE.

B<Notes:> Also may be used as an instance method. See below.

=cut

sub name_used {
    my ($self, $name, $oid) = @_;
    my @params;
    my $where = '';
    if (ref $self && !$name) {
        my ($n, $o, $id) = $self->_get(qw(name owner_id id));
        @params = (lc($n), $o);
        if (defined $id) {
            push @params, $id;
            $where = 'AND id <> ?'
        }
    } else {
        @params = (lc($name), $oid);
    }

    my $sel = prepare_ca(qq{
        SELECT 1
        FROM   alert_type
        WHERE  LOWER(name) = ?
               AND usr__id = ?
               $where
    }, undef);

    return col_aref($sel, @params)->[0];
}

################################################################################

=item $meths = Bric::Util::AlertType->my_meths

=item (@meths || $meths_aref) = Bric::Util::AlertType->my_meths(TRUE)

=item my (@meths || $meths_aref) = Bric::Util::AlertType->my_meths(0, TRUE)

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
              name      => {
                             name     => 'name',
                             get_meth => sub { shift->get_name(@_) },
                             get_args => [],
                             set_meth => sub { shift->set_name(@_) },
                             set_args => [],
                             disp     => 'Name',
                             search   => 1,
                             len      => 64,
                             req      => 1,
                             type     => 'short',
                             props    => {   type       => 'text',
                                             length     => 32,
                                             maxlength => 64
                                         }
                            },
              event_type_id => {
                             name     => 'event_type_id',
                             get_meth => sub { shift->get_event_type_id(@_) },
                             get_args => [],
                             set_meth => sub { shift->set_event_type_id(@_) },
                             set_args => [],
                             disp     => 'Event Type',
                             len      => 10,
                             req      => 1,
                             type     => 'short',
                             props    => {   type       => 'text',
                                             length     => 10,
                                             maxlength => 10
                                         }
                            },
              owner_id   => {
                             name     => 'owner_id',
                             get_meth => sub { shift->get_owner_id(@_) },
                             get_args => [],
                             set_meth => sub { shift->set_owner_id(@_) },
                             set_args => [],
                             disp     => 'Owner ID',
                             len      => 10,
                             req      => 1,
                             type     => 'short',
                             props    => {   type       => 'text',
                                             length     => 10,
                                             maxlength => 10
                                         }
                            },
              subject      => {
                             name     => 'subject',
                             get_meth => sub { shift->get_subject(@_) },
                             get_args => [],
                             set_meth => sub { shift->set_subject(@_) },
                             set_args => [],
                             disp     => 'Subject',
                             search   => 1,
                             len      => 128,
                             req      => 0,
                             type     => 'short',
                             props    => { type      => 'text',
                                           length    => 32,
                                           maxlength => 128
                                         }
                            },
              message      => {
                             name     => 'message',
                             get_meth => sub { shift->get_message(@_) },
                             get_args => [],
                             set_meth => sub { shift->set_message(@_) },
                             set_args => [],
                             disp     => 'Message',
                             search   => 0,
                             len      => 512,
                             req      => 0,
                             type     => 'short',
                             props    => { type => 'textarea',
                                           cols => 40,
                                           rows => 4,
                                           maxlength => 512
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

=item my $id = $at->get_id

Returns the ID of the Bric::Util::AlertType object.

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

B<Notes:> If the Bric::Util::AlertType object has been instantiated via the new()
constructor and has not yet been C<save>d, the object will not yet have an ID,
so this method call will return undef.

=item my $name = $at->get_name

Returns the name of the Bric::Util::AlertType object.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'name' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $self = $at->name_used

Use this class method once you have set both the name and the owner of this
Bric::Util::AlertType object. It will return $self if the user already owns an
Bric::Util::AlertType object by that name, and undef if not.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=item *

Unable to select column into arrayref.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $self = $at->set_name($name)

Sets the name of the Bric::Util::AlertType object. Be sure to call $at->save if
you want the new name to stick. The maximum length of the name is 64 characters.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: WRITE access for field 'name' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $subect = $at->get_subject

Returns the Bric::Util::AlertType object's subject. This is the subject data that
will be parsed for variables, sent as individual alerts, and saved with the
alert in the database. See set_subject() for details on customizing the subject
for variable interpolation.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'subject' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $self = $at->set_subject($subject)

Sets the subject that will be sent in the subject field of alerts of this type.
The subject can up to 128 characters long, and can contain special variables
which will be evaluated when the alert is sent. The variables that are allowed
for a given type of alert are specified by the type of object on which the alert
is based, and can be retrieved from the Bric::Util::EventType object in question
via its get_alert_props() method.

The list of hashrefs returned from that method contain a "name" key and a
"description" key. Append a dollar sign ($) to the beginning of a name to
indicate a variable to be evaluated in a subject. For example, one common use
for this functionality is to see who triggered the event that in turn triggered
the alert. Thus, a subject might be something like:

  $trig_full_name Saved a Story

When the alert is sent and saved as a Bric::Util::Alert object in the database,
these variables will be evaluated and filled in with their underlying values:

  David Wheeler Saved a Story

I recommend that, at most, one or two variables be included, since the subject
of the alert should be short. Be sure to call $at->save if you have set a new
value via set_subject().

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: WRITE access for field 'subject' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $message = $at->get_message

Returns the Bric::Util::AlertType object's message. This is the message that will
be parsed for variables, sent as individual alerts, and saved with the alert in
the database. See set_message() for details on customizing the message for
variable interpolation.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'message' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $self = $at->set_message($message)

Sets the message that will be sent out in alerts of this type. The message can
up to 512 characters long, and can contain special variables which will be
evaluated when the alert is sent. The variables that are allowed for a given
type of alert are specified by the type of object on which the alert is based,
and can be retrieved from the Bric::Util::EventType object in question via its
get_alert_props() method.

The list of hashrefs returned from that method contain a "name" key and a
"description" key. Append a dollar sign ($) to the beginning of a name to
indicate a variable to be evaluated in a message. For example, one common use
for this functionality is to see who triggered the event that in turn triggered
the alert. Thus, a message might be something like:

  A story was saved and moved to the $desk by $trig_full_name <$trig_email>.

When the alert is sent and saved as a Bric::Util::Alert object in the database,
these variables will be evaluated and filled in with their underlying values:

  A story was saved and moved to the Publish Desk by David Wheeler
  <david@justatheory.com>.

Feel free to use as many variables as necessary (and as are available from
Bric::Util::EventType::get_alert_props()). Be sure to call $at->save if you have
set a new value via set_message().

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: WRITE access for field 'message' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $user = $at->get_owner

Returns the Bric::Biz::Person::User object representing the user who owns the
Bric::Util::AlertType object.

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

B<Notes:> Uses Bric::Biz::Person::User->lookup internally.

=cut

sub get_owner {
    my $self = shift;
    Bric::Biz::Person::User->lookup({ id => $self->_get('owner_id') });
}

=item my $owner_id = $at->get_owner_id

Returns the owner_id of the Bric::Biz::Person::User object representing the user who
owns this Bric::Util::AlertType object.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'owner_id' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $self = $at->set_owner_id($owner_id)

Sets the Bric::Biz::Person::User ID representing the user who owns the
Bric::Util::AlertType object.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: WRITE access for field 'owner_id' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $event = $at->get_event_type

Returns the Bric::Util::EventType object for which the Bric::Util::AlertType object
defines alerts.

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

=back

B<Side Effects:> NONE.

B<Notes:> Uses Bric::Util::EventType->lookup internally.

=cut

sub get_event_type {
    my $self = shift;
    my $et = $self->_get('_et');
    return $et if $et;
    $et = Bric::Util::EventType->lookup({ id => $self->_get('event_type_id') });
    $self->_set(['_et'], [$et]);
    return $et;
}

=item my $event_type_id = $at->get_event_type_id

Returns the ID of the Bric::Util::EventType object for which this
Bric::Util::AlertType is defined.

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

=item $self = $at->set_event_type_id($event_type_id)

Sets the Bric::Util::EventType ID representing the event type for which this
Bric::Util::AlertType object is defined.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: WRITE access for field 'event_type_id' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $self = $at->activate

Activate the alert type. When an alert type is active, it will be triggered
whenever its associated event has been triggered and all its rules met. A new
Bric::Util::AlertType object is active by default, so you don't need to call this
method unless you need to reactivate an existing Bric::Util::AlertType object that
has previously been deactivated (see below). Be sure to call $at->save to save
the change to the object.

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

=item $self = $at->deactivate

Deactivates the Bric::Util::AlertType object. Deactivated Bric::Util::AlertTypes
will not send alerts. Call $at->save to make the change persistent.

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

=item $self = $at->remove

Deletes the Bric::Util::AlertType object. Deleted alert types are still in the
database, however; their del status is simply marked 1 while their active status
is marked 0. So they can be manually recalled via SQL, and their individual
alerts and alerted records still exist. Call $at->save to make the change
persistent.

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

sub remove {
    my $self = shift;
    $self->_set( [qw(_active _del)],  [0, 1] );
}

=item $self = $at->is_active

Returns $self if the Bric::Util::AlertType object is active, and undef if it is
not.

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
    my $a = $self->_get('_active');
    return $self if $a && $a != -1;
}

################################################################################

################################################################################

=item my (@rules || $rules_aref) = $at->get_rules(@rule_ids)

  foreach my $rule ($at->get_rules) {
      print "Name:  ", $rule->get_attr, "\n";
      $rule->set_attr($new_attr_name);
      print "Value: ", $rule->get_value, "\n\n";
      $rule->set_value($new_value);
  }
  $at->save;

If called with no arguemnts, returns a list of all the
Bric::Util::AlertType::Parts::Rule objects associated with this
Bric::Util::AlertType object. If called with Bric::Util::AlertType::Parts::Rule
object IDs, it will return only those rules.

Rules are Bric::Util::AlertType::Parts::Rule objects, and are strictly associated
with a Bric::Util::AlertType object. They cannot be created or destroyed in any
other way. Indeed, if you make changes to the rule via its accessors, those
changes will only stick if you call $at->save on the Bric::Util::AlertType object
with which the rule is associated.

See Bric::Util::AlertType::Parts::Rule for its interface.

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

B<Notes:> Uses Bric::Util::AlertType::Parts::Rule and Bric::Util::Coll::Rule
internally.

=cut

sub get_rules {
    my $self = shift;
    my $rules = &$get_rules($self);
    $rules->get_objs(@_);
}

################################################################################

=item my $rule = $at->new_rule

=item my $rule = $at->new_rule($attr, $op, $value)

  $at->new_rule($attr, $op, $value);
  $at->save;

Creates a new rule associated with this Bric::Util::AlertType object. You can pass
in a list of values for the rule in this order--attribute, operator, value--and
the rule will be complete. Or you can call new_rule() with no arguments, and
then use the Bric::Util::AlertType::Parts::Rule accessor methods to set these
values. Be sure to call $at->save whenever you want changes to the rule to
stick.

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

sub new_rule {
    my ($self, $attr, $op, $value) = @_;
    my $rules = &$get_rules($self);
    $rules->new_obj({ attr => $attr, operator => $op, value => $value,
                      alert_type_id => $self->_get('id') });
}

################################################################################

=item $self = $at->del_rules(@rule_ids)

  $at->del_rules();
  $at->save;

Deletes a rules from the object, and will delete them from the database once
$at->save has been called. The arguments may consist of a simple list of all the
IDs of Bric::Util::AlertType::Parts::Rule objects to be deleted. If called with no
arguments, all of the rules asscociated with $at will be deleted. Be sure to
call $at->save to save your changes.

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

sub del_rules {
    my $self = shift;
    my $rules = &$get_rules($self);
    $rules->del_objs(@_);
}

################################################################################

=item my (@uids || $uids_aref) = $at->get_user_ids($cont_type_id)

Returns a list or an anonymous array of Bric::Biz::Person::User object IDs that
represent the users who will receive alerts of this type. This list does not
include users in a group associated with an alert (see below). If any
Bric::Biz::Contact type names are passed as arguments, only those users who will be
notified of this type of alert by that method will be returned. To get a list of
available contact types, call Bric::Biz::Contact->list_alertable_types().

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

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

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_user_ids {
    my ($self, @ctypes) = @_;
    my $users = &$get_cont($self, '_usr');

    # We're either getting user IDs for the contact types passes in, or for
    # all of the contact types.
    @ctypes = keys %$users unless @ctypes;

    # Return the Bric::Biz::Person::User object IDs.
    return wantarray ? map { keys %{ $users->{$_} } } @ctypes
      : [ map { keys %{ $users->{$_} } } @ctypes ];
}

################################################################################

=item my (@users || $users_aref) = $at->get_users(@cids)

Returns a list or an anonymous array of Bric::Biz::Person::User objects that
represent the users who will receive this alert. This list does not include
users in a group associated with an alert (see below). If Bric::Biz::Contact type
names are passed as an arguments, only those users who will be notified of this
type of alert by that method will be returned. To get a list of available
contact types, call Bric::Biz::Contact->list_alertable_types().

B<Throws:>

=over 4

=item *

Too many Bric::Biz::Person::User objects found.

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

B<Notes:> Uses get_user_ids() and Bric::Biz::Person::User->lookup() internally.

=cut

sub get_users {
    return wantarray ? map { Bric::Biz::Person::User->lookup({ id => $_}) }
      get_user_ids(@_) : [ map { Bric::Biz::Person::User->lookup({ id => $_}) }
                          get_user_ids(@_) ];
}

################################################################################

=item $at->add_users($contact_type, @users)

  $at->add_users($contact_type, $user1, $user2);
  $at->save;

This method tells the Bric::Util::AlertMethod object which users to alert via a
given contact type when an alert it sent. The first argument must be a
Bric::Biz::Contact type, and the remaining arguments may be Bric::Biz::Person::User
objects or IDs. All users B<must> be associated with a contact type. Be sure to
call $at->save to save your changes. To get a list of available contact types,
call Bric::Biz::Contact->list_alertable_types().

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

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

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub add_users {
    my ($self, $ctype, @users) = @_;
    my $users = &$get_cont($_[0], '_usr');   # Get the current users.
    my $new_users = $self->_get('_new_usr'); # Get the new users.
    foreach my $u (@users) {
        # May want to throw an exception of $u is not an ID or User object.
        my $id = ref $u ? $u->get_id : $u;
        next if $users->{$ctype}{$id};
        $users->{$ctype}{$id} = 1;
        push @{ $new_users->{$ctype} }, $id
    }
    return $self;
}

################################################################################

=item $self = $at->del_users($contact_type, @users)

This method dissociates individual users from the Bric::Util::AlertType object.
These contacts will no longer receive alerts sent via $contact_type, although
they may continue to receive alerts if they are associated with different
contact types for this alert alerting. Be sure to call $at->save to save your
changes. To get a list of available contact types, call
Bric::Biz::Contact->list_alertable_types().

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

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

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub del_users {
    my ($self, $ctype, @users) = @_;
    my $users = &$get_cont($_[0], '_usr');   # Get the current users.
    my $del_users = $self->_get('_del_usr'); # Get the delete users.
    @users = keys %$users unless @users;
    foreach my $u (@users) {
        # May want to throw an exception of $u is not an ID or User object.
        my $id = ref $u ? $u->get_id : $u;
        next unless $users->{$ctype}{$id};
        delete $users->{$ctype}{$id};
        push @{ $del_users->{$ctype} }, $id
    }
    return $self;
}

################################################################################

=item my (@gids || $gids_aref) = $at->get_group_ids(@contact_types)

Returns a list or an anonymous array of Bric::Util::Grp::User object IDs
representing groups of users to whom alerts of this type will be sent via the
contact types passed as arguments. If @contact_types are not passed, all the
Bric::Util::Grp::User object IDs associated with this Bric::Util::AlertType object
will be returned. To get a list of available contact types, call
Bric::Biz::Contact->list_alertable_types().

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

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

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_group_ids {
    my ($self, @ctypes) = @_;
    my $groups = &$get_cont($self, '_grp');

    # We're either getting group IDs for the contact types passe in, or for
    # all of the contact types.
    @ctypes = keys %$groups unless @ctypes;

    # Return the Bric::Util::Group::User object IDs.
    return wantarray ? map { keys %{ $groups->{$_} } } @ctypes
      : [ map { keys %{ $groups->{$_} } } @ctypes ];
}

################################################################################

=item my (@groups || $groups_aref) = $at->get_groups(@cids)

Returns a list or an anonymous array of Bric::Util::Grp::User objects that
represent the groups who will receive this alert. If any Bric::Biz::Contact type
names are passed as an arguments, only those groups who will be notified of this
type of alert by that contct type will be returned. To get a list of available
contact types, call Bric::Biz::Contact->list_alertable_types().

B<Throws:>

=over 4

=item *

Too many Bric::Util::Grp::User objects found.

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

B<Notes:> Uses get_user_ids() and Bric::Biz::Person::User->lookup() internally.

=cut

sub get_groups {
    return wantarray ? map { Bric::Util::Grp::User->lookup({ id => $_}) }
      get_group_ids(@_) : [ map { Bric::Util::Grp::User->lookup({ id => $_}) }
                          get_group_ids(@_) ];
}

################################################################################

=item $self = $at->add_groups($contact_type, @groups)

  $at->add_grps($contact_type, $gid1, $gid2);
  $at->save;

This method tells the Bric::Util::AlertMethod object which groups of users to
alert via $contact_type when an alert it sent. The first argument must be a
Bric::Biz::Contact type, and the remaining arguments must be Bric::Util::Grp::User
objects or IDs. All groups I<must> be associated with a contact type. Be sure to
call $at->save to save your changes. To get a list of available contact types,
call Bric::Biz::Contact->list_alertable_types().

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

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

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub add_groups {
    my ($self, $ctype, @groups) = @_;
    my $groups = &$get_cont($_[0], '_grp');   # Get the current groups.
    my $new_groups = $self->_get('_new_grp'); # Get the new groups.
    foreach my $g (@groups) {
        # May want to throw an exception of $g is not an ID or Group object.
        my $id = ref $g ? $g->get_id : $g;
        next if $groups->{$ctype}{$id};
        $groups->{$ctype}{$id} = 1;
        push @{ $new_groups->{$ctype} }, $id
    }
    return $self;
}

################################################################################

=item $self = $at->del_groups($contact_type, @grps)

This method dissociates Bric::Util::Grp::User objects from the Bric::Util::AlertType
object. The users in these groups will no longer receive alerts sent via
$contact_type, although they may continue to receive alerts if they are
associated with different contact types. Be sure to call $at->save to save your
changes. To get a list of available contact types, call
Bric::Biz::Contact->list_alertable_types().

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

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

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub del_groups {
    my ($self, $ctype, @groups) = @_;
    my $groups = &$get_cont($_[0], '_grp');   # Get the current groups.
    my $del_groups = $self->_get('_del_grp'); # Get the delete groups.
    @groups = keys %$groups unless @groups;
    foreach my $g (@groups) {
        # May want to throw an exception of $g is not an ID or Group object.
        my $id = ref $g ? $g->get_id : $g;
        next unless $groups->{$ctype}{$id};
        delete $groups->{$ctype}{$id};
        push @{ $del_groups->{$ctype} }, $id
    }
    return $self;
}

################################################################################

=item $self = $at->save

Saves all the changes to the Bric::Util::AlertType object to the database. This
includes all simple properties, all rules, and all contacts and groups. This is
the method to call if you've changed anything about your alert type and want it
to stay changed. Returns $self on success and undef on failure.

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

    my ($r, $id) = $self->_get(qw(_rules id));
    my $dirt = $self->_get__dirty;
    my $new_id;

    unless (defined $id) {
        # It's a new alert type. Insert it.
        local $" = ', ';
        my $fields = join ', ', next_key('alert_type'), ('?') x $#cols;
        my $ins = prepare_c(qq{
            INSERT INTO alert_type (@cols)
            VALUES ($fields)
        }, undef);
        # Don't try to set ID - it will fail!
        execute($ins, $self->_get(@props[1..$#props]));
        # Now grab the ID.
        $new_id = $id = last_key('alert_type');
        $self->_set({id => $id});
        # Register this alert type with its mates.
        $self->register_instance;
        $self->SUPER::save;
    } elsif ($dirt) {
        # It's an existing alert type that has been changed. Update it.
        local $" = ' = ?, '; # Simple way to create placeholders with an array.
        my $upd = prepare_c(qq{
            UPDATE alert_type
            SET    @cols = ?
            WHERE  id = ?
        }, undef);
        execute($upd, $self->_get(@props), $id);
        $self->SUPER::save;
        unless ($self->_get('active')) {
            # Deactivate all group memberships if we've deactivated the at.
            foreach my $grp (Bric::Util::Grp::AlertType->list
                             ({ obj => $self, permanent => 0 })) {
                foreach my $mem ($grp->has_member({ obj => $self })) {
                    next unless $mem;
                    $mem->deactivate;
                    $mem->save;
                }
            }
        }
    }

    # Now that we're sure we have an ID, save all changes to rules and contacts.
    &$upd_cont($self);
    if ($r) {
        my $rules = $r;
        $rules->save($new_id);
    }

    return $self;
}

################################################################################

=item $self = $at->send_alerts($args)

This method will evaluate whether this type of alert's rules are true when
compared to the properties of the event and its associated Bricolage object. If so, it
will send all necessary alerts. You will not normally need to call this method -
it is called internally when a new event is logged via
Bric::Util::EventType->log_event() or Bric::Util::Event->new(). The anonymous hash
argument rquires the following keys:

=over 4

=item *

event - The Bric::Util::Event object for which the alerts are to be sent.

=item *

attr - The attributes of the Bric::Util::Event object.

=item *

obj - The Bricolage object for which the event was created.

=item *

user - The Bric::Biz::Person::User object representing the person who triggered the
alert.

=back

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

sub send_alerts {
    # Here's where we decide whether to send an alert.
    my ($self, $args) = @_;
    my ($obj, $event, $user, $e_attr) = @{$args}{qw(obj event user attr)};

    # For accessing data on the user who triggered the event and this alert.
    my $tmeths = Bric::Util::EventType->my_trig_meths;

    # For accessing data on the oject of the alert.
    my $omeths = $obj->my_meths;

    # For accessing data on the event itself.
    if ($e_attr && !$e_attr->{__SEEN__}) {
        for my $k (keys %$e_attr) {
            (my $v = lc $k) =~ s/\W+/_/g;
            $e_attr->{lc "et_$v"} = delete $e_attr->{$k};
        }
        $e_attr->{__SEEN__} = 1;
    }

    foreach my $rule ($self->get_rules) {
        # String naming the data to grab.
        my $attr = $rule->get_attr;

        # How to look it up in the Bric::Biz::User::Person object representing the
        # user who triggered the event and alerts.
        my ($tmeth, $targs) = $tmeths->{$attr} ?
          @{$tmeths->{$attr}}{'get_meth', 'get_args'} : ();

        # How to look it up in the object of the alert.
        my ($ometh, $oargs) = $omeths->{$attr} ?
          @{$omeths->{$attr}}{'get_meth', 'get_args'} : ();

        # Perl-style switch statement, since the value can be in one of three
        # different places.
        my $value = do {
            if ($tmeth) {
                # In the user who triggered the event.
                &$tmeth($user, @$targs);
            } elsif ($e_attr && exists $e_attr->{$attr}) {
                # In the event itself.
                $e_attr->{$attr};
            } elsif ($ometh){
                # Or in the object for which the event was logged.
                &$ometh($obj, @$oargs);
            } else {
                # There is no value.
                undef;
            }
        };

        # Here we check to see if the rule is true. The comparison, whether
        # direct or via a regular expression, is case-insensitive.
        my $op = $rule->get_operator;
        my $chk = $rule->get_value;
        # Perform a regular expression or simple comparison.
        my $code = $op eq '=~' || $op eq '!~'
          ? qq{q[$value] $op qr[$chk]}
          : qq{lc q[$chk] $op lc q[$value]};
        unless ($safe->reval($code)) {
            # Just return if there's no error.
            my $err = $@ or return;
            # Yow! An exception. Someone is trying to do something naughty!
            throw_dp error   => "Invalid alert rule",
                     payload => $err;
        }
    }

    # If we're here, send out alerts!
    Bric::Util::Alert->new({ at => $self, obj => $obj,
                           user => $user, event => $event });
}

=back

=head1 Private

=head2 Private Class Methods

NONE.

=head2 Private Instance Methods

NONE.

=head2 Private Functions

=over 4

=item my $ats_aref = &$get_em( $pkg, $params )

=item my $ats_ids_aref = &$get_em( $pkg, $params, 1 )

Function used by lookup() and list() to return a list of Bric::Util::AlertType
objects or, if called with an optional third argument, returns a listof
Bric::Util::AlertType object IDs (used by list_ids()).

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
    my ($pkg, $params, $ids) = @_;
    my $tables = "$table a, $mem_table m, $map_table c";
    my @wheres = ('a.id = c.object_id','c.member__id = m.id',
                  "m.active = '1'");
    push @wheres, "a.del = '0'" unless exists $params->{id};

    my @params;
    while (my ($k, $v) = each %$params) {
        if ($map{$k}) {
            push @wheres, any_where $v, "a.$map{$k} = ?", \@params;
        } elsif ($k eq 'grp_id') {
            # Fancy-schmancy second join.
            $tables .= ", $mem_table m2, $map_table c2";
            push @wheres, (
                'a.id = c2.object_id',
                'c2.member__id = m2.id',
                "m2.active = '1'",
                any_where $v, 'm2.grp__id = ?', \@params
            );
        } else {
            push @wheres, any_where $v, "LOWER(a.$k) LIKE LOWER(?)", \@params;
        }
    }

    # Create the where clause and the select columns.
    my $where = join ' AND ', @wheres;
    my ($qry_cols, $order) = $ids ? (\'DISTINCT a.id', 'a.id') :
      (\$sel_cols, 'a.name, a.usr__id, a.event_type__id');

    my $sel = prepare_c(qq{
        SELECT $$qry_cols
        FROM   $tables
        WHERE  $where
        ORDER BY $order
    }, undef);

    # Just return the IDs, if they're what's wanted.
    return col_aref($sel, @params) if $ids;

    execute($sel, @params);
    my (@d, @ats, $grp_ids);
    bind_columns($sel, \@d[0..$#sel_props]);
    $pkg = ref $pkg || $pkg;
    my $last = -1;
    while (fetch($sel)) {
        if ($d[0] != $last) {
            $last = $d[0];
            # Create a new alert type object.
            my $self = bless {}, $pkg;
            $self->SUPER::new;
            $grp_ids = $d[$#d] = [$d[$#d]];
            $self->_set(\@sel_props, \@d);
            $self->_set__dirty; # Disable the dirty flag.
            push @ats, $self
        } else {
            # Append the ID.
            push @$grp_ids, $d[$#d];
        }
    }
    return \@ats;
};

=item my $rules = &$get_rules($self)

Returns the collection of rules for this alert type. The collection is a
Bric::Util::Coll::Rule object. See that class and its parent, Bric::Util::Coll, for
interface details.

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

$get_rules = sub {
    my $self = shift;
    my ($id, $rules) = $self->_get('id', '_rules');
    return $rules if $rules;
    $rules = Bric::Util::Coll::Rule->new
      ( defined $id ? { alert_type_id => $id } : undef );
    my $dirt = $self->_get__dirty;
    $self->_set(['_rules'], [$rules]);
    $self->_set__dirty($dirt); # Reset the dirty flag.
    return $rules;
};

=item my $cont = &$get_cont($self)

Loads user and group contacts. It is called first thing when any user
or group contact method is called.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

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

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

$get_cont = sub {
    my ($self, $get_cat) = @_;

    # Get the existing contacts and return one if it exists.
    my %ret;
    @ret{qw(_usr _grp __id__)} = $self->_get(qw(_usr _grp id));
    return $ret{$get_cat} if $ret{$get_cat};

    # If we get here, we need to load all the contacts.
    my $cont;
    foreach my $cat ('usr', 'grp') { # Get both contact and group data.
        # Ensure there are at least empty hashrefs.
        @{$cont}{"_$cat", "_new_$cat", "_del_$cat"} = ({}, {}, {});
        my $sel = prepare_c(qq{
            SELECT c.type, a.${cat}__id
            FROM   alert_type__${cat}__contact a, contact c
            WHERE  a.contact__id = c.id
                   AND a.alert_type__id = ?
        }, undef);

        execute($sel, $ret{__id__});
        my ($ctype, $id);
        bind_columns($sel, \$ctype, \$id);
        # Associate the contact with the contact_type.
        while (fetch($sel)) { $cont->{"_$cat"}{$ctype}{$id} = 1 }
        finish($sel);
    }
    $self->_set($cont);
    return $cont->{$get_cat} if $get_cat;
};

=item $bool = &$upd_cont($self)

Saves any changes to the user and group contacts for this alert type. Called
by save().

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

Incorrect number of args to _set.

=item *

Bric::_set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

$upd_cont = sub {
    my $self = shift;
    my %cont;
    @cont{qw(dusr nusr dgrp ngrp id)} =
      $self->_get(qw(_del_usr _new_usr _del_grp _new_grp id));

    foreach my $cat ('usr', 'grp') { # Do it for both users and groups.
        my $key = "d$cat";
        # Delete existing contacts, first.
        if (my @ctypes = keys %{ $cont{$key} }) {
            my $del = prepare_c(qq{
                DELETE FROM alert_type__${cat}__contact
                WHERE  alert_type__id = ?
                       AND ${cat}__id = ?
                       AND contact__id = (
                           SELECT id
                           FROM   contact
                           WHERE  type = ?
                       )
            }, undef);

            foreach my $ctype (@ctypes) { # For each contact type.
                # Delete the record.
                execute($del, $cont{id}, $_, $ctype) for @{ $cont{$key}->{$ctype} };
            }
        }

        $key = "n$cat";
        # Now add new contacts.
        if (my @ctypes = keys %{ $cont{$key} }) {
            my $ins = prepare_c(qq{
                INSERT INTO alert_type__${cat}__contact
                            (alert_type__id, ${cat}__id, contact__id)
                VALUES (?, ?, (
                           SELECT id
                           FROM   contact
                           WHERE  type = ?
                        ))
            }, undef);

            foreach my $ctype (@ctypes) { # For each contact type.
                # Insert the new record.
                execute($ins, $cont{id}, $_, $ctype) for @{ $cont{$key}->{$ctype} };
            }
        }

        # Now reset the new and del caches.
        $self->_set(["_del_$cat", "_new_$cat"], [{}, {}]);
    }
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
L<Bric::Util::Alert|Bric::Util::Alert>,
L<Bric::Util::EventType|Bric::Util::EventType>,
L<Bric::Util::Event|Bric::Util::Event>

=cut
