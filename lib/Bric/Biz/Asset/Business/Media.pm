package Bric::Biz::Asset::Business::Media;
###############################################################################

=head1 NAME

Bric::Biz::Asset::Business::Media - The parent class of all media objects

=head1 VERSION

$Revision: 1.13 $

=cut

our $VERSION = (qw$Revision: 1.13 $ )[-1];

=head1 DATE

$Date: 2002-02-11 20:57:55 $

=head1 SYNOPSIS

=head1 DESCRIPTION


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
use Bric::Util::Attribute::Media;
use Bric::Util::Trans::FS;
use Bric::Util::Grp::Media;
use Bric::App::MediaFunc;
use File::Temp qw( tempfile );
use Bric::Config qw(:media);

#==============================================================================#
# Inheritance                          #
#======================================#

# The parent module should have a 'use' line if you need to import from it.
# use Bric;
use base qw( Bric::Biz::Asset::Business );

#=============================================================================#
# Function Prototypes                  #
#======================================#


# None

#==============================================================================#
# Constants                            #
#======================================#

use constant DEBUG => 0;
use constant TABLE  => 'media';
use constant VERSION_TABLE => 'media_instance';

use constant COLS	=> qw(
						element__id
						priority
						source__id
						current_version
						usr__id
						keyword_grp__id
						publish_date
						expire_date
						cover_date
						workflow__id
						publish_status
						active);
use constant VERSION_COLS => qw(
						name
						description
						media__id
						usr__id
						version
		                media_type__id
						category__id
						file_size
						file_name
						location
						uri
						checked_out);
use constant FIELDS	=> qw(
						element__id
						priority
						source__id
						current_version
						user__id
						keyword_grp_id
						publish_date
						expire_date
						cover_date
						workflow_id
						publish_status
						_active);
use constant VERSION_FIELDS => qw(
						name
						description
						id
						modifier
						version
				        media_type_id
						category__id
						size
						file_name
						location
						uri
						checked_out);

use constant GROUP_PACKAGE => 'Bric::Util::Grp::Media';
use constant INSTANCE_GROUP_ID => 32;

#==============================================================================#
# Fields                               #
#======================================#

#--------------------------------------#
# Public Class Fields                   

# Public fields should use 'vars'
#use vars qw();

#--------------------------------------#
# Private Class Fields                  
my ($meths, @ord);

#--------------------------------------#
# Instance Fields                       

# None

# This method of Bricolage will call 'use fields' for you and set some permissions.

BEGIN {
    Bric::register_fields(
			{
			 # Public Fields
			 location        => Bric::FIELD_READ,
			 file_name       => Bric::FIELD_READ,
			 uri             => Bric::FIELD_READ,
			 media_type_id   => Bric::FIELD_RDWR,
			 category__id    => Bric::FIELD_RDWR,
			 size            => Bric::FIELD_RDWR,

			 # Private Fields
			 _category_obj   => Bric::FIELD_NONE,
			 _file           => Bric::FIELD_NONE,
			 _media_type_obj => Bric::FIELD_NONE,
			});
}

#==============================================================================#
# Interface Methods                    #
#======================================#

=head1 INTERFACE

=head2 Constructors

=over 4

=cut

#--------------------------------------#
# Constructors  

#------------------------------------------------------------------------------#

=item $media = Bric::Biz::Asset::Business::Media->new( $initial_state )

This will create a new media object with an optionaly defined intiial state

=item Supported Keys

=over 4

=item *

active

=item *

priority

=item *

title - same as name

=item *

name - Will be over ridden by title

=item *

description

=item *

workflow_id

=item *

element__id - Required unless asset type object passed

=item *

element - the object required unless id is passed

=item *

source__id - required

=item *

cover_date - will set expire date in conjunction with the source

=item *

media_type_id

=item *

category__id  

=back

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE 

=cut

