package Bric::Biz::Workflow::Parts::Desk;
###############################################################################

=head1 NAME
 
 Bric::Biz::Workflow::Parts::Desk;

 Impliments a desk object as part of a workflow


=head1 VERSION

$Revision: 1.3 $

=cut

our $VERSION = substr(q$Revision: 1.3 $, 10, -1);


=head1 DATE

$Date: 2001-09-26 12:07:21 $


=head1 SYNOPSIS

 use Bric::Biz::Workflow::Parts::Desk;

 my $desk = new Bric::Biz::Workflow::Parts::Desk($init);

 my $desk = lookup Bric::Biz::Workflow::Parts::Desk($param);

 my @dsks = list Bric::Biz::Workflow::Parts::Desk($param);

 my $name = $desk->get_name;
 my $desk = $desk->set_name($name);

 my $dscr = $desk->get_description;
 my $desk = $desk->set_description($dscr);

 $desk    = $desk->link_desk($param)

 $desk    = $desk->unlink_desk({});

 $desk    = $desk->add_rule({'rule_pkg'  => $pkg,
                             'rule_name' => $name})

 $desk    = $desk->del_rule({'rule_pkg'  => $pkg, 'rule_name' => $name});

 # Return a list of assets on this desk.
 @assets  = $desk->assets();

 # Transfer a asset to a different desk.
 $ret     = $desk->transfer($asset_obj, $another_desk);

 # Accept a asset from another desk.
 $ret     = $desk->accept($asset_obj);

 $desk    = $desk->save;

=head1 DESCRIPTION

A desk is something that defines the steps in a workflow.  Assets arrive at a
desk and remain there until they are approved and moved to the next desk in the
workflow.

A desk may have any number of assets associated with it at any time.  Users may
checkout copies of these assets from the desk, make changes to them and check
them back into the desk.  Users may also get read only copies.

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

use Bric::Util::Grp::Asset;

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

use constant TABLE  => 'desk';
use constant COLS   => qw(name description pre_chk_rules 
			  post_chk_rules asset_grp publish active);
use constant FIELDS => qw(name description pre_chk_rules 
			  post_chk_rules asset_grp _publish _active);

use constant ASSET_GRP_PKG => 'Bric::Util::Grp::Asset';
use constant ORD => qw(name description publish active);

#==============================================================================#
# Fields                               #
#======================================#

#--------------------------------------#
# Public Class Fields                   

our $METH;

#--------------------------------------#
# Private Class Fields                  



#--------------------------------------#
# Instance Fields                       

# This method of Bricolage will call 'use fields' for you and set some permissions.
BEGIN {
    Bric::register_fields({
			 # Public Fields
			 'id'             => Bric::FIELD_READ,
			 'name'           => Bric::FIELD_RDWR,
			 'description'    => Bric::FIELD_RDWR,
			 'pre_chk_rules'  => Bric::FIELD_READ,
			 'post_chk_rules' => Bric::FIELD_READ,
			 'asset_grp'      => Bric::FIELD_READ,

			 # Private Fields
			 '_publish'       => Bric::FIELD_NONE,
			 '_asset_grp_obj' => Bric::FIELD_NONE,
			 '_remove'        => Bric::FIELD_NONE,
			 '_active'        => Bric::FIELD_NONE,
			 '_checkin'       => Bric::FIELD_NONE,
			 '_checkout'      => Bric::FIELD_NONE,
			 '_transfer'      => Bric::FIELD_NONE,
			});
}

#==============================================================================#

=head1 INTERFACE

=head2 Constructors

=over 4

=cut

#------------------------------------------------------------------------------#

=item $success = $obj = new Bric::Biz::Workflow::Parts::Desk($init);

The following is a list of parameter keys and their assiociated values.

Keys for $init are: 

=over 4

=item *

name

The name of this desk

=item *

description

A description of this desk

=back

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub new {
    my $self = shift;
    my ($init) = @_;

    # Create the object via fields which returns a blessed object.
    $self = bless {}, $self unless ref $self;

    $init->{_active} = !defined $init->{active} ? 1 : $init->{active} ? 1 : 0;
    $init->{_publish} = $init->{publish} ? 1 : 0;

    # Call the parent's constructor.
    $self->SUPER::new($init);

    $self->activate;

    # Make sure these are initialized as array refs.
    $self->_set(['_checkin', '_checkout', '_transfer'], [[],[],[]]);

    $self->_set__dirty(1);

    # Return the object.
    return $self;
}

#------------------------------------------------------------------------------#

=item $success = $obj = lookup Bric::Biz::Workflow::Parts::Desk($param);

