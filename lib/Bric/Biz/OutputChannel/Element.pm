package Bric::Biz::OutputChannel::Element;

#############################################################################

=head1 Name

Bric::Biz::OutputChannel::Element - Maps Output Channels to Element Types.

=cut

require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

  use Bric::Biz::OutputChannel::Element;

  # Constructors.
  my $oce = Bric::Biz::OutputChannel->new($init);
  my $oces_href = Bric::Biz::OutputChannel->href($params);

  # Instance methods.
  my $element_type_id = $oce->get_element_type_id;
  $oce->set_element_type_id($element_type_id);
  $oce->set_enabled_on;
  $oce->set_enabled_off;
  if ($oce->is_enabled) { } # do stuff.
  $oce->save;

=head1 Description

This subclass of Bric::Biz::OutputChannel manages the relationship between
output channels and elements (Bric::Biz::ElementType objects). It does so by
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
use base qw(Bric::Biz::OutputChannel);

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
my $SEL_COLS = Bric::Biz::OutputChannel::SEL_COLS() .
  ', eoc.id, eoc.element_type__id, eoc.enabled';
my @SEL_PROPS = (Bric::Biz::OutputChannel::SEL_PROPS(),
                 qw(_map_id element_type_id _enabled));

# Grabbed knowledge from parent, but the outer join depends on it. :-(
my $SEL_TABLES = 'output_channel oc LEFT OUTER JOIN ' .
  'element_type__output_channel eoc ON (oc.id = eoc.output_channel__id), ' .
  'member m, output_channel_member sm';

sub SEL_PROPS { @SEL_PROPS }
sub SEL_COLS { $SEL_COLS }
sub SEL_TABLES { $SEL_TABLES }

##############################################################################
# Instance Fields
BEGIN {
    Bric::register_fields({
        element_type_id => Bric::FIELD_RDWR,
        _enabled        => Bric::FIELD_NONE,
        _map_id         => Bric::FIELD_NONE,
    });
}

##############################################################################
# Class Methods
##############################################################################

=head1 Interface

This class inherits the majority of its interface from
L<Bric::Biz::OutputChannel|Bric::Biz::OutputChannel>. Only additional methods
are documented here.

=head2 Constructors

=over 4

=item my $oce = Bric::Biz::OutputChannel::Element->new($init);

Constructs a new Bric::Biz::OutputChannel::Element object intialized with the
values in the C<$init> hash reference and returns it. The suported values for
the C<$init> hash reference are the same as those supported by
C<< Bric::Biz::OutputChannel::Element->new >>, with the addition of the
following:

=over 4

=item C<oc_id>

The ID of the output channel object on which the new
Bric::Biz::OutputChannel::Element will be based. The relevant
Bric::Biz::OutputChannel object will be looked up from the database. Note that
all of the C<$init> parameters documented in
L<Bric::Biz::OutputChannel|Bric::Biz::OutputChannel> will be ignored if this
parameter is passed.

=item C<oc>

The output channel object on which the new Bric::Biz::OutputChannel::Element
will be based. Note that all of the C<$init> parameters documented in
L<Bric::Biz::OutputChannel|Bric::Biz::OutputChannel> will be ignored if this
parameter is passed.

=item C<element_type_id>

The ID of the Bric::Biz::ElementType object to which this output channel is
mapped.

=item C<enabled>

A boolean value indicating whether the output channel will have assets output
to it by default.

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

B<Side Effects:> If you pass in an output channel object via the C<oc>
parameter, that output channel object will be converted into a
Bric::Biz::OutputChannel::Element object.

B<Notes:> NONE.

=cut

sub new {
    my ($pkg, $init) = @_;
    my $en = ! exists $init->{enabled} ? 1 : delete $init->{enabled} ? 1 : 0;
    my $eid = delete $init->{element_type_id} || delete $init->{element_id};
    my ($oc, $ocid) = delete @{$init}{qw(oc oc_id)};
    my $self;
    if ($oc) {
        # Rebless the existing output channel object.
        $self = bless $oc, ref $pkg || $pkg;
    } elsif ($ocid) {
        # Lookup the existing output channel object.
        $self = $pkg->lookup({ id => $ocid });
    } else {
        # Construct a new output channel object.
        $self = $pkg->SUPER::new($init);
    }
    # Set the necessary properties and return.
    $self->_set([qw(_enabled element_type_id _map_id)], [$en, $eid, undef]);
    # New relationships should always trigger a save.
    $self->_set__dirty(1);
}

