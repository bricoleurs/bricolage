package Bric::Biz::Asset::Formatting;
###############################################################################

=head1 NAME

Bric::Biz::Asset::Formatting - AN object housing the formatting Assets

=head1 VERSION

$Revision: 1.14 $

=cut

our $VERSION = (qw$Revision: 1.14 $ )[-1];

=head1 DATE

$Date: 2001-12-04 23:17:32 $

=head1 SYNOPSIS

 # Creation of Objects
 $fa = Bric::Biz::Asset::Formatting->new( $init )
 $fa = Bric::Biz::Asset::Formatting->lookup( { id => $id })
 ($fa_list || @fas) = Bric::Biz::Asset::Formatting->list( $param )
 ($faid_list || @fa_ids) = Bric::Biz::Asset::Formatting->list_ids( $param )

 # get / set the data that is contained with in
 $fa = $fa->set_data()
 $data = $fa->get_data()

 # get the file name that this will be deployed to
 $file_name = $fa->get_file_name()

 # get / set the date that this will activate
 $date = $fa->get_deploy_date()
 $fa = $fa->set_deploy_date($date)

 # get the output channel that this is associated with  
 $output_channel_id = $fa->get_output_channel__id()

 # get the asset type that this is associated with 
 $element__id = $fa->get_element__id()

 # get the category that this is associated with
 $category_id = $fa->get_category_id()

 # Methods Inheriated from Bric::Biz::Asset

 # Class Methods
 $key_name = Bric::Biz::Asset->key_name()
 %priorities = Bric::Biz::Asset->list_priorities()
 $data = Bric::Biz::Asset->my_meths

 # looking up of objects
 ($asset_list || @assets) = Bric::Biz::Asset->list( $param )

 # General information
 $asset       = $asset->get_id()
 $asset       = $asset->set_name($name)
 $name        = $asset->get_name()
 $asset       = $asset->set_description($description)
 $description = $asset->get_description()
 $priority    = $asset->get_priority()
 $asset       = $asset->set_priority($priority)

 # User information
 $usr_id      = $asset->get_user__id()
 $modifier    = $asset->get_modifier()

 # Version information
 $vers        = $asset->get_version();
 $vers_id     = $asset->get_version_id();
 $current     = $asset->get_current_version();
 $checked_out = $asset->get_checked_out()

 # Expire Data Information
 $asset       = $asset->set_expire_date($date)
 $expire_date = $asset->get_expire_date()

 # Desk stamp information
 ($desk_stamp_list || @desk_stamps) = $asset->get_desk_stamps()
 $desk_stamp                        = $asset->get_current_desk()
 $asset                             = $asset->set_current_desk($desk_stamp)

 # Workflow methods.
 $id    = $asset->get_workflow_id;
 $obj   = $asset->get_workflow_object;
 $asset = $asset->set_workflow_id($id);

 # Access note information
 $asset                 = $asset->add_note($note)
 ($note_list || @notes) = $asset->get_notes()

 # Access active status
 $asset            = $asset->deactivate()
 $asset            = $asset->activate()
 ($asset || undef) = $asset->is_active()

 $asset = $asset->save()

 # returns all the groups this is a member of
 ($grps || @grps) = $asset->get_grp_ids()


=head1 DESCRIPTION

This has changed, it will need to be updated in a bit

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
use Bric::Util::Grp::AssetVersion;
use Bric::Util::Time qw(:all);
use Bric::Util::Fault::Exception::GEN;
use Bric::Util::Trans::FS;
use Bric::Util::Grp::Formatting;
use Bric::Biz::AssetType;
use Bric::Biz::Category;
use Bric::Biz::OutputChannel;
use Bric::Util::Attribute::Formatting;

#==============================================================================#
# Inheritance                          #
#======================================#

use base qw( Bric::Biz::Asset );

#=============================================================================#
# Function Prototypes                  #
#======================================#
my ($build_file_name);
# None

#==============================================================================#
# Constants                            #
#======================================#

use constant DEBUG => 0;

