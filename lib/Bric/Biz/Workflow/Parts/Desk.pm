package Bric::Biz::Workflow::Parts::Desk;

###############################################################################

=head1 Name

Bric::Biz::Workflow::Parts::Desk - Desks in Workflow

=cut

require Bric; our $VERSION = Bric->VERSION;


=head1 Synopsis

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
 $ret     = $desk->transfer($param);

 # Accept a asset from another desk.
 $ret     = $desk->accept($param);

 $desk    = $desk->save;

=head1 Description

A desk is something that defines the steps in a workflow. Assets arrive at a
desk and remain there until they are approved and moved to the next desk in
the workflow.

A desk may have any number of assets associated with it at any time. Users may
checkout copies of these assets from the desk, make changes to them and check
them back into the desk. Users may also get read only copies.

=cut

#==============================================================================#
# Dependencies                         #
#======================================#

#--------------------------------------#
# Standard Dependencies
use strict;

#--------------------------------------#
# Programmatic Dependencies
use Bric::Util::DBI qw(:all);
use Bric::Util::Grp::Asset;
use Bric::Util::Grp::Desk;
use Bric::Util::Fault qw(throw_dp);

#==============================================================================#
# Inheritance                          #
#======================================#

use base qw(Bric);

#=============================================================================#
# Function Prototypes                  #
#======================================#
my $get_em;

#==============================================================================#
# Constants                            #
#======================================#
use constant DEBUG => 0;
use constant ASSET_GRP_PKG => 'Bric::Util::Grp::Asset';
use constant GROUP_PACKAGE => 'Bric::Util::Grp::Desk';
use constant INSTANCE_GROUP_ID => 34;

#==============================================================================#
# Fields                               #
#======================================#

#--------------------------------------#
# Public Class Fields

#--------------------------------------#
# Private Class Fields
my $METHS;
my $TABLE = 'desk';
my @COLS = qw(name description pre_chk_rules post_chk_rules asset_grp publish
              active);
my @PROPS = qw(name description pre_chk_rules post_chk_rules asset_grp
               _publish _active);
my @ORD = qw(name description publish active);

my $SEL_COLS = 'a.id, a.name, a.description, a.pre_chk_rules, ' .
  'a.post_chk_rules, a.asset_grp, a.publish, a.active, m.grp__id';
my @SEL_PROPS = ('id', @PROPS, 'grp_ids');

