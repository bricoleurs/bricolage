package Bric::Biz::Keyword;
###############################################################################

=head1 NAME

Bric::Biz::Keyword - A general class to manage keywords.

=head1 VERSION

$Revision: 1.13 $

=cut

our $VERSION = (qw$Revision: 1.13 $ )[-1];

=head1 DATE

$Date: 2003-01-29 06:46:03 $

=head1 SYNOPSIS

 use Bric::Biz::Keyword;

 # Create a new keyword object.
 my $key = new Bric::Biz::Keyword($init);

 # Lookup an existing keyword.
 my $key = new Bric::Biz::Keyword($key_id);

 # Create a list of keyword objects.
 my $key = list Bric::Biz::Keyword($param);

 # Get/set the keyword name.
 $name    = $key->get_name();
 $success = $key->set_name($name);

 # Get/set the screen (display) name.
 $screen  = $key->get_screen_name();
 $success = $key->set_screen_name($screen);

 # Mark this keyword inactive
 $success = $key->delete();

 # Save this asset to the database.
 $success = $key->save();

 # Link a keyword with a story (or media object or category)
 $key->associate($story);

 # Break the link between a keyword and a story (or media object or category)a
 $key->dissociate($story);


=head1 DESCRIPTION

The Keyword module allows assets to be characterized by a set of topical
keywords. These keywords can be used to group assets or during a search on a
particular topic.

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
use Bric::Util::Grp::Keyword;

#==============================================================================#
# Inheritance                          #
#======================================#

use base qw(Bric);

#=============================================================================#
# Function Prototypes                  #
#======================================#


#==============================================================================#
# Constants                            #
#======================================#

use constant TABLE  => 'keyword';
use constant COLS   => qw(name screen_name sort_name active);


#==============================================================================#
# FIELDS                               #
#======================================#

#--------------------------------------#
# Public Class Fields
our $METH;

#--------------------------------------#
# Private Class Fields
my $gen = 'Bric::Util::Fault::Exception::GEN';

#--------------------------------------#
# Instance Fields

# This method of Bricolage will call 'use fields' for you and set some permissions.
BEGIN {
    Bric::register_fields({
                         # Public Fields
                         'id'             => Bric::FIELD_RDWR,
                         'name'           => Bric::FIELD_RDWR,
                         'screen_name'    => Bric::FIELD_RDWR,
                         'sort_name'      => Bric::FIELD_RDWR,
                         'active'         => Bric::FIELD_RDWR,
                        });
}

#==============================================================================#

=head1 INTERFACE

=head2 Constructors

=over 4

=cut

#--------------------------------------#
# Constructors
#------------------------------------------------------------------------------#

=item $obj = Bric::Biz::Keyword->new(\%init);

Creates a new keyword and keyword object.  Keys for %init are:

=over 4

=item C<name>

The name of this keyword - required.

=item C<screen_name>

The way this name should be displayed on screen (ie name='George',
screen name='George Washington').  If not specified name will be used
for screen_name.

=item C<sort_name>

The word used to sort keywords.  If not specified then name will be
used for sort_name.

=back

Throws: NONE

Side Effects: NONE

Notes: NONE

=cut

sub new {
    my ($pkg, $init) = @_;

    # Map state to active since state is just overriding active's role.
    $init->{'active'} = exists $init->{'state'} ? delete $init->{'state'} : 1;
    # construct the object
    my $self = $pkg->SUPER::new($init);

    # Return the object.
    return $self;
}

#------------------------------------------------------------------------------#

=item $obj = Bric::Biz::Keyword->lookup({ id   => $key_id    });

=item $obj = Bric::Biz::Keyword->lookup({ name => "key name" });

Retrieves a single existing keyword from the database.  Takes either a
keyword ID or the keyword name.

Throws:

=over 4

=item *

Bad parameters passed to 'lookup'

=back

Side Effects: NONE

Notes: NONE

=cut

sub lookup {
    my ($pkg, $param) = @_;
    my $self = $pkg->cache_lookup($param);
    return $self if $self;

    my $ret;
    if (exists $param->{'id'}) {
        $ret = _select_keywords('id = ?', [$param->{'id'}]);
    } elsif (exists $param->{'name'}) {
        $ret = _select_keywords('LOWER(name) LIKE ?', [lc $param->{'name'}]);
    } else {
        die $gen->new({ msg => "Bad parameters passed to 'lookup'"});
    }

    # return nothing if we got nothing
    return unless @$ret;

    # return the object
    return $ret->[0];
}

