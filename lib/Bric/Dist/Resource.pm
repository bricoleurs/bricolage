package Bric::Dist::Resource;

=head1 Name

Bric::Dist::Resource - Interface to distribution files and directories.

=cut

# Grab the Version Number.
require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

  use Bric::Dist::Resource;

  # Constructors.
  # Create a new resource.
  my $res = Bric::Dist::Resource->new;
  # Look up an existing resource.
  $res = Bric::Dist::Resource->lookup({ id => 1 });
  # Get a list of resources.
  my @res = Bric::Dist::Resource->list({ path => '/tech/feature%' });

  # Class methods.
  # Get a list of resource IDs.
  my @res_ids = Bric::Dist::Resource->list_ids({ path => '/tech/feature%' });
  # Get an introspection hashref.
  my $int = Bric::Dist::Resource->my_meths;

  # Instance methods.
  my $id = $res->get_id;
  my $path = $res->get_path;
  $res = $res->set_path($path);
  my $uri = $res->get_uri;
  $res = $res->set_uri($uri);
  my $tmp_path = $res->get_tmp_path;
  $res = $res->set_tmp_path($tmp_path);
  my $size = $res->get_size;
  $res = $res->set_size($size);
  my $mod_time = $res->get_mod_time;
  $res = $res->set_mod_time($mod_time)
  my $media_type = $res->get_media_type;
  $res = $res->set_media_type($media_type)
  print "It's a directory!\n" if $res->is_dir;

  # Reload size and mod_time, from the resource on the file system.
  $res = $res->stat_me;

  # Story relationships.
  my @story_ids = $res->get_story_ids;
  $res = $res->add_story_ids(@story_ids);
  $res = $res->del_story_ids(@story_ids);

  # Media relationships.
  my @media_ids = $res->get_media_ids;
  $res = $res->add_media_ids(@media_ids);
  $res = $res->del_media_ids(@media_ids);

  # File relationships.
  if ($res->is_dir) {
      my @file_ids = $res->get_file_ids;
      $res = $res->add_file_ids(@file_ids);
      $res = $res->del_file_ids(@file_ids);
  }

  # Save it!
  $res = $res->save;

=head1 Description

This class manages distribution resources. A resource is a file or directory.
Directory resources can be associated with file resources (in order to keep
a list of the contents of a directory), but not vice versa. Resources may also
track associations with assets, such that they can have story and/or media
associations. Other properties of resources are filesystem path, file size,
MEDIA type, and last modified date.

=cut

################################################################################
# Dependencies
################################################################################
# Standard Dependencies
use strict;

################################################################################
# Programmatic Dependences
use Bric::Config qw(:dist);
use Bric::Util::DBI qw(:all);
use Bric::Util::Time qw(:all);
use Bric::Util::MediaType;
use Bric::App::Event qw(log_event);
use Bric::Util::Fault qw(throw_gen throw_dp throw_da);

################################################################################
# Inheritance
################################################################################
use base qw(Bric);

################################################################################
# Function and Closure Prototypes
################################################################################
my ($get_em, $get_ids, $load_ids, $add_ids, $del_ids, $stat, $save_ids, $METHS);

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
my @rcols = qw(id parent_id path uri size mod_time is_dir);
my @cols = qw(r.id r.parent_id r.path r.uri r.size r.mod_time r.is_dir t.name);
my @props = qw(id parent_id path uri size _mod_time _is_dir media_type);
my @ORD = qw(path uri size mod_time media_type);

################################################################################

################################################################################
# Instance Fields
BEGIN {
    Bric::register_fields({
                         # Public Fields
                         id => Bric::FIELD_READ,
                         media_type => Bric::FIELD_READ,
                         parent_id => Bric::FIELD_RDWR,
                         path => Bric::FIELD_RDWR,
                         uri => Bric::FIELD_RDWR,
                         tmp_path => Bric::FIELD_RDWR,
                         size => Bric::FIELD_RDWR,

                         # Private Fields
                         _mod_time => Bric::FIELD_NONE,
                         _is_dir => Bric::FIELD_NONE,
                         _file_ids => Bric::FIELD_NONE,
                         _story_ids => Bric::FIELD_NONE,
                         _media_ids => Bric::FIELD_NONE
                        });
}

