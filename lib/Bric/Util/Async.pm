package Bric::Util::Async;

=head1 NAME

Bric::Util::Async - This will handle all the async events 

=head1 VERSION

$Revision: 1.2 $

=cut

# Grab the version #
our $VERSION = substr(q$Revision: 1.2 $, 10, -1);

=head1 DATE

$Date: 2001-10-09 20:48:54 $

=head1 SYNOPSIS

 # creation of new objects
 $a = Bric::Util::Async->new($param);
 $a = Bric::Util::Async->lookup( { id => $id });
 ($a_list || @as) = Bric::Util::Async->list( $param )

 # list of ids
 ($a_ids || @a_ids) = Bric::Util::Async->list_ids( $param )

 # manipulation of events
 $a = $a->add_event( $param )
 ($events || @events) = $a->get_events( $param )
 $a = $a->delete_events( $param )

 # manipulation of active state ( not the company )
 $a = $a->activate()
 $a = $a->deactivate();
 ($a || undef) $a->is_active()

 # save whatever just happened
 $a = $a->save()

=head1 DESCRIPTION

This class will govern the async output events

=cut

################################################################################
# Dependencies
################################################################################

# Standard Dependencies
use strict;

################################################################################
# Programmatic Dependencies
use Bric::Util::DBI qw(:all);
use Bric::Util::Async::Parts::Event;

################################################################################
# Inheritance
################################################################################
use base qw(Bric);

################################################################################
# Function and Closure Prototypes
################################################################################
# NONE

################################################################################
# Constants
################################################################################

use constant DEBUG => 1;

use constant SCRIPT => '/home/mike/test.pl';

use constant TABLE	=> 'async';

use constant COLS	=> qw(name description file_name active);

use constant FIELDS	=> qw(name description file_name _active);

################################################################################
# Fields
################################################################################
# Public Class Fields

# NONE

################################################################################
# Private Class Fields

# NONE

################################################################################
# Instance Fields
BEGIN {
	Bric::register_fields({
			# Public Fields
			'id'				=> Bric::FIELD_READ,

			'name'				=> Bric::FIELD_RDWR,

			'description'		=> Bric::FIELD_RDWR,

			'file_name'			=> Bric::FIELD_RDWR,

			# Private Fields
			'_events'			=> Bric::FIELD_NONE,

			'_new_events'		=> Bric::FIELD_NONE,

			'_del_events'		=> Bric::FIELD_NONE,

			'_delete'			=> Bric::FIELD_NONE,

			'_active'			=> Bric::FIELD_NONE
	});
}

################################################################################
# Class Methods
################################################################################

=head1 INTERFACE

=head2 Constructors

=over 4

=item $a = Bric::Util::Async->new( $init )

Creates a new Async Object

Supproted Keys:

=over 4

=item *

name

=item *

description

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

sub new {
	my ($class, $init) = @_;

	my $self = bless {}, $class;

	$init->{'_active'} = exists $init->{'active'} ? $init->{'active'} : 1;
	delete $init->{'active'};

	$self->_set({'_events' => {},'_new_events' => {},'_del_events' => {} });

	$self->SUPER::new($init);

	return $self;
}

################################################################################

=item $a = Bric::Util::Async->lookup({ id => $id } )

Looks up the object form the data base

B<Throws:>

"Missing required parameter 'id'"

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub lookup {
	my ($class, $param) = @_;

	die Bric::Util::Fault::Exception::GEN->new(
		{ 'msg' => "Missing required parameter 'id'" })
			unless $param->{'id'};

	my $self = _select_async('id=?', $param->{'id'} );

	my $parts = Bric::Util::Async::Parts::Event->list( { 
					'async_id' => $param->{'id'}, 'active' => 1 });

	my $ps = {};
	foreach (@$parts) {
		my $id = $_->get_id();
		$ps->{$id} = $_;
	}

	$self->_set({'_events' => $ps,'_del_events' => {},'_new_events' => {} });

	return $self;
} 

################################################################################

=item (@a_ids || $a_ids) = Bric::Util::Async->list( $param )

returns a list or list ref of objects that match the criteria

Supported Keys:

=over 4

=item *

name

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

	return _do_list($class, $params, undef);
}

################################################################################

=back 4

=head2 DESTRUCTORS

=over 4

=item $a->DESTROY

Dummy method to save the waste of autoloads time

B<Throws:>

NONE

B<Side Effects:> 

NONE

B<Notes:>

NONE

=cut

sub DESTROY { 
	# what a fun method name, shame it will not do anything 
}