#------------------------------------------------------------------------------#

=item @objs = list Bric::Biz::Keyword($param);

Searches for keywords returning matches ordered by sort_name.  The
possible keys to $param are the following;

=over 4

=item C<name>

Search for keywords by name.  Matched with LIKE.

=item C<screen_name>

Search for keywords by screen name.  Matched with LIKE.

=item C<sort_name>

Search for keywords by sort name.  Matched with LIKE.

=item C<active>

Search for keywords by active flag.  If you don't set this flag then
active => 1 is implicitely used.

=item C<synonyms>

Returns all the synonyms for the given keyword or keyword ID.  Cannot
be legally combined with the object param.

=item C<object>

Returns all keywords for a given object - may be a
Bric::Biz::Category, Bric::Biz::Asse::Business::Media or a
Bric::Biz::Asse::Business::Story object.  Cannot be legally combined
with the synonyms param.

=back

Throws:

=over 4

=item *

Unsupported object type : $ref

=item *

Synonyms search cannot be combined with object search.

=back

Side Effects: NONE

Notes: NONE

=cut

sub list {
    my ($pkg, $param) = @_;
    my (@select, $from, @where, @bind);

    # Make sure to set active explictly if its not passed.
    $param->{active} = 1 unless exists $param->{active};

    # default from clause
    $from = TABLE . ' k';

    # Build a list of selected columns.
    @select = ('k.id', map { "k.$_" } COLS);

    # handle text fields
    foreach my $f (qw(name screen_name sort_name )) {
        next unless exists $param->{$f};
        push @where, "LOWER(k.$f) LIKE ?";
        push @bind,  lc $param->{$f};
    }

    # handle numeric fields (id is supported here because the old
    # Bric::Biz::Keyword supported it and I can't be sure something
    # isn't using it.  Really lookup() is a better choice for getting
    # keywords by id.
    foreach my $f (qw(id active)) {
        next unless exists $param->{$f};
        push @where, "$f = ?";
        push @bind,  lc $param->{$f};
    }

    # handle searches for object keywords
    if (exists $param->{object}) {
        my $obj = $param->{object};

        # determine table and field name for search
        my ($table, $field) = _get_db_data_for_object($obj);

        # setup from and where clauses
        $from = "$table x, keyword k";
        push @where, ("x.keyword_id = k.id", "x.$field = ?");
        push @bind, $obj->get_id;
    }

    # build SQL
    my $sql = "SELECT " . join(',','id',COLS) . " FROM " . $from;
    $sql   .= ' WHERE ' . join(' AND ', @where) if @where;
    $sql   .= ' ORDER BY sort_name';

    # prepare and execute select
    my $sth = prepare_c($sql);
    execute($sth, @bind);

    # fetch data and build result objects
    my (@d, $keyword, @ret);
    bind_columns($sth, \@d[0..(scalar COLS)]);
    while (fetch($sth)) {
        # create a new keyword object and push it on the return array
        $keyword = __PACKAGE__->SUPER::new();
        $keyword->_set(['id', COLS], \@d);
        push @ret, $keyword->cache_me;
    }
    finish($sth);

    return wantarray ? @ret : \@ret;
}

#------------------------------------------------------------------------------#

=item $success = $key->delete;

Marks a keyword inactive in the database.  Equivalent to calling
set_active(0).

Throws: NONE

Side Effects: NONE

Notes: NONE

=cut

sub remove {
    my $self = shift;
    $self->set_active(0);
    return $self;
}

#--------------------------------------#

=back

=head2 Public Class Methods

=over 4

=item $meths = Bric::Biz::Keyword->my_meths

=item (@meths || $meths_aref) = Bric::Biz::Keyword->my_meths(TRUE)

