package Bric::Biz::Asset::Business;
###############################################################################

=head1 NAME

Bric::Biz::Asset::Business - An object that houses the business Assets

=head1 VERSION

$LastChangedRevision$

=cut

require Bric; our $VERSION = Bric->VERSION;

=head1 DATE

$LastChangedDate$

=head1 SYNOPSIS

 # Constructor
 $biz = Bric::Biz::Asset::Business->new($param);
 # DB object looukp
 $biz = Bric::Biz::Asset::Business->lookup({'id' => $biz_id});

 # Getting a list of objects
 ($biz_asset_list||@biz_assets) = Bric::Biz::Asset::Business->list( $criteria )

 # Geting a list of ids
 ($biz_ids || @biz_ids) = Bric::Biz::Asset::Business->list_ids( $criteria )


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
 $alias_id    = $asset->get_alias_id()
 $asset       = $asset->set_alias_id($alias_id)

 # User information
 $usr_id      = $asset->get_user__id()
 $modifier    = $asset->get_modifier()

 # Version information
 $vers        = $asset->get_version();
 $vers_id     = $asset->get_instance_id();
 $current     = $asset->get_current_version();
 $checked_out = $asset->get_checked_out()

 # Expire Data Information
 $asset       = $asset->set_expire_date($date)
 $expire_date = $asset->get_expire_date()

 # Desk information
 $desk        = $asset->get_current_desk;
 $asset       = $asset->set_current_desk($desk);

 # Workflow methods.
 $id    = $asset->get_workflow_id;
 $obj   = $asset->get_workflow_object;
 $asset = $asset->set_workflow_id($id);

 # Output channel associations.
 my @ocs = $asset->get_output_channels;
 $asset->add_output_channels(@ocs);
 $asset->del_output_channels(@ocs);

 # Input channel associations.
 my @ics = $asset->get_input_channels;
 $asset->add_input_channels(@ics);
 $asset->del_input_channels(@ics);

 # Access note information
 $asset         = $asset->set_note($note);
 my $note       = $asset->get_note;
 my $notes_href = $asset->get_notes()

 # Access active status
 $asset            = $asset->deactivate()
 $asset            = $asset->activate()
 ($asset || undef) = $asset->is_active()

 $asset = $asset->save()

 # returns all the groups this is a member of
 ($grps || @grps) = $asset->get_grp_ids()


=head1 DESCRIPTION

This is the parent class for all the documents, including
L<stories|Bric::Biz::Asset::Business::Story> and L<media
documents|Bric::Biz::Asset::Business::Media>. It inherits from
Bric::Biz::Asset.

Assumption here is that all Business assets have rights, publish dates
and keywords associated with them.

This class contains all the interfact to these data points

=cut

#==============================================================================#
# Dependencies                         #
#======================================#

#--------------------------------------#
# Standard Dependencies

use strict;

#--------------------------------------#
# Programatic Dependencies

use Bric::Config qw(:mod_perl);
use Bric::Util::Coll::Instance;
use Bric::Util::DBI qw(:all);
use Bric::Util::Time qw(:all);
use Bric::Util::Fault qw(:all);
use Bric::Util::Grp::AssetVersion;
use Bric::Util::Grp::AssetLanguage;
use Bric::Biz::Category;
use Bric::Biz::OutputChannel qw(:case_constants);
use Bric::Biz::Org::Source;
use Bric::Util::Coll::OutputChannel;
use Bric::Util::Coll::Keyword;
use Bric::Util::Pref;
use Data::UUID;

#=============================================================================#
# Inheritance                          #
#======================================#

use base qw( Bric::Biz::Asset );

#============================================================================+
# Function Prototypes                  #
#======================================#
my ($get_oc_coll, $get_ic_coll, $get_instance_coll, $get_kw_coll);

#=============================================================================#
# Constants                            #
#======================================#

use constant DEBUG => 0;

#=============================================================================#
# Fields                               #
#======================================#

#--------------------------------------#
# Public Class Fields

# None

#--------------------------------------#
# Private Class Fields
my $meths;
my @ord;
my $ug = Data::UUID->new;

my %uri_format_hash = ( 'categories' => '',
                        'day'        => '%d',
                        'month'      => '%m',
                        'slug'       => '',
                        'year'       => '%Y' );
#--------------------------------------#
# Instance Fields

BEGIN {
        Bric::register_fields
            ({
              # Public Fields
              uuid                      => Bric::FIELD_READ,
              source__id                => Bric::FIELD_RDWR,
              element__id               => Bric::FIELD_RDWR,
              related_grp__id           => Bric::FIELD_READ,
              primary_uri               => Bric::FIELD_READ,
              publish_date              => Bric::FIELD_RDWR,
              first_publish_date        => Bric::FIELD_RDWR,
              cover_date                => Bric::FIELD_RDWR,
              publish_status            => Bric::FIELD_RDWR,
              primary_oc_id             => Bric::FIELD_RDWR,
              primary_ic_id             => Bric::FIELD_RDWR,
              input_channel_context     => Bric::FIELD_RDWR,
              alias_id                  => Bric::FIELD_READ,

              # Private Fields
              _contributors             => Bric::FIELD_NONE,
              _queried_contrib          => Bric::FIELD_NONE,
              _del_contrib              => Bric::FIELD_NONE,
              _update_contributors      => Bric::FIELD_NONE,
              _related_grp_obj          => Bric::FIELD_NONE,
              _tile                     => Bric::FIELD_NONE,
              _queried_cats             => Bric::FIELD_NONE,
              _categories               => Bric::FIELD_NONE,
              _del_categories           => Bric::FIELD_NONE,
              _new_categories           => Bric::FIELD_NONE,
              _oc_coll                  => Bric::FIELD_NONE,
              _ic_coll                  => Bric::FIELD_NONE,
              _instance_coll            => Bric::FIELD_NONE,
              _kw_coll                  => Bric::FIELD_NONE,
              _alias_obj                => Bric::FIELD_NONE,
              _update_uri               => Bric::FIELD_NONE,
            });
    }

#=============================================================================#

=head1 INTERFACE

=head2 Constructors

=over 4

=cut

#--------------------------------------#
# Constructors

#-----------------------------------------------------------------------------#

=item $asset = Bric::Biz::Asset::Business->new( $initial_state )

new will only be called by Bric::Biz::Asset::Business's inherited classes

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub new {
    my ($self, $init) = @_;
    $self = bless {}, $self unless ref $self;
    $self->_init($init);
    $self->SUPER::new($init);
}

###############################################################################


#--------------------------------------#

=back

=head2 Destructors

=over 4

=item $self->DESTROY

Dummy method to prevent wasting time trying to AUTOLOAD DESTROY.

=cut

sub DESTROY {
        # This method should be here even if its empty so that we don't waste time
        # making Bricolage's autoload method try to find it.
}

###############################################################################

=item my $key_name = Bric::Biz::Asset::Business->key_name()

Returns the key name of this class.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub key_name { 'biz' }

################################################################################

=item $meths = Bric::Biz::Asset::Business->my_meths