sub new {
	my ($self, $init) = @_;

	# default to active unless passed otherwise
	$init->{'_active'} = (exists $init->{'active'}) ? $init->{'active'} : 1;
	delete $init->{'active'};
	$init->{priority} ||= 3;
	$init->{name} = delete $init->{title} if exists $init->{title};


	$self = bless {}, $self unless ref $self;

	$self->_init($init);

	$self->SUPER::new($init);

	return $self;
}

################################################################################

=item $media = Bric::Biz::Asset::Business::Media->lookup->( { id => $id })

This will return a media asset that matches the criteria defined

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE 

=cut

sub lookup {
	my ($self, $param) = @_;

	my $sql = 'SELECT m.id, ' . join(', ', map {"m.$_ "} COLS) .
				', i.id, ' . join(', ', map {"i.$_ "} VERSION_COLS) .
				' FROM ' . TABLE . ' m, ' . VERSION_TABLE . ' i ' .
				' WHERE m.id=? AND i.media__id=m.id ';

	my @where;
	push @where, $param->{'id'};

	if ($param->{'version'}) {
		$sql .= ' AND i.version=? ';
		push @where, $param->{'version'};
	} elsif ($param->{'checkout'}) {
		$sql .= ' AND i.checked_out=? ';
		push @where, 1;
	} else {
		$sql .= ' AND m.current_version=i.version ';
	}
	$sql .= ' ORDER BY m.cover_date';

	my @d;
	my $cols = (scalar COLS + scalar VERSION_COLS) + 1;
	my $sth = prepare_ca($sql, undef, DEBUG);
	execute($sth, @where);
	bind_columns($sth, \@d[0 .. $cols ]);
	fetch($sth);

	# get the asset type and from that the biz package
	# to bless the proper object
	$self = bless {}, $self unless ref $self;
	$self->_set([ 'id', FIELDS, 'version_id', VERSION_FIELDS], [@d]);

	return unless $self->_get('id');

	my $element = $self->_get_element_object();

	my $biz_class = $element->get_biz_class();
	if ($biz_class && ($biz_class ne $self)) {
		$self = bless $self, $biz_class;
	}

	$self->_set__dirty(0);

	return $self;
}

################################################################################

=item (@media || $media) =  Bric::Biz::Asset::Business::Media->list($param);

returns a list or list ref of media objects that match the criteria defined

=item Supported Keys

=over 4

=item *

name - the same as the title field

=item *

title

=item *

description

=item *

uri

=item *

source__id

=item *

id - the media id

=item *

version

=item *

user__id - returns the versions that are checked out by the user, otherwise
returns the most recent version

=item *

return_versions - returns past version objects as well

=item *

active - Will default to 1

=item *

inactive - Returns only inactive objects

=item *

workflow__id

=item *

element__id

=item *

priority

=item *

publish_date_start - if end is left blank will return everything after the arg

=item *

publish_date_end - if start is left blank will return everything before the arg

=item *

cover_date_start - if end is left blank will return everything after the arg

=item *

cover_date_end - if start is left blank will return everything before the arg

=item *

expire_date_start - if end is left blank will return everything after the arg

=item *

expire_date_end - if start is left blank will return everything before the arg

=item *

simple - a single OR search that hits name, description and uri.

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

B<Side Effects:>

NONE

B<Notes:>

NONE



=cut

sub list {
	my ($class, $param) = @_;

	# Send to _do_list function which will return objects
	_do_list($class,$param,undef);

}

################################################################################

#--------------------------------------#

=head2 Destructors

=item $self->DESTROY

dummy method to not waste the time of AUTOLOAD

=cut

sub DESTROY {
    # This method should be here even if its empty so that we don't waste time
    # making Bricolage's autoload method try to find it.
}

################################################################################

#--------------------------------------#

=head2 Public Class Methods

=cut
                  
=item (@ids||$id_list) = Bric::Biz::Asset::Business::Media->list_ids( $criteria );

returns a list or list ref of media object ids that match the criteria defined

Supported Keys:

=over 4

See List method

=back

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE 

