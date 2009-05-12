package Bric::Biz::Org::Source;

=head1 Name

Bric::Biz::Org::Source - Manages content sources.

=cut

# Grab the Version Number.
require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

  use Bric::Biz::Org::Source;

  # Constructors.
  my $src = Bric::Biz::Org::Source->new($init);
  $src = Bric::Biz::Org::Source->lookup({ id => $id });
  my @srces = Bric::Biz::Org::Source->list($params);

  # Class methods.
  my @sids = Bric::Biz::Org::Source->list_ids($params);
  my $meths = Bric::Biz::Org::Source->my_meths;

  # Instance Methods.
  my $id = $src->get_id;
  my $org_id = $src->get_org_id;
  $src = $src->set_org($org);
  my $src_name = $src->get_source_name;
  $src = $src->set_source_name($src_name);
  my $desc = $src->get_description;
  $src = $src->set_description($desc);
  my $expire = $src->get_expire;
  $src = $src->set_expire($expire);

  $src = $src->activate;
  $src = $src->deactivate;
  print "Active: ", $src->is_active ? 'Yes' : 'No', "\n";

  $src = $src->save;

=head1 Description

This class manages asset sources. A source is an organization that provides
content, such as a wire service or a syndicate. Thus, each source object is a
kind of organization, and inherits all of an relevant data accessors, including
those for addresses.

This class adds three basic data points to the organization: A description, an
expire, and an active flag. The description is a simple free-text
description of the source. The expire property is a simple integer
representing the number of days an asset provided by a given source may be used
before it must be removed as content. The active flag is just like any other
active flag, except that it is separate from the Bric::Biz::Org active flag. Thus a
Bric::Biz::Org::Source object may be deactivated while its parent Bric::Biz::Org
object remains active.

=cut

################################################################################
# Dependencies
################################################################################
# Standard Dependencies
use strict;

################################################################################
# Programmatic Dependences
use Bric::Util::DBI qw(:all);
use Bric::Util::Fault qw(throw_dp);
use Bric::Util::Grp::Source;

################################################################################
# Inheritance
################################################################################
use base qw(Bric::Biz::Org);

################################################################################
# Function and Closure Prototypes
################################################################################
my ($get_em);

################################################################################
# Constants
################################################################################
use constant DEBUG => 0;
use constant GROUP_PACKAGE => 'Bric::Util::Grp::Source';
use constant INSTANCE_GROUP_ID => 5;

################################################################################
# Fields
################################################################################
# Public Class Fields

################################################################################
# Private Class Fields
my @SCOLS = qw(id org__id name description expire active);
my @PROPS = qw(src_id id source_name description expire _active);

my $SEL_COLS = 's.id, o.id, o.name, o.long_name, s.name, s.description, ' .
 's.expire, s.active, o.personal, o.active, m.grp__id';
my @SEL_PROPS = qw(src_id id name long_name source_name description expire
                   _active _personal _org_active grp_ids);

my %TXT_MAP = ( name        => 'o.name',
                long_name   => 'o.long_name',
                description => 's.description',
                source_name => 's.name'
              );

my ($METHS, @ORD);

################################################################################

################################################################################
# Instance Fields
BEGIN {
    Bric::register_fields({
                         # Public Fields
                         src_id => Bric::FIELD_READ,
                         id => Bric::FIELD_READ,
                         source_name => Bric::FIELD_RDWR,
                         description => Bric::FIELD_RDWR,
                         expire => Bric::FIELD_RDWR,
                         grp_ids => Bric::FIELD_READ,

                         # Private Fields
                         _org_active => Bric::FIELD_NONE,
                         _active => Bric::FIELD_NONE
                        });
}

################################################################################
# Class Methods
################################################################################

=head1 Interface

=head2 Constructors

=over 4

=item my $src = Bric::Biz::Org::Source->new($init)

Instantiates a Bric::Biz::Org::Source object. An anonymous hash of initial values
may be passed. The supported initial value keys are:

=over 4

=item *

name

=item *

long_name

=item *

description

=item *

expire

=back

The new source will be active by default. Call $src->save() to save the new
object.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub new {
    my ($pkg, $init) = @_;
    my $self = bless {}, ref $pkg || $pkg;
    $init->{_active} = 1;
    $init->{_org_active} = 1;
    push @{$init->{grp_ids}}, INSTANCE_GROUP_ID;
    $self->SUPER::new($init);
}

################################################################################

=item my $src = Bric::Biz::Org::Source->lookup({ id => $id })

=item my $src = Bric::Biz::Org::Source->lookup({ source_name => $source_name })

Looks up and instantiates a new Bric::Biz::Org::Source object based on the
Bric::Biz::Org::Source object ID or name passed. If C<$id> or C<$name> is not
found in the database, C<lookup()> returns C<undef>.