=item (@meths || $meths_aref) = Bric::Biz::Asset::Business->my_meths(TRUE)

=item my (@meths || $meths_aref) = Bric::Biz:::Asset::Business->my_meths(0, TRUE)

Returns an anonymous hash of introspection data for this object. If called
with a true argument, it will return an ordered list or anonymous array of
introspection data. If a second true argument is passed instead of a first,
then a list or anonymous array of introspection data will be returned for
properties that uniquely identify an object (excluding C<id>, which is
assumed).

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

=item type

The display field type. Possible values are

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

=item *

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
    my ($pkg, $ord, $ident) = @_;
    return if $ident;

    # Return 'em if we got em.
    return !$ord ? $meths : wantarray ? @{$meths}{@ord} : [@{$meths}{@ord}]
      if $meths;

    # We don't got 'em. So get 'em!
    foreach my $meth (__PACKAGE__->SUPER::my_meths(1)) {
        $meths->{$meth->{name}} = $meth;
        push @ord, $meth->{name};
        push (@ord, 'title') if $meth->{name} eq 'name';
    }
    push @ord, qw(source_id source first_publish_date publish_date), pop @ord;

    $meths->{uuid} =         {
                              name     => 'uuid',
                              get_meth => sub { shift->get_uuid(@_) },
                              get_args => [],
                              disp     => 'UUID',
                              len      => 10,
                              type     => 'short',
                             };
    $meths->{source_id} =    {
                              name     => 'source_id',
                              get_meth => sub { shift->get_source__id(@_) },
                              get_args => [],
                              set_meth => sub { shift->set_source__id(@_) },
                              set_args => [],
                              disp     => 'Source ID',
                              len      => 1,
                              req      => 1,
                              type     => 'short',
                             };
    $meths->{source} =       {
                              name     => 'source',
                              get_meth => sub { Bric::Biz::Org::Source->lookup({
                                                  id => shift->get_source__id(@_) })
                                          },
                              get_args => [],
                              disp     => 'Source',
                              len      => 1,
                              type     => 'short',
                             };
    $meths->{publish_date} = {
                              name     => 'publish_date',
                              get_meth => sub { shift->get_publish_date(@_) },
                              get_args => [],
                              set_meth => sub { shift->set_publish_date(@_) },
                              set_args => [],
                              disp     => 'Last Publish Date',
                              len      => 64,
                              req      => 0,
                              type     => 'short',
                              props    => { type => 'date' }
                             };
    $meths->{first_publish_date} = {
                              name     => 'first_publish_date',
                              get_meth => sub { shift->get_first_publish_date(@_) },
                              get_args => [],
                              set_meth => sub { shift->set_first_publish_date(@_) },
                              set_args => [],
                              disp     => 'First Publish Date',
                              len      => 64,
                              req      => 0,
                              type     => 'short',
                              props    => { type => 'date' }
                             };
    $meths->{alias_id}     = {
                              name     => 'alias_id',
                              get_meth => sub { shift->get_alias_id },
                              get_args => [],
                              disp     => 'Alias',
                              len      => 10,
                              type     => 'short',
                             };
    # Copy the data for the title from name.
    $meths->{title} = { %{ $meths->{name} } };
    $meths->{title}{name} = 'title';
    $meths->{title}{disp} = 'Title';

    return !$ord ? $meths : wantarray ? @{$meths}{@ord} : [@{$meths}{@ord}];
}

###############################################################################

=back

=head2 Public Instance Methods

=over 4

=item $uuid = $asset->get_uuid

=item $uuid = $asset->get_uuid_bin

=item $uuid = $asset->get_uuid_hex

=item $uuid = $asset->get_uuid_base64

These methods the UUID field for this document. C<get_uuid> returns the string
representation of the UUID, such as "7713585E-0501-11DA-B4F2-BC394F2854A1".
This is the form of the UUID stored in the database. C<get_uuid_bin()> returns
the binary representation of the UUID. C<get_uuid_hex()> returns the UUID as a
hex string. C<get_uuid_base64()> returns the base64-encoded representation of
the UUID.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_uuid_bin    { $ug->from_string(  shift->get_uuid     ) }
sub get_uuid_hex    { $ug->to_hexstring( shift->get_uuid_bin ) }
sub get_uuid_base64 { $ug->to_b64string( shift->get_uuid_bin ) }

=item $title = $asset->get_title()

Returns the title field for this asset

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

title is the same as the name field

=cut

sub get_title { $_[0]->_get('name') }

################################################################################

=item $asset = $asset->set_title($title)

sets the title for this asset

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

title is the same as the name field

=cut

sub set_title { $_[0]->_set(['name'] => [$_[1]]) }

################################################################################

=item $alias_id = $biz->get_alias_id()

Returns the alias id from this business asset

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

################################################################################

=item $biz = $biz->set_source__id($s_id)

Sets the source id upon this story

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

################################################################################

=item $source = $biz->get_source__id()

Returns the source id from this business asset

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

################################################################################

=item $at_id = $biz->get_element__id()

Returns the asset type id that this story is associated with

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

################################################################################

=item $biz = $biz->set_element__id($at_id)

Sets the asset type id that this story is associated with.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub set_element__id {
    my ($self, $eid) = @_;
    my $old_eid = $self->_get('element__id');
    return $self if $eid == $old_eid;
    my $oc_coll = $get_oc_coll->($self);
    $oc_coll->del_objs($oc_coll->get_objs);
    my $elem = Bric::Biz::AssetType->lookup({ id => $eid });
    $oc_coll->add_new_objs( map { $_->is_enabled ? $_ : () }
                            $elem->get_output_channels );
    my $ic_coll = $get_ic_coll->($self);
    $ic_coll->del_objs($ic_coll->get_objs);
    $ic_coll->add_new_objs( map { $_->is_enabled ? $_ : () }
                            $elem->get_input_channels );
    $self->_set([qw(element__id element)], [$eid, $elem]);
}

##############################################################################

=item my $primary_oc_id = $p->get_primary_oc_id

Returns the asset's primary output channel ID.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $oc = $p->get_primary_oc

Returns the primary output channel object.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_primary_oc {
    my $self = shift;
    my $pocid = $self->get_primary_oc_id;
    my ($oc) = $self->get_output_channels($pocid);
    unless ($oc) {
        # Must be a new media. Go through the OCs till we find the primary.
        foreach ($self->get_output_channels) {
            next unless $_->get_id == $pocid;
            $oc = $_;
            last;
        }
    }
    return $oc;
}

=item $self = $p->set_primary_oc_id($primary_oc_id)

Sets the asset's primary output channel ID.

B<Throws:> NONE.

B<Side Effects:> The URIs for the asset will be changed.

B<Notes:> NONE.

=cut

################################################################################

=item my $primary_ic_id = $p->get_primary_ic_id

Returns the asset's primary input channel ID.

=item my $ic = $p->get_primary_ic

Returns the primary input channel object.

=cut

