package Bric::Biz::OutputChannel;
###############################################################################

=head1 NAME

Bric::Biz::OutputChannel - The manner of keeping track of output channels 

=head1 VERSION

$Revision: 1.11 $

=cut

our $VERSION = (qw$Revision: 1.11 $ )[-1];

=head1 DATE

$Date: 2001-11-20 00:02:44 $

=head1 SYNOPSIS

 $oc = Bric::Biz::OutputChannel->new( $initial_state )

 $oc = Bric::Biz::OutputChannel->lookup( { id => $id} )

 ($ocs_aref || @ocs) = Bric::Biz::OutputChannel->list( $criteria )

 ($id_aref || @ids) = Bric::Biz::OutputChannel->list_ids( $criteria )

 $oc = $oc->set_name( $name )

 $name = $oc->get_name()

 $oc = $oc->set_description( $description )

 $description = $oc->get_description()

 $oc = $oc->set_tile_aware( undef || 1)

 (undef || 1 ) = $oc->get_tile_aware()

 $oc = $oc->set_primary( undef || 1)

 (undef || 1 ) = $oc->get_primary()

 $oc = $oc->activate()

 $oc = $oc->deactivate()

 $oc = $oc->is_active()

 $id = $oc->get_id()

 $oc = $oc->save()

=head1 DESCRIPTION


Holds information about the output channels that will be associated with 
templates and elements

=cut

#==============================================================================## Dependencies                         #
#======================================#

#--------------------------------------#
# Standard Dependencies                 

use strict;

#--------------------------------------#
# Programatic Dependencies              

use Bric::Config qw(:oc);
use Bric::Util::DBI qw(:all);
use Bric::Util::Grp::OutputChannel;

#==============================================================================
## Inheritance                         #
#======================================#

# The parent module should have a 'use' line if you need to import from it.
# use Bric;
use base qw(Bric);

#=============================================================================
## Function Prototypes                 #
#======================================#

# None

#==============================================================================
## Constants                           #
#======================================#

use constant DEBUG => 0;

use constant TABLE => 'output_channel';
use constant FIELDS => qw(name description pre_path post_path primary filename
                          file_ext _active);
use constant COLS => qw(name description pre_path post_path primary_ce filename
                        file_ext active);
use constant ORD => qw(name description pre_path post_path filename file_ext
                       active);

use constant INSTANCE_GROUP_ID => 23;
use constant GROUP_PACKAGE => 'Bric::Util::Grp::OutputChannel';

#==============================================================================
## Fields                              #
#======================================#

#--------------------------------------#
# Public Class Fields
# Public fields should use 'vars'
#use vars qw();

#--------------------------------------#
# Private Class Fields

# Private fields use 'my'
my $meths;

#--------------------------------------#
# Instance Fields

# None

# This method of Bricolage will call 'use fields' for you and set some permissions.
BEGIN {
    Bric::register_fields({
            # Public Fields
			# The human readable name field
			'name'		=> Bric::FIELD_RDWR,

			# The human readable description field
			'description'	=> Bric::FIELD_RDWR,

			# might want to be write since if it changes
			# it will fuck alot up
			'pre_path'		=> Bric::FIELD_RDWR,

			# same as prepath
			'post_path'		=> Bric::FIELD_RDWR,

                        # These will be used to construct file names
                        # for content files burned to the Output Channel.
                        'filename'              => Bric::FIELD_RDWR,
                        'file_ext'              => Bric::FIELD_RDWR,

			# the flag as to wheather this is a primary
			# output channel
			'primary'		=> Bric::FIELD_RDWR,

			# The data base id
			'id'           => Bric::FIELD_READ,

			# Private Fileds

			# The active flag
			'_active'		=> Bric::FIELD_NONE
	});
}

#==============================================================================## Interface Methods                    #
#======================================#

=head1 INTERFACE

=head2 Public Methods

=over 4

=cut

#--------------------------------------#
# Constructors  

#------------------------------------------------------------------------------#

=item $oc = Bric::Biz::Output_channel->new( $initial_state )

This will create a new Output channel object with the optional 
defined state

suported keys:

=over 4

=item *

name

=item *

description

=item *

tile_aware

=item *

primary

=item *