# constants for the Database
use constant TABLE 	=> 'formatting';
use constant VERSION_TABLE => 'formatting_instance';
use constant COLS 	=> qw(
							name
                            priority
							description
							usr__id
							output_channel__id
							element__id
							category__id
							file_name
							current_version
							deploy_status
							deploy_date
							expire_date
							workflow__id
							active);

use constant VERSION_COLS => qw(
							formatting__id
							version
							usr__id
							data
							checked_out);

use constant FIELDS	=> qw(
							name
                                                        priority
							description
							user__id
							output_channel__id
							element__id
							category_id
							file_name
							current_version
							deploy_status
							deploy_date
							expire_date
							workflow_id
							_active);

use constant VERSION_FIELDS => qw(
							id
							version
							modifier
							data
							checked_out);

use constant GROUP_PACKAGE => 'Bric::Util::Grp::Formatting';
use constant INSTANCE_GROUP_ID => 33;

#==============================================================================#
# Fields                               #
#======================================#

#--------------------------------------#
# Public Class Fields

# None

#--------------------------------------#
# Private Class Fields 
my ($meths, @ord);
# None

#--------------------------------------#
# Instance Fields

BEGIN {
	Bric::register_fields(
	       {
		# Public Fields

		# the output channel that this is associated with
		output_channel__id => Bric::FIELD_READ,

		# the asset type that this formats
		element__id	   => Bric::FIELD_READ,

		# the category that this is associated with
		category_id    	   => Bric::FIELD_READ,

		# the file name as set by the burn system when deployed
		file_name	   => Bric::FIELD_READ,

		# Users will insert data into this field and then save will
		# populate the _data_oid field for DB insertion.
		data	           => Bric::FIELD_RDWR,

		deploy_status	   => Bric::FIELD_RDWR,
		deploy_date	   => Bric::FIELD_RDWR,	


		# Private Fields
		_active             => Bric::FIELD_NONE,
		_output_channel_obj => Bric::FIELD_NONE,
		_element_obj     => Bric::FIELD_NONE,
		_category_obj       => Bric::FIELD_NONE,
		_revert_obj			=> Bric::FIELD_NONE

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

=item $fa = Bric::Biz::Asset::Formatting->new( $initial_state )

new will only be called by Bric::Biz::Asset::Formatting's inherited classes

Supported Keys:

=over 4

=item *

description

=item *

data

=item *

deploy_date

=item *

expire_date

=item *

workflow_id

=item *

output_channel - Required unless output channel id passed

=item *

output_channel__id - Required unless output channel object passed

=item *

element - the at object

=item *

element__id - the id of the asset type

=item *

category - the category object

=item *

category__id - the category id

=item *

file_type - the type of the template file - this will be used as the
extension for the file_name derived from the element name.  Currently
supported file_type values are 'mc', 'pl' and 'tmpl'.

=back
 
B<Throws:>

"Method not implemented"

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub new {
	my ($class, $init) = @_;

	my $self = bless {}, $class;

	# set active unless we we passed another value
	$init->{'_active'} = exists $init->{'active'} ? $init->{'active'} : 1;
	# remove active from our list
	delete $init->{'active'};
	$init->{'modifier'} = $init->{'user__id'};
	$init->{'checked_out'} = 1;
	$init->{'deploy_status'} = 0;
	$init->{priority} ||= 3;

	# file type defaults to 'mc'
	$init->{file_type} ||= 'mc';

	# check for required output_channel__id, element__id, 
	# and category
	die Bric::Util::Fault::Exception::GEN->new( {
		msg =>  'missing required param output channel or asset type'})
			 unless (defined $init->{'output_channel'} || 
					defined $init->{'output_channel__id'});

	my $name; # used to construct file name
	if (defined $init->{'element'}) {
	    $init->{'element__id'} = $init->{'element'}->get_id();
	    $name = $init->{'element'}->get_name();
	} elsif (defined $init->{'element__id'}) {
	    my $at = Bric::Biz::AssetType->lookup({id => $init->{'element__id'}});
	    $name = $at->get_name();
	} else {
	    if ($init->{file_type} eq 'mc') {
		$name = 'autohandler';
	    } elsif ($init->{file_type} eq 'pl' or $init->{file_type} eq 'tmpl') {
		$name = 'category';
	    }
	}

	my ($pre, $post);
	if (defined $init->{'output_channel'}) {
		$init->{'output_channel__id'} = $init->{'output_channel'}->get_id();
		# need to check this!
		$pre = $init->{'output_channel'}->get_pre_path();
		$post = $init->{'output_channel'}->get_post_path();
	} else {
		my $channel = Bric::Biz::OutputChannel->lookup( { 
				id => $init->{'output_channel__id'}	});

		$pre = $channel->get_pre_path();
		$post = $channel->get_post_path();
	}

	my $cat_path;
	if (defined $init->{'category'}) {
		$init->{'category_id'} = $init->{'category'}->get_id();
		$cat_path = $init->{'category'}->ancestry_dir();
	} elsif (defined $init->{'category_id'}) {
		my $cat = Bric::Biz::Category->lookup( { id => $init->{'category_id'}});
		$cat_path = $cat->ancestry_dir();
	}

	# construct File Path for FA
	(my $file = $name) =~ s/\W+/_/g;
	
	# Don't put the file_type extension on if this is an
	# autohandler.
	$file .= '.' . $init->{file_type} unless $name eq 'autohandler';

	$init->{file_name} =
	  Bric::Util::Trans::FS->cat_dir('', $pre, $cat_path, $post, $file);

	@{$init}{qw(version current_version name)} = (0, 0, $name);
	$self->SUPER::new($init);

	return $self;
}

################################################################################

=item $formatting = Bric::Biz::Formatting->lookup( $param )

Returns an object that matches the parameters

Suported Keys

=over4

=item id

The unique id of formatting assets

=item version

Pass to request a specific version otherwise the most current will be 
returned

=back

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub lookup {
    my ($class, $param) = @_;
    my $self = bless {}, (ref $class ? ref $class : $class);
    
	my $sql = 'SELECT f.id, ' . join(', ', map {"f.$_ "} COLS) .
				', i.id, ' . join(', ', map {"i.$_ "} VERSION_COLS) .
				' FROM ' . TABLE . ' f, ' . VERSION_TABLE . ' i ' .
				' WHERE f.id=? AND i.formatting__id=f.id ';

	my @where;
	push @where, $param->{'id'};

	if ($param->{'version'}) {
		$sql .= ' AND i.version=? ';
		push @where, $param->{'version'};
	} else {
		$sql .= ' AND f.current_version=i.version ';
	}

	my $count = (scalar FIELDS) + (scalar VERSION_FIELDS) + 1;
	my @d;
	my $sth = prepare_ca($sql, undef, DEBUG);
	execute($sth, @where);
	bind_columns($sth, \@d[0 .. $count ]);
	fetch($sth);

	$self->_set( [ 'id', FIELDS, 'version_id', VERSION_FIELDS], [@d]);

	return unless $self->_get('id');

	$self->_set__dirty(0);

    return $self;
}

################################################################################

=item ($fa_list || @fas) = Bric::Biz::Asset::Formatting->list( $criteria )

This will return a list of blessed objects that match the defined criteria

Supported Keys:

=over 4

=item *

active - defaults to true

=item *

user__id - if defined will return the checked out versions that are checked out
to the user with this id.   Otherwise it will return the most current non
checked out versions

=item *

return_versions - will return all the versions of the given templates

=item *

id

=item *

workflow__id

=item *

output_channel__id

=item *

element__id

=item *

category__id

=item *

name

=item *

file_name

=item *

deploy_date_start

=item *

deploy_date_stop

=item *
expire_date_start

=item * 

expire_date_stop

=item *

simple - a single OR search that hits name and filename

=back

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut


sub list {
	my ($class, $param) = @_;

	# send this to do list
	return _do_list($class, $param, undef);
}


#--------------------------------------#

=head2 Destructors

=item $template->DESTROY

Dummy method to prevent wasting time trying to AUTOLOAD DESTROY.

=cut

sub DESTROY {
	# This method should be here even if its empty so that we don't waste time
	# making Bricolage's autoload method try to find it.
}

#--------------------------------------#

=head2 Public Class Methods

=cut

=item ($ids || @ids) = Bric::Biz::Asset::Formatting->list_ids($param)

Returns a list of ids that match the given parameters

=item Supported Keys

=over 4

See List Method

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

	# call do list with the flag that states we just want ids\
	return _do_list($class, $param, 1);
}


################################################################################

=item my $key_name = Bric::Biz::Asset::Formatting->key_name()

Returns the key name of this class.

B<Throws:> 

NONE

B<Side Effects:> 

NONE

B<Notes:> 

NONE

=cut

sub key_name { 'formatting' }

################################################################################

=item $meths = Bric::Biz::Asset::Business->my_meths

=item (@meths || $meths_aref) = Bric::Biz::Asset::Business->my_meths(TRUE)

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
    push @ord, qw(file_name deploy_date output_channel output_channel
                  category, category_name), pop @ord;

    $meths->{file_name} = {
			      name     => 'file_name',
			      get_meth => sub { shift->get_file_name(@_) },
			      get_args => [],
			      set_meth => sub { shift->set_file_name(@_) },
			      set_args => [],
			      disp     => 'File Name',
			      len      => 256,
			      req      => 0,
			      type     => 'short',
			      props    => {   type       => 'text',
					      length     => 32,
					      maxlength => 256
					  }
			     };
    $meths->{deploy_date} = {
			      name     => 'deploy_date',
			      get_meth => sub { shift->get_deploy_date(@_) },
			      get_args => [],
			      set_meth => sub { shift->set_deploy_date(@_) },
			      set_args => [],
			      disp     => 'Deploy Date',
			      len      => 64,
			      req      => 0,
			      type     => 'short',
			      props    => { type => 'date' }
			     };
    $meths->{output_channel} =  {
			      name     => 'output_channel',
			      get_meth => sub { shift->get_output_channel(@_) },
			      get_args => [],
			      set_meth => sub { shift->set_output_channel(@_) },
			      set_args => [],
			      disp     => 'Output Channel',
			      len      => 64,
			      req      => 0,
			      type     => 'short',
			     };

    $meths->{output_channel_name} = {
			  get_meth => sub { shift->get_output_channel_name(@_) },
			  get_args => [],
			  name     => 'output_channel_name',
			  disp     => 'Output Channel',
			  len      => 64,
			  req      => 1,
			  type     => 'short',
			 };

    $meths->{category} = {
			  get_meth => sub { shift->get_category(@_) },
			  get_args => [],
			  set_meth => sub { shift->set_category(@_) },
			  set_args => [],
			  name     => 'category',
			  disp     => 'Category',
			  len      => 64,
			  req      => 1,
			  type     => 'short',
			 };

    $meths->{category_name} = {
			  get_meth => sub { shift->get_category(@_)->get_name },
			  get_args => [],
			  name     => 'category_name',
			  disp     => 'Category',
			  len      => 64,
			  req      => 1,
			  type     => 'short',
			 };

    return !$ord ? $meths : wantarray ? @{$meths}{@ord} : [@{$meths}{@ord}];
}

################################################################################

#--------------------------------------#

=head2 Public Instance Methods

=cut

=item $template = $template->set_deploy_date($date)

=item $template = $template->set_cover_date($date)

Sets the deployment date for this template

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub set_deploy_date {
    my $self = shift;
    my $date = db_date(shift);
    my $deploy_date = $self->_get('deploy_date');

    unless (defined $deploy_date and $date eq $deploy_date) {
	$self->_set(['deploy_date'], [$date]);
    }

    return $self;
}

*set_cover_date = *set_deploy_date;

################################################################################

=item $date = $template->get_deploy_date()

=item $date = $template->get_cover_date()

Returns the deploy date set upon this template

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_deploy_date { local_date($_[0]->_get('deploy_date'), $_[1]) }

*get_cover_date = *get_deploy_date;

################################################################################

=item $status = $template->get_deploy_status()

=item $template = $template->get_publish_status()

Returns the deploy status of the formatting asset

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

this will return the deploy date

=cut

sub get_publish_status { $_[0]->_get('deploy_status') }

################################################################################

=item $template = $template->set_deploy_status()

=item $template = $template->set_publish_status()

sets the deploy status for this template

B<Throws:>

NONE

B<Side Effect:>

NONE

B<Notes:>

This is really the deploy date

=cut

sub set_publish_status {
    my $self = shift;
    my ($status) = @_;

    if ($status ne $self->get_deploy_status) {
	$self->set_deploy_status($status);
    }

    return $self;
}

################################################################################

=item $uri = $template->get_uri

An alias for 'get_file_name'

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_uri { Bric::Util::Trans::FS->dir_to_uri($_[0]->get_file_name) }

################################################################################

=item $file_name = $template->get_file_name()

Returns the file path of this template.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

################################################################################

=item $name = $template->get_output_channel_name;

Return the name of the output channel.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_output_channel_name {
    my $self = shift;
    my $oc_obj = $self->_get_output_channel_object;

    return unless $oc_obj;

    return $oc_obj->get_name;
}

################################################################################

=item $name = $template->get_output_channel;

Return the output channel associated with this Formatting asset.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_output_channel {
    my $self = shift;
    my $oc_obj = $self->_get_output_channel_object;

    return $oc_obj;
}

################################################################################

=item $name = $template->get_element_name;

Return the name of the AssetType associated with this object.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut


sub get_element_name {
    my $self = shift;
    my $at_obj = $self->_get_element_object;

    return unless $at_obj;

    return $at_obj->get_name;
}

################################################################################

=item $at_obj = $template->get_element

Return the AssetType object for this formatting asset.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_element {
    my $self = shift;
    my $at_obj = $self->_get_element_object;

    return $at_obj;
}

################################################################################

=item $fa = $fa->set_category_id($id)

Sets the category id for this formatting asset

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub set_category_id {
    my ($self, $id) = @_;

    if ($id != $self->get_category_id) {
	$self->_set(['category_id','_category_obj'], [$id, undef]);
	$self->_set(['file_name'], [&$build_file_name($self)]);
    }

    return $self;
}


################################################################################

=item $fa = $fa->get_cagetory_id

Get the category ID for this formatting asset.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

################################################################################

=item $fa = $fa->get_category

Returns the category object that has been associated with this formatting asset.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_category {
	my ($self) = @_;

	return $self->_get_category_object();
}

################################################################################

=item $fa = $fa->get_cagetory_path

Returns the path from the category

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_category_path {
	my ($self) = @_;

	my $cat = $self->_get_category_object || return;

	return $cat->ancestry_path;
}

################################################################################

=item $fa = $fa->get_cagetory_name

Get the category name of the category object associated with this
formatting asset.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_category_name {
	my ($self) = @_;

	my $cat = $self->_get_category_object || return;

	return $cat->get_name;
}

################################################################################

=item $template = $template->set_data( $data )

Set the main data for the formatting asset.   In future incarnations 
there might be more data points that surround this, but not for now.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

################################################################################

=item $data = $template->get_data()

Returns the chunk of text that makes up this template.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

################################################################################

=item $format = $format->checkout($param);

This will create a flag to add a new record to the instance table

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub checkout {
	my ($self, $param) = @_;

	# make sure that this version is the most current
	unless ($self->_get('version') == $self->_get('current_version') ) {
		die Bric::Util::Fault::Exception::GEN->new( { msg => 
				"Unable to checkout old_versions" });
	}
	# Make sure that the object is not already checked out
	if ($self->_get('user__id')) {
		die Bric::Util::Fault::Exception::GEN->new( {
			msg => "Already Checked Out" });
	}
	unless (defined $param->{'user__id'}) {
		die Bric::Util::Fault::Exception::GEN->new( { msg =>
			"Must be checked out to users" });
	}	

	$self->_set({'user__id'    => $param->{'user__id'} ,
		     'modifier'    => $param->{'user__id'},
		     'version_id'  => undef,
		     'checked_out' => 1
		    });

	return $self;
}

################################################################################

=item $fa = $fa->checkin()

This preforms a checkin.   It will make sure that there is not another
conflict version that exists.   If so it will fail and one must merge the
conflicts.   Otherwise it will promote the version and disassociate the 
user from the object

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut
						
sub checkin {
	my ($self) = @_;

	my $version = $self->_get('version');

	$version++;
	$self->_set({'user__id'        => undef,
		     'version'         => $version,
		     'current_version' => $version,
		     'checked_out'     => 0,
		    });

	return $self;
}

################################################################################

=item ($fa || undef) = $fa->is_current()

Return whether this is the most current version or not.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub is_current {
    my ($self) = @_;

    return ($self->_get('version') == $self->_get('current_version'))
		? $self : undef;
}

#------------------------------------------------------------------------------#

=item $fa = $fa->cancel()

This cancles a checkout.   This will delete the record from the 
database

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub cancel {
    my ($self) = @_;
    my $dirty = $self->_get__dirty;

    if (not $self->get_user__id) {
	# this is not checked out, it can not be deleted
	my $msg = 'Cannot cancel an asset that is not checked out';
	die Bric::Util::Fault::Exception::AP->new({'msg' => $msg});
    }

    $self->_set(['_cancel'], [1]);
    # Restore the original dirty value.
    $self->_set__dirty($dirty);

    return $self;
}

################################################################################

=item $fa = $fa->revert()

This will take an older version and copy its data to this version

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
			id 				=> $self->_get_id(),
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

	$self->_set(['data'], [$revert_obj->get_data]);

	return $self;
}

