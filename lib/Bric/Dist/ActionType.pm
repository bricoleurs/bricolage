package Bric::Dist::ActionType;

=head1 NAME

Bric::Dist::ActionType - Interface to types of actions supported by Bricolage distribution.

=head1 VERSION

$Revision: 1.1.1.1.2.1 $

=cut

# Grab the Version Number.
our $VERSION = substr(q$Revision: 1.1.1.1.2.1 $, 10, -1);

=head1 DATE

$Date: 2001-10-09 21:51:07 $

=head1 SYNOPSIS

  use Bric::Dist::ActionType;

  # Constructors.
  # Create a new object.
  my $at = Bric::Dist::ActionType->new;
  # Look up an existing object.
  $at = Bric::Dist::ActionType->lookup({ id => 1 });
  # Get a list of action type objects.
  my @servers = Bric::Dist::ActionType->list({ description => 'File%' });

  # Class methods.
  # Get a list of object IDs.
  my @st_ids = Bric::Dist::ActionType->list_ids({ description => 'File%' });
  # Get an introspection hashref.
  my $int = Bric::Dist::ActionType->my_meths;

  # Instance Methods.
  my $id = $at->get_id;
  my $name = $at->get_name;
  my $description = $at->get_description;
  my @medias = $at->get_media_types;
  my $medias = $at->get_medias_href;
  print "AT is ", $at->is_active ? '' : 'not ', "active\n";

=head1 DESCRIPTION

This class defines types of actions that can be performed on resources. Types of
actions include "Akamaize," "Gzip," "Put," "Delete," etc. All actions are
created at development time by Bricolage developers and cannot be created or changed by
users. Users can specify what types of actions apply to jobs executed for given
server types by accessing the Bric::Dist::Action class. Use Bric::Dist::ActionType
objects to help define Bric::Dist::Action objects.

=cut

################################################################################
# Dependencies
################################################################################
# Standard Dependencies
use strict;

################################################################################
# Programmatic Dependences
use Bric::Util::DBI qw(:standard col_aref);
use Bric::Util::Fault::Exception::DP;

################################################################################
# Inheritance
################################################################################
use base qw(Bric);

################################################################################
# Function and Closure Prototypes
################################################################################
my ($get_em, $make_obj);

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
my @cols = qw(a.id a.name a.description a.active t.name);
my @props = qw(id name description _active medias_href);

################################################################################

################################################################################
# Instance Fields
BEGIN {
    Bric::register_fields({
			 # Public Fields
			 id => Bric::FIELD_READ,
			 name => Bric::FIELD_READ,
			 description => Bric::FIELD_READ,
			 medias_href => Bric::FIELD_READ,

			 # Private Fields
			 _active => Bric::FIELD_NONE,
			});
}

################################################################################
# Class Methods
################################################################################

=head1 INTERFACE

=head2 Constructors

=over 4

=item my $at = Bric::Dist::ActionType->lookup({ id => $id })

=item my $at = Bric::Dist::ActionType->lookup({ name => $name })

Looks up and instantiates a new Bric::Dist::ActionType object based on the
Bric::Dist::ActionType object ID or name passed. If $id or $name is not found in
the database, lookup() returns undef.

B<Throws:>

=over

=item *

Too many Bric::Dist::Dist::ActionType objects found.

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

B<Side Effects:> If $id is found, populates the new Bric::Dist::ActionType object with
data from the database before returning it.

B<Notes:> NONE.

=cut

sub lookup {
    my $at = &$get_em(@_);
    # We want @$at to have only one value.
    die $dp->new({  msg => 'Too many Bric::Dist::ActionType objects found.' })
      if @$at > 1;
    return @$at ? $at->[0] : undef;
}

################################################################################

=item my (@ats || $ats_aref) = Bric::Dist::ActionType->list($params)

Returns a list or anonymous array of Bric::Dist::ActionType objects based on the search
parameters passed via an anonymous hash. The supported lookup keys are:

=over 4

=item *

description

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

B<Side Effects:> Populates each Bric::Dist::ActionType object with data from the
database before returning them all.

B<Notes:> NONE.

=cut

sub list { wantarray ? @{ &$get_em(@_) } : &$get_em(@_) }

################################################################################

=back 4

=head2 Destructors

=over 4

=item $at->DESTROY

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

=item my (@at_ids || $at_ids_aref) = Bric::Dist::ActionType->list_ids($params)

Returns a list or anonymous array of Bric::Dist::ActionType object IDs based on the
search criteria passed via an anonymous hash. The supported lookup keys are the
same as those for list().

B<Throws:>

over 4

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

=item $meths = Bric::Dist::ActionType->my_meths

Returns an anonymous hash of instrospection data for this object. The format for
the introspection is as follows:

Each hash key is the name of a property or attribute of the object. The value
for a hash key is another anonymous hash containing the following keys:

=over 4

=item *

meth - A reference to the method that will retrieve the value of the property
or attribute.