################################################################################
# Class Methods
################################################################################

=head1 Interface

=head2 Constructors

=over 4

=item my $res = Bric::Dist::Resource->new($init)

Instantiates a Bric::Dist::Resource object. An anonymous hash of initial values
may be passed. The supported initial value keys are:

=over 4

=item *

path

=item *

uri

=item *

media_type

=item *

size

=item *

mod_time

=back

Call $res->save() to save the new object.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub new {
    my ($pkg, $init) = @_;
    my $self = bless {}, ref $pkg || $pkg;
    $self->set_path(delete $init->{path}) if $init->{path};
    $self->set_media_type(delete $init->{media_type});
    $self->set_mod_time(delete $init->{mod_time}) if $init->{mod_time};
    $self->SUPER::new($init);
}

################################################################################

=item my $res = Bric::Dist::Resource->lookup({ id => $id })

=item my $res = Bric::Dist::Resource->lookup({ path => $path, uri  => $uri })

Looks up and instantiates a new Bric::Dist::Resource object based on the
Bric::Dist::Resource object ID or based on the path and uri. If a
Bric::Dist::Resource object is not found in the database, C<lookup()> returns
C<undef>.

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

Too many Bric::Dist::Resource objects found.

=back

B<Side Effects:> If $id or $path is found, populates the new Bric::Dist::Resource
object with data from the database before returning it.

B<Notes:> NONE.

=cut

sub lookup {
    my $pkg = shift;
    my $res = $pkg->cache_lookup(@_);
    return $res if $res;

    $res = $get_em->($pkg, @_);
    # We want @$res to have only one value.
    throw_dp(error => 'Too many Bric::Dist::Resource objects found.')
      if @$res > 1;
    return @$res ? $res->[0] : undef;
}

################################################################################

=item my (@res || $res_aref) = Bric::Dist::Resource->list($params)

Returns a list or anonymous array of Bric::Dist::Resource objects based on the
search parameters passed via an anonymous hash. The supported lookup keys are:

=over 4

=item id

Resource ID. May use C<ANY> for a list of possible values.

=item path

The path to the resource on the file system. Usually used in combination with
uri. May use C<ANY> for a list of possible values.

=item uri

The URI for a resource. Usually used in combination with path. May use C<ANY>
for a list of possible values.

=item not_uri

Search for resources with URIs I<not> like the specified URI. May use C<ANY>
for a list of possible values.

=item media_type

The resources' MEDIA type. May use C<ANY> for a list of possible values.

=item mod_time

The resources' last modified time. If passed as an anonymous array of two
values, those values will be used to retreive resources whose mod_times are
between the two times. Otherwise, may use C<ANY> for a list of possible
values.

=item size

The size, in bytes, of the file. If passed as an anonymous array of two
values, those values will be used to retreive resources whose sizes are
between the two sizes. Otherwise, may use C<ANY> for a list of possible
values.

=item is_dir

If true, return only those resources that are directories.

=item story_id

Resources associated with a given story ID. May use C<ANY> for a list of
possible values.

=item media_id

Resources associated with a given media ID. May use C<ANY> for a list of
possible values.

=item media_id

Resources associated with a given media ID. May use C<ANY> for a list of
possible values.

=item dir_id

File resources that are associated with a directory Resource's ID. May use
C<ANY> for a list of possible values.

=item job_id

Resources associated with a given job ID. May use C<ANY> for a list of
possible values.

=item not_job_id

Resources not associated with a given job ID. Best used in combination with
C<story_id> or C<media_id>. May use C<ANY> for a list of possible values.

=item oc_id

Resources associated with an output channel ID. Only returns the correct
results if the C<job> table has not been cleared, because it joins to
C<job__resource>, C<job__server_type>, and C<server_type__output_channel>.

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

B<Side Effects:> Populates each Bric::Dist::Resource object with data from the
database before returning them all.

B<Notes:> NONE.

=cut

sub list { wantarray ? @{ &$get_em(@_) } : &$get_em(@_) }