################################################################################

=item $fa = $fa->save()

this will update or create a record in the database

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub save {
    my ($self) = @_;

    # Handle a cancel.
    my ($id, $vid, $cancel, $ver) =
      $self->_get(qw(id version_id _cancel version));

    # Only update/insert this object if some of our fields are dirty.
    if ($self->_get__dirty) {
	if ($self->get_id) {
	    # make any necessary updates to the Main table
	    $self->_update_formatting();

	    # Update or insert depending on if we have an ID.
	    if ($self->get_version_id) {
		if ($cancel) {
		    if (defined $id and defined $vid) {
			$self->_delete_instance();
			$self->_delete_formatting() if $ver == 0;
			$self->_set(['_cancel'], [undef]);
		    }
		    return $self;
		}
		$self->_update_instance();
	    } else {
		$self->_insert_instance();
	    }
	} else {
	    # This is Brand new insert both Tables
	    $self->_insert_formatting();
	    $self->_insert_instance();
	}
    }

    # Call the parents save method
    $self->SUPER::save();

    $self->_set__dirty(0);

    return $self;
}


#=============================================================================#

=head2 PRIVATE

=cut

=item _do_list( $class, $param, $ids)

Executes for list and list_ids

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _do_list {
    my ($class, $param, $ids) = @_;
    my ($sql, $sth, @bind);
    my (@select, @from, @where, $order);

    # Make sure to set active explictly if its not passed.
    $param->{'active'} = exists $param->{'active'} ? $param->{'active'} : 1;

    # Setup the base query.
    @select = ('f.id');
    @from   = (TABLE.' f', VERSION_TABLE.' i');
    @where  = ('f.id=i.formatting__id');

    unless ($ids) {
	# if we want more than ids we have to ask for them
	push @select, (map { "f.$_ "} COLS),
		      'i.id',
		      (map { "i.$_ "} VERSION_COLS);
    }

    # the user__id field
    if (exists $param->{'user__id'}) {
	push @where, 'f.usr__id=?', 'i.checked_out=?';
	push @bind,  $param->{'user__id'}, 1;
    } else {
	push @where, 'i.checked_out=?';
	push @bind,  0;
    }

    unless ($param->{'return_versions'}) {
	push @where, 'f.current_version=i.version';
    }

    # Build the where clause for the trivial formatting table fields.
    foreach my $f (qw(id workflow__id output_channel__id element__id
                      category__id name file_name active)) {
	next unless exists $param->{$f};

	if (($f eq 'name') || ($f eq 'file_name')) {
	    push @where, "LOWER(f.$f) LIKE ?";
	    push @bind,  lc($param->{$f});
	} else { 
	    push @where, "f.$f=?";
	    push @bind,  $param->{$f};
	}
    }
    
    if ($param->{'simple'}) {
      push @where, ('(LOWER(f.name) LIKE ? OR LOWER(f.file_name) LIKE ?)');
      push @bind, (lc($param->{'simple'})) x 2;
    }


    # Handle searches on dates
    foreach my $type (qw(deploy_date expire_date)) {
	my ($start, $end) = ($param->{$type.'_start'},
			     $param->{$type.'_end'});

	# Handle date ranges.
	if ($start && $end) {
	    push @where, "f.$type BETWEEN ? AND ?";
	    push @bind, $start, $end;
	} else {
	    # Handle 'everying before' or 'everything after' $date searches.
	    if ($start) {
		push @where, "f.$type > ?";
		push @bind, $start;
	    } elsif ($end) {
		push @where, "f.$type < ?";
		push @bind, $end;
	    }
	}
    }

    # Determine how to order the results.
    if ( $param->{'return_versions'}) {
	$order = 'i.version';
    } else {
	$order = 'f.deploy_date';
    }

    $sql  = 'SELECT '  .join(',',     @select).' '.
            'FROM '    .join(',',     @from).' '.
            'WHERE '   .join(' AND ', @where).' '.
            'ORDER BY '.$order;

    $sth = prepare_ca($sql, undef, DEBUG);

    if ($ids) {
	my $return = col_aref($sth, @bind);

	return wantarray ? @$return : $return;

    } else {
	my (@d, @objs);

	my $count = (scalar FIELDS) + (scalar VERSION_FIELDS) + 1;
	execute($sth, @bind);
	bind_columns($sth, \@d[0 .. $count]);

	while (fetch($sth)) {
	    my $self = bless {}, $class;

	    $self->SUPER::new();

	    $self->_set( ['id', FIELDS, 'version_id', VERSION_FIELDS] , [@d]);
	    $self->_set__dirty(undef);

	    push @objs, $self;
	}
	return (wantarray ? @objs : \@objs) if @objs;
	return;
    }
}