B<Throws:>

=over

=item *

Invalid property.

=item *

Too many Bric::Dist::Biz::Org::Source objects found.

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

B<Side Effects:> If $id is found, populates the new Bric::Biz::Org::Source object
with data from the database before returning it.

B<Notes:> NONE.

=cut

sub lookup {
    my $pkg = shift;
    my $src = $pkg->cache_lookup(@_);
    return $src if $src;

    $src = $get_em->($pkg, @_);
    # We want @$src to have only one value.
    throw_dp(error => 'Too many Bric::Biz::Org::Source objects found.')
      if @$src > 1;
    return @$src ? $src->[0] : undef;
}

################################################################################

=item my (@srcs || $srcs_aref) = Bric::Biz::Org::Source->list($params)

Returns a list or anonymous array of Bric::Biz::Org::Source objects based on the
search parameters passed via an anonymous hash. The supported lookup keys are:

=over 4

=item id

Source ID. May use C<ANY> for a list of possible values.

=item name

The source's organization name. May use C<ANY> for a list of possible values.

=item long_name

The source organization's long name. May use C<ANY> for a list of possible
values.

=item source_name

The name of the source. May use C<ANY> for a list of possible values.

=item description

A description of the source May use C<ANY> for a list of possible values.

=item expire

The number of days until documents from the source should be expired. May use
C<ANY> for a list of possible values.

=item org_id

The ID for a Bric::Biz::Org object with which sources may be associated. May
use C<ANY> for a list of possible values.

=item grp_id

A Bric::Util::Grp::Keyword object ID. May use C<ANY> for a list of possible
values.

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

B<Side Effects:> Populates each Bric::Biz::Org::Source object with data from the
database before returning them all.

B<Notes:> NONE.

=cut

sub list { wantarray ? @{ &$get_em(@_) } : &$get_em(@_) }

################################################################################

=back

=head2 Destructors

=over 4

=item $src->DESTROY

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

=item my (@src_ids || $src_ids_aref) = Bric::Biz::Org::Source->list_ids($params)

Returns a list or anonymous array of Bric::Biz::Org::Source object IDs based
on the search criteria passed via an anonymous hash. The supported lookup keys
are the same as those for C<list()>.

B<Throws:>

=over 4

=item *

Invalid property.

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

B<Notes:> NONE.

=cut

sub list_ids { wantarray ? @{ &$get_em(@_, 1) } : &$get_em(@_, 1) }

################################################################################

=item my $meths = Bric::Biz::Org::Source->my_meths

=item my (@meths || $meths_aref) = Bric::Biz::Org::Source->my_meths(TRUE)

=item my (@meths || $meths_aref) = Bric::Biz::Org::Source->my_meths(0, TRUE)

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

    unless ($METHS) {
        # We don't got 'em. So get 'em!
        foreach my $meth (Bric::Biz::Org::Source->SUPER::my_meths(1)) {
            $METHS->{$meth->{name}} = $meth;
            push @ORD, $meth->{name};
        }
        $METHS->{name}{disp} = 'Organization Name';
        push @ORD, qw(source_name description expire), pop @ORD;

        $METHS->{description} = {
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
                            };
    $METHS->{source_name} = {
                             get_meth => sub { shift->get_source_name(@_) },
                             get_args => [],
                             set_meth => sub { shift->set_source_name(@_) },
                             set_args => [],
                             name     => 'source_name',
                             disp     => 'Source name',
                             search   => 1,
                             len      => 256,
                             req      => 1,
                             type     => 'short',
                             props    => { type => 'text',
                                          length     => 32,
                                          maxlength => 64
                                      }
                             };
    $METHS->{expire}  = {
                             get_meth => sub { shift->get_expire(@_) },
                             get_args => undef,
                             set_meth => sub { shift->set_expire(@_) },
                             set_args => [],
                             name     => 'expire',
                             disp     => 'Expiration',
                             len      => 4,
                             req      => 1,
                             type     => 'short',
                             props    => { type => 'select',
                                           vals => [ [ 0 => 'Never' ],
                                                     [ 1 => '1 Day' ],
                                                     [ 3 => '3 Days' ],
                                                     [ 5 => '5 Days' ],
                                                     [ 10 => '10 Days' ],
                                                     [ 15 => '15 Days' ],
                                                     [ 20 => '20 Days' ],
                                                     [ 30 => '30 Days' ],
                                                     [ 45 => '45 Days' ],
                                                     [ 90 => '90 Days' ],
                                                     [ 180 => '180 Days' ],
                                                     [ 365 => '1 Year' ]
                                                   ]
                                         }
                            };
    }

    if ($ord) {
        return wantarray ? @{$METHS}{@ORD} : [@{$METHS}{@ORD}];
    } elsif ($ident) {
        return wantarray ? $METHS->{source_name} : [$METHS->{source_name}];
    } else {
        return $METHS;
    }
}