################################################################################

=head2 Public Class Methods

=item (@a_ids || $a_ids) = Bric::Util::Async->list_ids( $param )

Returns a list of the ids that match said param.   Check out list to see 
what the possible params are

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub list_ids {
	my ($class, $params) = @_;

	return _do_list( $class, $params, 1);
}

################################################################################

=head2 Public Instance methods

=item $id = $a->get_id()

Returns the id

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

Well this will return the id only if there is one, ie gotta call save on a new 
object before there can be an id silly.

=cut

################################################################################

=item $a = $a->set_name( $name )

Sets the name for this collection of events

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

################################################################################

=item $name = $a->get_name()

returns the name for the object

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

################################################################################

=item $a = $a->set_description( $description )

Sets the description for the object

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

################################################################################

=item $description = $a->get_description()

returns the description of the object

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

################################################################################

=item $a = $a->add_events( $param )

Adds parts to the async object

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub add_events {
	my ($self, $parts) = @_;

	my ($events, $new_events, $del_events) = $self->_get( '_events',
									'_new_events', '_del_events');

	foreach my $e (@$parts) {
		my $e_id = $e->get_id();

		next if exists $events->{$e_id};

		$new_events->{$e_id} = $e;

		delete $del_events->{$e_id};
	}

	$self->_set( { 	'_events' 		=> $events, 
					'_new_events' 	=> $new_events,
					'_del_events'	=> $del_events });

	return $self;
}

################################################################################

=item ($parts || @parts) = $a->get_events()

Returns a list of the parts that are associated with this

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_events {
	my ($self) = @_;

	my ($events, $new_events) = $self->_get( '_events', '_new_events');

	my @parts = (values %$events, keys %$new_events);

	return wantarray ? @parts : \@parts;
}

################################################################################

=item $a = $a->delete_events()

removes the parts from the async obj

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub delete_events {
	my ($self, $del) = @_;

	my ($events, $new_events, $del_events) = $self->_get('_events', 
					'_new_events', '_del_events');

	foreach my $e (@$del) {
		my $e_id = $e->get_id();

		if (exists $events->{$e_id}) {
			my $obj = delete $events->{$e_id};
			$del_events->{$e_id} = $obj;

		} 
		delete $new_events->{$e_id};
	}

	$self->_set( { 	'_events' 		=> $events, 
					'_new_events'	=> $new_events, 
					'_del_events'	=> $del_events	});


	return $self;
}

################################################################################

=item $a = $a->delete()

Will set the delete flag and will then delete once save is called

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub delete {
	my ($self) = @_;

	$self->_set( { '_delete' => 1 });

	return $self;
}

################################################################################

=item $a = $a->activate()

Sets the active flag

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

################################################################################

=item $a = $a->deactivate()

unsets the active flag

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub deactivate {
	my ($self) = @_;

	$self->_set( { '_active' => 0 });

	return $self;
}

################################################################################


=item ($a || undef) = $a->is_active()

returns if the active flag is set

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub is_active {
	my ($self) = @_;

	return $self->_get('_active') ? $self : undef;
}

################################################################################


=item $a = $a->save()

saves the changes to the data base

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub save {
	my ($self) = @_;

	if ($self->_get('_delete')) {
		$self->_do_delete();
	} elsif ($self->_get('id')) {
		$self->_do_update();
	} else {
		$self->_do_insert();
	}

	$self->_sync_parts();

	$self->_generate_file();

	$self->SUPER::save();

	return $self;
}

################################################################################

=back 4

=head1 PRIVATE

################################################################################

=over 4

=head2 Private Class Methods

=item $self->_do_list()

This does the dirty work of list and list_ids

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _do_list {
	my ($class, $param, $ids) = @_;

	my @where;
	my @where_param;

	my $sql = 'SELECT id ';
	$sql .= ', ' . join( ', ', COLS) unless ($ids);
	$sql .= ' FROM ' . TABLE;


	if (@where) {
		$sql .= join(' AND ', @where);
	}

	my $sth = prepare_ca($sql, undef, DEBUG);

	if ($ids) {
		my $return = col_aref($sth, @where_param);

		return wantarray ? @$return : $return;
	} else {

		my @objs;
		execute($sth, @where_param);
		while (my $row = fetch($sth)) {
			my $self = bless {}, $class;
			$self->SUPER::new();
			$self->_set(['id', COLS], $row);

			my $parts = Bric::Util::Async::Parts::Event->list( { 
					'async_id' => $param->{'id'}, 'active' => 1 });

			my $ps = {};
			foreach (@$parts) {
				my $id = $_->get_id();
				$ps->{$id} = $_;
			}   

			$self->_set({	'_events' 		=> $ps,
							'_del_events' 	=> {},
							'_new_events' 	=> {} });

			push @objs, $self;
		}

		return wantarray ? @objs : \@objs;
	}
}