################################################################################

#--------------------------------------#

=head2 Private Instance Methods

=cut

=item $oc_obj = $self->_get_output_channel_object()

Returns the output channel object associated with this formatting object

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _get_output_channel_object {
    my $self = shift;
    my $dirty = $self->_get__dirty;
    my ($oc_id, $oc_obj) = $self->_get('output_channel__id',
				       '_output_channel_obj');

    return unless $oc_id;

    unless ($oc_obj) {
	$oc_obj = Bric::Biz::OutputChannel->lookup({'id' => $oc_id});
	
	$self->_set(['_output_channel_obj'], [$oc_obj]);

	# Restore the original dirty value.
	$self->_set__dirty($dirty);
    }

    return $oc_obj;
}

################################################################################

=item $at_obj = $self->_get_element_object()

Returns the asset type object that was associated with this formatting asset.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _get_element_object {
    my $self = shift;
    my $dirty = $self->_get__dirty;
    my ($at_id, $at_obj) = $self->_get('element__id', '_element_obj');

    return unless $at_id;

    unless ($at_obj) {
	$at_obj = Bric::Biz::AssetType->lookup({'id' => $at_id});
	
	$self->_set(['_element_obj'], [$at_obj]);

	# Restore the original dirty value.
	$self->_set__dirty($dirty);
    }

    return $at_obj;
}

