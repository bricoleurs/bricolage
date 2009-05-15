package Bric::Biz::Keyword;

=head1 Name

Bric::Biz::Keyword - Interface to Bricolage Keyword Objects

=cut

# Grab the Version Number.
require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

 use Bric::Biz::Keyword;

  # Constructors.
  my $keyword = Bric::Biz::Keyword->new($init);
  $keyword = Bric::Biz::Keyword->lookup({ id => $id });
  my @keywords = Bric::Biz::Keyword->list($params);

  # Class Methods.
  my @keyword_ids = Bric::Biz::Keyword->list_ids($params);
  my $keywords_href = Bric::Biz::Keyword->href($params);
  my $meths = Bric::Biz::Keyword->my_meths;

  # Instance methods.
  $id = $keyword->get_id;
  my $name = $keyword->get_name;
  $keyword = $keyword->set_name($name)
  my $screen_name = $keyword->get_screen_name;
  $keyword = $keyword->set_screen_name($screen_name)
  my $sort_name = $keyword->get_sort_name;
  $keyword = $keyword->set_sort_name($sort_name)

  $keyword = $keyword->activate;
  $keyword = $keyword->deactivate;
  $keyword = $keyword->is_active;

  # Save the changes to the database
  $keyword = $keyword->save;

=head1 Description

The Keyword module allows assets to be characterized by a set of topical
keywords. These keywords can be used to group assets or during a search on a
particular topic.

=cut

##############################################################################
# Dependencies
##############################################################################
# Standard Dependencies
use strict;

##############################################################################
# Programmatic Dependences
use Bric::Util::DBI qw(:all);
use Bric::Util::Grp::Keyword;
use Bric::Util::Fault qw(:all);

##############################################################################
# Inheritance
##############################################################################
use base qw(Bric);

##############################################################################
# Function and Closure Prototypes
##############################################################################
my ($get_em);

##############################################################################
# Constants
##############################################################################
use constant DEBUG => 0;
use constant GROUP_PACKAGE => 'Bric::Util::Grp::Keyword';
use constant INSTANCE_GROUP_ID => 50;

##############################################################################
# Fields
##############################################################################
# Private Class Fields
my $TABLE = 'keyword';
my @COLS =  qw(id name screen_name sort_name active);
my @PROPS = qw(name screen_name sort_name _active);

my $SEL_COLS = 'a.' . join(', a.', @COLS) . ', m.grp__id';
my @SEL_PROPS = ('id', @PROPS, 'grp_ids');

##############################################################################
# Instance Fields
BEGIN {
    Bric::register_fields
        ({
          # Public Fields
          id             => Bric::FIELD_RDWR,
          name           => Bric::FIELD_RDWR,
          screen_name    => Bric::FIELD_RDWR,
          sort_name      => Bric::FIELD_RDWR,

          # Private Fields
          _active        => Bric::FIELD_NONE,
         });
}

##############################################################################
# Constructors.
##############################################################################

=head1 Interface

=head2 Constructors

=head3 new

  my $keyword = Bric::Biz::Keyword->new;
  $keyword = Bric::Biz::Keyword->new($init);

Constructs a new keyword object and returns it. An anonymous hash of initial
values may be passed. The supported keys for that hash references are:

=over 4

=item name

The name of this keyword.

=item screen_name

The way this name should be displayed on screen (ie name='George', screen
name='George Washington'). If not specified name will be used for screen_name.

=item sort_name

The word used to sort keywords. If not specified then name will be used for
sort_name.

=back

The C<name> and C<domain_name> attributes must be globally unique or an
exception will be thrown.

B<Throws:>

=over

=item Exception::DA

=item Error::NotUnique

=back

=cut

sub new {
    my ($invocant, $init) = @_;
    my $class = ref $invocant || $invocant;
    $init->{_active} = 1;
    $init->{grp_ids} = [INSTANCE_GROUP_ID];
    my $name = delete $init->{name};
    my $self = $class->SUPER::new($init);
    $self->set_name($name) if defined $name;
    return $self;
}

################################################################################

