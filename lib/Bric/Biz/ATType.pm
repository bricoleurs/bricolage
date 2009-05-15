package Bric::Biz::ATType;

###############################################################################

=head1 Name

Bric::Biz::ATType - A class to represent ElementType types.

=cut

require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

 use Bric::Biz::ATType;

=head1 Description

This class sets up properties that are common to all elements
(Bric::Biz::ElementType) objects of a type.

=cut

#==============================================================================#
# Dependencies                         #
#======================================#

#--------------------------------------#
# Standard Dependencies
use strict;

#--------------------------------------#
# Programatic Dependencies
use Bric::Util::DBI qw(:all);
use Bric::Util::Grp::ATType;
use Bric::Util::Fault qw(throw_dp);

#==============================================================================#
# Inheritance                          #
#======================================#
use base qw(Bric);

#=============================================================================#
# Function Prototypes                  #
#======================================#
my $get_em;


#==============================================================================#
# Constants                            #
#======================================#
use constant DEBUG => 0;
use constant GROUP_PACKAGE => 'Bric::Util::Grp::ATType';
use constant INSTANCE_GROUP_ID => 28;
use constant STORY_CLASS_ID => 10;

#==============================================================================#
# FIELDS                               #
#======================================#

#--------------------------------------#
# Public Class Fields
# None.

#--------------------------------------#
# Private Class Fields
my $METHS;
my $TABLE = 'at_type';
my @COLS  = qw(name description top_level media paginated fixed_url
                related_story related_media biz_class__id active);
my @PROPS = qw(name description top_level media paginated fixed_url
               related_story related_media biz_class_id _active);

my $SEL_COLS = 'a.id, a.name, a.description, a.top_level, a.media, ' .
  'a.paginated, a.fixed_url, a.related_story, a.related_media, ' .
  'a.biz_class__id, a.active, m.grp__id';
my @SEL_PROPS = ('id', @PROPS, 'grp_ids');

my @ORD = qw(name description top_level media paginated fixed_url
             related_story related_media biz_class_id active);

#--------------------------------------#
# Instance Fields
BEGIN {
    Bric::register_fields({
                         # Public Fields
                         'id'             => Bric::FIELD_RDWR,
                         'name'           => Bric::FIELD_RDWR,
                         'description'    => Bric::FIELD_RDWR,
                         'top_level'      => Bric::FIELD_RDWR,
                         'paginated'      => Bric::FIELD_RDWR,
                         'fixed_url'      => Bric::FIELD_RDWR,
                         'related_story'  => Bric::FIELD_RDWR,
                         'related_media'  => Bric::FIELD_RDWR,
                         'media'          => Bric::FIELD_RDWR,
                         'biz_class_id'   => Bric::FIELD_RDWR,
                         'grp_ids'        => Bric::FIELD_READ,

                         # Private Fields
                         '_active'         => Bric::FIELD_NONE,
                        });
}

#==============================================================================#

=head1 Interface

=head2 Constructors

=over 4

=item $obj = Bric::Biz::ATType->new($init);

Constructs and returns a new Bric::Biz::ATType object initialized with the
parameters in the C<$init> hash reference. The supported keys for C<$init>
are:

=over 4

=item name

The name of this ATType.

=item description

A short description of this ATType.

=item top_level

A boolean value flagging whether elements (ElementTypes) of this this ATType
represent top level elements (story type elements or media type elements) or
subelements. Defaults to false.

=item paginated

A boolean value flagging whether elements (ElementTypes) of this this ATType
represent pages. Defaults to false.

=item fixed_url

A boolean value flagging whether elements (ElementTypes) of this this ATType
are fixed URL elements. Defaults to false.

=item related_story

A boolean value flagging whether elements (ElementTypes) of this this ATType
are rleated story elements. Defaults to false.

=item related_media

A boolean value flagging whether elements (ElementTypes) of this this ATType
are rleated media elements. Defaults to false.

=item media

A boolean value flagging whether elements (ElementTypes) of this this ATType
are media elements. Defaults to false.

=item biz_class_id

The ID corresponding to the Bric::Util::Class entry for one of the following
classes:

=over 4

=item Bric::Biz::Asset::Business::Story

=item Bric::Biz::Asset::Business::Media

=item Bric::Biz::Asset::Business::Media::Image

=item Bric::Biz::Asset::Business::Media::Audio

=item Bric::Biz::Asset::Business::Media::Video

=back

=back

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub new {
    my ($pkg, $init) = @_;

    # Create the object via fields which returns a blessed object.
    my $self = bless {}, ref $pkg || $pkg;

    # Set active to true and biz_class_id to the story class ID.
    $init->{_active} = 1;
    $init->{biz_class_id} ||= STORY_CLASS_ID;
    push @{$init->{grp_ids}}, INSTANCE_GROUP_ID;

    # Set other boolean values.
    for (qw(top_level media paginated fixed_url related_story related_media)) {
        $init->{$_} = $init->{$_} ? 1 : 0;
    }

    # Call the parent's constructor.
    $self->SUPER::new($init);

    # Return the object.
    return $self;
}