################################################################################

=item $cat_obj = $self->_get_category_object()

Returns the category object that this is associated with

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _get_category_object {
    my $self = shift;
    my $dirty = $self->_get__dirty;
    my ($cat_id, $cat_obj) = $self->_get('category_id', '_category_obj');

    return unless defined $cat_id;

    unless ($cat_obj) {
	$cat_obj = Bric::Biz::Category->lookup({id => $cat_id});
	$self->_set(['_category_obj'], [$cat_obj]);

	# Restore the original dirty value.
	$self->_set__dirty($dirty);
    }

    return $cat_obj;
}

################################################################################

=item $attr_obj = $self->_get_attribute_object()

Returns the attribute object that is associated with this formatting object

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _get_attribute_object {
    my ($self) = @_;
    my $dirty    = $self->_get__dirty;
    my $attr_obj = $self->_get('_attribute_object');

    unless (defined $attr_obj) {
	# Let's Create a new one if one does not exist
	$attr_obj = Bric::Util::Attribute::Formatting->new({id => $self->get_id});
	$self->_set(['_attribute_object'], [$attr_obj]);

	# Restore the original dirty value.
	$self->_set__dirty($dirty);
    }

    return $attr_obj;
}

################################################################################

=item 

=item $self = $self->_insert_formatting();