=head2 Private Instance Methods

=item $self = $self->_generate_file()

Goes through all the parts and writes out the cron tab file

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _generate_file {
	my ($self) = @_;

	my ($file, $parts) = $self->_get('file_name', '_events');

	rename $file, "$file.BAK"
		or die Bric::Util::Fault::Exception::GEN->new(
			{ msg => 'Could not Back up cron File', payload => $! });

	eval {
		open FILE, ">$file" or die $!;
		flock FILE, 2;
		foreach (keys %$parts) {
			my $obj = $parts->{$_};
			my $min = $obj->get_minutes || '*';
			my $hour = $obj->get_hours || '*';
			my $day = $obj->get_days || '*';
			my $mon = $obj->get_month || '*';
			my $dow = $obj->get_days_of_week || '*';
			print FILE $min . ' ' . $hour . ' ' . $day . ' ' . $mon . ' ' .
						$dow . ' ' .  SCRIPT . ' ' .
						$obj->get_obj_type . ' ' . $obj->get_obj_id . "\n";
		}
		flock FILE, 8;
		close FILE;
	};
	if ($@) {
		rename "$file.BAK", $file;
		die Bric::Util::Fault::Exception::GEN->new(
			{ msg => "Error Writing File: $@" });
	} else {
		unlink "$file.BAK";
	}

	return $self;
}

=item $self = $self->_sync_parts()

called by save this will sync the held parts

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _sync_parts {
	my ($self) = @_;

	my ($events, $new_events, $del_events) = $self->_get( '_events',
				'_new_events', '_del_events');

	foreach (keys %$new_events) {
		$new_events->{$_}->set_async_id($self->_get('id') );
		$new_events->{$_}->save();
		$events->{$_} = delete $new_events->{$_};
	}

	foreach (keys %$del_events) {
		$del_events->{$_}->deactivate();
		$del_events->{$_}->save();
		delete $del_events->{$_};
	}

	$self->_set( { '_events' => $events, '_new_events' => $new_events,
							'_del_events' => $del_events });
	return $self;
}

=item $self = $self->_do_insert()

This will create a record for this object

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _do_insert {
	my ($self) = @_;

	my $sql = "INSERT INTO " . TABLE . " (id," . join(', ', COLS) . ") ".
			"VALUES (${\next_key(TABLE)}," . join(',', ('?') x COLS) . ") ";

	my $insert = prepare_c($sql, undef, DEBUG);

	execute($insert, ($self->_get( FIELDS )) );

	# Now get the id that was created
	$self->_set( { 'id' => last_key(TABLE) } );

	return $self;
}

=item $self = $self->_do_update()

Updates the record in the data base

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
				'SET ' . join(', ', map { "$_=?" } COLS) .
				' WHERE id=? ';

	my $update = prepare_c($sql, undef, DEBUG);

	execute($update, $self->_get( FIELDS ), $self->_get('id') );

	return $self;
}

=item $self = $self->_do_delete()

removes this record from the database

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _do_delete {
	my ($self) = @_;

	my $sql = "DELETE FROM " . TABLE . 
				" WHERE id=? ";

	my $delete = prepare_c($sql, undef, DEBUG);

	execute($delete, $self->_get('id') );

	return $self;
}

=item $self = $self->_select_async()

Populates an object from the database

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut


sub _select_async {
	my ($self, $where, @bind) = @_;

	my @d;

	my $sql = 'SELECT id,'. join(',',COLS) . " FROM ". TABLE;

	$sql .= " WHERE $where";

	my $sth = prepare_ca($sql, undef, DEBUG);
	execute($sth, @bind);
	bind_columns($sth, \@d[0 .. (scalar COLS)]);
	fetch($sth);

	# set the values retrieved
	$self->_set( [ 'id', FIELDS], [@d]);

	return $self;
}


=head2 Private Functions

NONE

=cut

1;

__END__

=back

=head1 NOTES

NONE

=head1 AUTHOR

Michael Soderstrom <miraso@pacbell.net>

=head1 SEE ALSO

perl(1),
Bric (2),
Bric::Util::Async::Parts::Event(3)

=cut