################################################################################

=item my $res_href = Bric::Dist::Resource->href($params)

Returns a list or anonymous array of Bric::Dist::Resource objects based on the
search parameters passed via an anonymous hash. The supported lookup keys are
the same as for list().

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

B<Side Effects:> Populates each Bric::Dist::Resource object with data from the
database before returning them all.

B<Notes:> NONE.

=cut

sub href { &$get_em(@_, 0, 1) }

################################################################################

=back

=head2 Destructors

=over 4

=item $res->DESTROY

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

=item my (@res_ids || $res_ids_aref) = Bric::Dist::Resource->list_ids($params)

Returns a list or anonymous array of Bric::Dist::Resource object IDs based on the
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

=item $meths = Bric::Dist::Resource->my_meths

=item (@meths || $meths_aref) = Bric::Dist::Resource->my_meths(TRUE)

=item my (@meths || $meths_aref) = Bric::Dist::Resource->my_meths(0, TRUE)

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

An anonymous hash of key/value pairs representing the values and display names
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

    # Load field members.
    $METHS = { path       => { name     => 'path',
                               get_meth => sub { shift->get_path(@_) },
                               get_args => [],
                               set_meth => sub { shift->set_path(@_) },
                               set_args => [],
                               disp     => 'Path',
                               search   => 1,
                               len      => 256,
                               req      => 1,
                               type     => 'short',
                               props    => { type      => 'text',
                                             length    => 64,
                                             maxlength => 256
                                         }
                           },
               uri       => { name     => 'uri',
                               get_meth => sub { shift->get_uri(@_) },
                               get_args => [],
                               set_meth => sub { shift->set_uri(@_) },
                               set_args => [],
                               disp     => 'URI',
                               search   => 1,
                               len      => 256,
                               req      => 1,
                               type     => 'short',
                               props    => { type      => 'text',
                                             length    => 64,
                                             maxlength => 256
                                         }
                           },
               media_type => { name     => 'media_type',
                               get_meth => sub { shift->get_media_type(@_) },
                               get_args => [],
                               disp     => 'Media Type',
                               len      => 128,
                               req      => 1,
                           },
               size       => { name     => 'size',
                               get_meth => sub { shift->get_size(@_) },
                               get_args => [],
                               set_meth => sub { shift->set_size(@_) },
                               set_args => [],
                               disp     => 'Size',
                               len      => 10,
                               req      => 1,
                               type     => 'short',
                               props    => { type      => 'text',
                                             length    => 32,
                                             maxlength => 10
                                         }
                           },
               mod_time   => { name     => 'mod_time',
                               get_meth => sub { shift->get_mod_time(@_) },
                               get_args => [],
                               disp     => 'Last Modified Time',
                               req      => 1,
                           },
           };

    return !$ord ? $METHS : wantarray ? @{$METHS}{@ORD} : [@{$METHS}{@ORD}]
}

################################################################################

=back

=head2 Public Instance Methods

=over 4

=item my $id = $res->get_id

Returns the ID of the Bric::Dist::Resource object.

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

B<Notes:> If the Bric::Dist::Resource object has been instantiated via the new()
constructor and has not yet been C<save>d, the object will not yet have an ID,
so this method call will return undef.

=item my $media_type = $res->get_media_type

Returns the MEDIA type of the resource. Returns undef in the resource is a
directory.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_media_type {
    my $self = shift;
    my $media = $self->_get('media_type');
    return $media eq 'none' ? undef : $media;
}

=item $self = $res->set_media_type($media_type)

Sets the MEDIA type of the resource. Call Bric::Util::MediaType->list() to get a
list of available MEDIA types. Setting the MEDIA type to "none" will cause
is_dir() to return true, while any other MEDIA type setting will cause is_dir()
to return false.

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

sub set_media_type {
    my ($self, $media) = @_;
    $media ||= DEF_MEDIA_TYPE;
    $self->_set([qw(media_type _is_dir)],
                [$media, $media eq 'none' ? 1 : 0]);
}

################################################################################

=item my $path = $res->get_path