Inserts a row into the formatting table that represents a new 
formatting Asset

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _insert_formatting {
	my ($self) = @_;

	my $sql = 'INSERT INTO '. TABLE .' (id,'.join(',', COLS).') '.
		  "VALUES (${\next_key(TABLE)},".join(',', ('?') x COLS).')';

	my $sth = prepare_c($sql, undef, DEBUG);
	execute($sth, $self->_get(FIELDS));

	$self->_set(['id'], [last_key(TABLE)]);

	# And finally, register this person in the "All Templates" group.
	$self->register_instance(INSTANCE_GROUP_ID, GROUP_PACKAGE);

	return $self;
}

################################################################################

=item $self = $self->_insert_instance()

Inserts a row associated with an instance of a formatting asset

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
				' (id, '.join(', ', VERSION_COLS) .') '.
				"VALUES (${\next_key(VERSION_TABLE)}, " . 
					join(',',('?') x VERSION_COLS) . ')';

	my $sth = prepare_c($sql, undef, DEBUG);
	execute($sth, $self->_get(VERSION_FIELDS));

	$self->_set(['version_id'], [last_key(VERSION_TABLE)]);

	return $self;
}

################################################################################

=item $self = $self->_update_formatting()

Updates the formatting table

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _update_formatting {
	my ($self) = @_;

	my $sql = 'UPDATE ' . TABLE .
		  ' SET ' . join(', ', map {"$_=?" } COLS) .
		  ' WHERE id=? ';

	my $sth = prepare_c($sql, undef, DEBUG);

	execute($sth, $self->_get(FIELDS), $self->_get('id'));

	return $self;
}

