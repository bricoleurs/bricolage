package Bric::Biz::Asset::Business::Story;
###############################################################################

=head1 NAME

Bric::Biz::Asset::Business::Story - The interface to the Story Object

=head1 VERSION

$Revision: 1.4 $

=cut

our $VERSION = substr(q$Revision: 1.4 $, 10, -1);

=head1 DATE

$Date: 2001-10-09 20:48:53 $

=head1 SYNOPSIS

 # creation of new objects
 $story = Bric::Biz::Asset::Business::Story->new( $init )
 $story = Bric::Biz::Asset::Business::Story->lookup( $param )
 ($stories || @stories) = Bric::Biz::Asset::Business::Story->list($param)

 # list of object ids
 ($ids || @ids) = Bric::Biz::Asset::Business::Story->list_ids($param)


 ## METHODS INHERITED FROM Bric::Biz::Asset ##

  # General information
 $asset       = $asset->get_id()
 $asset       = $asset->set_description($description)
 $description = $asset->get_description()

 # User information
 $usr_id      = $asset->get_user__id()
 $asset       = $asset->set_user__id($usr_id)

 # Version information
 $vers_grp_id = $asset->get_version_grp__id();
 $vers_id     = $asset->get_assset_version_id();

 # Desk stamp information
 ($desk_stamp_list || @desk_stamps) = $asset->get_desk_stamps()
 $desk_stamp                        = $asset->get_current_desk()
 $asset                             = $asset->set_current_desk($desk_stamp)

 # Workflow methods.
 $id  = $asset->get_workflow_id;
 $obj = $asset->get_workflow_object;
 $id  = $asset->set_workflow_id;

 # Access note information
 $asset                 = $asset->add_note($note)
 ($note_list || @notes) = $asset->get_notes()

 # Creation and modification information.
 ($modi_date, $modi_by)       = $asset->get_modi()
 ($create_date, $create_date) = $asset->get_create()

 # Access active status
 $asset            = $asset->deactivate()
 $asset            = $asset->activate()
 ($asset || undef) = $asset->is_active()


 ## METHODS INHERITED FROM Bric::Biz::Asset::Business ##

 # General info
 $name = $biz->get_name()
 $biz  = $biz->set_name($name)
 $ver  = $biz->get_version()

 # AssetType information
 $name        = $biz->get_element_name()
 $at_id       = $biz->get_element__id()
 $biz         = $biz->set_element__id($at_id)

 # Tile methods
 $container_tile  = $biz->get_tile()
 @container_tiles = $biz->get_tiles()
 $biz             = $biz->add_data($at_data_obj, $data)
 $data            = $biz->get_data($name, $obj_order)
 $parts           = $biz->get_possible_data()

 # Container methods
 $new_container = $biz->add_container($at_contaier_obj)
 $container     = $biz->get_container($name, $obj_order)
 @containes     = $biz->get_possible_containers()

 # Access Categories
 $cat             = $biz->get_primary_category;
 $biz             = $biz->set_primary_category($cat);
 ($cats || @cats) = get_secondary_categories;
 $biz             = $biz->add_categories([$category, ...])
 ($cats || @cats) = $biz->get_categories()
 $biz             = $biz->delete_categories([$category, ...]);

 # Access keywords
 $biz               = $biz->add_keywords([{kw => $kw, weight => $weight}, ...])
 ($kw_list || @kws) = $biz->get_keywords()
 ($self || undef)   = $biz->has_keyword($keyword)
 $biz               = $biz->delete_keywords([$kw, ...])
 $kw_grp_id         = $biz->get_keyword_grp__id()

 # Related stories
 $biz                   = $biz->add_related([$other_biz, ...])
 (@related || $related) = $biz->get_related()
 $biz                   = $biz->delete_related([$other_ba, ...])
 $rel_grp__id           = $biz->get_related_grp__id()

 # Setting extra information
 $id   = $biz->create_attr($sql_type, $length, $at_data_id, $data_param);
 $data = $biz->get_attr()
 $id   = $biz->create_map($map_class, $map_type, $data_param);

 # Change control
 $biz            = $biz->cancel()
 $biz            = $biz->revert($version)
 (undef || $biz) = $biz->checkin()
 $biz            = $biz->checkout($param)


 ## INSTANCE METHODS FOR Bric::Biz::Asset::Business::Story

 # Manipulation of slug field
 $slug  = $story->get_slug()
 $story = $story->set_slug($slug)

 # Access the source ID
 $src_id = $story->get_source__id()

 # Change control
 ($story || undef) = $story->is_current()

 # Ad string management
 $story         = $story->delete_ad_param($key)
 $ad_param_hash = $story->get_ad_param()
 $story         = $story->set_ad_param($key ,$val);

 # Publish data
 $date  = $story->get_expire_date()
 $story = $story->set_expire_date()

 $date  = $story->get_publish_date()
 $story = $story->set_publish_date()

 # Save to the database
 $story = $story->save()