active (default is active, pass undef to make a new inactive Output Channe;

=back

B<Throws:>
NONE

B<Side Effects:>
NONE

B<Notes:>
NONE 

=cut

sub new {
	my ($class, $init) = @_;
	$init->{_active} = exists $init->{active}
	  ? delete $init->{active} : 1;
	$init->{filename} ||= DEFAULT_FILENAME;
	$init->{file_ext} ||= DEFAULT_FILE_EXT;
	my $self = bless {}, $class;
	$self->SUPER::new($init);
	return $self;
}

=item $oc = Bric::Biz::Output_channel->lookup( { id => $id} )

Will look up an output channel object for a given id

B<Throws:>
NONE

B<Side Effects:>
NONE

B<Notes:>
NONE 

=cut

sub lookup {
	my ($class, $params) = @_;

	die Bric::Util::Fault::Exception::GEN->new( {
		'msg' => 'missing required param id'} )
			unless $params->{'id'};

	my $self = bless {}, $class;

	$self->SUPER::new();

	my $sql = 'SELECT id,'. join(',',COLS) . " FROM ". TABLE . 
				' WHERE id=? ';

	my @d;
	my $sth = prepare_ca($sql, undef, DEBUG);
	execute($sth, $params->{'id'} );
	bind_columns($sth, \@d[0 .. (scalar COLS)]);
	fetch($sth);

	$self->_set( [ 'id', FIELDS], [@d]);


	return $self;
}

=item ($ocs_aref || @ocs) = Bric::Biz::Output_channel->list( $criteria )

Will return a list of objects that match a given criteria

supported keys:

=over 4

=item *

name

=item *

primary

=item *

tile_aware

=item *

server_type_id

=item *

active

=back

B<Throws:>
NONE

B<Side Effects:>
NONE

B<Notes:>
NONE 

=cut

sub list {
	my ($class, $params) = @_;

	_do_list($class, $params, undef);
}

=item $ocs_href = Bric::Biz::OutputChannel->href( $criteria )

Returns an anonymous hash of Output Channel objects, where each hash key is an
Output Channel ID, and each value is Output Channel object that corresponds to
that ID. Takes the same arguments as list().

B<Throws:>
NONE

B<Side Effects:>
NONE

B<Notes:>
NONE 

=cut

sub href {
	my ($class, $params) = @_;

	_do_list($class, $params, undef, 1);
}

#--------------------------------------#

=head2 Destructors

=item $self->DESTROY

Dummy method to prevent wasting time trying to AUTOLOAD DESTROY.

=cut

sub DESTROY {
    # empty for now

}

#--------------------------------------#

=head2 Public Class Methods

=cut


=item ($id_aref || @ids) = Bric::Biz::Output_channel->list_ids( $criteria )

Will return a list of ids that match the given criteria

Supported Keys:

=over 4

=item name

=item primary

=item tile_aware

=back

B<Throws:>
NONE

B<Side Effects:>
NONE

B<Notes:>
NONE 

=cut

sub list_ids {
	my $class = shift;
	my ($params) = @_;

	_do_list($class, $params, 1);
}

=item $meths = Bric::Biz::AssetType->my_meths

=item (@meths || $meths_aref) = Bric::Biz::AssetType->my_meths(TRUE)

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
    return !$ord ? $meths : wantarray ? @{$meths}{&ORD} : [@{$meths}{&ORD}]
      if $meths;

    # We don't got 'em. So get 'em!
    $meths = {
	      name        => {
			       name     => 'name',
			      get_meth => sub { shift->get_name(@_) },
			      get_args => [],
			      set_meth => sub { shift->set_name(@_) },
			      set_args => [],
			      disp     => 'Name',
			      search   => 1,
			      len      => 64,
			      req      => 1,
			      type     => 'short',
			      props    => {   type       => 'text',
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
	      pre_path      => {
			     name     => 'pre_path',
			     get_meth => sub { shift->get_pre_path(@_) },
			     get_args => [],
			     set_meth => sub { shift->set_pre_path(@_) },
			     set_args => [],
			     disp     => 'Pre',
			     len      => 64,
			     req      => 0,
			     type     => 'short',
			     props    => {   type       => 'text',
					     length     => 32,
					     maxlength => 64
					 }
			    },
	      post_path      => {
			     name     => 'post_path',
			     get_meth => sub { shift->get_post_path(@_) },
			     get_args => [],
			     set_meth => sub { shift->set_post_path(@_) },
			     set_args => [],
			     disp     => 'Post',
			     len      => 64,
			     req      => 0,
			     type     => 'short',
			     props    => {   type       => 'text',
					     length     => 32,
					     maxlength => 64
					 }
			    },
	      filename      => {
			     name     => 'filename',
			     get_meth => sub { shift->get_filename(@_) },
			     get_args => [],
			     set_meth => sub { shift->set_filename(@_) },
			     set_args => [],
			     disp     => 'File Name',
			     len      => 32,
			     req      => 0,
			     type     => 'short',
			     props    => { type      => 'text',
					   length    => 32,
				           maxlength => 32
					 }
			    },
	      file_ext      => {
			     name     => 'file_ext',
			     get_meth => sub { shift->get_file_ext(@_) },
			     get_args => [],
			     set_meth => sub { shift->set_file_ext(@_) },
			     set_args => [],
			     disp     => 'File Extension',
			     len      => 32,
			     req      => 0,
			     type     => 'short',
			     props    => { type      => 'text',
					   length    => 32,
				           maxlength => 32
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
			     len      => 1,
			     req      => 1,
			     type     => 'short',
			     props    => { type => 'checkbox' }
			    },
	     };
    return !$ord ? $meths : wantarray ? @{$meths}{&ORD} : [@{$meths}{&ORD}];
}

#--------------------------------------#

=head2 Public Instance Methods

=cut


=item $oc = $oc->set_name( $name )

Sets the name field

B<Throws:>
NONE

B<Side Effects:>
NONE

B<Notes:>
NONE

=cut


=item $name = $oc->get_name()

Returns the name field

B<Throws:>
NONE

B<Side Effects:>
NONE

B<Notes:>
NONE

=cut


=item $oc = $oc->set_description( $description )

Sets the description Field

B<Throws:>
NONE

B<Side Effects:>
NONE

B<Notes:>
NONE

=item $description = $oc->get_description()

Returns the description field

B<Throws:>
NONE

B<Side Effects:>
NONE

B<Notes:>
NONE

=item $oc = $oc->set_pre_path($pre_path)

Sets the string that will be used at the beginning of the URIs for assets in
this Output Channel.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $pre_path = $oc->get_pre_path

Gets the string that will be used at the beginning of the URIs for assets in
this Output Channel.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $oc = $oc->set_post_path($post_path)

Sets the string that will be used at the end of the URIs for assets in this
Output Channel.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $post_path = $oc->get_post_path

Gets the string that will be used at the end of the URIs for assets in
this Output Channel.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $oc = $oc->set_filename($filename)

Sets the filename that will be used in the names of files burned into this
Output Channel.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $filename = $oc->get_filename

Gets the filename that will be used in the names of files burned into this
Output Channel. Defaults to the value of the DEFAULT_FILENAME configuration
directive if unset.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $oc = $oc->set_file_ext($file_ext)

Sets the filename extension that will be used in the names of files burned into
this Output Channel.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $file_ext = $oc->get_file_ext

Gets the filename extension that will be used in the names of files burned into
this Output Channel. Defaults to the value of the DEFAULT_FILE_EXT configuration
directive if unset.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $oc = $oc->set_tile_aware( undef || 1)

Set the flag for wheather this output channel is tile aware

B<Throws:> NONE

B<Side Effects:> NONE

B<Notes:> NONE

=item (undef || 1 ) = $oc->get_tile_aware()

Return if this channel is tile aware or not

B<Throws:>
NONE

B<Side Effects:>
NONE

B<Notes:>
NONE

=cut


=item $oc = $oc->set_primary( undef || 1)

Set the flag that this is the primary out put channel or not

B<Throws:>
NONE

B<Side Effects:>
NONE

B<Notes:>
NONE

=cut


=item (undef || 1 ) = $oc->get_primary()

Returns 1 if this is the primary output channel undef otherwise

B<Throws:>
NONE

B<Side Effects:>
NONE

B<Notes:>
Only one Output channel can be the primary output channel

=cut


=item $oc = $oc->activate()

MAkes the item active 

B<Throws:>
NONE

B<Side Effects:>
NONE

B<Notes:>
NONE

=cut

sub activate {
	my ($self) = @_;

	$self->_set( { '_active' => 1 } );

	return $self;
}

=item $oc = $oc->deactivate()

Makes the item inactive

B<Throws:>
NONE

B<Side Effects:>
NONE

B<Notes:>
NONE

=cut


sub deactivate {
	my ($self) = @_;

	$self->_set( { '_active' => 0 } );

	return $self;
}

=item (undef || 1) = $oc->is_active()

Returns if the Output channel is active or not

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

=item $id = $oc->get_id()

Returns the data base id of the object

B<Throws:>
NONE

B<Side Effects:>
NONE

B<Notes:>
NONE

=cut


=item $oc = $oc->save()

Saves the info to the database

B<Throws:>
NONE

B<Side Effects:>
NONE

B<Notes:>
NONE

=cut

sub save {
	my ($self) = @_;
	return $self unless $self->_get__dirty();
	defined $self->_get('id') ? $self->_do_update : $self->_do_insert;
}


#==============================================================================## Private Methods                      #
#======================================#

=head1 PRIVATE

=cut

#--------------------------------------#

=head2 Private Class Methods                 

=item _do_list

called by list and list ids this does the brunt of their work

B<Throws:>
NONE

B<Side Effects:>
NONE

B<Notes:>
NONE

=cut

sub _do_list {
    my ($class, $params, $ids, $href) = @_;

	my $sql = 'SELECT id';

	unless ($ids) {
		$sql .= ', ' . join(', ', COLS);
	}

	$sql .= ' FROM ' . TABLE . ' ';


	# construct where clause
	my @where;
	my @where_params;

	if ( $params->{'name'} ) {
		push @where, 'LOWER(name) LIKE ?';
		push @where_params, lc($params->{'name'});
	}

    	if ( $params->{'pre_path'} ) {
		push @where, 'LOWER(pre_path) LIKE ?';
		push @where_params, lc($params->{'pre_path'});
	}

       	if ( $params->{'post_path'} ) {
		push @where, 'LOWER(post_path) LIKE ?';
		push @where_params, lc($params->{'post_path'});
	}

	if ( $params->{'primary'} ) {
		push @where, 'primary=?';
		push @where_params, $params->{'primary'};
	}

	if ( $params->{'active'} ) {
		push @where, 'active=?';
		push @where_params, $params->{'active'};
	}

	if ( exists $params->{server_type_id} ) {
		push @where, 'id in (select output_channel__id from server_type__output_channel where server_type__id = ?)';
		push @where_params, $params->{server_type_id};
	}

	unless ( $params->{'all'} ) {
		push @where, 'active=?';
		push @where_params, 1;
	}

	if (@where) {
		$sql .= 'WHERE ';
		$sql .= join ' AND ', @where;
	}
        $sql .= ' ORDER BY name';

	my $select = prepare_ca( $sql, undef, DEBUG);


	if ( $ids ) {
		# called from list_ids give em what they want
		my $return = col_aref($select,@where_params);

		return wantarray ? @{ $return } : $return;

	} else { # end if ids 
		# this must have been called from list so give objects
		my (@d, @objs, %objs);

		execute($select, @where_params);
		bind_columns($select, \@d[0 .. (scalar COLS)]);

		while (my $row = fetch($select) ) {

			my $self = bless {}, $class;
			$self->SUPER::new();
			$self->_set( ['id', FIELDS], \@d);

			$href ? $objs{$d[0]} = $self : push @objs, $self;
		}
		return \%objs if $href;
		return wantarray ? @objs : \@objs;
	}
 
}


#--------------------------------------#

=head2 Private Instance Methods              

=item _do_update()

will perform the update to the data base after being called 
from save

B<Throws:>
NONE

B<Side Effects:>
NONE

B<Notes:>
NONE

=cut

sub _do_update {
    my ($self) = @_;

	my $sql = "UPDATE " . TABLE . 
				" SET " . join(', ', map { "$_=?" } COLS) .
				" WHERE id=? ";

	my $sth = prepare_c($sql, undef, DEBUG);

	execute($sth, $self->_get( FIELDS ), $self->_get('id'));

	$self->_set__dirty(undef);

    return $self;
}

=item _do_insert

Will do the insert to the database after being called by save

B<Throws:>
NONE

B<Side Effects:>
NONE

B<Notes:>
NONE

=cut

sub _do_insert {
    my ($self) = @_;

    my $sql = 'INSERT INTO ' . TABLE . '(id, ' . join(', ', COLS) . ')' .
      'VALUES (' . ${\next_key(TABLE)} . ', '.
	join (',', ('?') x COLS) . ')';

    my $insert = prepare_c($sql, undef, DEBUG);
    execute($insert, $self->_get( FIELDS ) );
    $self->_set( { 'id' => last_key(TABLE) } );
    $self->_set__dirty(undef);
    $self->register_instance(INSTANCE_GROUP_ID, GROUP_PACKAGE);
    return $self;
}

1;
__END__

=head1 NOTES

NONE

=head1 AUTHOR

 michael soderstrom ( miraso@pacbell.net )

=head1 SEE ALSO

 L<perl>,L<Bric>,L<Bric::Biz::Asset::Business>,L<Bric::Biz::element>,
 L<Bric::Biz::Asset::Formatting> 

=cut


