package Bric::Util::MediaType;

=head1 NAME

Bric::Util::MediaType - Interface to Media Types.

=head1 VERSION

$Revision: 1.6 $

=cut

# Grab the Version Number.
our $VERSION = (qw$Revision: 1.6 $ )[-1];

=head1 DATE

$Date: 2002-01-06 04:40:36 $

=head1 SYNOPSIS

  use Bric::Util::MediaType;

=head1 DESCRIPTION

This class may be used for managing media types (a.k.a. "MIME types"). Bricolage ships
with a number of default media types accessible via this class. This class may
also be used to create new media types.

=cut

################################################################################
# Dependencies
################################################################################
# Standard Dependencies
use strict;

################################################################################
# Programmatic Dependences
use Bric::Util::DBI qw(:standard col_aref prepare_ca);
use Bric::Util::Fault::Exception::DP;
use Bric::App::Cache;

################################################################################
# Inheritance
################################################################################
use base qw(Bric);

################################################################################
# Function and Closure Prototypes
################################################################################
my ($get_em, $make_obj, $lookup_ext, $get_ext_data);

################################################################################
# Constants
################################################################################
use constant DEBUG => 0;

################################################################################
# Fields
################################################################################
# Public Class Fields

################################################################################
# Private Class Fields
my $dp = 'Bric::Util::Fault::Exception::DP';
my @cols = qw(m.id m.name m.description m.active e.extension);
my @mcols = qw(id name description active);
my @mprops = qw(id name description _active);
my @ecols = qw(id media_type__id extension);
my @props = qw(id name description _active _exts _new_exts _del_exts);
my @ord = qw(name description active);
my %map = ( name => 'LOWER(name) LIKE ?',
	    description => 'LOWER(description) LIKE ?',
	    ext => => 'LOWER(e.extension) LIKE ?');
my $key = '__MediaType__';
my ($meths, $cache);

################################################################################

################################################################################
# Instance Fields
BEGIN {
    Bric::register_fields({
			 # Public Fields
			 id => Bric::FIELD_READ,
			 name => Bric::FIELD_RDWR,
			 description => Bric::FIELD_RDWR,

			 # Private Fields
			 _exts => Bric::FIELD_NONE,
			 _new_exts => Bric::FIELD_NONE,
			 _del_exts => Bric::FIELD_NONE,
			 _active => Bric::FIELD_NONE
			});
}

################################################################################
# Class Methods
################################################################################

=head1 INTERFACE

=head2 Constructors

=over 4

=item my $mt = Bric::Util::MediaType->new($init)

Instantiates a Bric::Util::MediaType object. An anonymous hash of initial values
may be passed. The supported initial value keys are:

=over 4

=item *

name

=item *

description

=item *

ext - An anonymous array of extensions.

=back

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub new {
    my ($pkg, $init) = @_;
    my $self = bless {}, ref $pkg || $pkg;
    $init->{_exts} = { map { $_ => 1 } @{ delete $init->{ext} } }
      if $init->{ext};
    @{$init}{qw(_new_exts _del_exts)} = ({}, {});
    $self->SUPER::new($init);
}

################################################################################

=item my $mt = Bric::Util::MediaType->lookup({ id => $id })

=item my $mt = Bric::Util::MediaType->lookup({ name => $name })

=item my $mt = Bric::Util::MediaType->lookup({ ext => $ext })

Looks up and instantiates a new Bric::Util::MediaType object based on the
Bric::Util::MediaType object ID, name, or filename extension passed. If $id,
$name, or $ext is not found in the database, lookup() returns undef.

B<Throws:>

=over

=item *

Too many Bric::Dist::Util::MediaType objects found.

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

B<Side Effects:> If $id is found, populates the new Bric::Util::MediaType object with
data from the database before returning it.

B<Notes:> NONE.

=cut

sub lookup {
    my $mt = &$get_em(@_);
    # We want @$mt to have only one value.
    die $dp->new({  msg => 'Too many Bric::Util::MediaType objects found.' })
      if @$mt > 1;
    return @$mt ? $mt->[0] : undef;
}

################################################################################

=item my (@foos || $mts_aref) = Bric::Util::MediaType->list($params)

Returns a list or anonymous array of Bric::Util::MediaType objects based on the
search parameters passed via an anonymous hash. The supported lookup keys are:

=over 4

=item *

description

=item *

name

=item *

ext

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

B<Side Effects:> Populates each Bric::Util::MediaType object with data from the
database before returning them all.

B<Notes:> NONE.

=cut

sub list { wantarray ? @{ &$get_em(@_) } : &$get_em(@_) }

################################################################################

=back 4

=head2 Destructors

=over 4

=item $mt->DESTROY

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

=item my (@foo_ids || $mt_ids_aref) = Bric::Util::MediaType->list_ids($params)

