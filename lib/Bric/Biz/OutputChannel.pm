package Bric::Biz::OutputChannel;
###############################################################################

=head1 NAME

Bric::Biz::OutputChannel - Bricolage Output Channels.

=head1 VERSION

$Revision: 1.13 $

=cut

our $VERSION = (qw$Revision: 1.13 $ )[-1];

=head1 DATE

$Date: 2001-12-18 03:20:03 $

=head1 SYNOPSIS

  use Bric::Biz::OutputChannel;

  # Constructors.
  $oc = Bric::Biz::OutputChannel->new( $initial_state );
  $oc = Bric::Biz::OutputChannel->lookup( { id => $id} );
  my $ocs_aref = Bric::Biz::OutputChannel->list( $criteria );
  my @ocs = Bric::Biz::OutputChannel->list( $criteria );

  # Class Methos.
  my $id_aref = Bric::Biz::OutputChannel->list_ids( $criteria );
  my @ids = Bric::Biz::OutputChannel->list_ids( $criteria );

  # Instance Methods.
  $id = $oc->get_id;

  my $name = $oc->get_name;
  $oc = $oc->set_name( $name );

  my $description = $oc->get_description;
  $oc = $oc->set_description( $description );

  if ($oc->get_primary) { # do stuff }
  $oc = $oc->set_primary(1); # or pass undef.

  my @ocs = >$oc->get_includes(@ocs);
  $oc->set_includes(@ocs);

  $oc = $oc->activate;
  $oc = $oc->deactivate;
  $oc = $oc->is_active;

  $oc = $oc->save;

=head1 DESCRIPTION

Holds information about the output channels that will be associated with
templates and elements.

=cut

#==============================================================================
## Dependencies                        #
#======================================#

#--------------------------------------#
# Standard Dependencies.
use strict;

#--------------------------------------#
# Programatic Dependencies.
use Bric::Config qw(:oc);
use Bric::Util::DBI qw(:all);
use Bric::Util::Grp::OutputChannel;
use Bric::Util::Fault::Exception::GEN;
use Bric::Util::Fault::Exception::DP;

#==============================================================================
## Inheritance                         #
#======================================#
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

# None.

#--------------------------------------#
# Private Class Fields
my $meths;
my $gen = 'Bric::Util::Fault::Exception::GEN';
my $dp  = 'Bric::Util::Fault::Exception::DP';

my %txt_map = ( name      => 'LOWER(name) LIKE ?',
		pre_path  => 'LOWER(pre_path) LIKE ?',
		post_path => 'LOWER(post_path) LIKE ?',
);
my %num_map = ( primary => 'primary = ?',
	        active  => 'active = ?',
	        server_type_id => 'id in (select output_channel__id from '
		                  . 'server_type__output_channel where '
                                  . 'server_type__id = ?)'
);

#--------------------------------------#
# Instance Fields

# This method of Bricolage will call 'use fields' for you and set some permissions.
BEGIN {
    Bric::register_fields(
      {
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

#==============================================================================
## Interface Methods                   #
#======================================#

=head1 INTERFACE

=head2 Public Methods

=over 4

=cut

#--------------------------------------#
# Constructors

#------------------------------------------------------------------------------#

=item $oc = Bric::Biz::OutputChannel->new( $initial_state )

Instantiates a Bric::Biz::OutputChannel object. An anonymous hash of initial
values may be passed. The supported initial value keys are:

=over 4

=item *

name

=item *

description

=item *

primary

=item *

active (default is active, pass undef to make a new inactive Output Channel)

=back

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

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

=item $oc = Bric::Biz::OutputChannel->lookup( { id => $id } )

Looks up and instantiates a new Bric::Biz::OutputChannel object based on the
Bric::Biz::OutputChannel object ID passed. If $id is not found in the database,
lookup() returns undef.

B<Throws:>

=item *

Missing required param 'id'.

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
    my ($class, $params) = @_;

    die $gen->new( { msg => 'missing required param id'} )
      unless $params->{'id'};

    my $self = bless {}, $class;
    $self->SUPER::new();

    my $sql = 'SELECT id,'. join(',',COLS) . " FROM ". TABLE .
      ' WHERE id=? ';

    my @d;
    my $sth = prepare_c($sql, undef, DEBUG);
    execute($sth, $params->{'id'} );
    bind_columns($sth, \@d[0 .. (scalar COLS)]);
    fetch($sth);

    $self->_set( ['id', FIELDS], [@d]);
    return $self;
}

=item ($ocs_aref || @ocs) = Bric::Biz::OutputChannel->list( $criteria )

Returns a list or anonymous array of Bric::Biz::OutputChannel objects based on
the search parameters passed via an anonymous hash. The supported lookup keys
are:

=over 4

=item *

name

=item *

primary

=item *

server_type_id

=item *

active

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

sub list {
    my ($class, $params) = @_;
    _do_list($class, $params, undef);
}

=item $ocs_href = Bric::Biz::OutputChannel->href( $criteria )

Returns an anonymous hash of Output Channel objects, where each hash key is an
Output Channel ID, and each value is Output Channel object that corresponds to
that ID. Takes the same arguments as list().

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

B<Notes: NONE.

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


=item ($id_aref || @ids) = Bric::Biz::OutputChannel->list_ids( $criteria )

Returns a list or anonymous array of Bric::Biz::OutputChannel object IDs based
on the search criteria passed via an anonymous hash. The supported lookup keys
are the same as for list().

B<Throws:>

=over 4

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

sub list_ids {
    my ($class, $params) = @_;
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

=over 4

=item $id = $oc->get_id

Returns the OutputChannel's unique ID.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $oc = $oc->set_name( $name )

Sets the name of the Output Channel.

B<Throws:> NONE.

B<Side Effects: NONE.

B<Notes:> NONE.

=item $name = $oc->get_name()

Returns the name of the Output Channel.

B<Throws:> NONE.

B<Side Effects: NONE.

B<Notes:> NONE.

=item $oc = $oc->set_description( $description )

Sets the description of the Output Channel.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $description = $oc->get_description()

Returns the description of the Output Channel.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

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

=item $oc = $oc->set_primary( undef || 1)

Set the flag that indicates whether or not this is the primary Output Channel.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item (undef || 1 ) = $oc->get_primary()

Returns true if this is the primary Output Channel and false (undef) if it is
not.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> Only one Output channel can be the primary output channel.

=item $self = $oc->activate

Activates the Bric::Biz::OutputChannel object. Call $oc->save to make the change
persistent. Bric::Biz::OutputChannel objects instantiated by new() are active by
default.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub activate {
    my $self = shift;
    $self->_set({_active => 1 });
}

=item $self = $oc->deactivate

Deactivates (deletes) the Bric::Biz::OutputChannel object. Call $oc->save to
make the change persistent.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub deactivate {
    my $self = shift;
    $self->_set({_active => 0 });
}

=item $self = $oc->is_active

Returns $self (true) if the Bric::Biz::OutputChannel object is active, and undef
(false) if it is not.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub is_active {
    my $self = shift;
    $self->_get('_active') ? $self : undef;
}


=item $self = $oc->save

Saves any changes to the Bric::Biz::OutputChannel object. Returns $self on
success and undef on failure.

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
    my ($self) = @_;
    return $self unless $self->_get__dirty();
    defined $self->_get('id') ? $self->_do_update : $self->_do_insert;
    $self->SUPER::save();
}


#==============================================================================
## Private Methods                     #
#======================================#

=head1 PRIVATE

=cut

#--------------------------------------#

=head2 Private Class Methods

=item _do_list

Called by list and list ids this does the brunt of their work.

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

sub _do_list {
    my ($class, $params, $ids, $href) = @_;
    my (@wheres, @params);

    while (my ($k, $v) = each %$params) {
	if ($txt_map{$k}) {
	    push @wheres, $txt_map{$k};
	    push @params, lc $v;
	} elsif ($num_map{$k}) {
	    push @wheres, $num_map{$k};
	    push @params, $v;
	} elsif ($k eq 'all') {
	    push @wheres, 'active = ?';
	    push @params, 1;
	} else {
	    $dp->new({ msg => "Invalid property argument '$k'." });
	}
    }

    local $" = ' AND ';
    my $where = @wheres ? "WHERE  @wheres" : '';

    # Assemble and prepare the query.
    my $qry_cols = $ids ? [] : ['id', COLS()];
    $" = ', ';
    my $sel = prepare_c(qq{
        SELECT @$qry_cols
        FROM   ${ \TABLE() }
        $where
        ORDER BY name
    }, undef, DEBUG);

    if ( $ids ) {
	# called from list_ids give em what they want
	my $return = col_aref($sel, @params);
	return wantarray ? @{ $return } : $return;
    } else { # end if ids
	# this must have been called from list so give objects
	my (@d, @objs, %objs);
	execute($sel, @params);
	bind_columns($sel, \@d[0 .. (scalar COLS)]);
	while (my $row = fetch($sel) ) {
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

Will perform the update to the database after being called from save.

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

sub _do_update {
    my ($self) = @_;
    local $" = ' = ?, '; # Simple way to create placeholders with an array.
    my $upd = prepare_c(qq{
        UPDATE ${ \TABLE() }
        SET    @{ [COLS] } = ?
        WHERE  id = ?
    });
    execute($upd, $self->_get(FIELDS, 'id'));
    return $self;
}

=item _do_insert

Will do the insert to the database after being called by save

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

sub _do_insert {
    my ($self) = @_;

    local $" = ', ';
    my $fields = join ', ', next_key('output_channel'), ('?') x COLS;
    my $ins = prepare_c(qq{
        INSERT INTO output_channel (id, @{[COLS()]})
        VALUES ($fields)
    }, undef, DEBUG);
    execute($ins, $self->_get( FIELDS ) );
    $self->_set( { 'id' => last_key(TABLE) } );
    $self->register_instance(INSTANCE_GROUP_ID, GROUP_PACKAGE);
    return $self;
}

1;
__END__

=head1 NOTES

NONE.

=head1 AUTHOR

Michael Soderstrom L<lt>miraso@pacbell.netL<gt>

=head1 SEE ALSO

L<perl>,L<Bric>,L<Bric::Biz::Asset::Business>,L<Bric::Biz::AssetType>,
L<Bric::Biz::Asset::Formatting>.

=cut