##############################################################################

=item my $st = Bric::Biz::ATType->lookup({ id => $id })

=item my $st = Bric::Biz::ATType->lookup({ name => $name })

Looks up and instantiates a new Bric::Biz::ATType object based on the
Bric::Biz::ATType object ID or name passed. If C<$id> or C<$name> is not found
in the database, C<lookup()> returns C<undef>.

B<Throws:>

=over

=item *

Too many Bric::Biz::ATType objects found.

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
    my $pkg = shift;
    my $att = $pkg->cache_lookup(@_);
    return $att if $att;

    $att = $get_em->($pkg, @_);
    # We want @$att to have only one value.
    throw_dp(error => 'Too many ' . __PACKAGE__ . ' objects found.')
      if @$att > 1;
    return @$att ? $att->[0] : undef;
}

##############################################################################

=item my (@attypes || $attypes_aref) = Bric::Biz::ATType->list($params)

Returns a list or anonymous array of Bric::Biz::ATType objects based on the
search parameters passed via an anonymous hash. The supported lookup keys are:

=over 4

=item id

ATType ID. May use C<ANY> for a list of possible values.

=item name

Lookup ATType by name. May use C<ANY> for a list of possible values.

=item description

Lookup ATType by description. May use C<ANY> for a list of possible values.

=item top_level

Boolean; return all top level ATTypes

=item paginated

Boolean; return all paginated ATTypes.

=item fixed_url

Boolean; return all fixed URL ATTypes.

=item active

Boolean; return all active ATTypes. If passed as "all", returns all ATTypes.

=item related_story

Boolean; return all related story ATTypes.

=item related_media

Boolean; return all related media ATTypes.

=item media

Boolean; return all media ATTypes.

=item biz_class_id

Return all ATTypes associated with this business class ID. See C<new()> for a
list of business asset classes. May use C<ANY> for a list of possible values.

=item grp_id

Return all ATTypes in the Bric::Util::Grp::ATType group corresponding to this
ID. May use C<ANY> for a list of possible values.

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

=back

=head2 Destructors

=over 4

=item $st->DESTROY

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

=item my (@st_ids || $st_ids_aref) = Bric::Biz::ATType->list_ids($params)

Returns a list or anonymous array of Bric::Biz::ATType object IDs based on the
search criteria passed via an anonymous hash. The supported lookup keys are
the same as those for C<list()>.

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

=item my $meths = Bric::Biz::ATType->my_meths

=item my (@meths || $meths_aref) = Bric::Biz::ATType->my_meths(TRUE)