Returns a list or anonymous array of Bric::Util::MediaType object IDs based on the
search criteria passed via an anonymous hash. The supported lookup keys are the
same as those for list().

B<Throws:>

over 4

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

=item my $name = Bric::Util::MediaType->get_name_by_ext($filename)

=item my $name = Bric::Util::MediaType->get_name_by_ext($ext)

Returns the name of a media type that is associated with the extension found at
the end of $filename. If there is no extension, the entire argument is assumed
to be the extension. If the extension doesn't exist in the database,
get_name_by_ext() will return undef.

B<Throws:>

over 4

=item *

Unable to instantiate cache.

=item *

Unable to fetch value from the cache.

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=item *

Unable to select row.

=item *

Unable to cache value.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_name_by_ext { &$lookup_ext( $_[1], 1 ) }

################################################################################

=item my $id = Bric::Util::MediaType->get_id_by_ext($filename)

=item my $id = Bric::Util::MediaType->get_id_by_ext($ext)

Returns the id of a Bric::Util::MediaType object that is associated with the
extension found at the end of $filename. If there is no extension, the entire
argument is assumed to be the extension. If the extension doesn't exist in the
database, get_name_by_ext() will return undef.

B<Throws:>

over 4

=item *

Unable to instantiate cache.

=item *

Unable to fetch value from the cache.

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=item *

Unable to select row.

=item *

Unable to cache value.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_id_by_ext { &$lookup_ext( $_[1] ) }

################################################################################

=item $meths = Bric::Util::MediaType->my_meths

=item (@meths || $meths_aref) = Bric::Util::MediaType->my_meths(TRUE)

Returns an anonymous hash of instrospection data for this object. If called with
a true argument, it will return an ordered list or anonymous array of
intrspection data. The format for each introspection item introspection is as
follows:

Each hash key is the name of a property or attribute of the object. The value
for a hash key is another anonymous hash containing the following keys:

=over 4

=item *

name - The name of the property or attribute. Is the same as the hash key when
an anonymous hash is returned.

=item *

disp - The display name of the property or attribute.

=item *

get_meth - A reference to the method that will retrieve the value of the
property or attribute.

=item *

get_args - An anonymous array of arguments to pass to a call to get_meth in
order to retrieve the value of the property or attribute.

=item *

set_meth - A reference to the method that will set the value of the
property or attribute.

=item *

set_args - An anonymous array of arguments to pass to a call to set_meth in
order to set the value of the property or attribute.

=item *

type - The type of value the property or attribute contains. There are only
three types:

=over 4

=item short

=item date

=item blob

=back

=item *

len - If the value is a 'short' value, this hash key contains the length of the
field.

=item *

search - The property is searchable via the list() and list_ids() methods.

=item *

req - The property or attribute is required.

=item *

props - An anonymous hash of properties used to display the property or attribute.
Possible keys include:

=over 4

=item *

type - The display field type. Possible values are

=item text

=item textarea

=item password

=item hidden

=item radio

=item checkbox

=item select

=back

=item *

length - The Length, in letters, to display a text or password field.

=item *

maxlength - The maximum length of the property or value - usually defined by the
SQL DDL.

=item *

rows - The number of rows to format in a textarea field.

=item

cols - The number of columns to format in a textarea field.

=item *

vals - An anonymous hash of key/value pairs reprsenting the values and display
names to use in a select list.

