package Bric::Biz::Asset::Business;

###############################################################################

=head1 Name

Bric::Biz::Asset::Business - An object that houses the business Assets

=cut

require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

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
 $vers_id     = $asset->get_version_id();
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


=head1 Description

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
use Bric::Util::DBI qw(:all);
use Bric::Util::Time qw(:all);
use Bric::Util::Fault qw(:all);
use Bric::Util::Grp::AssetVersion;
use Bric::Util::Grp::AssetLanguage;
use Bric::Biz::Element::Field;
use Bric::Biz::Element::Container;
use Bric::Biz::Category;
use Bric::Biz::OutputChannel qw(:case_constants);
use Bric::Biz::Org::Source;
use Bric::Util::Coll::OutputChannel;
use Bric::Util::Coll::Keyword;
use Bric::Util::Pref;
use Data::UUID;
use List::Util qw(first);
use Scalar::Util qw(blessed);

#=============================================================================#
# Inheritance                          #
#======================================#

use base qw( Bric::Biz::Asset );

#============================================================================+
# Function Prototypes                  #
#======================================#
my ($get_oc_coll, $get_kw_coll);

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
              element_type_id           => Bric::FIELD_RDWR,
              related_grp__id           => Bric::FIELD_READ,
              primary_uri               => Bric::FIELD_READ,
              publish_date              => Bric::FIELD_RDWR,
              first_publish_date        => Bric::FIELD_RDWR,
              cover_date                => Bric::FIELD_RDWR,
              publish_status            => Bric::FIELD_RDWR,
              primary_oc_id             => Bric::FIELD_RDWR,
              alias_id                  => Bric::FIELD_READ,

              # Private Fields
              _contributors             => Bric::FIELD_NONE,
              _queried_contrib          => Bric::FIELD_NONE,
              _del_contrib              => Bric::FIELD_NONE,
              _update_contributors      => Bric::FIELD_NONE,
              _related_grp_obj          => Bric::FIELD_NONE,
              _element                     => Bric::FIELD_NONE,
              _queried_cats             => Bric::FIELD_NONE,
              _categories               => Bric::FIELD_NONE,
              _del_categories           => Bric::FIELD_NONE,
              _new_categories           => Bric::FIELD_NONE,
              _element_type_object      => Bric::FIELD_NONE,
              _oc_coll                  => Bric::FIELD_NONE,
              _kw_coll                  => Bric::FIELD_NONE,
              _alias_obj                => Bric::FIELD_NONE,
              _update_uri               => Bric::FIELD_NONE,
              _delete_element           => Bric::FIELD_NONE,
            });
    }

#=============================================================================#

=head1 Interface

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

    unless ($meths) {
    # We don't got 'em. So get 'em!
    foreach my $meth (__PACKAGE__->SUPER::my_meths(1)) {
        $meths->{$meth->{name}} = $meth;
        push @ord, $meth->{name};
        push (@ord, 'title') if $meth->{name} eq 'name';
    }
    push @ord, qw(source_id source first_publish_date publish_date category
                  category_name), pop @ord;

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
    $meths->{category} = {
                          get_meth => sub { shift->get_primary_category(@_) },
                          get_args => [],
                          set_meth => sub { shift->set_primary_category(@_) },
                          set_args => [],
                          name     => 'category',
                          disp     => 'Category',
                          len      => 64,
                          req      => 1,
                          type     => 'short',
                         };

    $meths->{category_name} = {
                          get_meth => sub { shift->get_primary_category(@_)->get_name },
                          get_args => [],
                          name     => 'category_name',
                          disp     => 'Category Name',
                          len      => 64,
                          req      => 1,
                          type     => 'short',
                         };
    $meths->{category_uri} = {
                          get_meth => sub { shift->get_primary_category(@_)->get_uri },
                          get_args => [],
                          name     => 'category_uri',
                          disp     => 'Category URI',
                          len      => 64,
                          req      => 1,
                          type     => 'short',
                         };
    # Copy the data for the title from name.
    $meths->{title} = { %{ $meths->{name} } };
    $meths->{title}{name} = 'title';
    $meths->{title}{disp} = 'Title';

    }
    if ($ord) {
        return wantarray ? @{$meths}{@ord} : [@{$meths}{@ord}];
    } elsif ($ident) {
        return wantarray ? $meths->{version_id} : [$meths->{version_id}];
    } else {
        return $meths;
    }
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

=item $biz = $biz->set_source_id($s_id)

Sets the source id upon this story

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

################################################################################

=item $source = $biz->get_source_id()