sub get_primary_ic {
    my $self = shift;
    my $picid = $self->get_primary_ic_id;
    my ($ic) = $self->get_input_channels($picid);
    unless ($ic) {
        # Must be a new media. Go through the ICs till we find the primary.
        foreach ($self->get_input_channels) {
            next unless $_->get_id == $picid;
            $ic = $_;
            last;
        }
    }
    return $ic;
}

=item $self = $p->set_primary_ic_id($primary_ic_id)

Sets the asset's primary input channel ID.

B<Side Effects:> The URIs for the asset will be changed.

=cut

################################################################################

=item $biz->add_contributor($contrib, $role );

Takes a contributor object or id and their role in the context of this story
and associates them

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub add_contributor {
    my ($self, $contrib, $role) = @_;
    my $dirty = $self->_get__dirty();
    my $contribs = $self->_get_contributors() || {};

    # get the contributor id
    my $c_id = ref $contrib ? $contrib->get_id() : $contrib;
    my $place = scalar keys %$contribs;
    if (exists $contribs->{$c_id}) {
        # already a contrib, update role if need be
        $contribs->{$c_id}->{'role'} = $role;
        $contribs->{$c_id}->{'obj'} = ref $contrib ? $contrib : undef;
        unless ($contribs->{$c_id}->{'action'} &&
                $contribs->{$c_id}->{'action'} eq 'insert') {
            $contribs->{$c_id}->{'action'} = 'update';
        }
    } else {
        $contribs->{$c_id}->{'role'} = $role;
        $contribs->{$c_id}->{'obj'} = ref $contrib ? $contrib : undef;
        $contribs->{$c_id}->{'place'} = $place;
        $contribs->{$c_id}->{'action'} = 'insert';
    }

    $self->_set({
                 '_contributors' => $contribs,
                 '_update_contributors' => 1
                });

    $self->_set__dirty($dirty);
    return $self;
}

sub _get_alias {
    my $self = shift;
    my ($alias_id, $alias_obj) = $self->_get(qw(alias_id _alias_obj));
    return unless $alias_id;
    unless ($alias_obj) {
        $alias_obj = ref($self)->lookup({ id => $alias_id });
        $self->_set(['_alias_obj'] => [$alias_obj]);
    }
    return $alias_obj;
}

=item ($contribs || @contribs) = $story->get_contributors()

Returns a list or list ref of the contributors that have been assigned
to this story

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_contributors {
    my $self = shift;

    if (my $alias_obj = $self->_get_alias) {
        return $alias_obj->get_contributors;
    }

    my $contribs = $self->_get_contributors;

    my @ret;
    foreach my $id (sort { $contribs->{$a}->{place} <=>
                           $contribs->{$b}->{place} }
                    keys %$contribs) {
        $contribs->{$id}->{obj} ||=
          Bric::Util::Grp::Parts::Member::Contrib->lookup({ id => $id });
        push @ret, $contribs->{$id}->{obj};
    }
    return wantarray ? @ret : \@ret;
}

################################################################################

=item $role = $biz->get_contributor_role($contrib)

Returns the role played by this contributor

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_contributor_role {
    my $self = shift;
    my ($contrib) = @_;
    my $c_id = ref $contrib ? $contrib->get_id : $contrib;
    my $contribs = $self->_get_contributors;

    return unless exists $contribs->{$c_id};
    return $contribs->{$c_id}->{'role'};
}

################################################################################

=item $story = $story->delete_contributors( $contributors )

Recieves a list of contributrs or their ids and deletes them from the story

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub delete_contributors {
    my ($self, $contributors) = @_;
    my $dirty = $self->_get__dirty();
    my $contribs = $self->_get_contributors();
    my $delete = $self->_get('_del_contrib');

    foreach (@$contributors) {
        my $id = ref $_ ? $_->get_id : $_;
        if ($contribs->{$id}->{'action'}
            && $contribs->{$id}->{'action'} eq 'insert') {
            delete $contribs->{$id};
        } else {
            $delete->{$id} = delete $contribs->{$id};
        }
    }

    # update the order fields for the remaining contribs
    my $i = 0;
    foreach (keys %$contribs) {
        if ($contribs->{$_}->{'place'} != $i) {
            $contribs->{$_}->{'place'} = $i;
            $contribs->{$_}->{action} ||= 'update';
        }
        $i++;
    }

    $self->_set( {
                  _contributors         => $contribs,
                  _update_contributors  => 1,
                  _del_contrib                  => $delete
                 });

    $self->_set__dirty($dirty);
    return $self;
}

=item $asset = $asset->reorder_contributors(@contributors)

Takes a list of ids and sets the new order upon them

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub reorder_contributors {
    my $self = shift;
    my @new_order = @_;
    my $dirty = $self->_get__dirty();
    my $existing = $self->_get_contributors();

    if ((scalar @new_order) != (scalar (keys %$existing))) {
        throw_gen 'Improper Args to reorder contributors';
    }

    my $i = 0;
    foreach (@new_order) {
        if (exists $existing->{$_}) {
            unless ($existing->{$_}->{'place'} == $i) {
                $existing->{$_}->{'place'} = $i;
                $existing->{$_}->{'action'} = 'update' 
                  unless $existing->{$_}->{'action'} eq 'insert';
            }
                        $i++;
        } else {
            throw_gen 'Improper Args to reorder contributors';
        }
    }

    $self->_set( { '_contributors' => $existing });
    $self->_set__dirty($dirty);
    return $self;
}

################################################################################

=item my @ocs = $biz->get_output_channels

=item my $ocs_aref = $biz->get_output_channels

=item my @ocs = $biz->get_output_channels(@oc_ids)

=item my $ocs_aref = $biz->get_output_channels(@oc_ids)

Returns a list or anonymous array of the output channels the business asset
will be output to when it is published. If C<@oc_ids> is passed, then only the
output channels with those IDs are returned, if they're associated with this
asset.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

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

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_output_channels { $get_oc_coll->(shift)->get_objs(@_) }

##############################################################################

=item $ba = $ba->add_output_channels(@ocs)

Adds output channels to the list of output channels to which this story will
be output upon publication.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

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

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub add_output_channels {
    my $self = shift;
    return unless @_;
    my $oc_coll = $get_oc_coll->($self);
    $oc_coll->add_new_objs(@_);
    $self->_set(['_update_uri'] => [1]);
}

##############################################################################

=item $biz = $biz->del_output_channels(@ocs)

=item $biz = $biz->del_output_channels(@oc_ids)

Removes output channels from this asset, so that it won't be output to these
output channels when it is published.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

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

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub del_output_channels {
    my $self = shift;
    return unless @_;
    my $oc_coll = $get_oc_coll->($self);
    $oc_coll->del_objs(@_);
    $self->_set(['_update_uri'] => [1]);
}

################################################################################

=item my @ics = $biz->get_instances

=item my $ics_aref = $biz->get_instances

=item my @ics = $biz->get_instances(@instance_ids)

=item my $ics_aref = $biz->get_instances(@instance_ids)

Returns a list or anonymous array of the input channels the business asset
is able to be edited in. If C<@ic_ids> is passed, then only the
input channels with those IDs are returned, if they're associated with this
asset.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

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

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_instances { $get_instance_coll->(shift)->get_objs(@_) }