################################################################################

=item $self = $self->_update_instance()

Updates the row related to the instance of the formatting asset

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

	execute($sth, $self->_get(VERSION_FIELDS), $self->get_version_id);

	return $self;
}

################################################################################

=item $self = $self->_delete_formatting()

Removes the row associated with this formatting asset from the database

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _delete_formatting {
	my ($self) = @_;

	my $sql = 'DELETE FROM ' . TABLE . ' WHERE id=?';

	my $sth = prepare_c($sql, undef, DEBUG);

	execute($sth, $self->get_id);

	return $self;
}

################################################################################

=item $self = $self->_delete_instance()

Removes the instance specific row from the database

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _delete_instance {
    my ($self) = @_;
    my $sql = 'DELETE FROM ' . VERSION_TABLE . ' WHERE id=? ';
    my $sth = prepare_c($sql, undef, DEBUG);
    execute($sth, $self->_get('version_id'));
    return $self;
}

################################################################################

#--------------------------------------#

=head2 Private Functions

=over 4

=item my $uri = &$build_file_name($fa, $cat, $oc);

Builds the file name for a template. If either or both $cat and $oc are not
passed, they'll be fetched from the $fa object.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

$build_file_name = sub {
    my ($self, $cat, $oc) = @_;

    # Get the category and Output Channel objects, if necessary.
    $oc ||= $self->_get_output_channel_object;
    $cat ||= $self->_get_category_object;

    # Get the pre and post values.
    my ($pre, $post) = ($oc->get_pre_path, $oc->get_post_path) if $oc;

    # Add the pre value.
    my @path = ('', defined $pre ? $pre : ());

    # Add on the Category URI.
    push @path, $cat->ancestry_path if $cat;

    # Add the post value.
    push @path, $post if $post;

    # Add the name.
    (my $file = $self->_get('name')) =~ s/\W+/_/g;
    $file .= '.mc' unless $file eq 'autohandler';

    # Return the filename.
    return Bric::Util::Trans::FS->cat_uri(@path, $file);
};

=back

=cut

1;
__END__

=back

=head1 NOTES

NONE

=head1 AUTHOR

michael soderstrom - miraso@pacbell.net

=head1 SEE ALSO

L<Bric>, L<Bric::Biz::Asset>

=cut