=cut

sub list_ids {
	my ($class, $param) = @_;

	# Send to _do_list function which will return objects
	_do_list($class,$param,1);
}

################################################################################

=item ($fields || @fields) = 
	Bric::Biz::Asset::Business::Media::autopopulated_fields()

Returns a list of the names of fields that are registered in the database as 
being autopopulatable for a given sub class

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub autopopulated_fields {
	my ($self) = @_;

	my $fields = $self->_get_auto_fields();

	my @auto;
	foreach (keys %$fields ) {
		push @auto, $_;
	}

	return wantarray ? @auto : \@auto;
}

################################################################################

=item my $key_name = Bric::Biz::Asset::Business::Media->key_name()

Returns the key name of this class.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub key_name { 'media' }

################################################################################

=item $meths = Bric::Biz::Asset::Business::Story->my_meths

=item (@meths || $meths_aref) = Bric::Biz::Asset::Business::Story->my_meths(TRUE)

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

    # We don't got 'em. So get 'em!
    foreach my $meth (__PACKAGE__->SUPER::my_meths(1)) {
	$meths->{$meth->{name}} = $meth;
	push @ord, $meth->{name};
    }

    push @ord, qw(file_name category category_name), pop @ord;
    $meths->{file_name} = {
			   get_meth => sub { shift->get_file_name(@_) },
			   get_args => [],
			   name     => 'file_name',
			   disp     => 'File Name',
			   len      => 256,
			   req      => 1,
			   type     => 'short',
			   props    => { type      => 'text',
					 length    => 32,
					 maxlength => 256
				       }
			  };
    $meths->{category} = {
			  get_meth => sub { shift->get_category_object(@_) },
			  get_args => [],
			  set_meth => sub { shift->set_category_object(@_) },
			  set_args => [],
			  name     => 'category',
			  disp     => 'Category',
			  len      => 64,
			  req      => 1,
			  type     => 'short',
			 };

    $meths->{category_name} = {
			  get_meth => sub { shift->get_category_object(@_)->get_name },
			  get_args => [],
			  name     => 'category_name',
			  disp     => 'Category',
			  len      => 64,
			  req      => 1,
			  type     => 'short',
			 };

	# Copy the data for the title from name.
	$meths->{title} = { %{ $meths->{name} } };
	$meths->{title}{disp} = 'Title';

    # Rename element.
    $meths->{element} = { %{ $meths->{element} } };
    $meths->{element}{disp} = 'Media Type';
    return !$ord ? $meths : wantarray ? @{$meths}{@ord} : [@{$meths}{@ord}];
}

################################################################################

=item $class_id = Bric::Biz::Asset::Business::Media->get_class_id()

Returns the class id of the Media class

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_class_id { 46 }

################################################################################

#--------------------------------------#

=head2 Public Instance Methods

=item $media = $media->set_category__id($id)

Associates this media asset with the given category

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

################################################################################

=item $category_id = $media->get_category__id()

Returns the category id that has been associated with this media object

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

################################################################################

=item $category = $media->get_category_object()

=item $category = $media->get_category()

Returns the object of the category that this is a member of

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_category_object {
	my ($self) = @_;

	my $cat = $self->_get( '_category_obj' );

	return $cat if $cat;

	$cat = Bric::Biz::Category->lookup( { id => $self->_get('category__id') });

	$self->_set({ '_category_obj' => $cat });

	return $cat;
}

*get_category = *get_category_object;

################################################################################

=item $uri = $media->get_local_uri()

Returns the uri of the media object for the Bricolage application server.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_local_uri {
    my $self = shift;
    my $loc = $self->get_location || return;
    return Bric::Util::Trans::FS->cat_uri(MEDIA_URI_ROOT, 
					Bric::Util::Trans::FS->dir_to_uri($loc) );
}

=item $uri = $media->get_path()