Returns the source id from this business asset

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_source_id { shift->_get('source__id') }
sub set_source_id { shift->_set(['source__id'] => [shift]) }

################################################################################

=item $at_id = $biz->get_element_type_id()

Returns the element type id that this story is associated with

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

################################################################################

=item $biz = $biz->set_element_type_id($at_id)

Sets the element type id that this story is associated with.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub set_element_type_id {
    my ($self, $eid) = @_;
    my $old_eid = $self->_get('element_type_id');
    return $self if $eid == $old_eid;
    my $oc_coll = $get_oc_coll->($self);
    $oc_coll->del_objs($oc_coll->get_objs);
    my $elem = Bric::Biz::ElementType->lookup({ id => $eid });
    $oc_coll->add_new_objs( map { $_->is_enabled ? $_ : () }
                            $elem->get_output_channels );
    $self->_set([qw(element_type_id _element_type_object)], [$eid, $elem]);
}

sub get_element__id { shift->get_element_type_id     }
sub set_element__id { shift->set_element_type_id(@_) }

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
    # Must be a new document. Find the primary.
    return $oc || first { $_->get_id == $pocid } $self->get_output_channels;
}

=item $self = $p->set_primary_oc_id($primary_oc_id)

Sets the asset's primary output channel ID.

B<Throws:> NONE.

B<Side Effects:> The URIs for the asset will be changed.

B<Notes:> NONE.

=cut

################################################################################

=item $biz->add_contributor($contrib, $role);

Takes a contributor object or id and their role in the context of this story
and associates them

B<Throws:>

=over 4

=item *

$contrib argument must be a Bric::Util::Grp::Parts::Member::Contrib

=back

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub add_contributor {
    my ($self, $contrib, $role) = @_;

    if (ref $contrib) {
        my $pkg = 'Bric::Util::Grp::Parts::Member::Contrib';
        throw_dp "\$contrib argument must be a $pkg"
          unless blessed($contrib) and $contrib->isa($pkg);
    }

    my $dirty = $self->_get__dirty();
    my $contribs = $self->_get_contributors() || {};
    $role ||= 'DEFAULT';

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
    if (my @objs_needed = grep { !$contribs->{$_}->{obj} } keys %$contribs) {
        $contribs->{$_->get_id}->{obj} = $_ for Bric::Util::Grp::Parts::Member::Contrib->list({ id => ANY(@objs_needed) });
    }

    my @ret;
    push @ret, $contribs->{$_}->{obj} for
        sort { $contribs->{$a}->{place} <=> $contribs->{$b}->{place} }
        keys %$contribs;

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
        throw_gen 'Improper args to reorder contributors: expected ' . scalar (keys %$existing) . ' but got ' . scalar @new_order;
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
            throw_gen 'Improper args to reorder contributors';
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

=item get_element_name()

Returns the name of the asset type that this is based on. This is the same as
the name of the top level element.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_element_name {
    my $self = shift;
    $self->get_element->get_name;
}

################################################################################

=item get_element_key_name()

Returns the key name of the asset type that this is based on. This is the same
as the key name of the top level element.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_element_key_name {
    my $self = shift;
    $self->get_element->get_key_name;
}

################################################################################

=item $ba->get_possible_field_types()

=item $ba->get_possible_data()

Returns a list or array reference of the field types that define the structure
of fields that can be added to the business document's element.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> C<get_possible_data()> is the deprecated form of this method.

=cut

sub get_possible_field_types {
    my $self = shift;
    my $element = $self->get_element;
    return $element->get_possible_field_types;
}

sub get_possible_data { shift->get_possible_field_types(@_) }

################################################################################

=item $ba->get_possible_containers()

Returns a list or array reference of the element types that define the
structure of elements that can be added to the business document's element.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_possible_containers {
    my $self = shift;
    my $element = $self->get_element;
    return $element->get_possible_containers;
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
    $self->get_uri;
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
    return $self;
}

################################################################################

=item $self = $story->set_publish_status($bool)

Sets the publish status to a true or false value.

B<Throws:> NONE.

B<Side Effects:> Also sets the first C<published_version> to the value stored
in the C<version> attribute if it hasn't been set before.

B<Notes:> NONE.

=cut

sub set_publish_status {
    my ($self, $val) = @_;
    my ($pubv, $curv) = $self->_get(qw(published_version version));
    return $self->_set([qw(publish_status published_version)] => [$val, $curv])
        if $val && !$pubv;
    return $self->_set(['publish_status'] => [$val]);
}

################################################################################

=item $self = $story->set_published_version($version)

Sets the published version of the document.

B<Throws:> NONE.