=item my (@meths || $meths_aref) = Bric::Biz::ATType->my_meths(0, TRUE)

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
        # We don't got 'em. So get 'em! Start by getting a list of Business
        # Asset Classes.
        my $sel = [];
        my $classes = Bric::Util::Class->pkg_href;
        while (my ($k, $v) = each %$classes) {
            next unless $k =~ /^bric::biz::asset::business::/;
            my $d = [ $v->get_id, $v->get_disp_name ];
            $d->[1] = 'Other Media' if $v->get_key_name eq 'media';
            push @$sel, $d;
        }

        $METHS = {
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
                              name     => 'description',
                              get_meth => sub { shift->get_description(@_) },
                              get_args => [],
                              set_meth => sub { shift->set_description(@_) },
                              set_args => [],
                              disp     => 'Description',
                              len      => 256,
                              req      => 0,
                              type     => 'short',
                              props    => { type => 'textarea',
                                            cols => 40,
                                            rows => 4
                                          }
                             },
             top_level    => {
                              name     => 'top_level',
                              get_meth => sub {shift->get_top_level(@_)},
                              get_args => [],
                              set_meth => sub {shift->set_top_level(@_)},
                              set_args => [],
                              disp     => 'Type',
                              len      => 1,
                              req      => 0,
                              type     => 'short',
                              props    => { type => 'radio',
                                            vals => [ [0, 'Element'], [1, 'Asset']] }
                             },
             paginated    => {
                              name     => 'paginated',
                              get_meth => sub {shift->get_paginated(@_)},
                              get_args => [],
                              set_meth => sub {shift->set_paginated(@_)},
                              set_args => [],
                              disp     => 'Page',
                              len      => 1,
                              req      => 0,
                              type     => 'short',
                              props    => { type => 'checkbox'}
                             },
             fixed_url    => {
                              name     => 'fixed_url',
                              get_meth => sub {shift->get_fixed_url(@_)},
                              get_args => [],
                              set_meth => sub {shift->set_fixed_url(@_)},
                              set_args => [],
                              disp     => 'Fixed',
                              len      => 1,
                              req      => 0,
                              type     => 'short',
                              props    => { type => 'checkbox'}
                             },
             related_story    => {
                              name     => 'related_story',
                              get_meth => sub {shift->get_related_story(@_)},
                              get_args => [],
                              set_meth => sub {shift->set_related_story(@_)},
                              set_args => [],
                              disp     => 'Related Story',
                              len      => 1,
                              req      => 0,
                              type     => 'short',
                              props    => { type => 'checkbox'}
                             },
             related_media    => {
                              name     => 'related_media',
                              get_meth => sub {shift->get_related_media(@_)},
                              get_args => [],
                              set_meth => sub {shift->set_related_media(@_)},
                              set_args => [],
                              disp     => 'Related Media',
                              len      => 1,
                              req      => 0,
                              type     => 'short',
                              props    => { type => 'checkbox'}
                             },
             media        => {
                              name     => 'media',
                              get_meth => sub {shift->get_media(@_)},
                              get_args => [],
                              set_meth => sub {shift->set_media(@_)},
                              set_args => [],
                              disp     => 'Content',
                              len      => 1,
                              req      => 0,
                              type     => 'short',
                              props    => { type => 'radio',
                                            vals => [ [ 0, 'Story'], [ 1, 'Media'] ]
                                      }
                             },
             biz_class_id => {
                              name     => 'biz_class_id',
                              get_meth => sub {shift->get_biz_class_id(@_)},
                              get_args => [],
                              set_meth => sub {shift->set_biz_class_id(@_)},
                              set_args => [],
                              disp     => 'Content Type',
                              len      => 3,
                              req      => 0,
                              type     => 'short',
                              props    => { type => 'select',
                                            vals => $sel }
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
    }

    if ($ord) {
        return wantarray ? @{$METHS}{@ORD} : [@{$METHS}{@ORD}];
    } elsif ($ident) {
        return wantarray ? $METHS->{name} : [$METHS->{name}];
    } else {
        return $METHS;
    }
}

##############################################################################

=back

=head2 Public Instance Methods

=over 4

=item $name = $att->get_name;

=item $name = $att->set_name($name);

Get/Set the name of this AT type.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $desc = $att->get_description;

=item $desc = $att->set_description($desc);

Get/Set the description for this AT type, first converting non-Unix line
endings.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub set_description {
    my ($self, $val) = @_;
    $val =~ s/\r\n?/\n/g if defined $val;
    $self->_set( [ 'description' ] => [ $val ]);
}

=item $topl = $att->get_top_level;

=item $topl = $att->set_top_level(1 || 0);

Get/Set the top level flag.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $page = $att->get_paginated;

=item $page = $att->set_paginated(1 || 0);

Get/Set the paginated flag.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $page = $att->get_fixed_url;

=item $page = $att->set_fixed_url(1 || 0);

Get/Set the fixed url flag.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $page = $att->get_related_story;

=item $page = $att->set_related_story(1 || 0);

Get/Set the related story flag.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $page = $att->get_related_media;

=item $page = $att->set_related_media(1 || 0);

Get/Set the related media flag.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $page = $att->get_media;

=item $page = $att->set_media(1 || 0);

Get/Set the media flag.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $page = $att->get_biz_class_id;

=item $page = $att->set_biz_class_id(1 || 0);

Get/Set the business class ID. See C<new()> for a list of the business asset
classes.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $att = $att->is_active;

=item $att = $att->activate;

=item $att = $att->deactivate;

Get/Set the active flag.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub is_active { $_[0]->_get('_active') ? $_[0] : undef }

sub activate { $_[0]->_set(['_active'], [1]) }

sub deactivate { $_[0]->_set(['_active'], [0]) }

=item $success = $attype->remove;

Deletes the AT type from the database.

B<Throws:>

=over 4

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=item *

Unable to execute SQL statement.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub remove {
    my $self = shift;
    my $id   = $self->get_id;
    return unless defined $id;
    my $sth = prepare_c("DELETE FROM $TABLE WHERE id = ?", undef);
    execute($sth, $id);
    return 1;
}

##############################################################################

=item $att = $att->save;

Save the AT type and/or all changes to the database.

B<Throws:>

=over 4

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=item *

Unable to execute SQL statement.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub save {
    my $self = shift;
    return unless $self->_get__dirty;

    if ($self->_get('id')) {
        $self->_update_attype;
    } else {
        $self->_insert_attype;
    }

    $self->SUPER::save;
}

##############################################################################

=back

=head2 Private Class Methods

NONE

=head2 Private Instance Methods

=over 4

=item _update_attype

Updates the ATType in the database.

B<Throws:>