Returns the path of the media object on the Bricolage file system.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_path {
    my $self = shift;
    my $loc = $self->_get('location') || return;
    return Bric::Util::Trans::FS->cat_dir(MEDIA_FILE_ROOT, $loc);
}

#------------------------------------------------------------------------------#

=item $mt_obj = $media->get_media_type()

Returns the media type object associated with this object.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_media_type {
    my $self = shift;
    my ($mt_obj, $mt_id) = $self->_get('_media_type_obj', 'media_type_id');

    return unless $mt_id;

    unless ($mt_obj) {
	$mt_obj = Bric::Util::MediaType->lookup({'id' => $mt_id});
	$self->_set(['_media_type_obj'], [$mt_obj]);
    }

    return $mt_obj;
}

################################################################################

=item $media = $media->upload_file($file_handle, $file_name)

Reads a file from the passed $file_handle and stores it in the media
object under $file_name.

B<Throws:>

NONE

B<Side Effects:>

Closes the $file_handle after reading.

B<Notes:> 

NONE

=cut

sub upload_file {
	my ($self, $fh, $name) = @_;

	my ($id, $v) = $self->_get(qw(id version));
	my $dir = Bric::Util::Trans::FS->cat_dir(MEDIA_FILE_ROOT, $id, $v);
	Bric::Util::Trans::FS->mk_path($dir);
	my $path = Bric::Util::Trans::FS->cat_dir($dir, $name);

	open FILE, ">$path" or die
	  Bric::Util::Fault::Exception::GEN->new({ msg => "Unable to open '$path': $!" });
	my $buffer;
	while(read($fh, $buffer, 10240)) {
	    print FILE $buffer;
	}
	close $fh;
	close FILE;

	# Set the location, name, and URI.
	my $uri = Bric::Util::Trans::FS->cat_uri(
          $self->_construct_uri($self->get_category_object), $name);
	my $loc = Bric::Util::Trans::FS->cat_dir('/', $id, $v, $name);
	$self->_set([qw(location file_name uri)], [$loc, $name, $uri]);

	# determine what needs to get autopopulated
	my $auto_fields = $self->_get_auto_fields();

	# get the top level tile
	my $tile = $self->get_tile();

	# itterate through all the tiles
	foreach my $dt ($tile->get_tiles()) {

		# skip if this is a container
		next if $dt->is_container();
		# see if this is an auto populated field
		my $name = $dt->get_name();

		my $path = Bric::Util::Trans::FS->cat_dir(MEDIA_FILE_ROOT, $loc);

		my $media_func = Bric::App::MediaFunc->new({ file_path => $path });

		if ($auto_fields->{$name} ) {
			# check the tile to see if we can override it
#			next if $dt->is_locked;
			# get the value
			my $method = $auto_fields->{$name};
			my $val = $media_func->$method();
			$val = 'No Val returned' unless $val;
			$dt->set_data($val);
			$dt->save();

		}
	}

	return $self;
}

################################################################################

=item $file_handle = $madia->get_file()

Returns the file handle for this given media object

B<Throws:>

"Error getting File"

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_file {
    my $self = shift;
    my $path = $self->get_path || return;
    my $fh;
    open $fh, $path or die
      Bric::Util::Fault::Exception::GEN->new({ msg => "Cannot open '$path': $!" });
    return $fh;
}

################################################################################

=item $location = $media->get_location()

The will return the location of the file on the file system, relative to
MEDIA_FILE_ROOT.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

################################################################################

=item $size = $media->get_size()

This is the size of the media file in bytes

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE 

=cut

################################################################################

=item $media = $story->revert();