Returns the file system path to the resource.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'path' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> For cross-platform portability, we may later want to implement the
get_path() and set_path() methods using File::Spec.

=item $self = $res->set_path($path)

Sets the file system path to the resource. This property cannot be changed in an
existing Bric::Dist::Resource object. The resource must exist on the file system
to set the path. In addition, once the resource has been found on the file
system the media_type, size, and mod_time properties will also be filled out, as
best as possible. These settings can be overridden by calling their own set_
methods.

B<Throws:>

=over 4

=item *

Cannot change path in existing Bric::Dist::Resource object.

=item *

Path does not exist.

=item *

Unable to format date.

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> For cross-platform portability, we may later want to implement the
get_path() and set_path() methods using File::Spec.

=cut

sub set_path {
    my ($self, $path) = @_;
    # Throw an error if the path has already been looaded in the database.
    throw_gen(error => "Cannot change path in existing " . __PACKAGE__ . " object")
      if $self->get_id;
    &$stat($self, $path);
}

################################################################################

=item my $uri = $res->get_uri

Returns the resource's URI.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'uri' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $self = $res->set_uri($uri)

Sets the resource's URI.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: WRITE access for field 'uri' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $tmp_path = $res->get_tmp_path

Returns the file system path to the a temporary copy of the resource. Used by
Bric::Util::Job and does not persist to the database.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'tmp_path' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> For cross-platform portability, we may later want to implement the
get_path() and set_path() methods using File::Spec.

=item $self = $res->set_tmp_path($tmp_path)

Sets the file system path to a temporary copy of the resource. Used by
Bric::Util::Job and does not persist to the database.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: WRITE access for field 'tmp_path' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> For cross-platform portability, we may later want to implement the
get_path() and set_path() methods using File::Spec.

=item $self = $res->stat_me

Finds the resource on the file system and reloads the size, mod_time, and
media_type properties. If the MEDIA type cannot be determined from the file
the existing media_type property setting is retained.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=item *

Bric::Dist::Resource::stat_me() requires the path property to be set.

=item *

Path does not exist.

=item *

Unable to format date.

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> For cross-platform portability, we may later want to implement the
get_path() and set_path() methods using File::Spec.

=cut

sub stat_me {
    my $self = shift;
    # Throw an error if the path propery has not been set.
    my ($path, $media) = $self->_get(qw(path media_type));
    throw_da(error => __PACKAGE__ . '::stat_me() requires the path property to be set')
      unless $path;
    &$stat($self, $path);
}

=item my $size = $res->get_size

Returns the size of the resource in bytes. If the resource is a directory, this
method will return 0.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'size' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $self = $res->set_size($size)

Sets the size of the resource in bytes. If the resource is a directory, set the
size to 0. Chances are that if you called set_path() first, this property will
already be enumerated.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: WRITE access for field 'size' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $mod_time = $res->get_mod_time($format)

Returns the last modified time of the resource. Pass in a strftime format string
to get the last modified time returned in that format.

B<Throws:>

=over 4

=item *

Unable to unpack date.

=item *

Unable to format date.

=item *

Bric::_get() - Problems retrieving fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_mod_time { local_date($_[0]->_get('_mod_time'), $_[1]) }

=item $self = $res->set_mod_time($mod_time)

Sets the mod_time of the resource in bytes. Chances are that if you called
set_path() first, this property will already be enumerated.

B<Throws:>

=over 4

=item *

Unable to unpack date.

=item *

Unable to format date.

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub set_mod_time { $_[0]->_set(['_mod_time'], [db_date($_[1])]) }

=item $self = $res->is_dir

Returns true if the resources is a directory.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub is_dir { return $_[0]->_get('_is_dir') ? $_[0] : undef }

=item my (@story_ids || $story_ids_aref) = $res->get_story_ids

Returns a list or anonymous array of story IDs representing the stories with
which this resources is associated.

B<Throws:>

=over 4

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=item *

Unable to select column into arrayref.

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_story_ids { &$get_ids($_[0], 'story') }

=item $self = $res->add_story_ids(@story_ids)

Associates this resource with the story IDs passed in.

B<Throws:>