Returns an anonymous hash of instrospection data for this object. If called
with a true argument, it will return an ordered list or anonymous array of
intrspection data. The format for each introspection item introspection is as
follows:

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
    # Load field members.
    return $METH if $METH;

    $METH = {'name'        => {'get_meth' => sub {shift->get_name(@_)},
                               'get_args' => [], 
                               'set_meth' => sub {shift->set_name(@_)},
                               'set_args' => [],
                               'disp'     => 'Keyword Name',
                               'search'   => 1,
                               'len'      => 256,
                               'type'     => 'short',
                               'props'    => {'type'       => 'text',
                                              'length'     => 32,
                                              'max_length' => 256,}
                              },
             'screen_name' => {'get_meth' => sub {shift->get_screen_name(@_)}, 
                               'get_args' => [],
                               'set_meth' => sub {shift->set_screen_name(@_)},
                               'set_args' => [],
                               'disp'     => 'Keyword screen name',
                               'search'   => 0,
                               'len'      => 256,
                               'type'     => 'short',
                               'props'    => {'type'       => 'text',
                                              'length'     => 64,
                                              'max_length' => 256,}
                              },
             'sort_name'   => {'get_meth' => sub {shift->get_sort_name(@_)},
                               'get_args' => [], 
                               'set_meth' => sub {shift->set_sort_name(@_)},
                               'set_args' => [],
                               'disp'     => 'Sort order name',
                               'search'   => 0,
                               'len'      => 256,
                               'type'     => 'short',
                               'props'    => {'type'       => 'text',
                                              'length'     => 64,
                                              'max_length' => 256,}
                              },
            };
    $METH->{keyword} = $METH->{name};
    # Load attributes.
    # NONE
    return $METH;
}

#--------------------------------------#

=back

=head2 Public Instance Methods

=over 4

=item $key->associate($obj)

Associates a keyword with an object.  The object must by of a type
that supports keywords - currently Bric::Biz::Asset::Business::Story,
Bric::Biz::Asset:::Business::Media and Bric::Biz::Category.  This call
commits the change directly to the database.  There is no need to call
save() afterward.

Returns 0 if $key is already associated with $obj, 1 if a new
relationship was created.

Throws:

=over 4

=item *

Unsupported object type : $ref.

=back

Side Effects: NONE

Notes: Cannot be called on an unsaved keyword.  Call save() first.

=cut

sub associate {
    my ($self, $obj) = @_;
    my $id           = $self->get_id;
    my $obj_id       = $obj->get_id;

    # determine table and field name for this relationship
    my ($table, $field) = _get_db_data_for_object($obj);

    # check if this keyword is already associated with this category
    my ($exists) = row_array("SELECT 1 FROM $table ".
                             "WHERE $field = ? AND keyword_id = ?",
                             $obj_id, $id);
    return 0 if defined $exists and $exists == 1;

    # insert a new relationship
    my $sth = prepare("INSERT INTO $table ($field, keyword_id) ".
                      "VALUES (?, ?)");
    execute($sth, $obj_id, $id);
    finish($sth);

    return 1;
}

=item $key->dissociate($obj)

Dissociates a keyword from an object.  The object must by of a type
that supports keywords - currently Bric::Biz::Asset::Business::Story,
Bric::Biz::Asset:::Business::Media and Bric::Biz::Category.  This call
commits the change directly to the database.  There is no need to call
save() afterward.

Returns 0 if $key is not associated with $obj, 1 if the relationship
was successfully removed.

Throws:

Unsupported object type : $ref.

Side Effects: NONE

Notes: Cannot be called on an unsaved keyword.  Call save() first.

=cut

sub dissociate {
    my ($self, $obj) = @_;
    my $id           = $self->get_id;
    my $obj_id       = $obj->get_id;

    # determine table and field name for this relationship
    my ($table, $field) = _get_db_data_for_object($obj);

    # delete relationship
    my $sth = prepare("DELETE FROM $table WHERE $field = ? AND keyword_id = ?");
    execute($sth, $obj_id, $id);
    finish($sth);

    return 1;
}

=item $name = $key->get_name();

Returns the name of this keyword

B<Throws:> NONE

B<Side Effects:> NONE

B<Notes:> NONE

=cut

#------------------------------------------------------------------------------#

=item $name = $key->set_name($name);

Sets the name of this keyword

B<Throws:> NONE

B<Side Effects:> NONE

B<Notes:> NONE

=cut

#------------------------------------------------------------------------------#

=item $name = $key->get_screen_name();

Returns the screen name of this keyword.  The screen name is how the
synonym should be displayed on screen (i.e. name='george'
screen_name='Washington, George')

B<Throws:> NONE

B<Side Effects:> NONE

B<Notes:> NONE

=cut

#------------------------------------------------------------------------------#

=item $name = $key->set_screen_name($name);

Sets the screen name of this keyword.

B<Throws:> NONE

B<Side Effects:> NONE

B<Notes:> NONE

=cut

#------------------------------------------------------------------------------#