##############################################################################

=item $ba = $ba->add_instances(@ics)

Adds instances to the list of instances associated with this asset

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

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

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub add_instances {
    my $self = shift;
    my @objs = @_;
    return unless @objs;
    my $instance_coll = $get_instance_coll->($self);
    $instance_coll->add_new_objs(@objs);
}

##############################################################################

=item $biz = $biz->del_instances(@insts)

=item $biz = $biz->del_instances(@inst_ids)

Removes instances from this asset

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

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

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub del_instances {
    my $self = shift;
    return unless @_;
    my $instance_coll = $get_instance_coll->($self);
    $instance_coll->del_objs(@_);
    $self->_set(['_update_uri'] => [1]);
}

################################################################################

=item my @ics = $biz->get_input_channels

=item my $ics_aref = $biz->get_input_channels

=item my @ics = $biz->get_input_channels(@ic_ids)

=item my $ics_aref = $biz->get_input_channels(@ic_ids)

Returns a list or anonymous array of the input channels the business asset
is able to be edited in. If C<@ic_ids> is passed, then only the
input channels with those IDs are returned, if they're associated with this
asset.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

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

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_input_channels { $get_ic_coll->(shift)->get_objs(@_) }

##############################################################################

=item $ba = $ba->add_input_channels(@ics)

Adds input channels to the list of input channels associated with this asset

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

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

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub add_input_channels {
    my $self = shift;
    my @objs = @_;
    return unless @objs;
    my $ic_coll = $get_ic_coll->($self);
    $ic_coll->add_new_objs(@objs);
    
    map { $self->_create_instance($_) } @objs;
    
    $self->_set(['_update_uri'] => [1]);
}

##############################################################################

=item $biz = $biz->del_input_channels(@ics)

=item $biz = $biz->del_input_channels(@ic_ids)

Removes input channels from this asset

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

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

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub del_input_channels {
    my $self = shift;
    return unless @_;
    my $ic_coll = $get_ic_coll->($self);
    $ic_coll->del_objs(@_);
    $self->_set(['_update_uri'] => [1]);
}

################################################################################

=item $story = $story->set_name($name);

Sets the name for this asset

=cut

sub set_name { shift->get_instance->set_name(@_); }

################################################################################

=item $name = $story->get_name;

Gets the name for this asset

=cut

sub get_name { shift->get_instance->get_name; }

################################################################################

=item get_element_name()

Returns the name of the asset type that this is based on. This is the same as
the name of the top level tile.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_element_name {
    my $self = shift;
    $self->get_tile->get_name;
}

################################################################################

=item get_element_key_name()

Returns the key name of the asset type that this is based on. This is the same
as the key name of the top level tile.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_element_key_name {
    my $self = shift;
    $self->get_tile->get_key_name;
}

################################################################################

=item (@parts || $parts) = $biz->get_possible_data()

Returns the possible data that can be added to the top level tile of this
business asset based upon rules defined in asset type

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_possible_data {
        my ($self) = @_;

        my $tile = $self->get_tile();

        my $parts = $tile->get_possible_data();

        return wantarray ? @$parts : $parts;
}

################################################################################

=item (@containers || $containers) = $biz->get_possible_containers()

Returns the containers that are possible to add to the top level container
of this businesss asset

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_possible_containers {
    my ($self) = @_;
    my $tile = $self->get_tile();
    my $cont = $tile->get_possible_containers();
    return wantarray ? @$cont : $cont;
}

################################################################################

=item $self = $story->set_cover_date($cover_date)

Sets the cover date.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=item *

Unable to unpack date.

=item *

Unable to format date.

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub set_cover_date {
    my $self = shift;
    my $cover_date = db_date(shift);
    my $old = $self->_get('cover_date');
    $self->_set([qw(cover_date _update_uri)] => [$cover_date, 1])
      if (not defined $cover_date && defined $old)
      || (defined $cover_date && not defined $old)
      || ($cover_date ne $old);
    # Update URI.
#    $self->get_uri;
    return $self;
}

################################################################################

=item my $cover_date = $story->get_cover_date($format)

Returns cover date.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=item *

Unable to unpack date.

=item *

Unable to format date.

=back

B<Side Effects:>

NONE

B<Notes:> 

NONE

=cut

sub get_cover_date { local_date($_[0]->_get('cover_date'), $_[1]) }

################################################################################

=item my $first_publish_date = $story->get_first_publish_date($format)

Returns the date the business asset was first published.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=item *

Unable to unpack date.

=item *

Unable to format date.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_first_publish_date { local_date($_[0]->_get('first_publish_date'), $_[1]) }

################################################################################

=item $self = $story->set_publish_date($publish_date)

Sets the publish date.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=item *

Unable to unpack date.

=item *

Unable to format date.

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:>

Also sets the first publish date if it hasn't been set before.

B<Notes:>

NONE

=cut

sub set_publish_date {
    my $self = shift;
    my $date = db_date(shift);
    if ($self->_get('first_publish_date')) {
        # It has been published before.
        $self->_set(['publish_date'], [$date]);
    } else {
        # First publish. Set both dates.
        $self->_set([qw(publish_date first_publish_date)], [$date, $date]);
    }
}

################################################################################

=item my $publish_date = $story->get_publish_date($format)

Returns publish date.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=item *

Unable to unpack date.

=item *

Unable to format date.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_publish_date { local_date($_[0]->_get('publish_date'), $_[1]) }

################################################################################

=item (@objs || $objs) = $asset->get_related_objects

Return all the related story or media objects for this business asset.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_related_objects {
    my $self = shift;

    return $self->_find_related($self->get_tile);
}

sub _find_related {
    my ($self, $tile) = @_;
    my @related;

    # Add this tile's related assets
    my $rmedia = $tile->get_related_media;
    my $rstory = $tile->get_related_story;
    push @related, $rmedia if $rmedia;
    push @related, $rstory if $rstory;

    # Check all the children for related assets.
    foreach my $c ($tile->get_containers) {
        push @related, $self->_find_related($c);
    }

    return wantarray ? @related : \@related if @related;
    return;
}

################################################################################

=item $element = $ba->get_element

 my $element = $ba->get_element;
 $element = $ba->get_tile; # Deprecated form.

Returns the top level element that contains content for this document.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_element { shift->get_instance->get_element(@_); }

sub get_tile { goto &get_element };

################################################################################

=item $element = $ba->get_instance

 my $element = $ba->get_instance($ic);

Returns the instance for the specified IC ID for this story version

=cut

sub get_instance {
    my ($self, $ic_id) = @_;
    $ic_id = $self->get_primary_ic_id unless $ic_id;
    foreach my $instance ($self->get_instances) {
        if ($instance->get_input_channel_id eq $ic_id) {
            return $instance;
        }
    }
}

################################################################################

=item $uri = $biz->get_primary_uri