=over 4

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=item *

Unable to select column into arrayref.

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub add_story_ids { &$add_ids($_[0], 'story', @_[1..$#_]) }

=item $self = $res->del_story_ids(@story_ids)

Dissociates this resource with the story IDs passed in. If no story IDs are
passed, then all story IDs will be dissociated from this resource.

B<Throws:>

=over 4

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=item *

Unable to select column into arrayref.

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub del_story_ids { &$del_ids($_[0], 'story', @_[1..$#_]) }

=item my (@media_ids || $media_ids_aref) = $res->get_media_ids

Returns a list or anonymous array of media IDs representing the stories with
which this resources is associated.

B<Throws:>

=over 4

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=item *

Unable to select column into arrayref.

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_media_ids { &$get_ids($_[0], 'media') }

=item $self = $res->add_media_ids(@media_ids)

Associates this resource with the media IDs passed in.

B<Throws:>

=over 4

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=item *

Unable to select column into arrayref.

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub add_media_ids { &$add_ids($_[0], 'media', @_[1..$#_]) }

=item $self = $res->del_media_ids(@media_ids)

Dissociates this resource with the media IDs passed in. If no media IDs are
passed, then all media IDs will be dissociated from this resource.

B<Throws:>

=over 4

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=item *

Unable to select column into arrayref.

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub del_media_ids { &$del_ids($_[0], 'media', @_[1..$#_]) }

################################################################################

=item my (@resource_ids || $resource_ids_aref) = $res->get_file_ids

Returns a list or anonymous array of Bric::Dist::Resource object IDs representing
the files that are the contents of this resource, assuming that this resource is
a directory. If this resource is a file, this method will return an empty list.

B<Throws:>

=over 4

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=item *

Unable to select column into arrayref.

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_file_ids {
    my $self = shift;
    return unless $self->is_dir;
    &$get_ids($self, 'file');
}

################################################################################

=item $self = $res->add_file_ids(@file_ids)

Associates this resource with the File IDs passed in. Note that is_dir() must
return true in order to associate files with this resource.

B<Throws:>

=over 4

=item *

Cannot associate file resources with another file resource.

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=item *

Unable to select column into arrayref.

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub add_file_ids {
    my $self = shift;
    throw_gen(error => "Cannot associate file resources with another file resource")
      unless $self->is_dir;
    &$add_ids($self, 'file', @_);
}

################################################################################

=item $self = $res->del_file_ids(@file_ids)

Dissociates this resource with the file IDs passed in. If no file IDs are
passed, then all file IDs will be dissociated from this resource. If this
is_dir() returns false, then this resource cannot be assocated with files and
will return undef.

B<Throws:>

=over 4

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=item *

Unable to select column into arrayref.

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub del_file_ids {
    my $self = shift;
    return unless $self->is_dir;
    &$del_ids($self, 'file', @_);
}

################################################################################

=item $self = $res->save

Saves any changes to the Bric::Dist::Resource object. Returns $self on success and
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
    return $self unless $self->_get__dirty;
    my ($id, $sids, $mids, $fids) = $self->_get(qw(id _story_ids _media_ids
                                                   _file_ids));

    if (defined $id) {
        # It's an existing record. Update it.
        local $" = ' = ?, '; # Simple way to create placeholders with an array.
        my $upd = prepare_c(qq{
            UPDATE resource
            SET    @rcols = ?,
                   media_type__id = (SELECT id FROM media_type WHERE name = ?)
            WHERE  id = ?
        }, undef);
        execute($upd, $self->_get(@props[0..$#props]), $id);
        log_event('resource_save', $self);
    } else {
        # It's a new resource. Insert it.
        local $" = ', ';
        my $fields = join ', ', next_key('resource'), ('?') x $#rcols;
        my $ins = prepare_c(qq{
            INSERT INTO resource (@rcols, media_type__id)
            VALUES ($fields, (SELECT id FROM media_type WHERE name = ?))
        }, undef);

        # Don't try to set ID - it will fail!
        execute($ins, $self->_get(@props[1..$#props]));
        # Now grab the ID.
        $id = last_key('resource');
        $self->_set(['id'], [$id]);
        log_event('resource_new', $self);
    }

    # Okay, now save any changes to associated Story, Media, and File IDs.
    &$save_ids($id, $sids, 'story');
    &$save_ids($id, $mids, 'media');
    &$save_ids($id, $fids, 'file');

    $self->SUPER::save;
    return $self;
}

################################################################################

################################################################################

=item $contents = $res->get_contents

Returns the contents of the file represented by the Bric::Dist::Resource object.

B<Throws:>

=over 4

=item *

Cannot open file.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_contents {
    my $self = shift;
    my $path = $self->get_tmp_path || $self->get_path or return;
    open F, $path or throw_gen "Cannot open file '$path': $!";
    return join '', <F>;
}

=back

=head1 Private

=head2 Private Class Methods

NONE.

=head2 Private Instance Methods

NONE.

=head2 Private Functions

=over 4

=item my $res_aref = &$get_em( $pkg, $params )

=item my $res_ids_aref = &$get_em( $pkg, $params, 1 )

Function used by lookup() and list() to return a list of Bric::Dist::Resource
objects or, if called with an optional third argument, returns a listof
Bric::Dist::Resource object IDs (used by list_ids()).

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

B<Notes:>

=cut

$get_em = sub {
    my ($pkg, $params, $ids, $href) = @_;
    my $tables = 'media_type t, resource r';
    my $wheres = 'r.media_type__id = t.id';
    my @params;

    # Handle not_job_id first, so as to make sure it joins to resource and
    # not any other table.
    if (my $jid = delete $params->{not_job_id}) {
        # if job_id is undef, just return no hits rather than toast the
        # database with the index-defeating query "WHERE job__id = NULL"
        return ($href ? {} : []) unless defined $jid;

        # Use an outer join and put the parameters there.
        $tables .= ' LEFT OUTER JOIN job__resource jrno ON ('
                 . 'r.id = jrno.resource__id AND '
                . any_where($jid, 'jrno.job__id = ?', \@params) . ')';
        $wheres .= ' AND jrno.resource__id IS NULL';
    }

    # Now deal with the remaining parameters.
    while (my ($k, $v) = each %$params) {
        if ($k eq 'mod_time') {
            if (ref $v eq 'ARRAY') {
                # It's an arrayref of times.
                $wheres .= " AND r.$k BETWEEN ? AND ?";
                push @params, db_date($v->[0]), db_date($v->[1]);
            } else {
                # It's a single value.
                $wheres .= ' AND '
                    . any_where db_date($v), "r.$k = ?", \@params;
            }
        } elsif ($k eq 'size') {
            if (ref $v eq 'ARRAY') {
                # It's an arrayref of sizes.
                $wheres .= " AND r.$k BETWEEN ? AND ?";
                push @params, @$v;
            } else {
                # It's a single value.
                $wheres .= ' AND ' . any_where $v, "r.$k = ?", \@params;
            }
        } elsif ($k eq 'path' || $k eq 'uri') {
            # A text comparison.
            $wheres .= ' AND ' . any_where $v, "$k LIKE ?", \@params;
        } elsif ($k eq 'not_uri') {
            # A text comparison.
            $wheres .= ' AND ' . any_where $v, "uri NOT LIKE ?", \@params;
        } elsif ($k eq 'media_type') {
            # Another text comparison.
            $wheres .= ' AND '
                    . any_where $v, 'LOWER(t.name) LIKE LOWER(?)', \@params;
        } elsif ($k eq 'story_id') {
            # We need to do a an inner join for the story_id.
            $tables .= ', story__resource sr';
            $wheres .= ' AND r.id = sr.resource__id AND '
                    . any_where $v, 'sr.story__id = ?', \@params;
        } elsif ($k eq 'media_id') {
            # We need to do a an inner join for the media_id.
            $tables .= ', media__resource sr';
            $wheres .= ' AND r.id = sr.resource__id AND '
                    . any_where $v, 'sr.media__id = ?', \@params;
        } elsif ($k eq 'dir_id') {
            # Simple numeric comparison.
            $wheres .= ' AND ' . any_where $v, 'r.parent_id = ?', \@params;
        } elsif ($k eq 'job_id') {
            # if job_id is undef, just return no hits rather than toast the
            # database with the index-defeating query "WHERE job__id = NULL"
            return ($href ? {} : []) unless defined $v;

            # We need to do a subselect for the job_id.
            $tables .= ', job__resource jr';
            $wheres .= ' AND r.id = jr.resource__id AND '
                    . any_where $v, 'jr.job__id = ?', \@params;
        } elsif ($k eq 'oc_id') {
            # if job_id is undef, just return no hits rather than toast the
            # database with the index-defeating query
            # "WHERE outut_channel__id = NULL"
            return ($href ? {} : []) unless defined $v;
            $wheres .= ' AND r.id IN (
                    SELECT jrr.resource__id
                    FROM   job__resource jrr,
                           job__server_type jst,
                           server_type__output_channel stoc
                    WHERE  jrr.job__id = jst.job__id
                           AND jst.server_type__id = stoc.server_type__id
                           AND jrr.resource__id = r.id AND '
                . any_where($v, 'stoc.output_channel__id = ?', \@params)
                . ')';
        } elsif ($k eq 'is_dir') {
            # Check for directories or not.
            $wheres .= " AND r.$k = ?";
            push @params, $v ? 1 : 0;
        } else {
            # It's an ID.
            $wheres .= ' AND ' . any_where $v, "r.$k = ?", \@params;
        }
    }

    # Prepare the SELECT statement.
    my ($qry_cols, $order) = $ids
        ? ('DISTINCT r.id', 'r.id')
        : (join(', ', @cols), 'path');
    my $sel = prepare_ca(qq{
        SELECT $qry_cols
        FROM   $tables
        WHERE  $wheres
        ORDER BY $order
    }, undef);

    # Just return the IDs, if they're what's wanted.
    return col_aref($sel, @params) if $ids;

    # Build the objects.
    execute($sel, @params);
    my (@d, @res, %res);
    bind_columns($sel, \@d[0..$#cols]);
    $pkg = ref $pkg || $pkg;
    while (fetch($sel)) {
        my $self = bless {}, $pkg;
        $self->SUPER::new;
        $self->_set(\@props, \@d);
        $self->_set__dirty; # Disables dirty flag.
        $href ? $res{$d[0]} = $self->cache_me : push @res, $self->cache_me;
    }
    return $href ? \%res : \@res;
};

=item my (@ids || $ids_aref) = &$get_ids($self, $type)

Returns the Asset IDs associated with this resource. If $type is 'story', it
returns Story IDs. If $type is 'media', it returns Media IDs.

B<Throws:>

=over 4

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=item *

Unable to select column into arrayref.

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:>

=cut

$get_ids = sub {
    my $ids = &$load_ids;
    return wantarray ? ( keys %{$ids->{cur}}, keys %{$ids->{new}} )
      : [ keys %{$ids->{cur}}, keys %{$ids->{new}} ];
};

################################################################################

=item my $bool = &$add_ids($self, $type)

Associates asset IDs with this resource. If $type is 'story', it associates
Story IDs. If $type is 'media', it associates Media IDs. Returns true.

B<Throws:>

=over 4

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=item *

Unable to select column into arrayref.

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:>

=cut

$add_ids = sub {
    my ($self, $type, @ids) = @_;
    my $ids = &$load_ids;
    foreach my $id (@ids) {
        next if $ids->{cur}{$id};
        $ids->{new}{$id} = 1;
        delete $ids->{del}{$id};
    }
    $self->_set__dirty(1);
};

################################################################################

=item my $bool = &$del_ids($self, $type)

Dissociates asset IDs from this resource. If $type is 'story', it dissociates
Story IDs. If $type is 'media', it dissociates Media IDs. Returns true.

B<Throws:>

=over 4

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=item *

Unable to select column into arrayref.

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:>

=cut

$del_ids = sub {
    my ($self, $type, @ids) = @_;
    my $ids = &$load_ids;
    foreach my $id (@ids) {
        next if $ids->{del}{$id};
        delete $ids->{cur}{$id};
        $ids->{del}{$id} = 1;
    }
    $self->_set__dirty(1);
};

################################################################################

=item my $ids_href = &$load_ids($self, $type)

Returns the Asset IDs associated with this resource. If $type is 'story', it
returns Story IDs. If $type is 'media', it returns Media IDs. The anonymous hash
returned has the following keys, each of which contains another anonymous hash
where the relevant IDs are the hash keys.

=over 4

=item *

cur - All new IDs and IDs currently in the database.

=item *

new - IDs to be added to the database.

=item *

del - IDs to be deleted from the database.

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

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:>

=cut

$load_ids = sub {
    my ($self, $type) = @_;
    # Grab and return the IDs if we've alreay got them.
    my ($id, $ids) = $self->_get('id', "_${type}_ids");
    return $ids if $ids;

    # Get ready to get them from the database.
    my $sel;
    if ($type eq 'file') {
        $sel = prepare_ca(qq{
            SELECT id
            FROM   resource
            WHERE  parent_id = ?
        }, undef);
    } else {
        $sel = prepare_ca(qq{
            SELECT ${type}__id
            FROM   ${type}__resource
            WHERE  resource__id = ?
        }, undef);
    }

    # Grab them and build a hashref to store them.
    $ids = { map { $_ => 1 } @{ col_aref($sel, $id) } };
    # Build the hashref to store, store it, and return it.
    $ids = {cur => $ids, new => {}, del => {} };
    $self->_set(["_${type}_ids"], [$ids]);
    return $ids;
};

################################################################################

=item $self = &$stat($self, $path)

Finds $path on the file system and loads the properties size, mod_time, and
media_type (if $path is a directory).

B<Throws:>

=over 4

=item *

Path does not exist.

=item *

Unable to format date.

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:>

=cut

$stat = sub {
    my ($self, $path) = @_;
    # Throw an error if the path doesn't exist on the file system.
    throw_gen(error => "Path '$path' does not exist.") unless -e $path;

    # Chop off trailing '/'. May need to change this later to be platform
    # independent.
    $path = substr($path, 0, -1) if substr($path, -1) eq '/';
    my $data = [$path];
    if (-d $path) {
        # It's a directory.
        push @$data, 0, (stat($path))[9], 1;
    } else {
        # It's a file.
        push @$data, (stat($path))[7,9], 0;
    }
    $data->[2] = db_date(strfdate($data->[2]));
    $self->_set([qw(path size _mod_time _is_dir)], $data);
};

################################################################################

=item $bool = &$save_ids($id, $ids, $type)

Saves the associated Story, Media, or File IDs by deleting those that need
deleting and inserting those that need inserting.

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

B<Notes:>

=cut

$save_ids = sub {
    my ($id, $ids, $type) = @_;
    my ($del, $ins);

    # Prepare SQL statements.
    if ($type eq 'file') {
        # It's for file resource IDs. Prepare the DELETE statement.
        $del = prepare_c(qq{
            UPDATE resource
            SET    parent_id = NULL
            WHERE  parent_id = ?
                   AND id = ?
        }, undef);

        # Prepare the INSERT statement.
        $ins = prepare_c(qq{
            UPDATE resource
            SET    parent_id = ?
            WHERE  id = ?
        }, undef);
    } else {
        # It's for Story or Media IDs. Prepare the DELETE statement.
        $del = prepare_c(qq{
            DELETE FROM ${type}__resource
            WHERE  resource__id = ?
                   AND ${type}__id = ?
        }, undef);

        # Prepare the INSERT statement.
        $ins = prepare_c(qq{
            INSERT INTO ${type}__resource (resource__id, ${type}__id)
            VALUES (?, ?)
        }, undef);
    }

    # Delete those that need deleting.
    execute($del, $id, $_) for keys %{$ids->{del}};
    $ids->{del} = {};

    # Insert those that need inserting.
    execute($ins, $id, $_) for keys %{$ids->{new}};
    $ids->{new} = {};
    return 1;
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
L<Bric::Util::Job|Bric::Util::Job>

=cut