#--------------------------------------#
# Instance Fields
BEGIN {
    Bric::register_fields({
                         # Public Fields
                         'id'             => Bric::FIELD_READ,
                         'name'           => Bric::FIELD_RDWR,
                         'description'    => Bric::FIELD_RDWR,
                         'pre_chk_rules'  => Bric::FIELD_READ,
                         'post_chk_rules' => Bric::FIELD_READ,
                         'asset_grp'      => Bric::FIELD_READ,
                         'grp_ids'        => Bric::FIELD_READ,

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

=head1 Interface

=head2 Constructors

=over 4

=item $success = $obj = new Bric::Biz::Workflow::Parts::Desk($init);

The following is a list of parameter keys and their associated values.

Keys for $init are:

=over 4

=item *

name

The name of this desk

=item *

description

A description of this desk

=item *

publish

Boolean; true if this is a publish desk

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


    # Set up the default values for active and publish.
    $init->{_active} = !defined $init->{active} ? 1 :
      delete $init->{active} ? 1 : 0;
    $init->{_publish} = delete $init->{publish} ? 1 : 0;
    push @{$init->{grp_ids}}, INSTANCE_GROUP_ID;

    # Call the parent's constructor.
    $self->SUPER::new($init);

    # Make sure these are initialized as array refs.
    $self->_set([qw(_checkin _checkout _transfer)], [[],[],[]]);

    $self->_set__dirty(1);

    # Return the object.
    return $self;
}

#------------------------------------------------------------------------------#

=item my $desk = Bric::Biz::Workflow::Parts::Desk->lookup({ id => $id });

=item my $desk = Bric::Biz::Workflow::Parts::Desk->lookup({ name => $name });

Looks up and instantiates a new Bric::Biz::Workflow::Parts::Desk object based
on the Bric::Biz::Workflow::Parts::Desk object ID or name passed. If C<$id> or
C<$name> is not found in the database, C<lookup()> returns C<undef>.

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

=item *

Too many Bric::Biz::Workflow::Parts::Desk objects found.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub lookup {
    my $pkg = shift;
    my $desk = $pkg->cache_lookup(@_);
    return $desk if $desk;

    $desk = $get_em->($pkg, @_);
    # We want @$desk to have only one value.
    throw_dp(error => 'Too many ' . __PACKAGE__ . ' objects found.')
      if @$desk > 1;
    return @$desk ? $desk->[0] : undef;
}

#------------------------------------------------------------------------------#

=item @objs = Bric::Biz::Workflow::Parts::Desk->list($param);

Returns a list of desk objects based on $param.  Keys of $param are:

=over 4

=item C<id>

Desk ID. May use C<ANY> for a list of possible values.

=item C<name>

Return all desks matching a certain name. May use C<ANY> for a list of
possible values.

=item C<description>

Return all desks with a matching description. May use C<ANY> for a list of
possible values.

=item C<publish>

Boolean; returns all desks that can or cannot publish assets.

=item C<active>

Boolean; Return all in/active desks.

=item C<grp_id>

Return all desks in the group corresponding to this group ID. May use C<ANY>
for a list of possible values.

=back

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

B<Notes:> Searches against C<name> and C<description> use the LIKE operator, so
'%' can be used for substring searching.

=cut

sub list { wantarray ? @{ &$get_em(@_) } : &$get_em(@_) }

##############################################################################

=item (@ids || $ids) = Bric::Biz::Workflow::Parts::Desk->list_ids($params);

Return a list of desk IDs. See C<list()> for a list of the relevant keys in
the C<$params> hash reference.

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

B<Notes:> Searches against C<name> and C<description> use the LIKE operator, so
'%' can be used for substring searching.

=cut

sub list_ids { wantarray ? @{ &$get_em(@_, 1) } : &$get_em(@_, 1) }

#--------------------------------------#

=back

=head2 Destructors

=over 4

=item $self->DESTROY

Dummy method to prevent wasting time trying to AUTOLOAD DESTROY.

=cut

sub DESTROY {
    # This method should be here even if it's empty so that we don't waste time
    # making Bricolage's autoload method try to find it.
}

#--------------------------------------#

=back

=head2 Public Class Methods

=over 4

=item my $meths = Bric::Biz::Workflow::Parts::Desk->my_meths

=item my (@meths || $meths_aref) = Bric::Biz::Workflow::Parts::Desk->my_meths(TRUE)

=item my (@meths || $meths_aref) = Bric::Biz::Workflow::Parts::Desk->my_meths(0, TRUE)

Returns an anonymous hash of introspection data for this object. If called
with a true argument, it will return an ordered list or anonymous array of
introspection data. If a second true argument is passed instead of a first,
then a list or anonymous array of introspection data will be returned for
properties that uniquely identify an object (excluding C<id>, which is
assumed).

Each hash key is the name of a property or attribute of the object. The value
for a hash key is another anonymous hash containing the following keys:

=over 4

=item name

The name of the property or attribute. Is the same as the hash key when an
anonymous hash is returned.

=item disp

The display name of the property or attribute.

=item get_meth

A reference to the method that will retrieve the value of the property or
attribute.

=item get_args

An anonymous array of arguments to pass to a call to get_meth in order to
retrieve the value of the property or attribute.

=item set_meth

A reference to the method that will set the value of the property or
attribute.

=item set_args

An anonymous array of arguments to pass to a call to set_meth in order to set
the value of the property or attribute.

=item type

The type of value the property or attribute contains. There are only three
types:

=over 4

=item short

=item date

=item blob

=back

=item len

If the value is a 'short' value, this hash key contains the length of the
field.

=item search

The property is searchable via the list() and list_ids() methods.

=item req

The property or attribute is required.

=item props

An anonymous hash of properties used to display the property or
attribute. Possible keys include:

=over 4

=item type

The display field type. Possible values are

=over 4

=item text

=item textarea

=item password

=item hidden

=item radio

=item checkbox

=item select

=back

=item length

The Length, in letters, to display a text or password field.

=item maxlength

The maximum length of the property or value - usually defined by the SQL DDL.

=back

=item rows

The number of rows to format in a textarea field.

=item cols

The number of columns to format in a textarea field.

=item vals

An anonymous hash of key/value pairs representing the values and display names
to use in a select list.

=back

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub my_meths {
    my ($pkg, $ord, $ident) = @_;

    # Create 'em if we haven't got 'em.
    $METHS ||= {
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

    if ($ord) {
        return wantarray ? @{$METHS}{@ORD} : [@{$METHS}{@ORD}];
    } elsif ($ident) {
        return wantarray ? $METHS->{name} : [$METHS->{name}];
    } else {
        return $METHS;
    }
}

#--------------------------------------#

=back

=head2 Public Instance Methods

=over 4

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
    $asset_grp->get_objects;
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
    my $chkin = $self->_get('_checkin');

#    my $asset_grp = $self->_get_grp_obj(ASSET_GRP_PKG, 'asset_grp',
#                                        '_asset_grp_obj');
#    my $vers_grp_id = $a_obj->get_version_grp__id;

    # Find the asset in this desk that has the same version group ID as the
    # asset we are checking in and delete it from the group; this is the old
    # version of the asset.
#    my $found = 0;
#    foreach my $a ($self->assets) {
#       if ($a->get_version_grp__id == $vers_grp_id) {
#           $asset_grp->delete_member({ obj => $a });
#           $found = 1;
 #           last;
#       }
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

    # Throw an exception if this asset isn't already on the desk.
    throw_dp(error => 'Cannot checkout asset not on desk')
      unless $asset_grp->has_member({ obj => $a_obj });

    # Checkout the asset.
    my $chkout = $self->_get('_checkout');
    $a_obj->checkout({'user__id' => $user_id});
    push @$chkout, $a_obj;
    return $a_obj;
}

#------------------------------------------------------------------------------#

=item $ret = $desk->transfer($param);

Transfer an asset to a different desk.  Keys for $param are:

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
    my ($self, $param) = @_;
    my $desk = $param->{to};
    return $self if $desk->get_id == $self->get_id;

    my $asset         = $param->{asset};
    my $asset_grp_obj
        = $self->_get_grp_obj(ASSET_GRP_PKG, 'asset_grp', '_asset_grp_obj');

    # If we don't have an asset_grp_obj there shouldn't be anything to
    # transfer!
    return unless $asset_grp_obj;

    # Do the pre-desk rule checks
    return unless $desk->accept({
        asset => $asset,
        from  => $self
    });

    # If the asset was accepted and we get here, remove this asset from the
    # desk
    $asset_grp_obj->delete_member({ obj => $asset });

    return $self
}

#------------------------------------------------------------------------------#

=item $ret = $desk->accept($param);

Accept an asset from another desk.  Keys for $param are:

=over 4

=item *

from

The desk from which this asset is coming.  Can be omitted if this is the first
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
    my ($self, $param) = @_;
    my $desk  = $param->{from};
    return $self if $desk and $desk->get_id == $self->get_id;

    my $dirty         = $self->_get__dirty;
    my $asset         = $param->{asset};
    my $xfer          = $self->_get('_transfer');
    my $asset_grp_obj
        = $self->_get_grp_obj(ASSET_GRP_PKG, 'asset_grp', '_asset_grp_obj');

    # Create the asset group for this desk if one doesn't exist.
    unless ($asset_grp_obj) {
        my $desc = 'A group for holding assets for Desk objects';
        $asset_grp_obj = Bric::Util::Grp::Asset->new(
                                             {'name'        => 'Desk Assets',
                                              'description' => $desc});

        # Throw an error if we could not create the group.
        my $err_msg = 'Could not create a new Grp object';
        throw_dp(error => $err_msg)
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
    my $asset_grp_obj = $self->_get_grp_obj(ASSET_GRP_PKG,
                                            'asset_grp',
                                            '_asset_grp_obj');

    # If the asset was accepted and we get here, remove this asset from the desk
    $asset_grp_obj->delete_member({ obj => $asset });
    $asset->remove_from_desk;
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
    my $asset_grp_obj = $self->_get_grp_obj(ASSET_GRP_PKG, 'asset_grp',
                                            '_asset_grp_obj')
      or return;
    $asset_grp_obj->get_objects;
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
    foreach ($self->get_assets) {
        push @{ $ass->{$_->key_name} }, $_;
    }
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

Checks the user to see if s/he has the right privileges to checkout stories.

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
            $asset_grp_obj = Bric::Util::Grp::Asset->new
              ({ name        => 'Desk Assets',
                 description => $desc});

            # Throw an error if we could not create the group.
            my $err_msg = 'Could not create a new Grp object';
            throw_dp(error => $err_msg) unless $asset_grp_obj;

            $self->_set(['_asset_grp_obj'], [$asset_grp_obj]);
            $self->_set__dirty($dirty);
        }
        $self->_sync_checkin;
        $self->_sync_checkout;
        $self->_sync_transfer;

        # Save all the grouped objects.
        $asset_grp_obj->save;

        # Save the IDs if we have them.
        my $ag = $self->get_asset_grp;
        my $newagid = $asset_grp_obj->get_id;
        if (! defined $ag or $ag != $newagid) {
            $self->_set(['asset_grp'], [$newagid]);
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
    return $self;
}

#==============================================================================#

=back

=head1 Private

=head2 Private Class Methods

NONE

=head2 Private Instance Methods

A few of these still need documenting.

=over 4

=item _sync_checkin

=cut

sub _sync_checkin {
    my $self = shift;
    my $chkin = $self->_get('_checkin');

    while (my $a = shift @$chkin) {
        $a->save;
    }
}

=item _sync_checkout

=cut

sub _sync_checkout {
    my $self = shift;
    my $chkout = $self->_get('_checkout');

    while (my $a = shift @$chkout) {
        $a->save;
    }
}

=item _sync_transfer

=cut

sub _sync_transfer {
    my $self = shift;
    my $xfer = $self->_get('_transfer');

    while (my $a = shift @$xfer) {
        $a->save;
    }
}

=item $obj = $desk->_get_grp_obj($id_field, $obj_field)

Retrieve the group object if it's set in this object.  Otherwise, try to look it
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
    my $nextval = next_key($TABLE);

    # Create the insert statement.
    my $ins = prepare_c(qq{
        INSERT INTO $TABLE (id, ${\join(', ', @COLS)})
        VALUES ($nextval, ${\join(', ', ('?') x @COLS)})
    }, undef);

    execute($ins, $self->_get(@PROPS));

    # Set the ID of this object.
    $self->_set(['id'],[last_key($TABLE)]);

    # And finally, register this desk in the "All Desks" group.
    $self->register_instance(INSTANCE_GROUP_ID, GROUP_PACKAGE);

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

    my $upd = prepare_c(qq{
        UPDATE $TABLE
        SET    ${\join(', ', map {"$_ = ?"} @COLS)}
        WHERE  id = ?
    }, undef);

    execute($upd, $self->_get(@PROPS, 'id'));
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
    my $sth = prepare_c("DELETE FROM $TABLE WHERE id = ?", undef);
    execute($sth, $self->_get('id'));
    return $self;
}