Returns the primary URL for this business asset. The primary URL is determined
by the pre- and post- directory strings of the primary output channel, the
URI of the business object's asset type, and the cover date if the asset type
is not a fixed URL.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_primary_uri {
    my $self = shift;
    my $uri = $self->_get('primary_uri');

    unless ($uri) {
        $uri = $self->get_uri;
        $self->_set(['primary_uri'], [$uri]);
    }
    return $uri;
}

################################################################################

=item $bool = $biz->is_fixed

Returns a boolean value: true if the business asset has a fixed URL
(for example, a Cover), false otherwise.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub is_fixed {
    my $self = shift;
    my $element = $self->get_instance->get_element_object;
    return $element->get_fixed_url;
}

################################################################################

=item ($tiles || @tiles) = $biz->get_tiles()

Returns the tiles that are held with in the top level tile of this business
asset. Convenience shortcut to C<< $ba->get_tile->get_tiles >>.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_tiles {
    my $self = shift;
    $self->get_tile->get_tiles;
}

###############################################################################

=item $ba = $ba->add_data( $atd_obj, $data )

This will create a tile and add it to the container. Convenience shortcut to
C<< $ba->get_tile->add_data >>.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub add_data {
    my $self = shift;
    $self->get_tile->add_data(@_);
}

###############################################################################

=item $new_container = $ba->add_container( $atc_obj )

This will create and return a new container tile that is added to the current
container. Convenience shortcut to C<< $ba->get_tile->add_container >>.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub add_container {
    my $self = shift;
    $self->get_tile->add_container(@_);
}

###############################################################################

=item $data = $ba->get_data( $name, $obj_order )

=item $data = $ba->get_data( $name, $obj_order, $format )

Returns the data of a given name and object order. Convenience shortcut to
C<< $ba->get_tile->get_data >>.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

For data fields that can return multiple values, you currently have to parse
the data string like this:

   my $str = $element->get_data('blah');
   my @opts = split /__OPT__/, $str;

This behavior might be changed so that the string is automatically split for
you.

=cut

sub get_data {
    my $self = shift;
    $self->get_tile->get_data(@_);
}

###############################################################################

=item $container = $ba->get_container( $name, $obj_order )

Returns a container object of the given name that falls at the given object
order position. Convenience shortcut to C<< $ba->get_tile->get_container >>.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_container {
    my $self = shift;
    $self->get_tile->get_container(@_);
}

###############################################################################

=item $ba = $ba->add_keywords(@keywords);

=item $ba = $ba->add_keywords(\@keywords);

=item $ba = $ba->add_keywords(@keyword_ids);

=item $ba = $ba->add_keywords(\@keyword_ids);

Associates a each of the keyword in a list or array reference of keywords with
the business asset.

B<Throws:> NONE.

B<Side Effects:> NONE

B<Notes:> NONE

=cut

sub add_keywords {
    my $self = shift;
    my $kw_coll = &$get_kw_coll($self);
    $self->_set__dirty(1);
    $kw_coll->add_new_objs(ref $_[0] eq 'ARRAY' ? @{$_[0]} : @_);
}

###############################################################################

=item @keywords = $cat->get_keywords;

=item @keywords = $cat->get_keywords(@keyword_ids);

Returns a list of keyword objects associated with this business asset. If
passed a list of keyword IDs, it will return only those keyword objects.

B<Throws:> NONE

B<Side Effects:> NONE

B<Notes:> NONE

=cut

sub get_keywords {
    my $self = shift;
    my $kw_coll = &$get_kw_coll($self);
    $kw_coll->get_objs(@_);
}

###############################################################################

=item $kw_aref || @kws = $asset->get_all_keywords()

Returns an array ref or an array of keyword objects assigned to this Business
Asset and to its categories.

B<Throws:> NONE

B<Side Effects:> NONE

B<Notes:> NONE

=cut

sub get_all_keywords {
    my $self = shift;
    my %kw = map { $_->get_id => $_ } $self->get_keywords;
    my $cats = $self->_get('_categories');
    foreach my $cid (keys %$cats) {

        my $cat = $cats->{$cid}->{object};
        unless ($cat) {
            $cat = Bric::Biz::Category->lookup({ id => $cid });
            $cats->{$cid}->{object} = $cat;
        }

        foreach my $k ($cat->get_keywords) {
            $kw{$k->get_id} = $k;
        }
    }

    my @kw = sort { lc $a->get_sort_name cmp lc $b->get_sort_name }
      values %kw;

    return wantarray ? @kw : \@kw;
}

###############################################################################

=item $ba = $ba->del_keywords(@keywords);

=item $ba = $ba->del_keywords(\@keywords);

=item $ba = $ba->del_keywords(@keyword_ids);

=item $ba = $ba->del_keywords(\@keyword_ids);

Dissociates a list or array reference of keyword objects or IDs from the
business asset.

B<Throws:> NONE.

B<Side Effects:> NONE

B<Notes:> NONE

=cut

sub del_keywords {
    my $self = shift;
    my $kw_coll = &$get_kw_coll($self);
    $self->_set__dirty(1);
    $kw_coll->del_objs(ref $_[0] eq 'ARRAY' ? @{$_[0]} : @_);
}

###############################################################################


=item ($self || undef) = $ba->has_keyword($keyword)

Returns a keyword if the keyword object is associated with this asset.

B<Throws:> NONE.

B<Side Effects:> NONE

B<Notes:> Uses C<get_keywords()> internally.

=cut

sub has_keyword {
    my ($self, $kw) = @_;
    scalar($self->get_keywords($kw->get_id))->[0];
}

###############################################################################

=item $self = $self->cancel()

Called upon a checked out asset.   This unchecks it out.

XXX Actually, it deletes the asset! I don't think that's what we want. Don't
use this method!

B<Throws:>

"Cannot cancel a non checked out asset"

B<Side Effects:>

This will remove the coresponding object from the database

B<Notes:>

NONE

=cut

sub cancel {
    my $self = shift;

    # the user has decided to uncheck this out. this will result in a delete
    # from the data base of this row

    if ( not defined $self->_get('user_id')) {
        # this is not checked out, it can not be deleted
        throw_gen "Cannot cancel a non checked out asset";
    }
    $self->_set( { '_delete' => 1});
}

################################################################################

=item ($ba || undef) = $ba->is_current()

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

        return ($self->_get('current_version') == $self->_get('version'))
                ? $self : undef;
}

################################################################################

=item = $biz = $biz->checkout( { user__id => $user_id })