B<Side Effects:> Also sets the first C<publishstatus> if it's set to a false
value.

B<Notes:> NONE.

=cut

sub set_published_version {
    my ($self, $version) = @_;
    return $self->_set([qw(publish_status published_version)] => [ 1, $version])
        if $version;
    return $self->_set([qw(published_version)] => [$version]);
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

=item $self = $story->mark_as_published

    $doc->mark_as_published;
    $doc->save;

If the document is not already marked as published, this method does so,
setting the publish status and publish date and saving the story. Use with
caution, since this method does not actually publish the document (no jobs are
created and no templates are executed).

B<Throws:> NONE.

B<Side Effects:> Sets the C<publish_status> to true and the C<publish_date> to
the current date and time, unless the document is already marked as published.
The setting of <publish_date> causes the C<first_publish_date> to be set to
the same date.

B<Notes:> This method is usually used when you have sucked the content of the
asset into something else that you are really publishing and want this asset
to be marked as published without creating any content on its own.

=cut

sub mark_as_published {
    my $self = shift;
    return if $self->get_publish_status;
    $self->set_publish_status(1);
    $self->set_publish_date( local_date(undef, undef, 1) );
}

################################################################################

=item (@objs || $objs) = $asset->get_related_objects

Return all the related story or media objects for this business asset. If the
asset is an alias of another asset, related objects will only be returned if
they are in the same site as the asset, or if there are aliases in the asset's
site for the related media associated with the aliased asset.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_related_objects {
    my $self = shift;
    return $self->_find_related($self->get_element);
}

sub _find_related {
    my ($self, $element) = @_;
    my @related;

    # Add this element's related assets
    for my $rel (
        $element->get_related_media,
        $element->get_related_story,
    ) {
        next unless $rel;
        if ( $self->get_alias_id && $rel->get_site_id != $self->get_site_id ) {
            # Try to find a local alias, instead. Skip it if there isn't one.
            $rel = ref($rel)->lookup({
                alias_id => $rel->get_id,
                site_id => $self->get_site_id,
            }) or next;
            push @related, $rel;
        } else {
            push @related, $rel;
        }
    }

    # Check all the children for related assets.
    foreach my $c ($element->get_containers) {
        push @related, $self->_find_related($c);
    }

    return wantarray ? @related : \@related if @related;
    return;
}

################################################################################

=item $element = $ba->get_element

 my $element = $ba->get_element;
 $element = $ba->get_element; # Deprecated form.

Returns the top level element that contains content for this document.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_element {
    my $self = shift;
    my $element = $self->_get('_element');
    unless ($element) {
        my $object = $self->_get_alias || $self;
        $element = Bric::Biz::Element::Container->lookup({
            object    => $object,
            parent_id => undef,
        });
        $object->_set(['_element'] => [$element]);
    }
    return $element;
}

sub get_tile { shift->get_element };

##############################################################################

=item $elem_type = $self->get_element_type

Returns the element object that coresponds defines the structure of the
elements of the document.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_element_type {
    my $self = shift;

    my ($at_id, $at_obj) = $self->_get(qw(element_type_id _element_type_object));
    return $at_obj if $at_obj;

    if (my $alias_obj = $self->_get_alias) {
        return $alias_obj->get_element_type;
    }

    return unless $at_id;
    my $dirty = $self->_get__dirty;
    $at_obj = Bric::Biz::ElementType->lookup({ id => $at_id });
    $self->_set(['_element_type_object'] => [$at_obj]);
    $self->_set__dirty($dirty);
    return $at_obj;
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
    my $element = $self->get_element_type;
    return $element->is_fixed_uri;
}

################################################################################

=item get_elements

  my $elements = $ba->get_elements;
  my @elements = $ba->get_elements;
  $elements    = $ba->get_elements(@key_names);
  @elements    = $ba->get_elements(@key_names);

  # Deprecated forms:
  $elements = $ba->get_tiles;
  @elements = $ba->get_tiles;
  $elements = $ba->get_tiles(@key_names);
  @elements = $ba->get_tiles(@key_names);

Returns the elements that are held with in the top level element of this business
asset. Convenience shortcut to C<< $ba->get_element->get_elements >>.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> C<get_tiles()> is the deprecated form of this method.

=cut

sub get_elements { shift->get_element->get_elements(@_) }
sub get_tiles    { shift->get_element->get_elements(@_) }

###############################################################################

=item $ba->add_field($field_type, $value)

=item $ba->add_data($field_type, $value)

Creates a new field and adds it to the business document's element. Convenience
shortcut to C<< $ba->get_element->add_field >>.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> C<add_data()> is the deprecated form of this method.

=cut

sub add_field { shift->get_element->add_field(@_) }
sub add_data  { shift->get_element->add_field(@_) }

###############################################################################

=item $new_container = $ba->add_container( $atc_obj )

This will create and return a new container element that is added to the current
container. Convenience shortcut to C<< $ba->get_element->add_container >>.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub add_container { shift->get_element->add_container(@_) }

###############################################################################

=item $value = $ba->get_value( $key_name, $obj_order )

=item $value = $ba->get_value( $key_name, $obj_order, $format )

=item $value = $ba->get_data( $key_name, $obj_order )

=item $value = $ba->get_data( $key_name, $obj_order, $format )

Returns the value for a field with the given key name and object order.
Convenience shortcut to C<< $ba->get_element->get_value >>.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:>

C<get_data()> is the deprecated form of this method. For fields that can
contain multiple values, call C<get_values()>, instead.

=cut

sub get_value { shift->get_element->get_value(@_) }
sub get_data  { shift->get_element->get_value(@_) }

###############################################################################

=item $container = $ba->get_container( $key_name, $obj_order )

Returns a container element object with the given key name and the given
object order position. Convenience shortcut to
C<< $ba->get_element->get_container >>.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_container { shift->get_element->get_container(@_) }

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
        # this is not checked out, it cannot be deleted
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
    my $self = shift;
    return $self->_get('current_version') == $self->_get('version')
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

    my $element = $self->get_element;
    $element->prepare_clone;

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

    $self->_set([qw(user__id modifier version_id checked_out note)] =>
                [$param->{user__id}, $param->{user__id}, undef, 1, undef]);
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

    my ($related_obj, $element, $oc_coll, $ci, $co, $vid, $kw_coll, $del_elem)
        = $self->_get(qw(_related_grp_obj _element _oc_coll _checkin _checkout
                         version_id _kw_coll _delete_element));

    if ($co) {
        $element->prepare_clone;
        $self->_set(['_checkout'], []);
    }

    # Once we've saved, clear the checkin flag.
    $self->_set(['_checkin'], []) if $ci;

    # Revert stores the old element for deletion. So save it to delete it.
    $del_elem->save if $del_elem;

    if ($element) {
        $element->set_object_instance_id($vid);
        $element->save;
    }

    $related_obj->save if $related_obj;
    $self->_sync_contributors;
    $oc_coll->save($self->key_name => $vid) if $oc_coll;
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

#=============================================================================#

=back

=head2 Private

=cut

#--------------------------------------#

=head2 Private Class Methods

=over 4

=item $self = $self->_init()

Preforms functions needed to create new business assets

B<Throws:>

=over 4

=item *

Cannot create an asset without an element type or alias ID.

=item *

Cannot create an asset with both an element type and an alias ID.

=item *

Cannot create an asset without a site.

=item *

Cannot create an alias to an asset in the same site.

=item *

Cannot create an alias to an alias.

=item *

Cannot create an alias to an asset based on an element type that is not
associated with this site.

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
    for my $old (qw(element_id element__id)) {
        $init->{element_type_id} = delete $init->{$old}
            if exists $init->{$old};
    }
    $init->{element_type} = delete $init->{element} if exists $init->{element};

    throw_dp "Cannot create an asset without an element type or alias ID"
        unless $init->{element_type_id}
            || $init->{element_type}
            || $init->{alias_id};

    throw_dp "Cannot create an asset with both an element type and an alias ID"
      if ($init->{element_type_id} || $init->{element_type})
         && $init->{alias_id};

    throw_dp "Cannot create an asset without a site" unless $init->{site_id};

    if ($init->{alias_id}) {
        my $alias_target = $class->lookup({ id => $init->{alias_id} });

        throw_dp "Cannot create an alias to an alias"
          if $alias_target->get_alias_id;

        # Re-bless the alias into the same class as the aliased.
        bless $self, ref $alias_target;

        $self->_set([qw(alias_id _alias_obj)],
                    [$init->{alias_id}, $alias_target]);

        my $at = $alias_target->get_element_type;
        my $at_exists = 0;
        foreach my $site (@{$at->get_sites}) {
            if ($site->get_id == $init->{site_id}) {
                $at_exists++;
                last;
            }
        }

        throw_dp "Cannot create an alias to an asset based on an " .
            "element type that is not associated with this site"
          unless $at_exists;

        $self->set_source__id( $alias_target->get_source__id );
        $self->_set(['cover_date'], [$alias_target->_get('cover_date')]);

        $self->add_output_channels(
            grep { $_->is_enabled && $_->get_site_id == $init->{site_id} }
              $at->get_output_channels
        );

        $self->set_primary_oc_id($at->get_primary_oc_id($init->{site_id}));

        throw_dp "Cannot create an alias to this asset because this element ".
            "type has no output channels associated with this site"
          unless @{$self->get_output_channels};

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

        $self->_set(['slug'], [$alias_target->_get('slug')])
          if $alias_target->_get('slug');

        $self->_set(['name'], [$alias_target->_get('name')])
          if $alias_target->_get('name');

        $self->_set(['element_type_id'], [$alias_target->_get('element_type_id')]);

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

        # Get the element type object.
        if ($init->{element_type}) {
            $init->{element_type_id} = $init->{element_type}->get_id;
        } else {
            $init->{element_type} =
              Bric::Biz::ElementType->lookup({ id => $init->{element_type_id}});
        }

        # Set up the output channels.
        if ($init->{element_type}->get_top_level) {
            $self->add_output_channels(
               map { ($_->is_enabled &&
                      $_->get_site_id == $init->{site_id}) ? $_ : () }
                   $init->{element_type}->get_output_channels);

            $self->set_primary_oc_id($init->{element_type}->get_primary_oc_id
                                     ($init->{site_id}));
        }

        # Let's create the new element as well.
        my $element = Bric::Biz::Element::Container->new ({
            object          => $self,
            element_type_id => $init->{element_type_id},
            element_type    => $init->{element_type}
        });

        $self->_set([qw(version current_version checked_out _element modifier
                        element_type_id _element_type_object site_id grp_ids
                        publish_status)],
                    [0, 0, 1, $element,
                     @{$init}{qw(user__id element_type_id element_type site_id)},
                     [$init->{site_id}, $self->INSTANCE_GROUP_ID], 0]);
    }

    $self->_set__dirty;
}