=head1 DESCRIPTION

Story contains all of the data that will result in published page(s)
It contains the metadata and associations with Formatting assets.

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
use Bric::Util::Time qw(:all);
use Bric::Util::Attribute::Story;
use Bric::Util::Grp::Parts::Member::Contrib;
use Bric::Util::Grp::Story;

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

use constant TABLE 	=> 'story';

use constant VERSION_TABLE => 'story_instance';

use constant COLS	=> qw(
						priority
						source__id
						usr__id
						element__id
						keyword_grp__id
						publish_date
						expire_date
						cover_date
						current_version
						workflow__id
						publish_status
                        primary_uri
						active);

use constant VERSION_COLS => qw(
						name
						description
						story__id
						version
						usr__id
						slug
						checked_out);

use constant FIELDS =>  qw(
						priority
						source__id 
						user__id
						element__id 
						keyword_grp__id
						publish_date 
						expire_date
						cover_date
						current_version
						workflow_id
						publish_status
                        primary_uri
						_active);

use constant VERSION_FIELDS => qw(
						name
						description
						id
						version
						modifier
						slug
						checked_out);

use constant AD_PARAM => '_AD_PARAM';
use constant GROUP_PACKAGE => 'Bric::Util::Grp::Story';
use constant INSTANCE_GROUP_ID => 31;

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
    Bric::register_fields({
			# Public Fields
			slug            => Bric::FIELD_RDWR

			# Private Fields
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

=item $story = Bric::Biz::Asset::Business::Story->new( $initial_state )

This will create a new story object with an optionaly defined intiial state

Supported Keys:

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

slug

=item *

element__id - Required unless asset type object passed

=item *

element - the object required unless id is passed

=item *

source__id - required

=item *

cover_date - will set expire date in conjunction with the source

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


=item $story = Bric::Biz::Asset::Business::Story->lookup->( { id => $id })

This will return a story asset that matches the id provided

B<Throws:>

"Missing required parameter 'id'"

B<Side Effects:>

NONE

B<Notes:>

NONE 

=cut

sub lookup {
	my ($class, $param) = @_;
	my $self = bless {}, (ref $class ? ref $class : $class);

	my $sql = 'SELECT s.id, ' . join(', ', map {"s.$_ "} COLS) .
				', i.id, ' . join(', ', map {"i.$_ "} VERSION_COLS) .
				' FROM ' . TABLE . ' s, ' . VERSION_TABLE . ' i ';

	my @where;
	if ($param->{'id'}) {
		$sql .= ' WHERE s.id=? AND i.story__id=s.id ';
		push @where, $param->{'id'};
	} elsif ($param->{'version_id'}) {
		$sql .= ' WHERE i.id=? AND i.story__id=s.id ';
		push @where, $param->{'version_id'};
	} else {
		die Bric::Util::Fault::Exception::GEN->new( { 
			msg => "Missing Required Parameters id or version_id" });
	}

	if ($param->{'version'}) {
		$sql .= ' AND i.version=? ';
		push @where, $param->{'version'};
	} elsif ($param->{'checkout'}) {
		$sql .= ' AND i.checked_out=? ';
		push @where, 1;
	} else {
		$sql .= ' AND s.current_version=i.version ';
	}

	# add the extra id field to the count
	my $col_count = (scalar COLS) + (scalar VERSION_COLS) + 1;
	my @d;

	my $sth = prepare_ca($sql, undef, DEBUG);
	local $" = ', '; #"
	execute($sth, @where);
	bind_columns($sth, \@d[0 .. $col_count ]);
	fetch($sth);

	# Return nothing if we don't get any results (no story ID)
	return unless $d[0];

	$self->_set( [ 'id', FIELDS, 'version_id', VERSION_FIELDS], [@d]);

	return unless $self->_get('id');

	$self->_set__dirty(0);

	return $self;
}

################################################################################

=item (@stories||$stories) = Bric::Biz::Asset::Business::Story->list($params)

Returns a list or anonymous array of Bric::Biz::Asset::Business::Story objects
based on the search parameters passed via an anonymous hash. The supported
lookup keys are:

=over 4

=item *

name - the same as the title field

=item *

title

=item *

description

=item *

id - the story id

=item *

version

=item *

slug

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

category_id

=item *

keyword - a string (not an object)

=item *

workflow__id

=item *

primary_url

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

Order - A property name to orer by.

=item *

OrderDirection - The direction in which to order the records, either "ASC" for
ascending (the default) or "DESC" for descending.

=item *

Limit - A maximum number of objects to return. If not specified, all objects
that match the query will be returned.

=item *

Offset - The number of objects to skip before listing the number of objects
specified by "Limit". Not used if "Limit" is not defined, and when "Limit" is
defined and "Offset" is not, no objects will be skipped.

=item *

simple - a single OR search that hits title, description, primary_uri
and keywords.

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
	my ($class, $params) = @_;

	# Send to _do_list function which will return objects
	_do_list($class,$params,undef);
}

################################################################################


#--------------------------------------#

=head2 Destructors

=item $self->DESTROY

This is a dummy method to save autoload the time to find it

=cut

sub DESTROY {
    # This method should be here even if its empty so that we don't waste time
    # making Bricolage's autoload method try to find it.
}

################################################################################

#--------------------------------------#

=head2 Public Class Methods

=cut                  

=item ($ids || @ids) = Bric::Biz::Asset::Business::Story->list_ids( $criteria )

Returns a list of the ids that match the given criteria

Supported Keys:

=over 4

=item *

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
	my ($class, $params) = @_;

	# Send to _do_list function which will return objects
	_do_list($class,$params,1);
}