Reverts the current version to a prior version

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub revert {
	my ($self, $version) = @_;

	if (!$self->_get('checked_out')) {
		die Bric::Util::Fault::Exception::GEN->new( {
			msg => "May not revert a non checked out version" });
	}

	my @prior_versions = __PACKAGE__->list( {
			id              => $self->_get_id(),
			return_versions => 1
		});

	my $revert_obj;
	foreach (@prior_versions) {
		if ($_->get_version == $version) {
			$revert_obj = $_;
		}
	}

	unless ($revert_obj) {
		die Bric::Util::Fault::Exception::GEN->new( {
			msg => "The requested version does not exist"
		});
	}

	# clone information from the tables
	$self->_set( {
			category__id 	=> $revert_obj->get_category__id(),
			media_type_id	=> $revert_obj->get_media_type_id(),
			size			=> $revert_obj->get_size(),
			file_name		=> $revert_obj->get_file_name(),
			uri				=> $revert_obj->get_uri() 
		});

	# COPY THE FILE HERE

	# clone the tiles
	# get rid of current tiles
	my $tile = $self->get_tile();
	$tile->do_delete();

	my $new_tile = $revert_obj->get_tile();
	
	$new_tile->prepare_clone();

	$self->_set( { 
			_delete_tile 	=> $tile,
			_tile			=> $new_tile
	});

	return $self;

}

################################################################################

=item $media = $media->clone()

Clones the media object

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub clone {
	my ($self) = @_;

	my $tile = $self->get_tile();
	$tile->prepare_clone();

	my $contribs = $self->_get_contributors();
	# clone contributors
	foreach (keys %$contribs ) {
		$contribs->{$_}->{'action'} = 'insert';
	}

	$self->_set( {
			version_id              => undef,
			id                      => undef,
			publish_date            => undef,
			publish_status          => 0,
			_update_contributors    => 1
		});

	return $self;
}


################################################################################

=item $self = $self->save()

Saves the object to the database doing either an insert or
an update

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub save {
	my ($self) = @_; 


	if ($self->_get('id')) {
		# we have the main id make sure there's a instance id
		$self->_update_media();

		if ($self->_get('version_id')) {
			if ($self->_get('_cancel')) {
				$self->_delete_instance();
				if ($self->_get('version') == 0) {
					$self->_delete_media();
				}
				$self->_set( {'_cancel' => undef });
				return $self;
			} else {
				$self->_update_instance();
			}
		} else {
			$self->_insert_instance();
		}
	} else {
		# insert both
		if ($self->_get('_cancel')) {
			return $self;
		} else {
			$self->_insert_media();
			$self->_insert_instance();
		}
	}


	$self->SUPER::save();

	return $self;
}

################################################################################

#==============================================================================#

=head1 PRIVATE

=cut

#--------------------------------------#

=head2 Private Class Methods


=item = _do_list

Called by list will return objects or ids depending on who is calling

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE 

=cut

