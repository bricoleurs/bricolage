package Bric::Biz::InputChannel;
###############################################################################

=head1 NAME

Bric::Biz::InputChannel - Bricolage Input Channels.

=head1 VERSION

$LastChangedRevision$

=cut

require Bric; our $VERSION = Bric->VERSION;

=head1 DATE

$LastChangedDate: 2005-10-10 03:15:55 -0400 (Mon, 10 Oct 2005) $

=head1 SYNOPSIS

  use Bric::Biz::InputChannel;

  # Constructors.
  $ic = Bric::Biz::InputChannel->new($init);
  $ic = Bric::Biz::InputChannel->lookup({ id => $id});
  my $ics_aref = Bric::Biz::InputChannel->list($params);
  my @ics = Bric::Biz::InputChannel->list($params);

  # Class Methods.
  my $id_aref = Bric::Biz::InputChannel->list_ids($params);
  my @ids = Bric::Biz::InputChannel->list_ids($params);

  # Instance Methods.
  $id = $ic->get_id;
  my $name = $ic->get_name;
  $ic = $ic->set_name( $name );
  my $description = $ic->get_description;
  $ic = $ic->set_description($description);
  if ($ic->get_primary) { # do stuff }
  $ic = $ic->set_primary(1); # or pass undef.
  my $site_id = $ic->get_site_id;
  $site = $site->set_site_id($site_id);

  # Active instance methods.
  $ic = $ic->activate;
  $ic = $ic->deactivate;
  $ic = $ic->is_active;

  # Persistence methods.
  $ic = $ic->save;

=head1 DESCRIPTION

Holds information about the input channels that will be associated with
templates and elements.

=cut

#==============================================================================
## Dependencies                        #
#======================================#

#--------------------------------------#
# Standard Dependencies.
use strict;

#--------------------------------------#
# Programatic Dependencies.
use Bric::Util::DBI qw(:all);
use Bric::Util::Grp::InputChannel;
use Bric::Util::Fault qw(throw_gen throw_dp);
use List::Util 'first';

#==============================================================================
## Inheritance                         #
#======================================#
use base qw(Bric);

#=============================================================================
## Function Prototypes                 #
#======================================#
my ($parse_uri_format);

#==============================================================================
## Constants                           #
#======================================#

use constant DEBUG => 0;
use constant HAS_MULTISITE => 1;
use constant INSTANCE_GROUP_ID => 69;
use constant GROUP_PACKAGE => 'Bric::Util::Grp::InputChannel';

#==============================================================================
## Fields                              #
#======================================#

#--------------------------------------#
# Public Class Fields
# None.

#--------------------------------------#
# Private Class Fields
my $METHS;

my $TABLE = 'input_channel';
my $SEL_TABLES = "$TABLE ic, member m, input_channel_member sm";
my $SEL_WHERES = 'ic.id = sm.object_id AND sm.member__id = m.id ' .
  "AND m.active = '1'";
my $SEL_ORDER = 'ic.name, ic.id';

my @COLS = qw(name description site__id active);

my @PROPS = qw(name description site_id _active);

my $SEL_COLS = 'ic.id, ic.name, ic.description, ic.site__id, ic.active, m.grp__id';
my @SEL_PROPS = ('id', @PROPS, 'grp_ids');

my @ORD = qw(name description site_id active);
my $GRP_ID_IDX = $#SEL_PROPS;

# These are provided for the InputChannel::Element subclass to take
# advantage of.
sub SEL_PROPS  { @SEL_PROPS }
sub SEL_COLS   { $SEL_COLS }
sub SEL_TABLES { $SEL_TABLES }
sub SEL_WHERES { $SEL_WHERES }
sub SEL_ORDER  { $SEL_ORDER }
sub GRP_ID_IDX { $GRP_ID_IDX }

#--------------------------------------#
# Instance Fields

# This method of Bricolage will call 'use fields' for you and set some permissions.
BEGIN {
    Bric::register_fields(
      {
       # Public Fields
       # The human readable name field
       'name'                  => Bric::FIELD_RDWR,

       # The human readable description field
       'description'           => Bric::FIELD_RDWR,

       # What site this IC is part of
       'site_id'               => Bric::FIELD_RDWR,

       # The data base id
       'id'                   => Bric::FIELD_READ,

       # Group IDs.
       'grp_ids'               => Bric::FIELD_READ,

       # Private Fileds
       # The active flag
       '_active'               => Bric::FIELD_NONE,

      });
}

#==============================================================================
## Interface Methods                   #
#======================================#

=head1 PUBLIC INTERFACE

=head2 Public Constructors

=over 4

=item $ic = Bric::Biz::InputChannel->new( $initial_state )

Instantiates a Bric::Biz::InputChannel object. An anonymous hash of initial
values may be passed. The supported initial value keys are:

=over 4

=item *

name

=item *

site_id

=item *

description

=item *

active (default is active, pass undef to make a new inactive Input Channel)

=back

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub new {
    my ($class, $init) = @_;
    $init->{_active} = exists $init->{active} ? delete $init->{active} : 1;
    push @{$init->{grp_ids}}, INSTANCE_GROUP_ID;
    return $class->SUPER::new($init);
}

##############################################################################

=item $ic = Bric::Biz::InputChannel->lookup({ id => $id })

=item $ic = Bric::Biz::InputChannel->lookup({ name => $name, site_id => $id})

Looks up and instantiates a new Bric::Biz::InputChannel object based on an
Bric::Biz::InputChannel object ID or name. If no input channelobject is
found in the database, C<lookup()> returns C<undef>.

B<Throws:>

=over 4

=item *

Missing required parameter 'id' or 'name'/'site_id'.

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

sub lookup {
    my ($class, $params) = @_;
    throw_gen(error => "Missing required parameter 'id' or 'name'/'site_id'")
      unless $params->{id} or ($params->{name} and $params->{site_id});

    my $ic = $class->cache_lookup($params);
    return $ic if $ic;

    $ic = $class->_do_list($params);

    # We want @$person to have only one value.
    throw_dp(error => 'Too many Bric::Biz::InputChannel objects found.')
      if @$ic > 1;
    return @$ic ? $ic->[0] : undef;
}

=item ($ics_aref || @ics) = Bric::Biz::InputChannel->list( $criteria )

Returns a list or anonymous array of Bric::Biz::InputChannel objects based on
the search parameters passed via an anonymous hash. The supported lookup keys
are:

=over 4

=item id

Input channel ID. May use C<ANY> for a list of possible values.

=item name

The name of the input channel. May use C<ANY> for a list of possible values.

=item description

Description of the input channel. May use C<ANY> for a list of possible
values.

=item site_id

The ID of the Bric::Biz::Site object with which the input channel is
associated. May use C<ANY> for a list of possible values.

=item story_version_id

The ID of a story with which input channels may be associated. May use C<ANY>
for a list of possible values.

=item media_version_id

The ID of a media document with which input channels may be associated. May
use C<ANY> for a list of possible values.

=item active

A boolean indicating whether or not an input channel is active.

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

sub list {
    my ($class, $params) = @_;
    _do_list($class, $params, undef);
}

=item $ics_href = Bric::Biz::InputChannel->href( $criteria )

Returns an anonymous hash of Input Channel objects, where each hash key is an
Input Channel ID, and each value is Input Channel object that corresponds to
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
    my ($class, $params) = @_;
    _do_list($class, $params, undef, 1);
}