################################################################################

=item my $key_name = Bric::Biz::Asset::Business::Story->key_name()

Returns the key name of this class.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub key_name { 'story' }

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
    push @ord, qw(slug category category_name), pop @ord;
    $meths->{slug}    = {
			  get_meth => sub { shift->get_slug(@_) },
			  get_args => [],
			  set_meth => sub { shift->set_slug(@_) },
			  set_args => [],
			  name     => 'slug',
			  disp     => 'Slug',
			  len      => 64,
			  type     => 'short',
			  props    => {   type       => 'text',
					  length     => 32,
					  maxlength => 64
				      }
			 };
    $meths->{category} = {
			  get_meth => sub { shift->get_primary_category(@_) },
			  get_args => [],
			  set_meth => sub { shift->set_primary_category(@_) },
			  set_args => [],
			  name     => 'category',
			  disp     => 'Category',
			  len      => 64,
			  req      => 1,
			  type     => 'short',
			 };

    $meths->{category_name} = {
			  get_meth => sub { shift->get_primary_category(@_)->get_name },
			  get_args => [],
			  name     => 'category_name',
			  disp     => 'Category',
			  len      => 64,
			  req      => 1,
			  type     => 'short',
			 };

    # Rename element, too.
    $meths->{element} = { %{ $meths->{element} } };
    $meths->{element}{disp} = 'Story Type';

    return !$ord ? $meths : wantarray ? @{$meths}{@ord} : [@{$meths}{@ord}];
}

################################################################################

#--------------------------------------#

=head2 Public Instance Methods

=over 4

=item $uri = $biz->get_uri(($cat_id||$cat_obj), ($oc_id||$oc_obj))

Returns the a URL for this business asset. The  URL is determined
by the pre- and post- directory strings of an output channel, the
URI of the business object's asset type, and the cover date if the asset type
is not a fixed URL.

B<Throws:> 

NONE

B<Side Effects:> 

NONE

B<Notes:> 

NONE

=cut

sub get_uri {
    my $self = shift;
    my ($cat, $oc) = @_;
    my ($cat_obj, $oc_obj);

	my $dirty = $self->_get__dirty();

    if ($cat) {
		$cat_obj = ref $cat ? $cat : Bric::Biz::Category->lookup({'id'=>$cat});
		$oc_obj  = ref $oc  ? $oc  : Bric::Biz::OutputChannel->lookup({'id'=>$oc});
    } else {
		$cat_obj = $self->get_primary_category();
		my $at_obj = $self->_get_element_object();
		($oc_obj) = $at_obj->get_output_channels($at_obj->get_primary_oc_id);
    }
    my $uri = $self->_construct_uri($cat_obj, $oc_obj);

    # Update the 'primary_uri' field if we were called with no arguments.
    $self->_set(['primary_uri'], [$uri]) unless scalar(@_);

	$self->_set__dirty($dirty);
    return $uri;
}

################################################################################

=item $story = $story->set_slug($slug);

Sets the slug for this story

B<Throws:> 