=back

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub my_meths {
    my ($pkg, $ord) = @_;

    # Return 'em if we got em.
    return !$ord ? $meths : wantarray ? @{$meths}{@ord} : [@{$meths}{@ord}]
      if $meths;

#my @ord = qw(name description active);
    # We don't got 'em. So get 'em!
    $meths = {
	      name   => {
			      name     => 'name',
			      get_meth => sub { shift->get_name(@_) },
			      get_args => [],
			      set_meth => sub { shift->set_name(@_) },
			      set_args => [],
			      disp     => 'Name',
			      search   => 1,
			      len      => 128,
			      req      => 0,
			      type     => 'short',
			      props    => {   type       => 'text',
					      length     => 32,
					      maxlength => 128
					  }
			     },
	      description => {
			      name     => 'description',
			      get_meth => sub { shift->get_description(@_) },
			      get_args => [],
			      set_meth => sub { shift->set_description(@_) },
			      set_args => [],
			      disp     => 'Description',
			      search   => 1,
			      len      => 256,
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

=back

=head2 Public Instance Methods

=over 4

=item my $id = $mt->get_id

Returns the ID of the Bric::Util::MediaType object.

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

B<Notes:> If the Bric::Util::MediaType object has been instantiated via the new()
constructor and has not yet been C<save>d, the object will not yet have an ID,
so this method call will return undef.

=item my $name = $mt->get_name

Returns the media type name, e.g., 'text/html'.

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

=item $self = $mt->set_name($name)

Sets the media type name.

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

=item my $description = $mt->get_description

Returns the media type description.

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

=item $self = $mt->set_description($description)

Sets the media type description.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: WRITE access for field 'description' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my (@exts || $exts_aref) = $mt->get_exts()

Returns a list or anonymous array of filename extensions that indicate this
media type.

B<Throws:>

=over 4

=item *

Problems retrieving fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_exts {
    my $self = shift;
    my ($ex, $new) = $self->_get(qw(_exts _new_exts));
    return sort (keys %$ex, keys %$new);
}

################################################################################

=item $self = $mt->add_exts(@exts)

Associates extensions with this media type. Note that all extensions must be
unique; no two media types can share the same extension.

B<Throws:>

=over 4

=item *

Problems retrieving fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub add_exts {
    my ($self, @exts) = @_;
    my ($ex, $new) = $self->_get(qw(_exts _new_exts));
    foreach my $e (@exts) {
	$e = lc $e;
	$new->{$e} = 1 unless $ex->{$e};
    }
    return $self;
}

################################################################################

=item $self = $mt->del_exts(@exts)

Dissociates extensions from this media type.

B<Throws:>

=over 4

=item *

Problems retrieving fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub del_exts {
    my ($self, @exts) = @_;
    my ($ex, $new, $del) = $self->_get(qw(_exts _new_exts _del_exts));
    foreach my $e (@exts) {
	$e = lc $e;
	$del->{$e} = 1 if delete $ex->{$e};
	delete $new->{$e};
    }
    return $self;
}

################################################################################

=item $self = $mt->activate

Activates the Bric::Util::MediaType object. Call $mt->save to make the change
persistent. Bric::Util::MediaType objects instantiated by new() are active by
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

sub activate { $_[0]->_set(['_active'], [1]) }

=item $self = $mt->deactivate

Deactivates (deletes) the Bric::Util::MediaType object. Call $mt->save to make
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

sub deactivate { $_[0]->_set(['_active'], [0]) }

=item $self = $mt->is_active

Returns $self if the Bric::Util::MediaType object is active, and undef if it is not.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub is_active { $_[0]->_get('_active') ? $_[0] : undef }

################################################################################

=item $self = $mt->save

Saves any changes to the Bric::Util::MediaType object. Returns $self on success and undef on
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

=item *

Unable to instantiate cache.

=item *

Unable to fetch value from the cache.

=item *

Unable to cache value.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub save {
    my $self = shift;
    return $self unless $self->_get__dirty;
    my ($id, $ext, $new, $old) = $self->_get(qw(id _exts _new_exts _del_exts));

    if (defined $id) {
	# It's an existing media type. Update it.
	local $" = ' = ?, '; # Simple way to create placeholders with an array.
	my $upd = prepare_c(qq{
            UPDATE media_type
            SET   @mcols = ?
            WHERE  id = ?
        });
	execute($upd, $self->_get(@mprops), $id);
    } else {
	# It's a new media type. Insert it.
	local $" = ', ';
	my $fields = join ', ', next_key('media_type'), ('?') x $#mcols;
	my $ins = prepare_c(qq{
            INSERT INTO media_type (@mcols)
            VALUES ($fields)
        }, undef, DEBUG);
	# Don't try to set ID - it will fail!
	execute($ins, $self->_get(@mprops[1..$#mprops]));
	# Now grab the ID.
	$id = last_key('media_type');
	$self->_set(['id'], [$id]);
    }

    # Load the cache.
    $cache ||= Bric::App::Cache->new;
    my $exts_cache = $cache->get($key) || {};

    # Delete extensions.
    if (%$old) {
	my $del = prepare_c(qq{
            DELETE FROM media_type_ext
            WHERE extension = ?
        }, undef, DEBUG);
	foreach my $e (keys %$old) {
	    execute($del, $e);
	    delete $exts_cache->{$e};
	}
	%$old = ();
    }

    # Save new extensions.
    if (%$new) {
	local $" = ', ';
	my $fields = join ', ', next_key('media_type_ext'), ('?') x $#ecols;
	my $ins = prepare_c(qq{
            INSERT INTO media_type_ext (@ecols)
            VALUES ($fields)
        }, undef, DEBUG);

	my $name = $self->_get('name');
	foreach my $e (keys %$new) {
	    execute($ins, $id, $e);
	    $ext->{$e} = 1;
	    $exts_cache->{$e} = [$id, $name] if $exts_cache->{$e};
	}
	%$new = ();
    }

    # Save the cache.
    $cache->set($key, $exts_cache);


    $self->SUPER::save;
    return $self;
}

################################################################################

=back 4

=head1 PRIVATE

=head2 Private Class Methods

NONE.

=head2 Private Instance Methods

NONE.

=head2 Private Functions

=over 4

=item my $mt_aref = &$get_em( $pkg, $params )

=item my $mt_ids_aref = &$get_em( $pkg, $params, 1 )

Function used by lookup() and list() to return a list of Bric::Util::MediaType objects
or, if called with an optional third argument, returns a listof Bric::Util::MediaType
object IDs (used by list_ids()).

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
    my ($pkg, $params, $ids) = @_;
    my (@wheres, @params);
    while (my ($k, $v) = each %$params) {
	if ($k eq 'id') {
	    push @wheres, "m.$k = ?";
	    push @params, $v;
	} else {
	    # It's a varchar field.
	    push @wheres, $map{$k};
	    push @params, lc $v;
	}
    }

    # Assemble the WHERE statement.
    my $where = @wheres ? join("\n               AND ", ('', @wheres)) : '';

    # Assemble the query.
    local $" = ', ';
    my $qry_cols = $ids ? ['DISTINCT m.id'] : \@cols;
    my $sel = prepare_ca(qq{
        SELECT @$qry_cols
        FROM   media_type m, media_type_ext e
        WHERE  m.id = e.media_type__id$where
        ORDER BY m.name
    }, undef, DEBUG);

    # Just return the IDs, if they're what's wanted.
    return col_aref($sel, @params) if $ids;

    execute($sel, @params);
    my ($last, @d, @init, $ext, @mts) = (-1);
    bind_columns($sel, \@d[0..$#cols-1], \$ext);
    $pkg = ref $pkg || $pkg;
    while (fetch($sel)) {
	if ($d[0] != $last) {
	    # Create a new object.
	    push @mts, &$make_obj($pkg, \@init) unless $last == -1;
	    # Get the new record.
	    $last = $d[0];
	    @init = (@d, {});
	}
	# Grab the MIME type.
	$init[$#init]->{$ext} = 1;
    }
    # Grab the last object.
    push @mts, &$make_obj($pkg, \@init) if @init;
    # Return the objects.
    return \@mts;
};

################################################################################]

=item my $mt = &$make_obj( $pkg, $init )

Instantiates a Bric::Util::MediaType object. Used by &$get_em().

B<Throws:>

=over 4

=item *

Unable to load action subclass.

=item *

Invalid parameter passed to constructor method.

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

$make_obj = sub {
    my ($pkg, $init) = @_;
    my $self = bless {}, $pkg;
    $self->SUPER::new;
    push @$init, ({}, {});
    $self->_set(\@props, $init);
};

################################################################################

=item my $ext_data_aref = &$get_ext_data()

Looks up the name and id of a media type corresponding to a given filename
extension. Returns them in an anonymous array with the ID first and the name
second. Used by &$lookup_ext().

B<Throws:>

=over 4

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=item *

Unable to select row.

=item *

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

$get_ext_data = sub {
    my $ext = shift;
    my $sel = prepare_ca(qq{
        SELECT id, name
        FROM   media_type
        WHERE  id in ( SELECT media_type__id
                       FROM   media_type_ext
                       WHERE  extension = ? )
    });
    row_aref($sel, $ext);
};

=item my $id = &$lookup_ext($filename)

=item my $name = &$lookup_ext($filename, 1)

Looks up the name or id of a media type corresponding to a given filename
extension.

B<Throws:>

=over 4

=item *

Unable to instantiate cache.

=item *

Unable to fetch value from the cache.

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=item *

Unable to select row.

=item *

Unable to cache value.

=back

B<Side Effects:> NONE.

B<Notes:> Uses Bric::App::Cache for persistence across processes.

=cut

$lookup_ext = sub {
    my ($filename, $name) = @_;
    # Look for an extension on the file name. If there isn't one, assume the
    # argument is the suffix itself.
    my $ext = substr $filename, rindex($filename, '.') + 1;
    return unless defined $ext;

    # Load the cache.
    $cache ||= Bric::App::Cache->new;
    my $exts = $cache->get($key);

    unless ($exts && exists $exts->{$ext}) {
	# We haven't looked up this extension before. Do so now.
	my $e = &$get_ext_data($ext);
	# Don't save the extension if it doesn't actually exist.
	$exts->{$ext} = $e if $e;
	# Cache the extensions.
	$cache->set($key, $exts);
    }
    return $exts->{$ext}[$name ? 1 : 0];
};

1;
__END__

=back

=head1 NOTES

NONE.

=head1 AUTHOR

David Wheeler <david@wheeler.net>

=head1 SEE ALSO

L<Bric|Bric>, 
L<Bric::Dist::Resource|Bric::Dist::Resource>

=cut