Look up a desk object by ID.  Keys for param are:

=over 4

=item *

id

A desk ID

=back

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub lookup {
    my $class = shift;
    my ($param) = @_;
    my $id = $param->{'id'};

    # Create the object via fields which returns a blessed object.
    my $self = bless {}, ref $class || $class;

    # Call the parent's constructor.
    $self->SUPER::new();

    my $ret = _select_desk('id=?', [$id]);

    # Set the columns selected as well as the passed ID.
    $self->_set(['id', FIELDS], $ret->[0]);

    # Do not return anything if the lookup failed.
    return unless $self->get_id;

    # Make sure these are initialized as array refs.
    $self->_set(['_checkin', '_checkout', '_transfer'], [[],[],[]]);

    $self->_set__dirty(0);

    # Return the object.
    return $self;
}

#------------------------------------------------------------------------------#

=item @objs = Bric::Biz::Workflow::Parts::Desk->list($param);

Returns a list of desk objects based on $param.  Keys of $param are:

=over 4

=init *

name

Return all desks matching a certain name

=init *

description

Return all desks with a matching description.

=init *

active

Boolean; Return all in/active workflows

=back

All searches except 'active' are done using the LIKE operator, so '%' can be 
used for substring searching.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub list {
    my $class = shift;
    my ($param, $id_only) = @_;

    my (@num, @txt);

    # Make sure to set active explictly if its not passed.
    $param->{'active'} = exists $param->{'active'} ? $param->{'active'} : 1;

    foreach (keys %$param) {
	if (/^name$/ or /^description$/) {
	    push @txt, $_;
	    $param->{$_} = lc $param->{$_};
	} else {
	    push @num, $_;
	}
    }

    my $where = join(' AND ', (map { "$_=?" }             @num),
			      (map { "LOWER($_) LIKE ?" } @txt));
	
    my $ret = _select_desk($where, [@$param{@num,@txt}], $id_only);

    # $ret is just a bunch of IDs if the $id_only flag is set.  Return them.
    return wantarray ? @$ret : $ret if $id_only;

    my @all;
	
    foreach my $d (@$ret) {
	# Create the object via fields which returns a blessed object.
	my $self = bless {}, $class;

	# Call the parent's constructor.
	$self->SUPER::new();

	# Set the columns selected as well as the passed ID.
	$self->_set(['id', FIELDS], $d);

	# Make sure these are initialized as array refs.
	$self->_set(['_checkin', '_checkout', '_transfer'], [[],[],[]]);

	# Clear the dirty flag from the previous '_set'
	$self->_set__dirty(0);

	push @all, $self;
    }

    return wantarray ? @all : \@all;
}

#------------------------------------------------------------------------------#

=item @objs = Bric::Biz::Workflow::Parts::Desk->list($param);

Returns a list of IDs for all desk objects.  See 'list' for legal parameters.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub list_ids {
    my $self = shift;
    my ($param) = @_;

    return $self->list($param, 1);
}

#--------------------------------------#

=head2 Destructors

=item $self->DESTROY

Dummy method to prevent wasting time trying to AUTOLOAD DESTROY.

=cut

sub DESTROY {
    # This method should be here even if its empty so that we don't waste time
    # making Bricolage's autoload method try to find it.
}

#--------------------------------------#

=head2 Public Class Methods

NONE

=cut

#------------------------------------------------------------------------------#

=item my $meths = Bric::Biz::Workflow::Parts::Desk->my_meths