'Invalid characters found in slug'

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub set_slug {
	my ($self, $slug) = @_;

	my $dirty = $self->_get__dirty();

	if ($slug =~ m/\W/) {
		die Bric::Util::Fault::Exception::GEN->new( {
			msg => 'Slug Must conform to URL character rules' });
	} else {
		$self->_set( { slug => $slug });
	}

	$self->_set__dirty($dirty);
	return $self;
}

################################################################################

=item $slug = $story->get_slug()

returns the slug that has been set upon this story

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

################################################################################

=item ($categories || @categories) = $ba->get_categories()

This will return a list of categories that have been associated with
the business asset

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_categories {
    my ($self) = @_;
    my $cats = $self->_get_categories();
    my @all;
    my $reset;
    foreach my $c_id (keys %$cats) {
	next if $cats->{$c_id}->{'action'}
	  && $cats->{$c_id}->{'action'} eq 'delete';
	if ($cats->{$c_id}->{'object'} ){
	    push @all, $cats->{$c_id}->{'object'};
	} else {
	    my $cat = Bric::Biz::Category->lookup({ id => $c_id });
	    $cats->{$c_id}->{'object'} = $cat;
	    $reset = 1;
	    push @all, $cat;
	}
    }
    if ($reset) {
	my $dirty = $self->_get__dirty();
	$self->_set({ '_categories' => $cats });
	$self->_set__dirty($dirty);
    }
    return wantarray ? @all : \@all;
}

###############################################################################

=item $cat = $story->get_primary_category()

Returns the category object that has been defined as primary

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_primary_category {
	my ($self) = @_;

	my $cats = $self->_get_categories();

	foreach my $c_id (keys %$cats) {
		if ($cats->{$c_id}->{'primary'}) {
			if ($cats->{$c_id}->{'object'} ) {
				return $cats->{$c_id}->{'object'};
			} else {
				return Bric::Biz::Category->lookup( { id => $c_id });
			}
		}
	}
}

################################################################################

=item $story = $story->set_primary_category()

Defines a category as being the the primary one for this story.   If a category
is aready marked as being primary, this will disassociate it.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub set_primary_category {
    my ($self, $cat) = @_;
    my $cats = $self->_get_categories();
    foreach my $c_id (keys %$cats) {
	if ($cats->{$c_id}->{'primary'}) {
	    unless ($c_id == $cat) {
		$cats->{$c_id}->{'primary'} = 0;
		$cats->{$c_id}->{'action'} = 'update';
	    }
	} else {
	    if ($cat == $c_id) {
		$cats->{$c_id}->{'primary'} = 1;
		if ($cats->{$c_id}->{'action'}
		    && $cats->{$c_id}->{'action'} ne 'insert') {
		    $cats->{$c_id}->{'action'} = 'update';
		}
	    }
	}
    }
    return $self;
}

################################################################################

=item (@cats || $cats) = $story->get_secondary_categories()

Returns the non-primary categories that are associated with this story

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_secondary_categories {
	my ($self) = @_;

	my $cats = $self->_get_categories();

	my @seconds;
	foreach my $c_id (keys %$cats) {
		next if $cats->{$c_id}->{'primary'};
		if ($cats->{$c_id}->{'object'} ) {
			push @seconds, $cats->{$c_id}->{'object'};
		} else {
			push @seconds, Bric::Biz::Category->lookup( { id => $c_id });
		}
	}
	return wantarray ? @seconds : \@seconds;
}

################################################################################

=item $ba = $ba->add_categories( [ $category] )

This will take a list ref of category objects or ids and will associate 
them with the business asset

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub add_categories {
	my ($self, $categories) = @_;

	my $cats = $self->_get_categories();

	foreach my $c (@$categories) {
		# get the id
		my $cat_id = ref $c ? $c->get_id() : $c;

		# if it already is associated make sure it is not
		# going to be deleted
		if (exists $cats->{$cat_id}) {
			$cats->{$cat_id}->{'action'} = undef;
		} else {
			$cats->{$cat_id}->{'action'} = 'insert';
			$cats->{$cat_id}->{'object'} = ref $c ? $c : undef;
		}
	}

	# store the values

	$self->_set({   '_categories' => $cats});

	# set the dirty flag
	$self->_set__dirty(1);

	return $self;
}

################################################################################

=item $ba = $ba->delete_categories([$category]);

This will take a list of categories and remove them from the asset

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub delete_categories {
    my ($self, $categories) = @_;
    my ($cats) = $self->_get_categories();

    foreach my $c (@$categories) {
	# get the id if there was an object passed
	my $cat_id = ref $c ? $c->get_id() : $c;
	# remove it from the current list and add it to the delete list
	if (exists $cats->{$cat_id} ) {
	    if ($cats->{$cat_id}->{'action'}
		&& $cats->{$cat_id}->{'action'} eq 'insert') {
		delete $cats->{$cat_id};
	    } else {
		$cats->{$cat_id}->{'action'} = 'delete';
	    }
 	}
    }

    # set the values.
    $self->_set( {  '_categories' => $cats });
    $self->_set__dirty(1);
    return $self;
}