checks out the asset to the specified user

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
    throw_gen "Unable to checkout old_versions"
      unless $self->_get('version') == $self->_get('current_version');

    # Make sure that the object is not already checked out
    throw_gen "Already Checked Out" if defined $self->_get('user__id');

    throw_gen "Must be checked out to users"
      unless defined $param->{user__id};

    my $contribs = $self->_get_contributors;
    # clone contributors
    foreach (keys %$contribs ) {
        $contribs->{$_}->{action} = 'insert';
    }

    # Clone output channels.
    my $oc_coll = $get_oc_coll->($self);
    my @ocs = $oc_coll->get_objs;
    $oc_coll->del_objs(@ocs);
    $oc_coll->add_new_objs(@ocs);
    
    # Clone input channels
    my $ic_coll = $get_ic_coll->($self);
    my @ics = $ic_coll->get_objs;
    $ic_coll->del_objs(@ics);
    $ic_coll->add_new_objs(@ics);

    # Clone instances
    my $instance_coll = $get_instance_coll->($self);
    my @insts = $instance_coll->get_objs;
    $instance_coll->del_objs(@insts);
    @insts = map { $_->clone } @insts;
    $instance_coll->add_new_objs(@insts);


    $self->_set({ user__id => $param->{user__id},
                  modifier => $param->{user__id},
                  version_id => undef,
                  checked_out => 1 });
    $self->_set(['_update_contributors'] => [1]) if $contribs;
}

################################################################################

=item $ba = $ba->save()

Commits the changes to the database

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub save {
    my $self = shift;

    my ($related_obj, $tile, $oc_coll, $ic_coll, $ci, $co, $vid, $instance_coll, $kw_coll) =
      $self->_get(qw(_related_grp_obj _tile _oc_coll _ic_coll _checkin _checkout
                     version_id _instance_coll _kw_coll));

    if ($co) {
        foreach my $instance ($self->get_instances) {
            $instance->clone();
        }
        $self->_set(['_checkout'], []);
    }

    # Is this necessary? Seems kind of pointless. [David 2002-09-19]
    $self->_set(['_checkin'], []) if $ci;

    $related_obj->save if $related_obj;
    $self->_sync_contributors;
    $oc_coll->save($self->key_name => $vid) if $oc_coll;
    $ic_coll->save($self->key_name => $vid) if $ic_coll;
    $instance_coll->save($self->key_name => $vid) if $instance_coll;
    $kw_coll->save($self) if $kw_coll;   
    $self->SUPER::save;
}

################################################################################

=item $story_name = $story->check_uri;

=item $story_name = $story->check_uri($user_id);

Returns name of story that has clashing URI.

C<Notes:> This method has been deprecated. URI uniqueness is now checked by
C<save()>, so this method is no longer strictly necessary.

=cut

sub check_uri {
    my $self = shift;

    # Warn 'em.
    warn __PACKAGE__ . "->check_uri has been deprecated and will be" .
      " removed in a future version of Bricolage";

    my $id = $self->_get('id');
    my $key = $self->key_name;
    my @ocs = $self->get_output_channels;
    my %seen;
    my $sel = prepare_c(qq{
        SELECT $key\__id
        FROM   $key\_uri
        WHERE  $key\__id <> ?
               AND LOWER(uri) = ?});

    if ($key eq 'story') {
        for my $cat ($self->get_categories) {
            for my $oc (@ocs) {
                my $uri = lc $self->get_uri($cat, $oc);
                # Skip it if we've seen it before.
                next if $seen{$uri};
                if (my $ret = $self->_check_uri_table($sel, $id, $uri)) {
                    return $ret;
                }
                $seen{$uri} = 1;
            }
        }
    } else {
        for my $oc (@ocs) {
            my $uri = lc $self->get_uri($oc);
            # Skip it if we've seen it before.
            next if $seen{$uri};
            if (my $ret = $self->_check_uri_table($sel, $id, $uri)) {
                return $ret;
            }
            $seen{$uri} = 1;
        }
    }
}

sub _check_uri_table {
    my ($self, $sel, $id, $uri) = @_;
    # Make it so.
    execute($sel, $id, $uri);
    my $sid;
    bind_columns($sel, \$sid);
    if (fetch($sel)) {
        finish($sel);
        return $self->lookup({ id => $sid })->get_title;
    }
}


###############################################################################

=item $at_obj = $self->get_element_object()

Returns the asset type object that coresponds to this business object

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_element_object { shift->get_instance->get_element_object(@_); }

###############################################################################

#=============================================================================#

=back

=head2 PRIVATE

=cut

#--------------------------------------#

=head2 Private Class Methods

=over 4

=item $self = $self->_init()

Preforms functions needed to create new business assets

B<Throws:>

=over 4

=item *

Cannot create an asset without an element or alias ID.

=item *

Cannot create an asset with both an element and an alias ID.

=item *

Cannot create an asset without a site.

=item *

Cannot create an alias to an asset in the same site.

=item *

Cannot create an alias to an alias.

=item *

Cannot create an alias to an asset based on an element that is not associated
with this site.

