package Bric::Biz::ElementType::Subelement;

#############################################################################

=head1 Name

Bric::Biz::ElementType::Subelement - Maps a subelement ElementType
to its parent's Element Types with occurrence relations and place.

=cut

require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

  use Bric::Biz::ElementType::Subelement;

  # Constructors.
  my $subelem = Bric::Biz::ElementType::Subelement->new($init);
  my $subelems_href = Bric::Biz::ElementType::Subelement->href($params);

  # Instance methods.
  my $element_type_id = $subelem->get_parent_element_type_id;
  $subelem->set_parent_element_type_id($element_type_id);

  my $min = $subelem->get_min_occurrence;
  $subelem->set_min_occurrence($min);

  my $max = $subelem->get_max_occurrence;
  $subelem->set_max_occurrence($max);

  my $place = $subelem->get_place;
  $subelem->set_place($place);

  $subelem->save;

=head1 Description

This subclass of Bric::Biz::ElementType manages the relationship between
parent ElementTypes and subelement ElementTypes. It contains information
on the minimum and maximum occurrence that can be used, and also the place
it should appear in when displaying. This class provides accessors to the
relevant properties, as well as an C<href()> method to help along the use
of a Bric::Util::Coll object.

=cut

##############################################################################
# Dependencies
##############################################################################
# Standard Dependencies
use strict;
use Bric::Util::Fault qw(throw_invalid);

##############################################################################
# Programmatic Dependences
use Bric::Util::DBI qw(:all);

##############################################################################
# Inheritance
##############################################################################
use base qw(Bric::Biz::ElementType);

##############################################################################
# Function and Closure Prototypes
##############################################################################
# None.

##############################################################################
# Constants
##############################################################################
use constant DEBUG => 0;

##############################################################################
# Fields
##############################################################################
# Public Class Fields

##############################################################################
# Private Class Fields
my $SEL_COLS = Bric::Biz::ElementType::SEL_COLS() .
  ', subet.id, subet.parent_id, subet.place,' .
  ' subet.min_occurrence, subet.max_occurrence';
my @SEL_PROPS = (Bric::Biz::ElementType::SEL_PROPS(),
                 qw(_map_id parent_id place min_occurrence max_occurrence));

# Grabbed knowledge from parent, but the outer join depends on it. :-(
my $SEL_TABLES = 'element_type a LEFT OUTER JOIN ' .
  'subelement_type subet ON (a.id = subet.child_id), ' .
  'member m, element_type_member etm';

sub SEL_PROPS { @SEL_PROPS }
sub SEL_COLS { $SEL_COLS }
sub SEL_TABLES { $SEL_TABLES }

##############################################################################
# Instance Fields
BEGIN {
    Bric::register_fields({
        min_occurrence  => Bric::FIELD_RDWR,
        max_occurrence  => Bric::FIELD_RDWR,
        place           => Bric::FIELD_RDWR,
        parent_id       => Bric::FIELD_RDWR,
        _map_id         => Bric::FIELD_NONE,
    });
}
##############################################################################
# Class Methods
##############################################################################

=head1 Interface

This class inherits the majority of its interface from
L<Bric::Biz::ElementType|Bric::Biz::ElementType>. Only additional methods
are documented here.

=head2 Constructors

=over 4

=item my $subelem = Bric::Biz::ElementType::Subelement->new($init);

Constructs a new Bric::Biz::ElementType::Subelement object intialized with the
values in the C<$init> hash reference and returns it. The suported values for
the C<$init> hash reference are the same as those supported by
C<< Bric::Biz::ElementType::Subelement->new >>, with the addition of the
following:

=over 4

=item C<child_id>

The ID of the element type object on which the new
Bric::Biz::ElementType::Subelement will be based. The relevant
Bric::Biz::ElementType object will be looked up from the database. Note that
all of the C<$init> parameters documented in
L<Bric::Biz::ElementType|Bric::Biz::ElementType> will be ignored if this
parameter is passed.

=item C<child>