################################################################################

=item $slug = $story->get_slug()

Returns the slug that the story is associated with

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE 

=cut

################################################################################

=item $story = $story->checkout()

Preforms story specific checkout stuff and then calls checkout on the 
parent class

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub checkout {
	my ($self ,$param) = @_;

	my $cats = $self->_get_categories();

	$self->SUPER::checkout($param);

	# clone the category associations
	foreach (keys %$cats ) {
		$cats->{$_}->{'action'} = 'insert';
	}

	$self->_set__dirty(1);

	return $self;
}

################################################################################

=item my (@gids || $gids_aref) = $story->get_grp_ids

=item my (@gids || $gids_aref) = Bric::Biz::Asset::Business::Story->get_grp_ids

Returns a list or anonymous array of Bric::Biz::Group object ids representing the
groups of which this Bric::Biz::Asset::Business::Story object is a member.

B<Throws:> See Bric::Util::Grp::list().

B<Side Effects:> NONE.

B<Notes:> This list includes the Group IDs of the Desk, Workflow, and categories
in which the story is a member. [Actually, this method is currently disabled,
since categories don't actually add assets to an underlying group. If we later
find that customers need to control access to assets based on category, we'll
figure out a way to rectify this.]

=cut

#sub get_grp_ids {
#    my $self = shift;
#    my @ids = $self->SUPER::get_grp_ids;
#    # Add the category group IDs.
#    push @ids, (map { $_->get_asset_grp_id } $self->get_categories)
#      if ref $self;
#    return wantarray ? @ids : \@ids;
#}

#############################################################################	

=item $story = $story->revert();

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
			id				=> $self->_get_id(),
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
			slug => $revert_obj->get_slug()
		});

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

	$self->_set__dirty(1);

	return $self;
}

################################################################################

=item $story = $story->clone()

Creates an identical copy of this asset with a different id

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
		version					=> 1,
		current_version			=> 1,
		version_id 				=> undef,
		id						=> undef,
		publish_date			=> undef,
		publish_status			=> 0,
		_update_contributors 	=> 1
		});


	return $self;
}

################################################################################

=item $story = $story->save()

Updates the story object in the database

B<Throws:>
 NONE

B<Side Effects:>
 NONE

B<Notes:>
 NONE 

=cut