=item *

args - An anonymous array of arguments to pass to a call to meth in order to
retrieve the value of the property or attribute.

=item *

disp_name - The display name of the property or attribute.

=item *

type - The type of value the property or attribute contains. There are only
three types:

=over 4

=item short

=item date

=item blob

=back

=item *

length - If the value is a 'short' value, this hash key contains the length of
the field.

=back

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub my_meths {
    # Load field members.
    my $ret = { name        => { meth => sub {shift->get_name(@_)},
				 args => [],
				 disp => '',
				 type => 'short',
				 len  => 64 },
		description => { meth => sub {shift->get_description(@_)},
				 args => [],
				 disp => '',
				 type => 'short',
				 len  => 256 },
		};
    # Load attributes here.
    return $ret;
}

################################################################################

=back

=head2 Public Instance Methods

=over 4

=item my $id = $at->get_id

Returns the ID of the Bric::Dist::ActionType object.

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

B<Notes:> If the Bric::Dist::ActionType object has been instantiated via the new()
constructor and has not yet been C<save>d, the object will not yet have an ID,
so this method call will return undef.

=item my $name = $at->get_name

Returns the name of this type of action.

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

=item my $description = $at->get_description

Returns the description of this type of action.

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

=item my (@medias || $medias_aref) = $at->get_media_types

Returns a list or anonymous array of the MEDIA types that apply to this
action. Returns an empty list (or undef in a scalar context) if this action
applies to  B<all> MEDIA types.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_media_types {
    my $medias = $_[0]->_get('medias_href');
    return if $medias->{none};
    return wantarray ? sort keys %$medias : [ sort keys %$medias ];
}

################################################################################

=item my (@medias || $medias_aref) = $at->get_medias_href

Returns an anonymous hash of the MEDIA types that apply to this action. Returns
undef if this action applies to B<all> MEDIA types.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_medias_href {
    my $medias = $_[0]->_get('medias_href');
    return $medias->{none} ? undef : $medias;
}

################################################################################

=item $self = $st->is_active

Returns $self if the Bric::Dist::ActionType object is active, and undef if it is
not.

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

=back 4

=head1 PRIVATE

=head2 Private Class Methods

NONE.

=head2 Private Instance Methods

NONE.

=head2 Private Functions

=over 4

=item my $at_aref = &$get_em( $pkg, $params )

=item my $at_ids_aref = &$get_em( $pkg, $params, 1 )

Function used by lookup() and list() to return a list of Bric::Dist::ActionType objects
or, if called with an optional third argument, returns a listof Bric::Dist::ActionType
object IDs (used by list_ids()).

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

$get_em = sub {
    my ($pkg, $params, $ids) = @_;
    my (@wheres, @params);
    while (my ($k, $v) = each %$params) {
	if ($k eq 'id') {
	    push @wheres, 'a.id = ?';
	    push @params, $v;
	} elsif ($k eq 'media_type') {
	    push @wheres, "t.name LIKE ?";
	    push @params, lc $v;
	} else {
	    push @wheres, "LOWER(a.$k) LIKE ?";
	    push @params, lc $v;
	}
    }

    # Assemble the WHERE clause.
    push @wheres, "a.active = 1" if $params->{id};
    my $where = @wheres ? "\n               AND " . join ' AND ', @wheres : '';

    # Assemble and prepare the query.
    local $" = ', ';
    my $qry_cols = $ids ? ['a.id'] : \@cols;
    my $sel = prepare_c(qq{
        SELECT @$qry_cols
        FROM   action_type a, action_type__media_type m, media_type t
        WHERE  a.id = m.action_type__id
               AND m.media_type__id = t.id $where
        ORDER BY a.name
    }, undef, DEBUG);

    # Just return the IDs, if they're what's wanted.
    return col_aref($sel, @params) if $ids;

    # Grab all the records.
    execute($sel, @params);
    my ($last, @d, @init, $media, @ats) = (-1);
    bind_columns($sel, \@d[0..$#cols - 1], \$media);
    $pkg = ref $pkg || $pkg;
    while (fetch($sel)) {
	if ($d[0] != $last) {
	    # Create a new object.
	    push @ats, &$make_obj($pkg, \@init) unless $last == -1;
	    # Get the new record.
	    $last = $d[0];
	    @init = (@d, {});
	}
	# Grabe the MEDIA type.
	$init[$#init]->{$media} = 1;
    }
    # Grab the last object.
    push @ats, &$make_obj($pkg, \@init);
    # Return the objects.
    return \@ats;
};

$make_obj = sub {
    my ($pkg, $init) = @_;
    my $self = bless {}, $pkg;
    $self->SUPER::new;
    $self->_set(\@props, $init);
};

1;
__END__

=back

=head1 NOTES

NONE.

=head1 AUTHOR

David Wheeler <david@wheeler.net>

=head1 SEE ALSO

perl(1),
Bric (2),

=cut
