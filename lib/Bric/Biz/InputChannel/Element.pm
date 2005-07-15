package Bric::Biz::InputChannel::Element;
#############################################################################

=head1 NAME

Bric::Biz::InputChannel::Element - Maps Input Channels to Elements.

=head1 VERSION

$LastChangedRevision$

=cut

require Bric; our $VERSION = Bric->VERSION;

=head1 DATE

$LastChangedDate: 2004-11-08 22:32:57 -0500 (Mon, 08 Nov 2004) $

=head1 SYNOPSIS

  use Bric::Biz::InputChannel::Element;

  # Constructors.
  my $ice = Bric::Biz::InputChannel->new($init);
  my $ices_href = Bric::Biz::InputChannel->href($params);

  # Instance methods.
  my $element_id = $ice->get_element_id;
  $ice->set_element_id($element_id);
  $ice->set_enabled_on;
  $ice->set_enabled_off;
  if ($ice->is_enabled) { } # do stuff.
  $ice->save;

=head1 DESCRIPTION

This subclass of Bric::Biz::InputChannel manages the relationship between
input channels and elements (Bric::Biz::AssetType objects). It does so by
providing accessors to properties relevant to the relationship, as well as an
C<href()> method to help along the use of a Bric::Util::Coll object.

=cut

##############################################################################
# Dependencies
##############################################################################
# Standard Dependencies
use strict;

##############################################################################
# Programmatic Dependences
use Bric::Util::DBI qw(:all);

##############################################################################
# Inheritance
##############################################################################
use base qw(Bric::Biz::InputChannel);

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
my $SEL_COLS = Bric::Biz::InputChannel::SEL_COLS() .
  ', eic.id, eic.element__id, eic.enabled';
my @SEL_PROPS = (Bric::Biz::InputChannel::SEL_PROPS(),
                 qw(_map_id element_id _enabled));

# Grabbed knowledge from parent, but the outer join depends on it. :-(
my $SEL_TABLES = 'input_channel ic LEFT OUTER JOIN ' .
  'element__input_channel eic ON (ic.id = eic.input_channel__id), ' .
  'member m, input_channel_member sm';

sub SEL_PROPS { @SEL_PROPS }
sub SEL_COLS { $SEL_COLS }
sub SEL_TABLES { $SEL_TABLES }

##############################################################################
# Instance Fields
BEGIN {
    Bric::register_fields({ element_id => Bric::FIELD_RDWR,
                            _enabled => Bric::FIELD_NONE,
                            _map_id => Bric::FIELD_NONE });

}

##############################################################################
# Class Methods
##############################################################################

=head1 INTERFACE

This class inherits the majority of its interface from
L<Bric::Biz::InputChannel|Bric::Biz::InputChannel>. Only additional methods
are documented here.

=head2 Constructors

=over 4

=item my $ice = Bric::Biz::InputChannel::Element->new($init);

Constructs a new Bric::Biz::InputChannel::Element object intialized with the
values in the C<$init> hash reference and returns it. The suported values for
the C<$init> hash reference are the same as those supported by
C<< Bric::Biz::InputChannel::Element->new >>, with the addition of the
following:

=over 4

=item C<ic_id>

The ID of the input channel object on which the new
Bric::Biz::InputChannel::Element will be based. The relevant
Bric::Biz::InputChannel object will be looked up from the database. Note that
all of the C<$init> parameters documented in
L<Bric::Biz::InputChannel|Bric::Biz::InputChannel> will be ignored if this
parameter is passed.

=item C<ic>

The input channel object on which the new Bric::Biz::InputChannel::Element
will be based. Note that all of the C<$init> parameters documented in
L<Bric::Biz::InputChannel|Bric::Biz::InputChannel> will be ignored if this
parameter is passed.

=item C<element_id>

The ID of the Bric::Biz::AssetType object to which this input channel is
mapped.

=item C<enabled>

A boolean value indicating whether the input channel will automatically be
added to new assets by default.

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

B<Side Effects:> If you pass in an input channel object via the C<oc>
parameter, that input channel object will be converted into a
Bric::Biz::InputChannel::Element object.

B<Notes:> NONE.

=cut