sub save {
	my ($self) = @_;

	# Make sure the primary uri is up to date.
	$self->_set(['primary_uri'], [$self->get_uri])
		unless ($self->get_primary_uri eq $self->get_uri);

	if ($self->_get('id')) {

		# make any necessary updates to the Main table
		$self->_update_story();

		if ($self->_get('version_id')) {
			if ($self->_get('_cancel')) {
				$self->_delete_instance();
				if ($self->_get('version') == 0) {
					$self->_delete_story();
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

		if ($self->_get('_cancel')) {
			return $self;
		} else {
			# This is Brand new insert both Tables
			$self->_insert_story();
			$self->_insert_instance();
		}
	}


	$self->_sync_categories();
	$self->SUPER::save();


	$self->_set__dirty(0);

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
    my ($sql, @select, @tables, @where, @bind);

    # Make sure to set active explictly if its not passed.
    $param->{'active'} = exists $param->{'active'} ? $param->{'active'} : 1;

    # Build a list of selected columns.
    push @select, 's.id';

    # Don't add any more if we're just listing IDs
    unless ($ids) {
	push @select, (map { "s.$_" } COLS),
	              (map { "i.$_" } 'id', VERSION_COLS);
    }

    # Build a list of table names to use.
    push @tables, TABLE.' s', VERSION_TABLE.' i';

    # Put the story__category mapping table in if they are searching by category
    if (defined($param->{'category_id'})) {
	push @tables, 'story__category c';
    }

    if ($param->{'keyword'}) {
	push @tables, 'member m', 'keyword_member km', 'keyword k';
	push @where, ('s.keyword_grp__id=m.grp__id',
		      'm.id=km.member__id',
		      'km.object_id=k.id',
		      'LOWER(k.name) LIKE ?');
	push @bind, lc($param->{'keyword'});
    }

    # Map field 'title' to field 'name'.
    $param->{'name'} = $param->{'title'} if exists $param->{'title'};
    # Map inverse alias inactive to active.
    $param->{'active'} = ($param->{'inactive'} ? 0 : 1)
      if exists $param->{'inactive'};

     # handle simple search - hits title, primary_uri, description and
     # keywords.
     if ($param->{'simple'}) {
       # replace TABLE select with left join to select keywords if
       # there are any
       $tables[0] = 'story s left outer join (member m left outer join (keyword_member km left outer join keyword k on (km.object_id=k.id)) on (m.id=km.member__id)) on (s.keyword_grp__id=m.grp__id)';
       push @where, ('(LOWER(k.name) LIKE ? OR LOWER(i.name) LIKE ? OR LOWER(i.description) LIKE ? OR LOWER(s.primary_uri) LIKE ?)');
       push @bind, (lc($param->{'simple'})) x 4;
     }


    # Build the where clause for the trivial story table fields.
    foreach my $f (qw(workflow__id primary_uri element__id 
		      priority active id)) {
	next unless exists $param->{$f};

	if ($f eq 'primary_uri') {
	    push @where, "LOWER(s.$f) LIKE ?";
	    push @bind,  lc($param->{$f});
	} else { 
	    push @where, "s.$f=?";
	    push @bind,  $param->{$f};
	}
    }

    # Build the where clause for the trivial story version table fields.
    foreach my $f (qw(name description version slug)) {
	next unless exists $param->{$f};

	if (($f eq 'name') || ($f eq 'description') || ($f eq 'slug')) {
	    push @where, "LOWER(i.$f) LIKE ?";
	    push @bind,  lc($param->{$f});
	} else { 
	    push @where, "i.$f=?";
	    push @bind,  $param->{$f};
	}
    }

    # Handle the custom list fields.

    # Special sql needed for searching on user_id
    if (defined $param->{'user__id'}) {
	push @where, 's.usr__id=?';
	push @bind, $param->{'user__id'};
	push @where, 'i.checked_out=?';
	push @bind, 1;
    } else {
	push @where, 'i.checked_out=?';
	push @bind, 0;
    }

    # Return only the current version unless they want them all.
    unless ($param->{'return_versions'}) {
	push @where, 's.current_version=i.version';
    }

    # Handle searches on dates
    foreach my $type (qw(publish_date cover_date expire_date)) {
	my ($start, $end) = ($param->{$type.'_start'},
			     $param->{$type.'_end'});
	
	# Handle date ranges.
	if ($start && $end) {
	    push @where, "s.$type BETWEEN ? AND ?";
	    push @bind, $start, $end;
	} else {
	    # Handle 'everying before' or 'everything after' $date searches.
	    if ($start) {
		push @where, "s.$type > ?";
		push @bind, $start;
	    } elsif ($end) {
		push @where, "s.$type < ?";
		push @bind, $end;
	    }
	}
    }

    if (defined $param->{'category_id'}) {
	push @where, 'i.id = c.story_instance__id';
	push @where, 'c.category__id = ?';
	push @bind, $param->{'category_id'};
    }

    push @where, 's.id=i.story__id';

    $sql  = 'SELECT DISTINCT '.join(', ',@select).' FROM '.join(', ',@tables);
    $sql .= ' WHERE '.join(' AND ',@where);

    # a small selection of possible order bys - this could be made
    # general like where.
    if ($param->{'return_versions'}) {
	$sql .= ' ORDER BY i.version ';
    } elsif ($param->{Order}) {
	if ($param->{'Order'} eq 'cover_date') {
	    $sql .= ' ORDER BY s.cover_date';
	} elsif ($param->{'Order'} eq 'publish_date') {
	    $sql .= ' ORDER BY s.publish_date';
	}
    } else {
	$sql .= ' ORDER BY s.cover_date';
    }

    # check for ORDER BY direction
    if ($param->{OrderDirection}) {
      $sql .= ' ' . $param->{OrderDirection} . ' ';
    }

    # check for limit and offset
    if ($param->{'Limit'}) {
      $sql .= ' LIMIT ' . $param->{'Limit'} . ' ';
      if ($param->{'Offset'}) {
        $sql .= ' OFFSET ' . $param->{'Offset'} . ' ';
      }
    }

    # print STDERR "\n\n", $sql, "\n\n", join(', ', @bind), "\n\n";

    my $select = prepare_ca($sql, undef, DEBUG);

    if ($ids) {
	# called from list_ids give em what they want
	my $return = col_aref($select,@bind);

	return wantarray ? @{ $return } : $return;
    } else { # end if ids
	# this must have been called from list so give objects
	my (@objs, @d);
	my $count = (scalar FIELDS) + (scalar VERSION_FIELDS) + 1;	

	execute($select,@bind);
	bind_columns($select, \@d[0 .. $count]);
	
	while (fetch($select)) {    
	    my $self = bless {}, $class;

	    $self->_set(['id', FIELDS, 'version_id', VERSION_FIELDS], [@d]);
		$self->_set__dirty(0);	
	    push @objs, $self;
	}

	# Return the objects.
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

	unless ($queried) {

		my $dirty = $self->_get__dirty();

		my $sql = 'SELECT member__id, place, role FROM story__contributor ' .
					'WHERE story_instance__id=? ';

		my $sth = prepare_ca($sql, undef, DEBUG);
		execute($sth, $self->_get('version_id'));
		while (my $row = fetch($sth)) {
			$contrib->{$row->[0]}->{'role'} = $row->[2];
			$contrib->{$row->[0]}->{'place'} = $row->[1];
		}
		$self->_set( { 
				'_queried_contrib' => 1,
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

	my $sql = 'INSERT INTO story__contributor ' .
				' (id, story_instance__id, member__id, place, role) ' . 
				" VALUES (${\next_key('story__contributor')},?,?,?,?) ";

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

	my $sql = 'UPDATE story__contributor ' .
				' SET role=?, place=? ' . 
				' WHERE story_instance__id=? ' . 
				' AND member__id=? ';

	my $sth = prepare_c($sql, undef, DEBUG);

	execute($sth, $role, $place, $self->_get('version_id'), $id);

	return $self;
}

################################################################################

=item $self = $self->_delete_contributor($id)

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

	my $sql = 'DELETE FROM story__contributor ' . 
				' WHERE story_instance__id=? ' . 
				' AND member__id=? ';

	my $sth = prepare_c($sql, undef, DEBUG);

	execute($sth, $self->_get('version_id'), $id);

	return $self;
}

################################################################################

=item $category_data = $self->_get_categories()

Returns the category data structure for this story

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _get_categories {
	my ($self) = @_;

	my ($cats, $queried) = $self->_get('_categories', '_queried_cats');

	unless ($queried) {
		my $dirty = $self->_get__dirty();
		my $sql = 'SELECT category__id, main '.
					"FROM story__category ".
					" WHERE story_instance__id=? ";

		my $sth = prepare_ca($sql, undef, DEBUG);

		execute($sth, $self->_get('version_id'));
		while (my $row = fetch($sth)) {
			$cats->{$row->[0]}->{'primary'} = $row->[1];
		}

		# Write this back in case it has not yet been defined.
		$self->_set( {
				'_categories' => $cats,
				'_queried_cats' => 1 
			});

		$self->_set__dirty($dirty);
	}

	return $cats;
}

################################################################################

=item $ba = $ba->_sync_categories 

Called by save this will make sure that all the changes in category
mappings are reflected in the database

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _sync_categories {
    my ($self) = @_;
    my $dirty = $self->_get__dirty();
    my $cats = $self->_get_categories();
    foreach my $cat_id (keys %$cats) {
	next unless $cats->{$cat_id}->{'action'};
	if ($cats->{$cat_id}->{'action'} eq 'insert') {
	    my $primary = $cats->{$cat_id}->{'primary'} ? 1 : 0;
	    $self->_insert_category($cat_id, $primary);
	    $cats->{$cat_id}->{'action'} = undef;
	} elsif ($cats->{$cat_id}->{'action'} eq 'update') {
	    my $primary = $cats->{$cat_id}->{'primary'} ? 1 : 0;
	    $self->_update_category($cat_id, $primary);
	    $cats->{$cat_id}->{'action'} = undef;
	} elsif ($cats->{$cat_id}->{'action'} eq 'delete') {
	    $self->_delete_category($cat_id);
	    delete $cats->{$cat_id};
	}
    }

    $self->_set( { '_categories' => $cats });
    $self->_set__dirty($dirty);
    return $self;
}

################################################################################

=item $ba = $ba->_insert_category($cat_id, $primary)

Adds a record that associates this ba with the category

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _insert_category {
	my ($self, $category_id,$primary) = @_;

	my $sql = "INSERT INTO story__category ".
				"(id, story_instance__id, category__id, main) ".
				"VALUES (${\next_key('story__category')},?,?,?)";

	my $sth = prepare_c($sql, undef, DEBUG);
	execute($sth, $self->_get('version_id'), $category_id, $primary);

	return $self;
}

################################################################################

=item $ba = $ba->_delete_category( $cat_id)

Removes this record for the database

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _delete_category {
	my ($self, $category_id) = @_;

	my $sql = "DELETE FROM story__category ".
				"WHERE story_instance__id=? AND category__id=? ";

	my $sth = prepare_c($sql, undef, DEBUG);
	execute($sth, $self->_get('version_id'), $category_id);

	return $self;
}

################################################################################

=item $ba = $ba->_update_category($cat_id, $primary);

Preforms an update on the row in the data base

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _update_category {
	my ($self, $category_id,$primary) = @_;

	my $sql = "UPDATE story__category ".
				"SET main=? ".
				"WHERE story_instance__id=? AND category__id=? ";

	my $sth = prepare_c($sql, undef, DEBUG);
	execute($sth, $primary, $self->_get('version_id'), $category_id);

	return $self;
}

###############################################################################

=item $attribute_obj = $self->_get_attribute_object()

Returns the attribte object for this story

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _get_attribute_object {
	my ($self) = @_;

	my $dirty = $self->_get__dirty();

	my $attr_obj = $self->_get('_attribute_object');

	return $attr_obj if $attr_obj;

	# Let's Create a new one if one does not exist
	$attr_obj = Bric::Util::Attribute::Story->new(
				{id => $self->_get('id')});

	$self->_set( {'_attribute_object' => $attr_obj} );
	$self->_set__dirty($dirty);

	return $attr_obj;
}

################################################################################

=item $self = $self->_do_delete()

Removes the row from te database

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _do_delete {
	my ($self) = @_;

	my $delete = prepare_c( qq{
		DELETE FROM 
			TABLE
		WHERE
			id=?
		}, undef, DEBUG);

	execute($delete, $self->_get('id'));
}

################################################################################

=item $self = $self->_insert_story()

Inserts a story record into the database

B<Throws:>

NONE

B<side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _insert_story {
	my ($self) = @_;

	my $sql = 'INSERT INTO ' . TABLE . ' (id, ' . join(', ', COLS) . ') '.
				"VALUES (${\next_key(TABLE)}, ". join(', ',  ('?') x COLS) .')';

	my $sth = prepare_c($sql, undef, DEBUG);
	execute($sth, $self->_get(FIELDS));

	$self->_set( { id => last_key(TABLE) });

	# And finally, register this person in the "All Stories" group.
	$self->register_instance(INSTANCE_GROUP_ID, GROUP_PACKAGE);

	return $self;
}

################################################################################

=item $self = $self->_insert_instance()

Inserts an instance record into the database

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
				' (id, '.join(', ', VERSION_COLS) . ')'.
				"VALUES (${\next_key(VERSION_TABLE)}, ".
					join(', ', ('?') x VERSION_COLS) . ')';

	my $sth = prepare_c($sql, undef, DEBUG);
	execute($sth, $self->_get(VERSION_FIELDS));

	$self->_set( { version_id => last_key(VERSION_TABLE) });

	return $self;
}

################################################################################

=item $self = $self->_update_story()

Updates the story record in the database

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _update_story {
	my ($self) = @_;

	return unless $self->_get__dirty();

	my $sql = 'UPDATE ' . TABLE . ' SET ' . join(', ', map {"$_=?" } COLS) .
				' WHERE id=? ';

	my $sth = prepare_c($sql, undef, DEBUG);
	execute($sth, $self->_get(FIELDS), $self->_get('id'));

	return $self;
}

################################################################################

=item $self = $self->_update_instance()

Updates the record for the story instance

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _update_instance {
	my ($self) = @_;

	return unless $self->_get__dirty();

	my $sql = 'UPDATE ' . VERSION_TABLE .
				' SET ' . join(', ', map {"$_=?" } VERSION_COLS) .
				' WHERE id=? ';

	my $sth = prepare_c($sql, undef, DEBUG);
	execute($sth, $self->_get(VERSION_FIELDS), $self->_get('version_id'));

	return $self;
}

################################################################################

=item $self = $self->_delete_instance();

Deletes the version record from a cancled checkout

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

=item $self = $self->_delete_story();

Deletes from the story table for a story that has never been checked in

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _delete_story {
	my ($self) = @_;

	my $sql = 'DELETE FROM ' . TABLE .
				' WHERE id=? ';

	my $sth = prepare_c($sql, undef, DEBUG);
	execute($sth, $self->_get('id'));

	return $self;
}

################################################################################

1;
__END__

=back

=head1 NOTES

NONE

=head1 AUTHOR

"Michael Soderstrom" <miraso@pacbell.net>
Bricolage Engineering

=head1 SEE ALSO

L<perl>, L<Bric>, L<Bric::Biz::Asset>, L<Bric::Biz::Asset::Business>

=cut