=back

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _init {
    my ($self, $init) = @_;
    my $class = ref $self or throw_mni "Method not implemented";
    $self->_set(['uuid'] => [$ug->create_str]);

    throw_dp "Cannot create an asset without an element or alias ID"
      unless $init->{element__id} || $init->{element} || $init->{alias_id};

    throw_dp "Cannot create an asset with both an element and an alias ID"
      if ($init->{element__id} || $init->{element}) && $init->{alias_id};

    throw_dp "Cannot create an asset without a site" unless $init->{site_id};

    if ($init->{alias_id}) {
        my $alias_target = $class->lookup({ id => $init->{alias_id} });
        
        throw_dp "Cannot create an alias to an alias"
          if $alias_target->get_alias_id;

        # Re-bless the alias into the same class as the aliased.
        bless $self, ref $alias_target;

        $self->_set([qw(alias_id _alias_obj)],
                    [$init->{alias_id}, $alias_target]);

        my $at = $alias_target->get_element_object;
        my $at_exists = 0;
        foreach my $site (@{$at->get_sites}) {
            if ($site->get_id == $init->{site_id}) {
                $at_exists++;
                last;
            }
        }

        throw_dp "Cannot create an alias to an asset based on an " .
            "element that is not associated with this site"
          unless $at_exists;
        
        $self->_set({ element__id => $alias_target->_get('element__id') });

        $self->set_source__id( $alias_target->get_source__id );
        $self->_set(['cover_date'], [$alias_target->_get('cover_date')]);

        $self->add_output_channels(
            grep { $_->is_enabled && $_->get_site_id == $init->{site_id} }
              $at->get_output_channels
        );

        $self->set_primary_oc_id($at->get_primary_oc_id($init->{site_id}));

        throw_dp "Cannot create an alias to this asset because this element ".
          "has no output channels associated with this site"
          unless @{$self->get_output_channels};
          
          
        my $ic_coll = $get_ic_coll->($self);
        $ic_coll->add_new_objs(grep { $_->is_enabled && $_->get_site_id == $init->{site_id} }
                                    $at->get_input_channels);

        $self->set_primary_ic_id($at->get_primary_ic_id($init->{site_id}));

        throw_dp "Cannot create an alias to this asset because this element ".
          "has no input channels associated with this site"
          unless @{$self->get_input_channels};

        $self->add_instances($alias_target->get_instances);
        
use Data::Dumper;
print STDERR "Instances: " . Dumper($alias_target->get_instances) . "\n\n";

        $self->_set
          ([qw(current_version publish_status modifier
               checked_out     version site_id
               grp_ids)
           ] =>
           [   0,              0,             $init->{user__id},
               1,              0,      $init->{site_id},
               [$init->{site_id}, $self->INSTANCE_GROUP_ID]
           ]);

        if ($self->key_name eq 'story') {
            # It's a story asset.
            delete $init->{_categories};
            foreach my $cat ($alias_target->get_primary_category,
                             $alias_target->get_secondary_categories) {

                my $new_cat = Bric::Biz::Category->lookup
                  ({ uri => $cat->get_uri, site_id => $init->{site_id}})
                  or next;
                $self->add_categories([$new_cat]);
                $self->set_primary_category($new_cat);
                last;
            }
            unless ($self->get_primary_category) {
                # No equivalent category found. So use the root category.
                my $new_cat = Bric::Biz::Category->site_root_category
                  ( $init->{site_id} );
                $self->add_categories([$new_cat]);
                $self->set_primary_category($new_cat);
            }
        } else {
            # It's a media asset. Give it an empty file name.
            $self->_set(['file_name'] => ['']);
            # Assign the category.
            my $cat = $alias_target->get_category_object;
            if (my $new_cat = Bric::Biz::Category->lookup
                ({ uri => $cat->get_uri, site_id => $init->{site_id}})) {
                $self->set_category__id($new_cat->get_id);
            } else {
                my $new_cat_id = Bric::Biz::Category->site_root_category_id
                  ( $init->{site_id} );
                $self->set_category__id($new_cat_id);
            }
        }

        $self->set_slug($alias_target->get_slug);
        $self->set_name($alias_target->get_name);
        $self->set_description($alias_target->get_description);

        # Copy the keywords.
        $self->add_keywords(scalar $alias_target->get_keywords);

    } else {
        throw_dp "Can not create asset without a source"
          unless $init->{source__id};

        if ($init->{cover_date}) {
            $self->set_cover_date( delete $init->{cover_date} );
            my $source = Bric::Biz::Org::Source->lookup
              ({ id => $init->{source__id} });
            if (my $expire = $source->get_expire) {
                # add the days to the cover date and set the expire date
                my $date = local_date($self->_get('cover_date'), 'epoch');
                my $new_date = $date + ($expire * 24 * 60 * 60);
                $new_date = strfdate($new_date);
                $new_date = db_date($new_date);
                $self->_set( { expire_date => $new_date });
            }
        }

        # Get the element object.
        if ($init->{element}) {
            $init->{element__id} = $init->{element}->get_id;
        } else {
            $init->{element} =
              Bric::Biz::AssetType->lookup({ id => $init->{element__id}});
        }

        $self->_set({ element__id     => $init->{element__id},
                      _element_object => $init->{element} });

        # Set up the input and output channels.
        if ($init->{element}->get_top_level) {
            $self->add_output_channels(
               map { ($_->is_enabled &&
                      $_->get_site_id == $init->{site_id}) ? $_ : () }
                   $init->{element}->get_output_channels);

            $self->set_primary_oc_id($init->{element}->get_primary_oc_id
                                     ($init->{site_id}));
                                     
            $self->add_input_channels(
               map { ($_->is_enabled &&
                      $_->get_site_id == $init->{site_id}) ? $_ : () }
                   $init->{element}->get_input_channels);

            $self->set_primary_ic_id($init->{element}->get_primary_ic_id
                                     ($init->{site_id}));

            my $inst = $self->get_instance($self->get_primary_ic_id);
            $inst->set_name($init->{name});
            $inst->set_description($init->{description});
            $inst->set_slug($init->{slug});

        }

        $self->_set([qw(version current_version checked_out modifier
                        site_id grp_ids publish_status _instances 
                        input_channel_context)],
                    [0, 0, 1,
                     @{$init}{qw(user__id site_id)},
                     [$init->{site_id}, $self->INSTANCE_GROUP_ID], 0, 
                     {}, $self->get_primary_ic_id]);
    }

    $self->_set__dirty;
}

###############################################################################


#--------------------------------------#

=back

=head2 Private Instance Methods

=over 4

=item $at_obj = $self->_construct_uri()

Returns URI contructed from the output channel paths, categories and the date.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _construct_uri {
    my $self = shift;
    my ($cat_obj, $oc_obj) = @_;
#    $cat_obj ||= $self->get_primary_category();
    my $element_obj = $self->get_element_object or return;
    my $fu = $element_obj->get_fixed_url;
    my ($pre, $post);

    # Get the pre and post values.
    ($pre, $post) = ($oc_obj->get_pre_path, $oc_obj->get_post_path) if $oc_obj;

    # Get URI Format.
    my $fmt = $fu ? $oc_obj->get_fixed_uri_format : $oc_obj->get_uri_format;

    my ($category_uri, $slug);
    $category_uri = $cat_obj ? $cat_obj->ancestry_path : '';

    $slug = $self->key_name eq 'story' ? $self->get_slug : '';

    $fmt =~ s/\/%{categories}/$category_uri/g;
    $fmt =~ s/%{slug}/$slug/g;
    unless ($fmt =~ s/%{uuid}/$self->get_uuid/ge) {
        unless ($fmt =~ s/%{base64_uuid}/$self->get_uuid_base64/ge) {
            $fmt =~ s/%{hex_uuid}/$self->get_uuid_hex/ge;
        }
    }

    my $path = $self->get_cover_date($fmt) or return;
    my @path = split( '/', $path );

    # Add the pre and post values.
    unshift @path, $pre if $pre;
    push @path, $post if $post;

    # Return the URI with the case adjusted as necessary.
    my $uri_case = $oc_obj->get_uri_case;
    if( $uri_case == LOWERCASE ) {
        return lc Bric::Util::Trans::FS->cat_uri(@path);
    } elsif( $uri_case == UPPERCASE ) {
        return uc Bric::Util::Trans::FS->cat_uri(@path);
    } else {
        return Bric::Util::Trans::FS->cat_uri(@path);
    }
}

################################################################################

=item $self = $self->_sync_contributors()

Syncs the contributors for this story

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _sync_contributors {
    my $self = shift;
    return $self unless $self->_get('_update_contributors');

    my $contribs = $self->_get_contributors();
    my ($del_contribs, $vid) = $self->_get(qw(_del_contrib instance_id));

    foreach (keys %$del_contribs) {
        $self->_delete_contributor($_);
        delete $del_contribs->{$_};
    }

    foreach my $id (keys %$contribs) {
        my $role = $contribs->{$id}->{'role'};
        my $place = $contribs->{$id}->{'place'};
        if ($contribs->{$id}->{'action'} eq 'insert') {
            $self->_insert_contributor($id, $role, $place);
        } elsif ($contribs->{$id}->{'action'} eq 'update') {
            $self->_update_contributor($id, $role, $place);
        }
        delete $contribs->{$id}->{'action'};
    }

    $self->_set( {
                  '_del_contrib'        => $del_contribs,
                  '_update_contributors' => undef,
                  '_contributors' => $contribs
                 });

    return $self;
}

################################################################################

=item $self = $self->_delete_uris;

Deletes the URI records for this document. Called by C<save()> when the document
has been deactivated.

B<Throws:>

=over

=item Exception::DA

=back