###############################################################################


#--------------------------------------#

=back

=head2 Private Instance Methods

=over 4

=item $at_obj = $self->_construct_uri()

Returns URI contructed from the output chanel paths, categories and the date.

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
    my $element_obj = $self->get_element_type or return;
    my $fu = $element_obj->get_fixed_url;
    my ($pre, $post);

    # Get URI Format.
    my $fmt = $fu ? $oc_obj->get_fixed_uri_format : $oc_obj->get_uri_format;

    my $category_uri = $cat_obj ? $cat_obj->ancestry_path : '';
    my ($slug, $slash) = $self->key_name eq 'story' ? ($self->get_slug, '/')
                                                    : ('', '')
                                                    ;
    $slug = '' unless defined $slug;
    $fmt =~ s{/%{categories}/?}{$category_uri}g;
    $fmt =~ s/%{slug}/$slug/g;
    unless ($fmt =~ s/%{uuid}/$self->get_uuid/ge) {
        unless ($fmt =~ s/%{base64_uuid}/$self->get_uuid_base64/ge) {
            $fmt =~ s/%{hex_uuid}/$self->get_uuid_hex/ge;
        }
    }

    Bric::Util::Pref->use_user_prefs(0);
    my $path = $self->get_cover_date($fmt);
    Bric::Util::Pref->use_user_prefs(1);

    # If there is no cover date, then strip out the strftime formats.
    ($path = $fmt) =~ s/%(?:[%a-zA-Z]|{\w+}|\d+N)//g unless $path;

    # Return the URI with the case adjusted as necessary.
    my $uri = Bric::Util::Trans::FS->cat_uri( split '/', $path ) . $slash;
    my $uri_case = $oc_obj->get_uri_case;
    return $uri_case == LOWERCASE ? lc $uri
         : $uri_case == UPPERCASE ? uc $uri
                                  : $uri;
}

###############################################################################

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
    my ($del_contribs, $vid) = $self->_get(qw(_del_contrib version_id));

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
          /violates unique[\s-]constraint\s[^\[]udx_$key\_uri__site_id__uri/i
          # Check for PostgreSQL 7.3, 7.2, or 7.1 error message.
          or $err->get_payload =~
          /Cannot insert a duplicate key into unique index udx_$key\_uri__site_id__uri/i;
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
      (defined $id ? {$self->key_name . '_instance_id' => $id} : undef);
    $self->_set(['_oc_coll'], [$oc_coll]);
    $self->_set__dirty($dirt); # Reset the dirty flag.
    return $oc_coll;
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

=head1 Notes

NONE

=head1 Author

michael soderstrom <miraso@pacbell.net>

=head1 See Also

L<Bric>, L<Bric::Biz::Asset>

=cut