=head3 lookup

  my $keyword = Bric::Biz::Keyword->lookup({ id => $id });
  $keyword = Bric::Biz::Keyword->lookup({ name => $name });

Looks up and constructs an existing keyword object in the database and returns
it. A Keyword ID or name name can be used as the keyword object unique
identifier to look up. If no keyword object is found in the database, then
C<lookup()> will return C<undef>.

B<Throws:>

=over 4

=item Exception::DA

=back

=cut

sub lookup {
    my $invocant = shift;
    # Look for the keyword in the cache, first.
    my $keyword = $invocant->cache_lookup(@_);
    return $keyword if $keyword;

    # Look up the keyword in the database.
    my $class = ref $invocant || $invocant;
    $keyword = $get_em->($class, @_) or return;

    # Throw an exception if we looked up more than one keyword.
    throw_da "Too many $class objects found" if @$keyword > 1;

    return $keyword->[0];
}

##############################################################################

=head3 list

  my @keywords = Bric::Biz::Keyword->list($params);
  my $keywords_aref = Bric::Biz::Keyword->list($params);

Returns a list or anonymous array of keyword objects based on the search
parameters passed via an anonymous hash. The supported lookup keys that may
use valid SQL wild card characters are:

=over

=item name

=item screen_name

=item sort_name

=back

The C<ANY()> operator may be used to specify a list of values for any of these
parameters.

The supported lookup keys that must be an exact value are:

=over 4

=item id

Keyword ID. May use C<ANY> for a list of possible values.

=item active

A boolean value indicating if the keyword is active.

=item grp_id

A Bric::Util::Grp::Keyword object ID. May use C<ANY> for a list of possible
values.

=item object

Returns all keywords for a given object - may be a Bric::Biz::Category,
Bric::Biz::Asset::Business::Media or a Bric::Biz::Asset::Business::Story
object. May use C<ANY> for a list of possible values.

=back

B<Throws:>

=over 4

=item Exception::DA

=back

=cut

sub list { $get_em->(@_) }

##############################################################################

=head3 href

  my $keywords_href = Bric::Biz::Keyword->href($params);

Returns an anonymous hash of keyword objects based on the search parameters
passed via an anonymous hash. The hash keys will be the keyword IDs, and the
values will be the corresponding keywords. The supported lookup keys are the
same as those for C<list()>.

B<Throws:>

=over 4

=item Exception::DA

=back

=cut

sub href { $get_em->(@_, undef, 1) }

##############################################################################
# Class Methods
##############################################################################

=head2 Class Methods

=head3 list_ids

  my @keyword_ids = Bric::Biz::Keyword->list_ids($params);
  my $keyword_ids_aref = Bric::Biz::Keyword->list_ids($params);

Returns a list or anonymous array of keyword object IDs based on the search
parameters passed via an anonymous hash. The supported lookup keys are the
same as for the C<list()> method.

B<Throws:>

=over 4

=item Exception::DA

=back

=cut

sub list_ids { $get_em->(@_, 1) }

##############################################################################

=head3 my_meths

  my $meths = Bric::Biz::Keyword->my_meths
  my @meths = Bric::Biz::Keyword->my_meths(1);
  my $meths_aref = Bric::Biz::Keyword->my_meths(1);
  @meths = Bric::Biz::Keyword->my_meths(0, 1);
  $meths_aref = Bric::Biz::Keyword->my_meths(0, 1);

Returns Bric::Biz::Keyword attribute accessor introspection data. See
L<Bric|Bric> for complete documtation of the format of that data. Returns
accessor introspection data for the following attributes:

=over

=item name

The keyword name. A unique identifier attribute.

=item screen_name

The keyword display name.

=item sort_name

The keyword sort name.

=item active

The keyword's active status boolean.

=back

=cut