sub new {
    my ($pkg, $init) = @_;
    my $en = ! exists $init->{enabled} ? 1 : delete $init->{enabled} ? 1 : 0;
    my ($eid, $ic, $icid) = delete @{$init}{qw(element_id ic ic_id)};
    my $self;
    if ($ic) {
        # Rebless the existing input channel object.
        $self = bless $ic, ref $pkg || $pkg;
    } elsif ($icid) {
        # Lookup the existing input channel object.
        $self = $pkg->lookup({ id => $icid });
    } else {
        # Construct a new input channel object.
        $self = $pkg->SUPER::new($init);
    }
    # Set the necessary properties and return.
    $self->_set([qw(_enabled element_id _map_id)], [$en, $eid, undef]);
    # New relationships should always trigger a save.
    $self->_set__dirty(1);
}

##############################################################################

=item my $ice_href =
Bric::Biz::InputChannel::Element->href({ element_id => $eid });

Returns a hash reference of Bric::Biz::InputChannel::Element objects. Each
hash key is a Bric::Biz::InputChannel::Element ID, and the values are the
corresponding Bric::Biz::InputChannel::Element objects. Only a single
parameter argument is allowed, C<element_id>. All of the input channels
associated with that element ID will be returned.

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
    my ($pkg, $params) = @_;
    my $class = ref $pkg || $pkg;

    # HACK: Really there's too much going on here getting information from
    # the parent class. Perhaps one day we'll have a SQL factory class to
    # handle all this stuff, but this will have to do for now.
    my $ord = $pkg->SEL_ORDER;
    my $cols = $pkg->SEL_COLS;
    my $tables = $pkg->SEL_TABLES;
    my $wheres = $pkg->SEL_WHERES .
      ' AND ic.id = eic.input_channel__id AND eic.element__id = ?';
    my $sel = prepare_c(qq{
        SELECT $cols
        FROM   $tables
        WHERE  $wheres
        ORDER BY $ord
    }, undef);

    execute($sel, $params->{element_id});
    my (@d, %ics, $grp_ids);
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
            $ics{$d[0]} = $self;
        } else {
            push @$grp_ids, $d[$grp_id_idx];
        }
    }
    # Return the objects.
    return \%ics;
}

=back

##############################################################################

=head2 Public Instance Methods

=over 4

=item my $eid = $ice->get_element_id

Returns the ID of the Element definition with which this input channel is
associated.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $ice = $ice->set_element_id($eid)

Sets the ID of the Element definition with which this input channel is
associated.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

##############################################################################

=item $ice = $ice->set_enabled_on

Causes this input channel to be available to new stories by default.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub set_enabled_on { $_[0]->_set(['_enabled'], [1]) }

##############################################################################

=item $ice = $ice->set_enabled_off

Makes this input channel optional, so users have to add it to each story 
manually

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub set_enabled_off { $_[0]->_set(['_enabled'], [0]) }

##############################################################################

=item $ice = $ice->is_enabled

Returns true if this input channel is enabled, and false if it is not.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub is_enabled { $_[0]->_get('_enabled') ? $_[0] : undef }

##############################################################################

=item $ice = $ice->remove

Marks this input channel-element association to be removed. Call the
C<save()> method to remove the mapping from the database.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub remove { $_[0]->_set(['_del'], [1]) }

##############################################################################

=item $ice = $ice->save

Saves the input channel.

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
    # Save the enabled property.
    my ($icid, $eid, $map_id, $en, $del) =
      $self->_get(qw(id element_id _map_id _enabled _del));
    if ($del and $map_id) {
        # Delete it.
        my $del = prepare_c(qq{
            DELETE FROM element__input_channel
            WHERE  id = ?
        }, undef);
        execute($del, $map_id);
        $self->_set([qw(_map_id _del)], []);

    } elsif ($map_id) {
        # Update the existing value.
        my $upd = prepare_c(qq{
            UPDATE element__input_channel
            SET    input_channel__id = ?,
                   element__id = ?,
                   enabled = ?,
                   active = '1'
            WHERE  id = ?
        }, undef);
        execute($upd, $icid, $eid, $en, $map_id);

    } else {
        # Insert a new record.
        my $nextval = next_key('element__input_channel');
        my $ins = prepare_c(qq{
            INSERT INTO element__input_channel
                        (id, element__id, input_channel__id, enabled, active)
            VALUES ($nextval, ?, ?, ?, '1')
        }, undef);
        execute($ins, $eid, $icid, $en);
        $self->_set(['_map_id'], [last_key('element__input_channel')]);
    }
    return $self;
}

1;
__END__

=back

=head1 NOTES

NONE.

=head1 AUTHOR

David Wheeler <david@wheeler.net>

=head1 SEE ALSO

L<Bric::Biz::InputChannel|Bric::Biz::InputChannel>,
L<Bric::Biz::AssetType|Bric::Biz::AssetType>,

=cut