=item $state = $key->get_state();

Deprecated alias for get_active().

B<Throws:> NONE

B<Side Effects:> NONE

B<Notes:> NONE

=cut

sub get_state { shift->get_active }

#------------------------------------------------------------------------------#

=item $state = $key->set_state();

Deprecated alias for set_active().

B<Throws:> NONE

B<Side Effects:> NONE

B<Notes:> NONE

=cut

sub set_state { shift->set_active(@_) }

#------------------------------------------------------------------------------#

=item $success = $key->save;

Save the keyword to the database.

B<Throws:>

"Unable to save";

B<Side Effects:>

Will give default values to screen_name and sort_name if they are not set.

B<Notes:> NONE

=cut

sub save {
    my $self = shift;
    my $id = $self->get_id;

    return unless $self->_get__dirty;

    # Set some defaults if these values aren't already set.
    my ($name, $scrn, $sort) = $self->_get('name', 'screen_name', 'sort_name');
    $scrn = $name unless defined $scrn;
    $sort = $name unless defined $sort;
    $self->_set(['screen_name', 'sort_name'], [$scrn, $sort]);

    if ($id) {
        $self->_update_keyword();
    } else {
        $self->_insert_keyword();
    }

    $self->_set__dirty(0);

    return $self;
}

#==============================================================================#

=back

=head2 Private Methods

=cut

#--------------------------------------#

=head2 Private Class Methods

NONE

=cut

#--------------------------------------#

=head2 Private Instance Methods

=over 4

=item $keywords = _select_keywords($where, $bind)

=item @keywords = _select_keywords($where, $bind)

Selects keywords from the database given an SQL where clause and a ref
to an array of bind parameters.  Returns fully constructed
Bric::Biz::Keyword objects.

=cut

sub _select_keywords {
    my ($where, $bind) = @_;
    my (@d, @ret);

    my $sql = 'SELECT '.join(',','id',COLS).' FROM '.TABLE;
    $sql   .= ' WHERE '.$where if $where;
    $sql   .= ' ORDER BY sort_name';

    my $sth = prepare_c($sql);
    execute($sth, @$bind);
    bind_columns($sth, \@d[0..(scalar COLS)]);

    my ($keyword);
    while (fetch($sth)) {
        # create a new keyword object and push it on the return array
        $keyword = __PACKAGE__->SUPER::new();
        $keyword->_set(['id', COLS], \@d);
        push @ret, $keyword->cache_me;
    }

    finish($sth);

    return wantarray ? @ret : \@ret;
}

=item $self->_update_keyword()

Updates the keyword object in the database.

=cut

sub _update_keyword {
    my $self = shift;
    my $sql = 'UPDATE '.TABLE.
              ' SET '.join(',', map {"$_=?"} COLS).' WHERE id=?';


    my $sth = prepare_c($sql);
    execute($sth, $self->_get(COLS), $self->get_id);
    return 1;
}

=item $self->_insert_keyword()

Inserts the new keyword object into the database.

=cut

sub _insert_keyword {
    my $self = shift;
    my $nextval = next_key(TABLE);

    # Create the insert statement.
    my $sql = 'INSERT INTO '.TABLE." (id,".join(',',COLS).") ".
              "VALUES ($nextval,".join(',', ('?') x COLS).')';

    my $sth = prepare_c($sql);
    execute($sth, $self->_get(COLS));

    # Set the ID of this object.
    $self->_set(['id'],[last_key(TABLE)]);

    return 1;
}

=item ($table, $field) = _get_db_data_for_object($obj)

Returns the correct relationship table and field name for a given
supported object.  For example, for a story object it returns
("story_keyword", "story_id").

Throws:

Unsupported object type : $ref.

Side Effects: NONE

Notes: NONE

=cut

sub _get_db_data_for_object {
    my $obj = shift;
    my $ref = ref $obj;
    return ("story_keyword",    "story_id")    if $ref =~ /Story$/;
    return ("media_keyword",    "media_id")    if $ref =~ /Media$/;
    return ("category_keyword", "category_id") if $ref =~ /Category$/;
    die $gen->new({msg => "Unsupported object type : $ref."});
}

1;
__END__

=back

=head1 NOTES

NONE

=head1 AUTHOR

"Garth Webb" <garth@perijove.com> Bricolage Engineering

Sam Tregar <stregar@about-inc.com>

=head1 SEE ALSO

L<Bric>

=cut