{
    my @ORD = qw(name screen_name sort_name);
    my $METHS =
      { name        => { name     => 'name',
                         get_meth => sub {shift->get_name(@_)},
                         get_args => [],
                         set_meth => sub {shift->set_name(@_)},
                         set_args => [],
                         disp     => 'Name',
                         search   => 0,
                         len      => 256,
                         req      => 1,
                         type     => 'short',
                         props    => { type       => 'text',
                                       length     => 32,
                                       max_length => 256,
                                     },
                       },
        screen_name => { name     => 'screen_name',
                         get_meth => sub {shift->get_screen_name(@_)},
                         get_args => [],
                         set_meth => sub {shift->set_screen_name(@_)},
                         set_args => [],
                         disp     => 'Display Name',
                         search   => 0,
                         len      => 256,
                         type     => 'short',
                         props    => { type       => 'text',
                                       length     => 64,
                                       max_length => 256,
                                     },
                       },
        sort_name   => { name     => 'sort_name',
                         get_meth => sub {shift->get_sort_name(@_)},
                         get_args => [],
                         set_meth => sub {shift->set_sort_name(@_)},
                         set_args => [],
                         disp     => 'Sort Name',
                         search   => 1,
                         len      => 256,
                         type     => 'short',
                         props    => { type       => 'text',
                                       length     => 64,
                                       max_length => 256,
                                     },
                       },
        active      => { name     => 'active',
                         get_meth => sub { shift->is_active(@_) ? 1 : 0 },
                         get_args => [],
                         set_meth => sub { $_[1] ? shift->activate(@_)
                                             : shift->deactivate(@_)
                                         },
                         set_args => [],
                         disp     => 'Active',
                         len      => 1,
                         req      => 1,
                         props    => { type => 'checkbox' }
                       },
      };
    $METHS->{keyword} = $METHS->{name};

    sub my_meths {
        my ($invocant, $ord, $ident) = @_;
        if ($ord) {
            return wantarray ? @{$METHS}{@ORD} : [@{$METHS}{@ORD}];
        } elsif ($ident) {
            return wantarray ? $METHS->{name} : [$METHS->{name}];
        } else {
            return $METHS;
        }
    }
}

##############################################################################
# Instance Methods
##############################################################################

=head2 Accessors

=head3 id

  my $id = $keyword->get_id;

Returns the keyword object's unique database ID.

=head3 name

  my $name = $keyword->get_name;
  $keyword = $keyword->set_name($name);

Get and set the keyword object's unique name. The value of this attribute must be
case-insensitively globally unique. If a non-unique value is passed to
C<set_name()>, an exception will be thrown.

B<Side Effects:> The <screen_name> and C<sort_name> attributes will be set to
the same value as the C<name> attribute if they are not yet defined.

B<Throws:>

=over

=item Error::NotUnique

=item Error::Undef

=back

=cut

sub set_name {
    my ($self, $name) = @_;
    my $disp = $self->my_meths->{name}{disp};
    # Make sure we have a name.
        throw_undef error    => "Value of $disp cannot be empty",
                    maketext => ["Value of [_1] cannot be empty", $disp]
      unless $name and $name ne '';

    my ($old_name, $screen, $sort) =
      $self->_get(qw(name screen_name sort_name));

    # Just succeed if the new name is the same as the old name.
    return $self if defined $old_name and lc $name eq lc $old_name;

    # Check the database for any existing keywords with the new name.
    if ($self->list_ids({ name => $name })) {
        throw_not_unique
          error    => "A keyword with the $disp '$name' already exists",
          maketext => ["A keyword with the [_1] '[_2]' already exists",
                       $disp, $name];
    }

    # Success! Set the screen and sort names, if necessary.
    $screen = $name unless defined $screen and $screen ne '';
    $sort = $name unless defined $sort and $sort ne '';
    $self->_set([qw(name screen_name sort_name)], [$name, $screen, $sort]);
}

=head3 screen_name

  my $screen_name = $keyword->get_screen_name;
  $keyword = $keyword->set_screen_name($screen_name);

Get and set the keyword object's screen_name.

=head3 sort_name

  my $sort_name = $keyword->get_sort_name;
  $keyword = $keyword->set_sort_name($sort_name);

Get and set the keyword object's sort_name.

=head3 active

  $keyword = $keyword->activate;
  $keyword = $keyword->deactivate;
  $keyword = $keyword->is_active;