=item my (@meths || $meths_aref) = Bric::Biz::Workflow::Parts::Desk->my_meths(TRUE)

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
    return !$ord ? $METH : wantarray ? @{$METH}{&ORD} : [@{$METH}{&ORD}]
      if $METH;

    # We don't got 'em. So get 'em!
    $METH = {
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
	     publish      => {
			      name     => 'publish',
			      get_meth => sub { shift->can_publish(@_) ? 1 : 0 },
			      get_args => [],
			      set_meth => sub { $_[1] ? shift->make_publish_desk(@_)
						  : shift->make_regular_desk(@_) },
			      set_args => [],
			      disp     => 'Publish Desk',
			      search   => 0,
			      len      => 1,
			      req      => 1,
			      type     => 'short',
			      props    => { type => 'checkbox' }
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
    return !$ord ? $METH : wantarray ? @{$METH}{&ORD} : [@{$METH}{&ORD}];
}

#--------------------------------------#

=head2 Public Instance Methods

=cut

#------------------------------------------------------------------------------#

=item @assets = $desk->assets();

Return a list of assets on this desk.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub assets {
    my $self = shift;
    my $asset_grp = $self->_get_grp_obj(ASSET_GRP_PKG, 'asset_grp', 
					'_asset_grp_obj');

    my @a = map {$_->get_object} $asset_grp->get_members;

    return wantarray ? @a : \@a;
}

#------------------------------------------------------------------------------#

=item $ret = $desk->checkin($asset_obj);

=item $ret = $desk->checkout($asset_obj, $user_id);

Checkin/checkout an asset from this desk.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub checkin {
    my $self = shift;
    my ($a_obj) = @_;
    my $asset_grp = $self->_get_grp_obj(ASSET_GRP_PKG, 'asset_grp',
					'_asset_grp_obj');
    my $chkin = $self->_get('_checkin');
#    my $vers_grp_id = $a_obj->get_version_grp__id;

    # Find the asset in this desk that has the same version group ID as the
    # asset we are checking in and delete it from the group; this is the old
    # version of the asset.
#    my $found = 0;
#    foreach my $a ($self->assets) {
#	if ($a->get_version_grp__id == $vers_grp_id) {
#	    $asset_grp->delete_members([{'package' => ref($a), 'id' => $a->get_id}]);
#	    $found = 1;
 #           last;
#	}
#    }

    # Don't do anything else if this asset wasn't found on this desk.
#    return unless $found;

    $a_obj->checkin;
    push @$chkin, $a_obj;

    return $a_obj;
}

sub checkout {
    my $self = shift;
    my ($a_obj, $user_id) = @_;
    my $asset_grp = $self->_get_grp_obj(ASSET_GRP_PKG, 'asset_grp', 
					'_asset_grp_obj');

    # Don't do anything unless this asset is already on this desk.
    return unless $asset_grp->has_member($a_obj);

    my $chkout = $self->_get('_checkout');

    $a_obj->checkout({'user__id' => $user_id});
    push @$chkout, $a_obj;

    return $a_obj;
}

#------------------------------------------------------------------------------#

=item $ret = $desk->transfer($param);

Transfer a asset to a different desk.  Keys for $param are:

=over 4

=item *

asset

An asset object.

=item *

to

The desk to which this asset should be transfered.

=back

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub transfer {
    my $self = shift;
    my ($param) = @_;
    my $desk          = $param->{'to'};
    my $asset         = $param->{'asset'};
    my $asset_grp_obj = $self->_get_grp_obj(ASSET_GRP_PKG, 'asset_grp',
					    '_asset_grp_obj');

    # If we don't have an asset_grp_obj there shouldn't be anything to transfer!
    return unless $asset_grp_obj;

    # Do the pre-desk rule checks
    return unless $desk->accept({'asset' => $asset,
				 'from'  => $self});

    # If the asset was accepted and we get here, remove this asset from the desk
    $asset_grp_obj->delete_members([{'package' => ref $asset, 'id' => $asset->get_id}]);

    return $self
}

#------------------------------------------------------------------------------#

=item $ret = $desk->accept($param);

Accept a asset from another desk.  Keys for $param are:

=over 4

=item *

from

The desk from which this asset is comming.  Can be omitted if this is the first
desk in the workflow.

=item *

asset

The asset to accept.

=back

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub accept {
    my $self = shift;
    my ($param) = @_;
    my $dirty = $self->_get__dirty;
    my $desk          = $param->{'from'};
    my $asset         = $param->{'asset'};
    my $asset_grp_obj = $self->_get_grp_obj(ASSET_GRP_PKG,
					    'asset_grp', '_asset_grp_obj');
    my $xfer = $self->_get('_transfer');

    # Create the asset group for this desk if one doesn't exist.
    unless ($asset_grp_obj) {
	my $desc = 'A group for holding assets for Desk objects';
	$asset_grp_obj = Bric::Util::Grp::Asset->new(
					     {'name'        => 'Desk Assets',
					      'description' => $desc});

	# Throw an error if we could not create the group.
	my $err_msg = 'Could not create a new Grp object';
	die Bric::Util::Fault::Exception::DP->new({'msg' => $err_msg})
	  unless $asset_grp_obj;

	$self->_set(['_asset_grp_obj'], [$asset_grp_obj]);

	$self->_set__dirty($dirty);
    }

    # Add this asset.
    $asset_grp_obj->add_asset([$asset]);

    # Update the asset with its new desk.
    $asset->set_current_desk($self);
    push @$xfer, $asset;

    return $self;
}
#------------------------------------------------------------------------------#

=item $ret = $desk->remove_asset();

Remove an asset from this desk.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub remove_asset {
    my $self = shift;
    my ($asset) = @_;
    my $asset_grp_obj= $self->_get_grp_obj(ASSET_GRP_PKG,
					   'asset_grp',
					   '_asset_grp_obj');

    # If the asset was accepted and we get here, remove this asset from the desk
    $asset_grp_obj->delete_members([{'package' => ref $asset,
				     'id'      => $asset->get_id}]);

    return $self;
}

#------------------------------------------------------------------------------#

=item $assets = $desk->get_assets;

Return a list of assets on this desk.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_assets {
    my $self = shift;
    my $asset_grp_obj = $self->_get_grp_obj(ASSET_GRP_PKG, 
					    'asset_grp', '_asset_grp_obj');

    return unless $asset_grp_obj;

    # Return all the assets on this desk.
    return map { $_->get_object } $asset_grp_obj->get_members;
}

#------------------------------------------------------------------------------#

=item $assets_href = $desk->get_assets_href;

Return an anonymous hash of assets on this desk. The keys are the key names
of the class of each asset, and the values are anonymous arrays of the assets
of that type.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_assets_href {
    my $self = shift;
    my $ass;
    foreach ($self->get_assets) { push @{ $ass->{$_->key_name} }, $_ }
    return $ass;
}

#------------------------------------------------------------------------------#

=item $att || undef = $desk->can_publish

=item $att = $desk->make_publish_desk;

=item $att = $desk->make_regular_desk;

Get/Set is-publish-desk flag.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub can_publish {
    my $self = shift;

    return $self->_get('_publish') ? $self : undef;
}

sub make_publish_desk {
    my $self = shift;

    $self->_set__dirty(1);

    $self->_set(['_publish'], [1]) and return $self;
}

sub make_regular_desk {
    my $self = shift;

    $self->_set__dirty(1);

    $self->_set(['_publish'], [0]) and return $self;
}


#------------------------------------------------------------------------------#

=item $att || undef = $desk->is_active;

=item $att = $desk->activate;

=item $att = $desk->deactivate;

Get/Set the active flag.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub is_active {
    my $self = shift;

    return $self->_get('_active') ? $self : undef;
}

sub activate {
    my $self = shift;

    $self->_set__dirty(1);

    $self->_set(['_active'], [1]) and return $self;
}

sub deactivate {
    my $self = shift;

    $self->_set__dirty(1);

    $self->_set(['_active'], [0]) and return $self;
}


#------------------------------------------------------------------------------#

=item $desk->remove;

Get/Set the active flag.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub remove {
    my $self = shift;

    $self->_set__dirty(1);

    $self->_set(['_remove'], [1]);
}

#------------------------------------------------------------------------------#

=item $desk = $desk->save;

Checks the user to see if s/he has the right priviledges to checkout stories.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub save {
    my $self = shift;
    my $id    = $self->get_id;
    my $asset_grp_obj = $self->_get_grp_obj(ASSET_GRP_PKG,
					    'asset_grp', '_asset_grp_obj');

    unless ($self->_get('_remove')) {
	# Create the asset group for this desk if one doesn't exist.
	unless ($asset_grp_obj) {
	    my $dirty = $self->_get__dirty;
	    my $desc = 'A group for holding assets for Desk objects';
	    $asset_grp_obj = Bric::Util::Grp::Asset->new(
							 {'name' => 'Desk Assets',
							  'description' => $desc});

	    # Throw an error if we could not create the group.
	    my $err_msg = 'Could not create a new Grp object';
	    die Bric::Util::Fault::Exception::DP->new({'msg' => $err_msg})
	      unless $asset_grp_obj;

	    $self->_set(['_asset_grp_obj'], [$asset_grp_obj]);
	    $self->_set__dirty($dirty);
	}

	$self->_sync_checkin;
	$self->_sync_checkout;
	$self->_sync_transfer;

	# Save all the grouped objects.
	$asset_grp_obj->save;
	
	# Save the IDs if we have them.
	if ($self->get_asset_grp != $asset_grp_obj->get_id) {
	    $self->_set(['asset_grp'], [$asset_grp_obj->get_id]);
	}

	if ($self->_get__dirty) {
	    if ($id) {
		$self->_update_desk;
	    } else {
		$self->_insert_desk;
	    }
	}
    } else {
	$asset_grp_obj->deactivate and $asset_grp_obj->save if $asset_grp_obj;
	$self->_remove_desk;
    }
}

#==============================================================================#

=head1 PRIVATE

=cut

#--------------------------------------#

=head2 Private Class Methods

NONE

=cut

#--------------------------------------#

=head2 Private Instance Methods

=cut

sub _sync_checkin {
    my $self = shift;
    my $chkin = $self->_get('_checkin');

    while (my $a = shift @$chkin) {
	$a->save;
    }
}

sub _sync_checkout {
    my $self = shift;
    my $chkout = $self->_get('_checkout');

    while (my $a = shift @$chkout) {
	$a->save;
    }
}

sub _sync_transfer {
    my $self = shift;
    my $xfer = $self->_get('_transfer');

    while (my $a = shift @$xfer) {
	$a->save;
    }
}

#------------------------------------------------------------------------------#

=item $obj = $desk->_get_grp_obj($id_field, $obj_field)

Retrieve the group object if its set in this object.  Otherwise, try to look it
up via the ID field passed.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _get_grp_obj {
    my $self = shift;
    my ($pkg, $id_field, $obj_field) = @_;
    my $dirty      = $self->_get__dirty;
    my ($id, $obj) = $self->_get($id_field, $obj_field);

    return unless $id;

    unless ($obj) {
	$obj = $pkg->lookup({'id' => $id});
	
	$self->_set([$obj_field], [$obj]);
	
	$self->_set__dirty($dirty);
    }

    return $obj;
}

#------------------------------------------------------------------------------#

=item $desk = $desk->_select_desk

Select values from the desk table.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _select_desk {
    my ($where, $bind, $id_only) = @_;
    my (@d, @ret);
    my @cols = 'id';

    # Don't bother selecting the other columns if they just want the IDs.
    push @cols, COLS unless $id_only;

    my $sql = 'SELECT '.join(',',@cols).' FROM '.TABLE.
              ' WHERE '.$where if $where;

    my $sth = prepare_c($sql);

    if ($id_only) {
	my $ids = col_aref($sth,@$bind);
	
	return wantarray ? @$ids : $ids;
    } else {
	execute($sth, @$bind);
	bind_columns($sth, \@d[0..(scalar COLS)]);
	
	while (fetch($sth)) {
	    push @ret, [@d];
	}
	
	finish($sth);
	
	return \@ret;
    }
}

#------------------------------------------------------------------------------#

=item $desk = $desk->_insert_desk

Insert values into the Desk table from the desk structure.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _insert_desk {
    my $self = shift;
    my $nextval = next_key(TABLE);

    # Create the insert statement.
    my $sql = 'INSERT INTO '.TABLE.' (id,'.join(',',COLS).") ".
              "VALUES ($nextval,".join(',', ('?') x COLS).')';

    my $sth = prepare_c($sql);
    execute($sth, $self->_get(FIELDS));

    # Set the ID of this object.
    $self->_set(['id'],[last_key(TABLE)]);

    return $self;
}

#------------------------------------------------------------------------------#

=item $desk = $desk->_update_desk

Update values from the desk structure.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _update_desk {
    my $self = shift;

    my $sql = 'UPDATE '.TABLE.
              ' SET '.join(',', map {"$_=?"} COLS).' WHERE id=?';

    my $sth = prepare_c($sql);
    execute($sth, $self->_get(FIELDS), $self->get_id);

    return $self;
}

#------------------------------------------------------------------------------#

=item $desk = $desk->_remove_desk

Remove this desk.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _remove_desk {
    my $self = shift;

    my $sth = prepare_c('DELETE FROM '.TABLE.' WHERE id=?');
    execute($sth, $self->get_id);

    return $self;
}


#--------------------------------------#

=head2 Private Functions

NONE

=cut

# Add functions here that can be used only internally to the class. They should
# not be publicly available (hence the prefernce for closures). Use the same POD
# comment style as above for 'new'.

1;
__END__

=back

=head1 NOTES

NONE

=head1 AUTHOR

 "Garth Webb" <garth@perijove.com>
 Creative Engines Engineering

=head1 SEE ALSO

L<Bric>, L<Bric::Biz::Workflow>, L<perl>

=head1 REVISION HISTORY

$Log: Desk.pm,v $
Revision 1.3  2001-09-26 12:07:21  wheeler
An asset group is now created for a desk if one doesn't currently exist.
Necessary for creating new desks and allowing them to show up in the Permissions
UI without breaking it. It's possible that this should be done differently --
Garth, I welcome your feedback.

Revision 1.2  2001/09/06 22:30:06  samtregar
Fixed remaining BL->App, BC->Biz conversions

Revision 1.1.1.1  2001/09/06 21:54:17  wheeler
Upload to SourceForge.

=cut