=over 4

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=item *

Unable to execute SQL statement.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _update_attype {
    my $self = shift;

    my $sql = "UPDATE $TABLE SET " . join(',', map {"$_ = ?"} @COLS) .
      ' WHERE id = ?';

    my $sth = prepare_c($sql, undef);
    execute($sth, $self->_get(@PROPS), $self->get_id);
    return 1;
}

##############################################################################

=item _insert_attype

Inserts the ATType into the database.

B<Throws:>

=over 4

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=item *

Unable to execute SQL statement.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _insert_attype {
    my $self = shift;
    my $nextval = next_key($TABLE);

    # Create the insert statement.
    my $sql = "INSERT INTO $TABLE (id," . join(', ', @COLS) . ") " .
              "VALUES ($nextval, " . join(', ', ('?') x @COLS) . ')';

    my $sth = prepare_c($sql, undef);
    execute($sth, $self->_get(@PROPS));

    # Set the ID of this object.
    $self->_set(['id'],[last_key($TABLE)]);

    # And finally, register this person in the "All Element Types" group.
    $self->register_instance(INSTANCE_GROUP_ID, GROUP_PACKAGE);

    return 1;
}

##############################################################################

=back

=head2 Private Functions

=over 4

=item my $attypes_aref = &$get_em( $pkg, $params )

=item my $attypes_ids_aref = &$get_em( $pkg, $params, 1 )

Function used by C<lookup()> and C<list()> to return a list of
Bric::Biz::ATType objects or, if called with an optional third argument,
returns a list of Bric::Biz::ATType object IDs (used by C<list_ids()>).

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
    my $tables = "$TABLE a, member m, at_type_member c";
    my $wheres = 'a.id = c.object_id AND c.member__id = m.id ' .
      "AND m.active = '1'";
    my @params;

    # Set the active parameter, if necessary.
    if ($params->{id} or ($params->{active} and $params->{active} eq 'all')) {
        # Disregard any active parameter.
        delete $params->{active};
    } else {
        # Make sure it's a boolean value.
        $params->{active} = exists $params->{active} ?
          delete $params->{active} ? 1 : 0 : 1;
    }

    while (my ($k, $v) = each %$params) {
        if ($k eq 'id') {
            # Simple ID lookup.
            $wheres .= ' AND ' . any_where($v, 'a.id = ?', \@params);
        } elsif ($k eq 'biz_class_id') {
            # Simple ID lookup.
            $wheres .= ' AND ' . any_where($v, 'a.biz_class__id = ?', \@params);
        } elsif ($k eq 'name' or $k eq 'description') {
            # Simple string comparison.
            $wheres .= " AND " . any_where($v, "LOWER(a.$k) LIKE LOWER(?)", \@params);
        } elsif ($k eq 'grp_id') {
            # Add in the group tables a second time and join to them.
            $tables .= ", member m2, at_type_member c2";
            $wheres .= " AND a.id = c2.object_id AND c2.member__id = m2.id" .
              " AND m2.active = '1'";
            $wheres .= ' AND ' . any_where($v, "m2.grp__id = ?", \@params);
        } else {
            # It's a boolean comparison.
            $wheres .= " AND a.$k = ?";
            push @params, $v ? 1 : 0;
        }
    }

    # Assemble and prepare the query.
    my ($qry_cols, $order) = $ids ? (\'DISTINCT a.id', 'a.id') :
      (\$SEL_COLS, 'a.name, a.id');
    my $sel = prepare_c(qq{
        SELECT $$qry_cols
        FROM   $tables
        WHERE  $wheres
        ORDER BY $order
    }, undef);

    # Just return the IDs, if they're what's wanted.
    return col_aref($sel, @params) if $ids;

    # Grab all the records.
    execute($sel, @params);
    my (@d, @atts, $grp_ids);
    bind_columns($sel, \@d[0..$#SEL_PROPS]);
    my $last = -1;
    $pkg = ref $pkg || $pkg;
    while (fetch($sel)) {
        if ($d[0] != $last) {
            $last = $d[0];
            # Create a new server type object.
            my $self = bless {}, $pkg;
            $self->SUPER::new;
            # Get a reference to the array of group IDs.
            $grp_ids = $d[$#d] = [$d[$#d]];
            $self->_set(\@SEL_PROPS, \@d);
            $self->_set__dirty; # Disables dirty flag.
            push @atts, $self->cache_me;
        } else {
            push @$grp_ids, $d[$#d];
        }
    }
    # Return the objects.
    return \@atts;
};

1;
__END__

=back

=head1 Notes

NONE

=head1 Author

Garth Webb <garth@perijove.com>

Refactored by David Wheeler <david@justatheory.com>

=head1 See Also

L<perl>, L<Bric>, L<Bric::Biz::ElementType>

=cut