The element type object on which the new Bric::Biz::ElementType::Subelement
will be based. Note that all of the C<$init> parameters documented in
L<Bric::Biz::ElementType|Bric::Biz::ElementType> will be ignored if this
parameter is passed.

=item C<parent_id>

The ID of the Bric::Biz::ElementType object to which this subelement is
mapped.

=item C<min_occurrence>

The minimum occurrence that the child ElementType must exist within any
element with the parent ElementType

=item C<max_occurrence>

The maximum occurrence that the child ElementType may exist within any
element with the parent ElementType. A max of 0 means that there is no
maximum.

=item C<place>

The place that the child exists in relation to the other children within
the parent element type.

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

B<Side Effects:> If you pass in an element type object via the C<child>
parameter, that element type will be converted into a
Bric::Biz::ElementType::Subelement object.

B<Notes:> NONE.

=cut

sub new {
    my ($pkg, $init) = @_;

    my $min = delete $init->{min_occurrence} || 0;
    my $max = delete $init->{max_occurrence} || 0;
    my $place = delete $init->{place} || 0;


    my $parent = delete $init->{parent} || 0;
    my $parent_id = ($parent == 0) ? 0 : $parent->get_id;
    $parent_id = delete $init->{parent_id} || $parent_id;

    # Set the place to one more than the number of subelements there are already
    my $href = Bric::Biz::ElementType::Subelement->href({ parent_id => $parent_id })
        unless ($parent_id == 0 || $place != 0);
    $place = 1 + scalar keys %$href unless ($parent_id == 0 || $place != 0);

    my ($child, $childid) = delete @{$init}{qw(child child_id)};
    my $self;
    if ($child) {
        # Rebless the existing element type object.
        $self = bless $child, ref $pkg || $pkg;
    } elsif ($childid) {
        # Lookup the existing output channel object.
        $self = $pkg->lookup({ id => $childid });
    } else {
        # Construct a new element type object.
        $self = $pkg->SUPER::new($init);
    }
    # Set the necessary properties and return.
    $self->_set([qw(min_occurrence max_occurrence place parent_id _map_id)],
        [$min, $max, $place, $parent_id, undef]);
    # New relationships should always trigger a save.
    $self->_set__dirty(1);
}

##############################################################################

=item my $subelem_href = Bric::Biz::ElementType::Subelement->href({ parent_id => $eid });

Returns a hash reference of Bric::Biz::ElementType::Subelement objects. Each
hash key is a Bric::Biz::ElementType::Subelement ID, and the values are the
corresponding Bric::Biz::ElementType::Subelement objects. Only a single
parameter argument is allowed, C<parent_id>, though C<ANY> may be used
to specify a list of element type IDs. All of the child element types
associated with that parent element type ID will be returned.

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