sub _do_list {
    my ($class, $param, $ids) = @_;

    # Make sure to set active explictly if its not passed.
    $param->{'active'} = exists $param->{'active'} ? $param->{'active'} : 1;

	# Build a list of select cols
	my @select;

	push @select, 'm.id';
	unless ($ids) {
		push @select, (map { "m.$_" } COLS),(map {"i.$_" } 'id', VERSION_COLS);
	}

	# get the tables
	my @tables;
	push @tables, TABLE . ' m', VERSION_TABLE . ' i';

	# map name to title if passed
	$param->{'name'} = $param->{'title'} if exists $param->{'title'};
	# Map inverse alias inactive to active.
	$param->{'active'} = ($param->{'inactive'} ? 0 : 1)
		if exists $param->{'inactive'};

	# build the where clause
	my (@where, @bind);

	# include trivial media table fields
	foreach my $f (qw(id active priority element__id
			  workflow__id source__id)) {
		next unless exists $param->{$f};

		push @where, "m.$f=?";
		push @bind, $param->{$f};
	}

	# do for instance table
	foreach my $f (qw(name description version uri)) {
		next unless exists $param->{$f};

		if (($f eq 'name') || ($f eq 'description') || ($f eq 'uri')) {
			push @where, "LOWER(i.$f) LIKE ?";
			push @bind, lc($param->{$f});
		} else {
			push @where, "i.$f=?";
			push @bind, $param->{$f};
		}
	}

	# handle the special fields
        if ($param->{'simple'}) {
          push @where, ('(LOWER(i.name) LIKE ? OR LOWER(i.description) LIKE ? OR LOWER(i.uri) LIKE ?)');
            push @bind, (lc($param->{'simple'})) x 3;
        }

	# for searching for user_id
	if (defined $param->{'user__id'}) {
		push @where, " m.usr__id=? ";
		push @bind, $param->{'user__id'};
		push @where, " i.checked_out=? ";
		push @bind, 1;
	} else {
		push @where, ' i.checked_out=? ';
		push @bind, 0;
	}

	unless ($param->{'return_versions'}) {
		push @where, " m.current_version=i.version ";
	}

	# Handle searches on dates
	foreach my $type (qw(publish_date cover_date expire_date)) {
		my ($start, $end) = ($param->{$type.'_start'},
			$param->{$type.'_end'});

		# Handle date ranges.
		if ($start && $end) {
			push @where, "m.$type BETWEEN ? AND ?";
			push @bind, $start, $end;
		} else {
			# Handle 'everying before' or 'everything after' $date searches.
			if ($start) {
				push @where, "m.$type > ?";
				push @bind, $start;
			} elsif ($end) {
				push @where, "m.$type < ?";
				push @bind, $end;
			}
		}
	}

	push @where, ' m.id=i.media__id ';

	my $sql;
	$sql = 'SELECT DISTINCT ' . join(', ', @select) . ' FROM ' . join(', ', @tables);
	$sql .= ' WHERE ' . join(' AND ', @where);

        if ($ids) {
                # when doing a SELECT DISTINCT you can't ORDER BY a
                # field outside the SELECT list.
	        $sql .= ' ORDER BY m.id';
        } elsif ($param->{'return_versions'}) {
		$sql .= ' ORDER BY i.version ';
	} else {
		$sql .= ' ORDER BY m.cover_date';
	}

	my $select = prepare_ca($sql, undef, DEBUG);

	if ( $ids ) {
		# called from list_ids give em what they want
		my $return = col_aref($select,@bind);

		return wantarray ? @{ $return } : $return;

	} else { # end if ids 
		# this must have been called from list so give objects
		my (@objs, @d);
    
		my $count = (scalar FIELDS) + (scalar VERSION_FIELDS) + 1;
		execute($select,@bind);
		bind_columns($select, \@d[0 .. $count ]);
    
		while (my $row = fetch($select) ) {

			my $self = bless {}, $class;
            
			$self->_set( [ 'id', FIELDS, 'version_id', VERSION_FIELDS], [@d]);

			my $element = $self->_get_element_object();
			my $biz_class = $element->get_biz_class();
			if ($biz_class && ($biz_class ne $self)) {
				$self = bless $self, $biz_class;
			}
			push @objs, $self;
		}

		return (wantarray ? @objs : \@objs) if @objs;
		return;
	}
}

################################################################################

#--------------------------------------#

=head2 Private Instance Methods

=item $contribs = $self->_get_contributors()

Returns the contributors from a cache or looks em up

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _get_contributors {
	my ($self) = @_;

	my ($contrib, $queried) = 
		$self->_get('_contributors', '_queried_contrib');

	unless ($contrib) {

		my $dirty = $self->_get__dirty();

		my $sql = 'SELECT member__id, place, role FROM media__contributor ' .
					'WHERE media_instance__id=? ';

		my $sth = prepare_ca($sql, undef, DEBUG);
		execute($sth, $self->_get('version_id'));
		while (my $row = fetch($sth)) {
			$contrib->{$row->[0]}->{'role'} = $row->[2];
			$contrib->{$row->[0]}->{'place'} = $row->[1];
		}

		$self->_set( { 
				'_queried_contrib' 	=> 1,
				'_contributors' => $contrib 
			});
		$self->_set__dirty($dirty);
	}

	return $contrib;
}

################################################################################

=item $self = $self->_insert_contributor( $id, $role) 