#--------------------------------------#

=back

=head2 Destructors

=over 4

=item $self->DESTROY

Dummy method to prevent wasting time trying to AUTOLOAD DESTROY.

=cut

sub DESTROY {
    # empty for now
}

#--------------------------------------#

=back

=head2 Public Class Methods

=over 4

=item ($id_aref || @ids) = Bric::Biz::InputChannel->list_ids( $criteria )

Returns a list or anonymous array of Bric::Biz::InputChannel object IDs based
on the search criteria passed via an anonymous hash. The supported lookup keys
are the same as for list().

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

sub list_ids {
    my ($class, $params) = @_;
    _do_list($class, $params, 1);
}

##############################################################################

=item my $meths = Bric::Biz::InputChannel->my_meths

=item my (@meths || $meths_aref) = Bric::Biz::InputChannel->my_meths(TRUE)

=item my (@meths || $meths_aref) = Bric::Biz::InputChannel->my_meths(0, TRUE)

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

    # Create 'em if we haven't got 'em.
    $METHS ||= {
              name        => {
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
                              props    => {   type      => 'text',
                                              length    => 32,
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
              site_id     => {
                              get_meth => sub { shift->get_site_id(@_) },
                              get_args => [],
                              set_meth => sub { shift->set_site_id(@_) },
                              set_args => [],
                              name     => 'site_id',
                              disp     => 'Site',
                              len      => 10,
                              req      => 1,
                              type     => 'short',
                              props    => {}
                             },
              site        => {
                              name     => 'site',
                              get_meth => sub { my $s = Bric::Biz::Site->lookup
                                                  ({ id => shift->get_site_id })
                                                  or return;
                                                $s->get_name;
                                            },
                              disp     => 'Site',
                              type     => 'short',
                              req      => 0,
                              props    => { type       => 'text',
                                            length     => 10,
                                            maxlength  => 10
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

    if ($ord) {
        return wantarray ? @{$METHS}{@ORD} : [@{$METHS}{@ORD}];
    } elsif ($ident) {
        return wantarray ? $METHS->{name} : [$METHS->{name}];
    } else {
        return $METHS;
    }
}

#--------------------------------------#

=back

=head2 Public Instance Methods

=over 4

=item $id = $ic->get_id

Returns the InputChannel's unique ID.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $ic = $ic->set_name( $name )

Sets the name of the Input Channel.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $name = $ic->get_name()

Returns the name of the Input Channel.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $ic = $ic->set_description( $description )

Sets the description of the Input Channel.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $description = $ic->get_description()

Returns the description of the Input Channel.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $id = $ic->get_site_id()

Returns the ID of the site this IC is a part of

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $id = $ic->set_site_id($id)

Set the ID this IC should be a part of

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

##############################################################################

=item $self = $ic->activate

Activates the Bric::Biz::InputChannel object. Call $ic->save to make the change
persistent. Bric::Biz::InputChannel objects instantiated by new() are active by
default.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub activate { $_[0]->_set({_active => 1 }) }

##############################################################################

=item $self = $ic->deactivate

Deactivates (deletes) the Bric::Biz::InputChannel object. Call $ic->save to
make the change persistent.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub deactivate { $_[0]->_set({_active => 0 }) }

##############################################################################

=item $self = $ic->is_active

Returns $self (true) if the Bric::Biz::InputChannel object is active, and undef
(false) if it is not.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub is_active { $_[0]->_get('_active') ? $_[0] : undef }

##############################################################################

=item $self = $ic->save

Saves any changes to the Bric::Biz::InputChannel object. Returns $self on
success and undef on failure.

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
    my ($self) = @_;
    return $self unless $self->_get__dirty;
    my $id = $self->_get('id');
    defined $id ? $self->_do_update($id) : $self->_do_insert;
    $self->SUPER::save();
}

##############################################################################

=back

=head1 PRIVATE

=head2 Private Class Methods

=over 4

=item _do_list

Called by list and list ids this does the brunt of their work.

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

sub _do_list {
    my ($pkg, $params, $ids, $href) = @_;
    my $tables = $pkg->SEL_TABLES;
    my $wheres = $pkg->SEL_WHERES;
    my @params;
    while (my ($k, $v) = each %$params) {
        if ($k eq 'id') {
            # Simple numeric comparison.
            $wheres .= ' AND ' . any_where $v, "ic.$k = ?", \@params;
        } elsif ($k eq 'active') {
            # Simple boolean comparison.
            $wheres .= " AND ic.$k = ?";
            push @params, $v ? 1 : 0;
        } elsif ($k eq 'grp_id') {
            # Add in the group tables a second time and join to them.
            $tables .= ", member m2, input_channel_member c2";
            $wheres .= " AND ic.id = c2.object_id AND c2.member__id = m2.id"
              . " AND m2.active = '1' AND "
              . any_where $v, 'm2.grp__id = ?', \@params;
        } elsif ($k eq 'story_version_id') {
            # Join in the story__input_channel table.
            $tables .= ', story__input_channel sic';
            $wheres .= ' AND ic.id = sic.input_channel__id AND '
              . any_where $v, 'sic.story_version__id = ?', \@params;
        } elsif ($k eq 'media_version_id') {
            # Join in the media__input_channel table.
            $tables .= ', media__input_channel mic';
            $wheres .= ' AND ic.id = mic.input_channel__id AND '
              . any_where $v, 'mic.media_version__id = ?', \@params;
        } elsif ($k eq 'site_id') {
            $wheres .= ' AND ' . any_where $v, 'ic.site__id = ?', \@params;
        } else {
            # Simple string comparison!
            $wheres .= ' AND '
                    . any_where $v, "LOWER(ic.$k) LIKE LOWER(?)", \@params;
        }
    }

    my @sel_props = $pkg->SEL_PROPS;
    my $sel_cols = $pkg->SEL_COLS;
    my $sel_order = $pkg->SEL_ORDER;
    my ($order, $props, $qry_cols) = ($sel_order, \@sel_props, \$sel_cols);
    if ($ids) {
        $qry_cols = \'DISTINCT ic.id';
        $order = 'ic.id';
    } # Else nothing!

    # Assemble and prepare the query.
    my $sel = prepare_c(qq{
        SELECT $$qry_cols
        FROM   $tables
        WHERE  $wheres
        ORDER BY $order
    }, undef);

    # Just return the IDs, if they're what's wanted.
    return wantarray ? @{ col_aref($sel, @params) } : col_aref($sel, @params)
      if $ids;

    # Grab all the records.
    execute($sel, @params);
    my (@d, @ics, %ics, $grp_ids);
    bind_columns($sel, \@d[0..$#$props]);
    my $last = -1;
    $pkg = ref $pkg || $pkg;
    my $grp_id_idx = $pkg->GRP_ID_IDX;
    while (fetch($sel)) {
        if ($d[0] != $last) {
            $last = $d[0];
            # Create a new server type object.
            my $self = bless {}, $pkg;
            $self->SUPER::new;
            # Get a reference to the array of group IDs.
            $grp_ids = $d[$GRP_ID_IDX] = [$d[$GRP_ID_IDX]];
            $self->_set($props, \@d);
            $self->_set__dirty; # Disables dirty flag.
            $href ? $ics{$d[0]} = $self->cache_me :
              push @ics, $self->cache_me;
        } else {
            push @$grp_ids, $d[$GRP_ID_IDX];
        }
    }
    # Return the objects.
    return $href ? \%ics : wantarray ? @ics : \@ics;
}

##############################################################################

=back

=head2 Private Instance Methods

=over 4

=item _do_update()

Will perform the update to the database after being called from save.

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

sub _do_update {
    my ($self, $id) = @_;
    local $" = ' = ?, '; # Simple way to create placeholders with an array.
    my $upd = prepare_c(qq{
        UPDATE $TABLE
        SET    @COLS = ?
        WHERE  id = ?
    }, undef);
    execute($upd, $self->_get(@PROPS), $id);
    return $self;
}

##############################################################################

=item _do_insert

Will do the insert to the database after being called by save

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

sub _do_insert {
    my ($self) = @_;

    local $" = ', ';
    my $fields = join ', ', next_key('input_channel'), ('?') x @COLS;
    my $ins = prepare_c(qq{
        INSERT INTO input_channel (id, @COLS)
        VALUES ($fields)
    }, undef);
    execute($ins, $self->_get( @PROPS ) );
    $self->_set( { 'id' => last_key($TABLE) } );
    $self->register_instance(INSTANCE_GROUP_ID, GROUP_PACKAGE);
    return $self;
}

##############################################################################

=back

=head2 Private Functions

=over 4

=item my $uri_format = $parse_uri_format->($name, $format)

Parses a URI format as passed to C<set_uri_format()> or
C<set_fixed_uri_format()> and returns it if it parses properly. If it doesn't,
it throws an exception. The C<$name> attribute is used in the exceptions.

B<Throws:>

=over 4

=item *

No URI Format value specified.

=item *

Invalid URI Format tokens.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

$parse_uri_format = sub {
    my ($name, $format) = @_;

    # Throw an exception for an empty or bogus format.
    throw_dp(error => "No $name value specified")
      if not $format or $format =~ /^\s*$/;

    # Make sure that the URI format has %{categories}.
    throw_dp "Missing the %{categories} token from $name"
      unless $format =~ /%{categories}/;

    # Make sure there's a closing slash.
    $format .= '/' unless $format =~ m|/$|;
    return $format;
};

1;
__END__

=back

=head1 NOTES

NONE.

=head1 AUTHORS

Michael Soderstrom <miraso@pacbell.net>

David Wheeler <david@kineticode.com>

=head1 SEE ALSO

L<perl>, L<Bric>, L<Bric::Biz::Asset::Business>, L<Bric::Biz::ElementType>,
L<Bric::Biz::Asset::Template>.

=cut