#--------------------------------------#

=back

=head2 Private Functions

=over 4

=item my $desk_aref = &$get_em( $pkg, $search_href )

=item my $desk_ids_aref = &$get_em( $pkg, $search_href, 1 )

Function used by C<lookup()> and C<list()> to return a list of
Bric::Biz::Workflow::Parts::Desk objects or, if called with an optional third
argument, returns a list of Bric::Biz::Workflow::Parts::Desk object IDs (used
by C<list_ids()>).

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

$get_em = sub {
    my ($pkg, $params, $ids) = @_;

    # Make sure to set active explicitly if it's not passed.
    if (exists $params->{active}) {
        if (defined $params->{active}) {
            $params->{active} = $params->{active} ? 1 : 0;
        } else {
            delete $params->{active};
        }
    } else {
        $params->{active} = 1;
    }

    $params->{publish} = $params->{publish} ? 1 : 0
      if exists $params->{publish};

    my $tables = "$TABLE a, member m, desk_member c";
    my $wheres = 'a.id = c.object_id AND c.member__id = m.id AND ' .
      "m.active = '1'";
    my @params;
    while (my ($k, $v) = each %$params) {
        if ($k eq 'name' or $k eq 'description') {
            $wheres .= ' AND '
                    . any_where $v, "LOWER(a.$k) LIKE LOWER(?)", \@params;
        } elsif ($k eq 'grp_id') {
            $tables .= ", member m2, desk_member c2";
            $wheres .= " AND a.id = c2.object_id AND c2.member__id = m2.id"
              . " AND m2.active = '1' AND "
              . any_where $v, 'm2.grp__id = ?', \@params;
        } else {
            $wheres .= ' AND ' . any_where $v, "a.$k = ?", \@params;
        }
    }

    my ($qry_cols, $order) = $ids ? (\'DISTINCT a.id', 'a.id') :
      (\$SEL_COLS, 'a.name, a.id');

    my $sel = prepare_c(qq{
        SELECT $$qry_cols
        FROM   $tables
        WHERE  $wheres
        ORDER BY $order
    }, undef);

    # Just return the IDs, if they're what's wanted.
    return col_aref($sel, @params) if $ids;

    execute($sel, @params);
    my (@d, @desks, $grp_ids);
    bind_columns($sel, \@d[0..$#SEL_PROPS]);
    my $last = -1;
    $pkg = ref $pkg || $pkg;
    while (fetch($sel)) {
        if ($d[0] != $last) {
            $last = $d[0];
            # Create a new desk object.
            my $self = bless {}, $pkg;
            $self->SUPER::new;
            # Get a reference to the array of group IDs.
            $grp_ids = $d[$#d] = [$d[$#d]];
            $self->_set(\@SEL_PROPS, \@d);
            $self->_set([qw(_checkin _checkout _transfer)], [[],[],[]]);
            $self->_set__dirty; # Disables dirty flag.
            push @desks, $self->cache_me;
        } else {
            push @$grp_ids, $d[$#d];
        }
    }
    return \@desks;
};

1;
__END__

=back

=head1 Notes

NONE

=head1 Author

Garth Webb <garth@perijove.com>

=head1 See Also

L<Bric>, L<Bric::Biz::Workflow>, L<perl>

=cut