Get and set the keyword object's active status. C<activate()> and
C<deactivate()> each return the keyword object. C<is_active()> returns the
keyword object when the keyword is active, and C<undef> when it is not.

B<Note:> The old C<remove()>, C<get_state()> C<set_state()>, C<get_active()>,
and C<set_active()> methods have been deprecated. Please use C<is_active()>,
C<activate()>, and C<deactivate()> instead.

=cut

sub activate   { $_[0]->_set(['_active'], [1]) }
sub deactivate { $_[0]->_set(['_active'], [0]) }
sub is_active  { $_[0]->_get('_active') ? $_[0] : undef }
sub remove     {
    warn __PACKAGE__ . "->remove has been deprecated.\n" .
      "Use ", __PACKAGE__, "->deactivate instead";
    $_[0]->deactivate;
}

sub get_state {
    warn __PACKAGE__ . "->get_state has been deprecated.\n" .
      "Use ", __PACKAGE__, "->is_active instead";
    $_[0]->is_active;
}

sub set_state {
    warn __PACKAGE__ . "->set_state has been deprecated.\n" .
      "Use activate() and deactivate() instead";
    $_[1] ? $_[0]->activate : $_[0]->deactivate;
}

sub get_active {
    warn __PACKAGE__ . "->get_active has been deprecated.\n" .
      "Use ", __PACKAGE__, "->is_active instead";
    $_[0]->is_active;
}

sub set_active {
    warn __PACKAGE__ . "->set_active has been deprecated.\n" .
      "Use activate() and deactivate() instead";
    $_[1] ? $_[0]->activate : $_[0]->deactivate;
}

sub associate {
    my ($self, $obj) = @_;
    warn __PACKAGE__ . "->associate has been deprecated.\n" .
      "Use the keyword accessors on the asset or category instead";
    $obj->add_keywords($obj);
}

sub dissociate {
    my ($self, $obj) = @_;
    warn __PACKAGE__ . "->dissociate has been deprecated.\n" .
      "Use the keyword accessors on the asset or category instead";
    $obj->del_keywords($obj);
}

=head2 Instance Methods

=head3 save

  $keyword = $keyword->save;

Saves any changes to the keyword object to the database. Returns the keyword
object on success and throws an exception on failure.

B<Thows:>

=over 4

=item Error::Undef

=item Exception::DA

=back

=cut

sub save {
    my $self = shift;
    return $self unless $self->_get__dirty;
    my ($id, $name) = $self->_get(qw(id name));

    # Make sure we have a name.
    unless (defined $name and $name ne '') {
        my $disp = $self->my_meths->{name}{disp};
        throw_undef error    => "Value of $disp cannot be empty",
                    maketext => ["Value of [_1] cannot be empty", $disp];
    }

    if ($id) {
        # Update the record in the database.
        my $set_cols = join ' = ?, ', @COLS;
        my $upd = prepare_c(qq{
            UPDATE $TABLE
            SET    $set_cols = ?
            WHERE  id = ?
        }, undef, DEBUG);

        # Make it so.
        execute($upd, $self->_get('id', @PROPS), $id);
    } else {
        # Insert a new record into the database.
        my $value_cols = join ', ', next_key('keyword'), ('?') x @PROPS;
        my $ins_cols = join ', ', @COLS;
        my $ins = prepare_c(qq{
            INSERT INTO $TABLE ($ins_cols)
            VALUES ($value_cols)
        }, undef, DEBUG);

        # Make it so.
        execute($ins, $self->_get(@PROPS));

        # Now grab the new ID.
        $self->_set(['id'], [last_key('keyword')]);

        # And finally, register this keyword in the "All Keywords" group.
        $self->register_instance(INSTANCE_GROUP_ID, GROUP_PACKAGE);
    }

    # Finish up.
    $self->SUPER::save;
}

##############################################################################

=begin private

=head2 Private Functions

=head3 $get_em

  $get_em->($invocant, $params, $ids_only, $href);

Function used by C<lookup()>, C<list()>, and C<list_ids()> to retrieve
keyword objects from the database. The arguments are as follows:

=over

=item C<$invocant>

The class name or object that invoked the method call.

=item C<$params>