Inserts a row into the mapping table for contributors

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _insert_contributor {
	my ($self, $id, $role, $place) = @_;

	my $sql = 'INSERT INTO media__contributor ' .
				' (id, media_instance__id, member__id, place, role) ' .
				" VALUES (${\next_key('media__contributor')},?,?,?,?) ";

	my $sth = prepare_c($sql, undef, DEBUG);
	execute($sth, $self->_get('version_id'), $id, $place, $role);

	return $self;
}

################################################################################

=item $self = $self->_update_contributor($id, $role)

Updates the contributor mapping table

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _update_contributor {
	my ($self, $id, $role, $place) = @_;

	my $sql = 'UPDATE media__contributor ' .
				' SET role=?, place=? ' .
				' WHERE media_instance__id=? ' .
				' AND member__id=? ';

	my $sth = prepare_c($sql, undef, DEBUG);

	execute($sth, $role, $place, $self->_get('version_id'), $id);

	return $self;
}

################################################################################

=item $self = $self->_delete_contributors($id)

Deletes the rows from these mapping tables

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _delete_contributor {
	my ($self, $id) = @_;

	my $sql = 'DELETE FROM media__contributor ' .
				' WHERE media_instance__id=? ' .
				' AND member__id=? ';

	my $sth = prepare_c($sql, undef, DEBUG);

	execute($sth, $self->_get('version_id'), $id);

	return $self;
}

################################################################################

=item ($fields) = $self->_get_auto_fields($biz_pkg)

returns a hash ref of the fields that are to be autopopulated from this 
type of media object.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _get_auto_fields {
    my ($self) = @_;

    my $auto_fields;
    if (ref $self) {
	$auto_fields = $self->_get('_auto_fields');
	return $auto_fields if $auto_fields;
    }

    my $sth = prepare_c(qq{
        SELECT name, function_name
        FROM   media_fields
        WHERE  biz_pkg = ?
               AND active = ?
        ORDER BY id
    });

    execute($sth, ($self->get_class_id, 1));
    while (my $row = fetch($sth)) {
	$auto_fields->{$row->[0]} = $row->[1];
    }

    $self->_set( { '_auto_fields' => $auto_fields }) if ref $self;
    return $auto_fields;
}

################################################################################

=item $attribute_object = $self->_get_attribute_object()

Returns the attribute object from a cache or creates a new record

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _get_attribute_object {
	my ($self) = @_;

	my $attr_obj = $self->_get('_attribute_object');

	return $attr_obj if $attr_obj;

	# Let's Create a new one if one does not exist
	$attr_obj = Bric::Util::Attribute::Media->new(
		{id => $self->_get('id')});

	$self->_set( {'_attribute_object' => $attr_obj} );

	return $attr_obj;
}

################################################################################

=item $self = $self->_insert_media()

Inserts a media record into the database

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _insert_media {
	my ($self) = @_;

	my $sql = 'INSERT INTO ' . TABLE . ' (id, ' . join(', ', COLS) . ') '.
				"VALUES (${\next_key(TABLE)}, ". join(', ',('?') x COLS).')';

	my $sth = prepare_c($sql, undef, DEBUG);
	execute($sth, $self->_get(FIELDS));

	$self->_set( { id => last_key(TABLE) });

	# And finally, register this person in the "All Media" group.
	$self->register_instance(INSTANCE_GROUP_ID, GROUP_PACKAGE);

	return $self;
}

################################################################################

=item $self = $self->_update_media()

Preforms the SQL that updates the media table

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _update_media {
	my ($self) = @_;

	my $sql = 'UPDATE ' . TABLE . ' SET '. join(', ', map {"$_=?"} COLS) .
				' WHERE id=? ';

	my $sth = prepare_c($sql, undef, DEBUG);
	execute($sth, $self->_get(FIELDS), $self->_get('id'));

	return $self;
}

################################################################################

=item $self = $self->_insert_instance()