##############################################################################

=item my $oce_href = Bric::Biz::OutputChannel::Element->href({ element_type_id => $eid });

Returns a hash reference of Bric::Biz::OutputChannel::Element objects. Each
hash key is a Bric::Biz::OutputChannel::Element ID, and the values are the
corresponding Bric::Biz::OutputChannel::Element objects. Only a single
parameter argument is allowed, C<element_type_id>, though C<ANY> may be used
to specify a list of element type IDs. All of the output channels associated
with that element type ID will be returned.

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
    $p->{element_type_id} = delete $p->{element_id} if exists $p->{element_id};
    my $class = ref $pkg || $pkg;

    # XXX Really there's too much going on here getting information from
    # the parent class. Perhaps one day we'll have a SQL factory class to
    # handle all this stuff, but this will have to do for now.
    my $ord = $pkg->SEL_ORDER;
    my $cols = $pkg->SEL_COLS;
    my $tables = $pkg->SEL_TABLES;
    my @params;
    my $wheres = $pkg->SEL_WHERES
               . ' AND oc.id = eoc.output_channel__id AND '
               . any_where $p->{element_type_id}, 'eoc.element_type__id = ?', \@params;
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

=item my $eid = $oce->get_element_type_id

Returns the ID of the Element Type definition with which this output channel
is associated.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $oce = $oce->set_element_type_id($eid)

Sets the ID of the Element type definition with which this output channel is
associated.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_element_id { shift->get_element_type_id     }
sub set_element_id { shift->set_element_type_id(@_) }

##############################################################################

=item $oce = $oce->set_enabled_on

Enables this output channel to have assets ouptut to it by default.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub set_enabled_on { $_[0]->_set(['_enabled'], [1]) }

##############################################################################

=item $oce = $oce->set_enabled_off

Sets this output channel to not have assets ouptut to it by default.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub set_enabled_off { $_[0]->_set(['_enabled'], [0]) }

##############################################################################

=item $oce = $oce->is_enabled

Returns true if the this output channel is set to have assets output to it by
default, and false if it is not.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub is_enabled { $_[0]->_get('_enabled') ? $_[0] : undef }

##############################################################################

=item $oce = $oce->remove

Marks this output channel-element type association to be removed. Call the
C<save()> method to remove the mapping from the database.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub remove { $_[0]->_set(['_del'], [1]) }

##############################################################################

=item $oce = $oce->save

Saves the output channel.

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
    my ($ocid, $eid, $map_id, $en, $del) =
      $self->_get(qw(id element_type_id _map_id _enabled _del));
    if ($del and $map_id) {
        # Delete it.
        my $del = prepare_c(qq{
            DELETE FROM element_type__output_channel
            WHERE  id = ?
        }, undef);
        execute($del, $map_id);
        $self->_set([qw(_map_id _del)], []);

    } elsif ($map_id) {
        # Update the existing value.
        my $upd = prepare_c(qq{
            UPDATE element_type__output_channel
            SET    output_channel__id = ?,
                   element_type__id = ?,
                   enabled = ?,
                   active = '1'
            WHERE  id = ?
        }, undef);
        execute($upd, $ocid, $eid, $en, $map_id);

    } else {
        # Insert a new record.
        my $nextval = next_key('element_type__output_channel');
        my $ins = prepare_c(qq{
            INSERT INTO element_type__output_channel
                        (id, element_type__id, output_channel__id, enabled, active)
            VALUES ($nextval, ?, ?, ?, '1')
        }, undef);
        execute($ins, $eid, $ocid, $en);
        $self->_set(['_map_id'], [last_key('element_type__output_channel')]);
    }
    return $self;
}

1;
__END__

=back

=head1 Notes

NONE.

=head1 Author

David Wheeler <david@justatheory.com>

=head1 See Also

L<Bric::Biz::OutputChannel|Bric::Biz::OutputChannel>,
L<Bric::Biz::ElementType|Bric::Biz::ElementType>,

=cut