The hashref of parameters supported by the method and that can be used to
create a SQL search query.

=item C<$ids_only>

A boolean indicating whether to return keyword objects or keyword IDs only.

=item C<$href>

A boolean indicating whether to return the keyword objects as a hash
reference. Used by C<href()>.

=back

B<Throws:>

=over 4

=item Exception::DA

=back

=cut

$get_em = sub {
    my ($invocant, $params, $ids_only, $href) = @_;
    my $tables = "$TABLE a, member m, keyword_member c";
    my $wheres = 'a.id = c.object_id AND c.member__id = m.id AND ' .
      "m.active = '1'";
    my @params;

    while (my ($k, $v) = each %$params) {
        if ($k eq 'id') {
            # Simple lookup by ID.
            $wheres .= ' AND ' . any_where($v, "a.id = ?", \@params);
        } elsif ($k eq 'active') {
            # Simple lookup by "active" boolean.
            $wheres .= " AND a.active = ?";
            push @params, $v ? 1 : 0;
        } elsif ($k eq 'grp_id') {
            # Look up by group membership.
            $tables .= ", member m2, keyword_member c2";
            $wheres .= " AND a.id = c2.object_id AND c2.member__id = m2.id"
              . " AND m2.active = '1' AND "
              . any_where($v, "m2.grp__id = ?", \@params);
        } elsif ($k eq 'object') {
            # Look up by object association.
            my $key = $v->key_name;
            $tables .= ", $key\_keyword o";
            $v = $v->isa('Bric::Util::DBI::ANY')
              ? ANY(map { $_->get_id } @$v)
              : $v->get_id;
            $wheres .= " AND o.keyword_id = a.id AND "
              . any_where($v, "o.$key\_id = ?", \@params);
        } else {
            # Simple string comparison.
            $wheres .= ' AND '
              . any_where($v, "LOWER(a.$k) LIKE LOWER(?)", \@params);
        }
    }

    my ($qry_cols, $order) = $ids_only ? (\'DISTINCT a.id', 'a.id') :
      (\$SEL_COLS, 'LOWER(a.sort_name), a.id');

    my $sel = prepare_c(qq{
        SELECT $$qry_cols
        FROM   $tables
        WHERE  $wheres
        ORDER BY $order
    }, undef, DEBUG);

    # Just return the IDs, if they're what's wanted.
    if ($ids_only) {
        my $ids = col_aref($sel, @params);
        return unless @$ids;
        return wantarray ? @$ids : $ids;
    }

    execute($sel, @params);
    my (@d, @keywords, %keywords, $grp_ids);
    bind_columns($sel, \@d[0..$#SEL_PROPS]);
    my $last = -1;
    my $class = ref $invocant || $invocant;
    while (fetch($sel)) {
        if ($d[0] != $last) {
            $last = $d[0];
            # Create a new keyword object.
            my $self = $class->SUPER::new;
            # Get a reference to the array of group IDs.
            $grp_ids = $d[$#d] = [$d[$#d]];
            $self->_set(\@SEL_PROPS, \@d);
            $self->_set__dirty; # Disables dirty flag.
            $href ? $keywords{$d[0]} = $self->cache_me :
              push @keywords, $self->cache_me;
        } else {
            push @$grp_ids, $d[$#d];
        }
    }

    return \%keywords if $href;
    return unless @keywords;
    return wantarray ? @keywords : \@keywords;
};

1;
__END__

=pod

=end private

=head1 Authors

Garth Webb <garth@perijove.com>

Sam Tregar <stregar@about-inc.com>

David Wheeler <david@kineticode.com>

=head1 See Also

=over 4

=item L<Bric::Biz::Asset::Business|Bric::Biz::Asset::Business>

Business assets, including stories and media, can be associated with keywords.

=item L<Bric::Biz::Category|Bric::Biz::Category>

Categories can be associated with key words.

=back

=head1 Copyright and License

Copyright (c) 2001 About.com. Changes Copyright (c) 2002-2003 Kineticode, Inc.
and others. See L<Bric::License|Bric::License> for complete license terms and
conditions.

=cut