sub href {
    my ($pkg, $p) = @_;
    my $class = ref $pkg || $pkg;

    # XXX Really there's too much going on here getting information from
    # the parent class. Perhaps one day we'll have a SQL factory class to
    # handle all this stuff, but this will have to do for now.
    my $ord = $pkg->SEL_ORDER;
    my $cols = $pkg->SEL_COLS;
    my $tables = $pkg->SEL_TABLES;
    my @params;
    my $wheres = $pkg->SEL_WHERES
               . ' AND a.id = subet.child_id AND '
               . any_where $p->{parent_id}, 'subet.parent_id = ?', \@params;
    my $sel = prepare_c(qq{
        SELECT $cols
        FROM   $tables
        WHERE  $wheres
        ORDER BY $ord
    }, undef);

    execute($sel, @params);
    my (@d, %ocs, $grp_ids);
    my @sel_props = $pkg->SEL_PROPS;
    bind_columns($sel, \@d[0..$#sel_props]);
    my $last = -1;
    $pkg = ref $pkg || $pkg;
    my $grp_id_idx = $pkg->GRP_ID_IDX;
    while (fetch($sel)) {
        if ($d[0] != $last) {
            $last = $d[0];
            # Create a new server type object.
            my $self = $pkg->SUPER::new;
            # Get a reference to the array of group IDs.
            $grp_ids = $d[$grp_id_idx] = [$d[$grp_id_idx]];
            $self->_set(\@sel_props, \@d);
            $self->_set__dirty; # Disables dirty flag.
            $ocs{$d[0]} = $self;
        } else {
            push @$grp_ids, $d[$grp_id_idx];
        }
    }
    # Return the objects.
    return \%ocs;
}

=back

##############################################################################

=head2 Public Instance Methods

=over 4

=item my $eid = $subelem->get_parent_id

Returns the ID of the Element Type definition of the parent with which this
sub element is associated.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $subelem = $subelem->set_parent_id($eid)

Sets the ID of the parent element type definition with which this sub element is
associated.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

##############################################################################

=item $subelem = $subelem->set_min_occurrence($min)

Set the minimum occurrence for this subelement

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $min = $subelem->get_min_occurrence

Get the minimum occurrence for this subelement

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub set_min_occurrence {
    my ($this, $min) = @_;
    # Throw an error if we get a string when a number is needed
    throw_invalid error => qq{min_occurrence must be a positive number.}
        unless (($min =~ /^\d+$/) && ($min >= 0));
    $this->_set(['min_occurrence'], [$min])
}

##############################################################################

=item $subelem = $subelem->set_max_occurrence($max)

Set the maximum occurrence for this subelement

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $max = $subelem->get_max_occurrence

Get the maximum occurrence for this subelement

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub set_max_occurrence {
    my ($this, $max) = @_;
    # Throw an error if we get a string when a number is needed
    throw_invalid error => qq{max_occurrence must be a positive number.}
        unless (($max =~ /^\d+$/) && ($max >= 0));
    $this->_set(['max_occurrence'], [$max])
}

##############################################################################

=item $subelem = $subelem->set_place($place)

Set the place for this subelement

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $place = $subelem->get_place

Get the place for this subelement

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub set_place {
    my ($this, $place) = @_;
    # Throw an error if we get a string when a number is needed
    throw_invalid error => qq{place must be a positive number.}
        unless (($place =~ /^\d+$/) && ($place >= 0));
    $this->_set(['place'], [$place])
}

##############################################################################

=item $subelem = $subelem->remove

Marks this parent/child element type association to be removed. Call the
C<save()> method to remove the mapping from the database.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub remove { $_[0]->_set(['_del'], [1]) }

##############################################################################

=item $subelem = $subelem->save

Saves the subelement.

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
    # Save the base class' properties.
    $self->SUPER::save;
    # Save the occurrence and place.
    my ($childid, $parentid, $min, $max, $place, $map_id, $del) =
      $self->_get(qw(id parent_id min_occurrence max_occurrence place _map_id _del));
    if ($del and $map_id) {
        # Delete it.
        my $delete = prepare_c(qq{
            DELETE FROM subelement_type
            WHERE  id = ?
        }, undef);
        execute($delete, $map_id);
        $self->_set([qw(_map_id _del)], []);

    } elsif ($map_id) {
        # Update the existing value.
        my $upd = prepare_c(qq{
            UPDATE subelement_type
            SET    parent_id = ?,
                   child_id = ?,
                   place = ?,
                   min_occurrence = ?,
                   max_occurrence = ?
            WHERE  id = ?
        }, undef);
        execute($upd, $parentid, $childid, $place, $min, $max, $map_id);

    } else {
        # Insert a new record.
        my $nextval = next_key('subelement_type');
        my $ins = prepare_c(qq{
            INSERT INTO subelement_type
                        (id, parent_id, child_id, place, min_occurrence, max_occurrence)
            VALUES ($nextval, ?, ?, ?, ?, ?)
        }, undef);
        execute($ins, $parentid, $childid, $place, $min, $max);
        $self->_set(['_map_id'], [last_key('subelement_type')]);
    }
    return $self;
}

1;
__END__

=back

=head1 Notes

NONE.

=head1 Author

David Wheeler <christian.muise@gmail.com>

=head1 See Also

L<Bric::Biz::ElementType|Bric::Biz::ElementType>,

=cut