Preforms the sql that inserts a record into the media instance table

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _insert_instance {
	my ($self) = @_;

	my $sql = 'INSERT INTO '. VERSION_TABLE .
				' (id, '.join(', ', VERSION_COLS) . ')' .
				" VALUES (${\next_key(VERSION_TABLE)}, ".
				join(', ', ('?') x VERSION_COLS) . ')';

	my $sth = prepare_c($sql, undef, DEBUG);
	execute($sth, $self->_get(VERSION_FIELDS));

	$self->_set( { version_id => last_key(VERSION_TABLE) });

	return $self;
}

################################################################################

=item $self = $self->_update_instance()

Preforms the sql that updates the media_instance table

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _update_instance {
	my ($self) = @_;

	my $sql = 'UPDATE ' . VERSION_TABLE .
				' SET ' . join(', ', map {"$_=?" } VERSION_COLS) .
				' WHERE id=? ';

	my $sth = prepare_c($sql, undef, DEBUG);
	execute($sth, $self->_get(VERSION_FIELDS), $self->_get('version_id'));

	return $self;
}

################################################################################

=item $self = $self->_delete_media()

Removes the media row from the database

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _delete_media {
	my ($self) = @_;

	my $sql = 'DELETE FROM ' . TABLE .
				' WHERE id=? ';

	my $sth = prepare_c($sql, undef, DEBUG);

	execute($sth, $self->_get('id'));
}

################################################################################

=item $self = $self->_delete_instance()

Removes the instance row from the database

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _delete_instance {
	my ($self) = @_;

	my $sql = 'DELETE FROM ' . VERSION_TABLE .
				' WHERE id=? ';

	my $sth = prepare_c($sql, undef, DEBUG);
	execute($sth, $self->_get('version_id'));

	return $self;
}

################################################################################

=item $self = $self->_select_media($where, @bind);

Populates the object from a database row

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _select_media {
	my ($self,$where,@bind) = @_;

	my @d;

	my $sql = 'SELECT id,'. join(',',COLS) . " FROM ". TABLE;

	# add the where Clause
	$sql .= " WHERE $where";

	my $sth = prepare_ca($sql, undef, DEBUG);
	execute($sth, @bind);
	bind_columns($sth, \@d[0 .. (scalar COLS)]);
	fetch($sth);

	# set the values retrieved
	$self->_set( [ 'id', FIELDS], [@d]);

	my $v_grp = Bric::Util::Grp::AssetVersion->lookup(
		{ id => $self->_get('version_grp__id') } );

	$self->_set( { '_version_grp' => $v_grp });

	return $self;
}

################################################################################

=item $self = $self->_do_update()

Updates the row in the data base

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Note:>

NONE

=cut


sub _do_update {
	my ($self) = @_;

	my $sql = 'UPDATE ' . TABLE . ' '.
				'SET ' . join(', ', map { "$_=?" } COLS) .
				' WHERE id=? ';
	my $update = prepare_c($sql, undef, DEBUG);

	execute($update, $self->_get( FIELDS ), $self->_get('id') );

	return $self;
}

################################################################################

=item $attr_object = $self->_get_attr_obj()

returns the attribute object for this story

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut


sub _get_attr_obj {
	my ($self) = @_;

	my $attr_obj = $self->_get('_attr_obj');

	return $attr_obj if ($attr_obj);

	$attr_obj = Bric::Util::Attribute::Media->new(
		{ object_id => $self->_get('id')});

	$self->_set( { '_attr_obj' => $attr_obj });

	return $attr_obj;
}

################################################################################

1;
__END__

=back

=head1 NOTES

Some additional fields may be needed here such as a field for what kind of 
object this represents etc.

=head1 AUTHOR

"Michael Soderstrom" <miraso@pacbell.net>
Bricolage Engineering

=head1 SEE ALSO

L<perl>, L<Bric>, L<Bric::Biz::Asset>, L<Bric::Biz::Asset::Business>

=cut