################################################################################

=back

=head2 Public Instance Methods

Besides the methods inherited from Bric::Biz::Org, Bric::Biz::Org::Source offers
accessors relevant to source-specific data.

=over 4

=item my $id = $src->get_id

Returns the ID of the Bric::Biz::Org::Source object.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=back

B<Side Effects:> NONE.

B<Notes:> If the Bric::Biz::Org::Source object has been instantiated via the new()
constructor and has not yet been C<save>d, the object will not yet have an ID,
so this method call will return undef.

=cut

sub get_id { $_[0]->_get('src_id') }

################################################################################

=item my $org_id = $src->get_org_id

Returns the ID of the Bric::Biz::Org object from which this source object inherits.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_org_id { $_[0]->_get('id') }

################################################################################

=item $self = $src->set_org($org)

Sets the ID representing Bric::Biz::Org object from which this Bric::Biz::Org::Source
object inherits.

B<Throws:>

=over 4

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

sub set_org {
    my ($self, $org) = @_;
    $self->_set([ qw(id name long_name _org_active) ],
                [ $org->_get( qw(id name long_name _active) ) ]);
}

################################################################################

=item my $source_name = $src->get_source_name

Returns the source_name of this source.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'source_name' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $self = $src->set_source_name($source_name)

Sets the source_name of this source.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: WRITE access for field 'source_name' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $description = $src->get_description

Returns the description of this source.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'description' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $self = $src->set_description($description)

Sets the description of this source, converting any non-Unix line endings.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub set_description {
    my ($self, $val) = @_;
    $val =~ s/\r\n?/\n/g if defined $val;
    $self->_set( [ 'description' ] => [ $val ]);
}

=item my $expire = $src->get_expire

Returns the number of days before assets associated with this source expire.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'expire' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $self = $src->set_expire($expire)

Sets the number of days before assets associated with this source expire. Set
this value to 0 (zero) to prevent assets provided by this source from ever
expiring.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: WRITE access for field 'expire' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

################################################################################

=item $self = $src->activate

Activates the Bric::Biz::Org::Source object. Call $src->save to make the change
persistent. Bric::Biz::Org::Source objects instantiated by new() are active by
default.

B<Throws:>

=over 4

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> A Bric::Biz::Org::Source object's active status is not inherited from
Bric::Biz::Org. A Bric::Biz::Org::Source object may be deactivated while its parent
Bric::Biz::Org object remains active.

=cut

sub activate { $_[0]->_set(['_active'], [1]) }

=item $self = $src->deactivate

Deactivates (deletes) the Bric::Biz::Org::Source object. Call $src->save to make
the change persistent.

B<Throws:>

=over 4

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> See activate() above.

=cut

sub deactivate { $_[0]->_set(['_active'], [0]) }

=item $self = $src->is_active

Returns $self if the Bric::Biz::Org::Source object is active, and undef if it is not.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=back

B<Side Effects:> NONE.

B<Notes:> See activate() above.

=cut

sub is_active { $_[0]->_get('_active') ? $_[0] : undef }

################################################################################

=item my (@gids || $gids_aref) = $u->get_grp_ids

=item my (@gids || $gids_aref) = Bric::Biz::Person::User->get_grp_ids

Returns a list or anonymous array of Bric::Biz::Group object ids representing the
groups of which this Bric::Biz::Org::Source object is a member.

B<Throws:> See Bric::Util::Grp::list().

B<Side Effects:> NONE.

B<Notes:> This method returns the group IDs for the current object both as a
Bric::Biz::Org object and as a Bric::Biz::Org::Source object. [Actually, I've
commented this out for now, since it seems more likely at this point that we'll
want only the source group IDs, not also the organization IDs. We can uncomment
this later if we decide we need it, though.]

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

=item $self = $src->save