=cut

sub _delete_uris {
    my $self = shift;
    my $id = $self->_get('id') or return;
    my $key = $self->key_name;

    my $del = prepare_c(qq{
        DELETE FROM $key\_uri
        WHERE  $key\__id = ?
    });

    execute($del, $id);
    return $self;
}

################################################################################

=item $self = $self->_update_uris;

Updates the URI records for this document.

B<Throws:>

=over

=item Error::NotUnique

=item Exception::DA

=back

=cut

sub _update_uris {
    my $self = shift;
    my ($id, $site_id, $pub_status) = $self->_get(qw(id site_id publish_status));
    my $key = $self->key_name;

    # First, expire or delete all existing URIs for this document.
    $self->_delete_uris;

    # Prepare the insert that we'll use.
    my $ins = prepare_c(qq{
        INSERT INTO $key\_uri ($key\__id, site__id, uri)
        VALUES (?, ?, ?)
    });

    # Now, go through all of the URIs for this document and either update them
    # or insert them.
    my @ocs = $self->get_output_channels;
    my (%seen, $uri);
    eval {
        if ($key eq 'media') {
            for my $oc (@ocs) {
                $uri = lc $self->get_uri($oc);
                # Skip it if we've seen it before.
                next if $seen{$uri};
                # Insert the URI.
                execute($ins, $id, $site_id, $uri);
                $seen{$uri} = 1;
            }
        } else {
            for my $cat ($self->get_categories) {
                for my $oc (@ocs) {
                    $uri = lc $self->get_uri($cat, $oc);
                    # Skip it if we've seen it before.
                    next if $seen{$uri};
                    # Insert the URI.
                    execute($ins, $id, $site_id, $uri);
                    $seen{$uri} = 1;
                }
            }
        }
    };

    if (my $err = $@) {
        # Just die if its any exception other than the one we're interested in.
        rethrow_exception($err)
          # Check for PostgreSQL 7.4 error message.
          unless $err->get_payload =~
          /duplicate key violates unique constraint "udx_$key\_uri__site_id__uri"/
          # Check for PostgreSQL 7.3, 7.2, or 7.1 error message.
          or $err->get_payload =~
          /Cannot insert a duplicate key into unique index udx_$key\_uri__site_id__uri/;
        my $things = $key eq 'media'
          ? 'category, or file name'
          : 'slug, or categories';
        throw_not_unique
          error    => "The URI '$uri' is not unique.",
          maketext => ['The URI "[_1]" is not unique. Please change the' .
                       " cover date, output channels, $things as necessary" .
                       " to make the URIs unique.", $uri];
    }

    # If we succeeded, then mark it!
    $self->_set(['_update_uri'] => [0]);
}


sub _create_instance {
    my ($self, $ic) = @_;

    $ic = $ic->get_id if ref $ic;

    my $instance = Bric::Biz::Asset::Business::Parts::Instance::Story->new
        ({ element          => $self->_get('_element_object'),
           element__id      => $self->_get('element__id'),
           input_channel_id => $ic });
    
    $self->add_instances($instance);
    
use Data::Dumper;
print STDERR "Creating instance: " . Dumper($instance) . "\n\n";

}

################################################################################

=back

=head2 Private Functions

=over 4

=item my $oc_coll = $get_oc_coll->($ba)

Returns the collection of output channels for this asset.
L<Bric::Util::Coll::OutputChannel|Bric::Util::Coll::OutputChannel>
object. See that class and its parent, L<Bric::Util::Coll|Bric::Util::Coll>,
for interface details.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

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

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

$get_oc_coll = sub {
    my $self = shift;
    my $dirt = $self->_get__dirty;
    my ($id, $oc_coll) = $self->_get('version_id', '_oc_coll');
    return $oc_coll if $oc_coll;
    $oc_coll = Bric::Util::Coll::OutputChannel->new
      (defined $id ? {$self->key_name . '_version_id' => $id} : undef);
    $self->_set(['_oc_coll'], [$oc_coll]);
    $self->_set__dirty($dirt); # Reset the dirty flag.
    return $oc_coll;
};

sub _get_oc_coll {
    $get_oc_coll;
}

##############################################################################

=item my $ic_coll = $get_ic_coll->($ba)

Returns the collection of input channels for this asset.
L<Bric::Util::Coll::InputChannel|Bric::Util::Coll::InputChannel>
object. See that class and its parent, L<Bric::Util::Coll|Bric::Util::Coll>,
for interface details.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

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

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

$get_ic_coll = sub {
    my $self = shift;
    my $dirt = $self->_get__dirty;
    my ($id, $ic_coll) = $self->_get('version_id', '_ic_coll');    
    return $ic_coll if $ic_coll;
    $ic_coll = Bric::Util::Coll::InputChannel->new
      (defined $id ? {$self->key_name . '_version_id' => $id} : undef);
    $self->_set(['_ic_coll'], [$ic_coll]);
    $self->_set__dirty($dirt); # Reset the dirty flag.
    return $ic_coll;
};

sub _get_ic_coll {
    $get_ic_coll;
}

##############################################################################

=item my $instance_coll = $get_instance_coll->($ba)

Returns the collection of instances for this asset.
L<Bric::Util::Coll::Instance|Bric::Util::Coll::Instance>
object. See that class and its parent, L<Bric::Util::Coll|Bric::Util::Coll>,
for interface details.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

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

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

$get_instance_coll = sub {
    my $self = shift;
    my $dirt = $self->_get__dirty;
    my ($id, $instance_coll) = $self->_get('version_id', '_instance_coll');    
    return $instance_coll if $instance_coll;
    my $class;
    if ($self->key_name eq 'story') {
        $class = "Bric::Util::Coll::Instance::Story";
    } elsif ($self->key_name eq 'media') {
        $class = "Bric::Util::Coll::Instance::Media";
    }
    $instance_coll = $class->new
      (defined $id ? {$self->key_name . '_version_id' => $id} : undef);
    $self->_set(['_instance_coll'], [$instance_coll]);
    $self->_set__dirty($dirt); # Reset the dirty flag.
    return $instance_coll;
};


##############################################################################

=item my $kw_coll = &$get_kw_coll($self)

Returns the collection of keywords for this business asset. The collection is
a Bric::Util::Coll::Keyword object. See that class and its parent,
Bric::Util::Coll, for interface details.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

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

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

$get_kw_coll = sub {
    my $self = shift;
    my $dirt = $self->_get__dirty;
    my $kw_coll = $self->_get('_kw_coll');
    return $kw_coll if $kw_coll;
    $kw_coll = Bric::Util::Coll::Keyword->new
      (defined $self->get_id ? { object => $self, active => 1 } : undef);
    $self->_set(['_kw_coll'], [$kw_coll]);
    $self->_set__dirty($dirt); # Reset the dirty flag.
    return $kw_coll;
};

1;

__END__

=back

=head1 NOTES

NONE

=head1 AUTHOR

michael soderstrom <miraso@pacbell.net>

=head1 SEE ALSO

L<Bric>, L<Bric::Biz::Asset>

=cut