Saves any changes to the Bric::Biz::Org::Source object. Returns $self on success
and undef on failure.

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
    my ($id, $act) = $self->_get('src_id', '_active');

    if (defined $id) {
        # It's an existing source. Update it.
        $self->_set(['_active'], [$self->_get('_org_active')]);
        $self->SUPER::save;
        $self->_set(['_active'], [$act]);
        local $" = ' = ?, '; # Simple way to create placeholders with an array.
        my $upd = prepare_c(qq{
            UPDATE source
            SET    @SCOLS = ?
            WHERE  id = ?
        }, undef);
        execute($upd, $self->_get(@PROPS, 'src_id'));
        unless ($act) {
            # Deactivate all group memberships if we've deactivated the source.
            foreach my $grp (Bric::Util::Grp::Source->list
                             ({ obj => $self, permanent => 0 })) {
                foreach my $mem ($grp->has_member({ obj => $self })) {
                    next unless $mem;
                    $mem->deactivate;
                    $mem->save;
                }
            }
        }
    } else {
        # It's a new source. Insert it.
        # HACK. I have to fake it into being Bric::Biz::Org so that it gets
        # inserted into the proper group when Bric::Biz::Org::save() calls
        # register_instance().
        $self = bless $self, 'Bric::Biz::Org';
        $self->SUPER::save;
        $self = bless $self, __PACKAGE__;
        local $" = ', ';
        my $fields = join ', ', next_key('source'), ('?') x $#SCOLS;
        my $ins = prepare_c(qq{
            INSERT INTO source (@SCOLS)
            VALUES ($fields)
        }, undef);
        # Don't try to set ID - it will fail!
        execute($ins, $self->_get(@PROPS[1..$#PROPS]));
        # Now grab the ID.
        $id = last_key('source');
        $self->_set(['src_id'], [$id]);

        # And finally, add this source to the "All Sources" group.
        $self->register_instance(INSTANCE_GROUP_ID, GROUP_PACKAGE);
    }
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

=item my $src_aref = &$get_em( $pkg, $params )

=item my $src_ids_aref = &$get_em( $pkg, $params, 1 )

Function used by lookup() and list() to return a list of Bric::Biz::Org::Source
objects or, if called with an optional third argument, returns a listof
Bric::Biz::Org::Source object IDs (used by list_ids()).

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

B<Notes:> NONE.

=cut

$get_em = sub {
    my ($pkg, $params, $ids, $href) = @_;
    my $tables = 'source s, org o, member m, source_member c';
    my $wheres = 's.org__id = o.id AND s.id = c.object_id '
      . "AND m.active = '1' AND m.id = c.member__id";
    my @params;
    while (my ($k, $v) = each %$params) {
        if ($k eq 'id' or $k eq 'expire') {
            # Simple numeric comparison.
            $wheres .= " AND " . any_where $v, "s.$k = ?", \@params;
        } elsif ($k eq 'org_id') {
            # Simple numeric comparison.
            $wheres .= " AND " . any_where $v, "o.id = ?", \@params;
        } elsif ($TXT_MAP{$k}) {
            # Simple string comparison.
            $wheres .= " AND "
              . any_where $v, "LOWER($TXT_MAP{$k}) LIKE LOWER(?)", \@params;
        } elsif ($k eq 'grp_id') {
            # Add in the group tables a second time and join to them.
            $tables .= ", member m2, source_member c2";
            $wheres .= " AND s.id = c2.object_id AND c2.member__id = m2.id "
              . "AND m2.active = '1' AND "
              . any_where $v, "m2.grp__id = ?", \@params;
        } else {
            # We're horked.
            throw_dp(error => "Invalid property '$k'.")
              unless $k eq 'all'; # XXX Allow all.
        }
    }

    # Make sure it's active unless and ID has been passed.
    # XXX Allow all. I will never again implicitly add search parameters to
    # an API.
    $wheres .= " AND s.active = '1'" unless defined $params->{id}
      || $params->{all};

    # Assemble and prepare the query.
    my ($qry_cols, $order) = $ids ? (\'DISTINCT s.id', 's.id') :
      (\$SEL_COLS, 'o.id, s.name, s.id');
    my $sel = prepare_c(qq{
        SELECT $$qry_cols
        FROM   $tables
        WHERE  $wheres
        ORDER BY $order
    }, undef);

    # Just return the IDs, if they're what's wanted.
    return col_aref($sel, @params) if $ids;

    execute($sel, @params);
    my (@d, @orgs, $grp_ids);
    $pkg = ref $pkg || $pkg;
    bind_columns($sel, \@d[0..$#SEL_PROPS]);
    my $last = -1;
    while (fetch($sel)) {
        if ($d[0] != $last) {
            $last = $d[0];
            # Create a new org object.
            my $self = bless {}, $pkg;
            $self->SUPER::new;
            # Get a reference to the array of group IDs.
            $grp_ids = $d[$#d] = [$d[$#d]];
            $self->_set(\@SEL_PROPS, \@d);
            $self->_set__dirty; # Disables dirty flag.
            push @orgs, $self->cache_me;
        } else {
            push @$grp_ids, $d[$#d];
        }
    }
    return \@orgs;
};

1;
__END__

=back

=head1 Notes

NONE.

=head1 Author

David Wheeler <david@justatheory.com>

=head1 See Also

L<Bric|Bric>

=cut
