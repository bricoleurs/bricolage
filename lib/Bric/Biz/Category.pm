package Bric::Biz::Category;

###############################################################################

=head1 Name

Bric::Biz::Category - A module to group assets into categories.

=cut

require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

 # Return a new category object.
 my $cat = Bric::Biz::Category->new($init);

 # Look up an existing category object.
 my $cat = Bric::Biz::Category->lookup({'id' => $cat_id});

 # Search for a list of categories.
 my @cats = Bric::Biz::Category->list($crit);

 # Attribute accessors.
 my $id = $cat->get_id;
 my $name = $cat->get_name;
 $cat = $cat->set_name($name);
 my $desc = $cat->get_description;
 $cat = $cat->set_description($desc);
 my $site_id = $cat->get_site_id;
 $cat = $cat->set_site_id($site_id);

 # Return a list of child categories of this category.
 @cats   = $cat->get_children();
 # Return the parent of this category.
 $parent = $cat->get_parent();

 # Attribute methods.
 $val = $element->set_attr($name, $value);
 $val = $element->get_attr($name);
 $val = $element->set_meta($name, $field, $value);
 $val = $element->get_meta($name, $field);

 # Ad string methods
 $txt = $element->get_ad_string;
 $element->set_ad_string($value);
 $txt = $element->get_ad_string2;
 $element->set_ad_string2($value);

 # Add/Delete child categories for this category.
 $cat->add_child([$cat || $cat_id]);
 $cat->del_child([$cat || $cat_id]);

 # Manage keyword associations.
 @keys = $cat->get_keywords;
 $cat->add_keywords(@keywords);
 $cat->del_keywords(@keywords);

 # Save information for this category to the database.
 $cat->save;

=head1 Description

Allows assets to be grouped into categories. In addition to assets a category
can contain other categories, allowing a hierarchical layout of categories and
assets. New categories will inherit group memberships and asset group
permissions from their parents, but those relationships will thereafter be
independent of the parent's.

=cut

#==============================================================================#
# Dependencies                         #
#======================================#

#--------------------------------------#
# Standard Dependencies
use strict;

#--------------------------------------#
# Programatic Dependencies
use Bric::Util::Grp::CategorySet;
use Bric::Util::Attribute::Category;
use Bric::Util::Trans::FS;
use Bric::Util::Fault qw(throw_gen throw_dp);
use Bric::Util::DBI qw(:standard :junction col_aref);
use Bric::Util::Grp::Asset;
use Bric::Util::Coll::Keyword;

#==============================================================================#
# Inheritance                          #
#======================================#
use base qw(Bric);

#=============================================================================#
# Function Prototypes                  #
#======================================#
my $get_kw_coll;

#==============================================================================#
# Constants                            #
#======================================#
use constant DEBUG => 0;
use constant HAS_MULTISITE => 1;
use constant ORD => qw(name description site_id uri directory ad_string
                       ad_string2);

use constant INSTANCE_GROUP_ID => 26;
use constant GROUP_PACKAGE => 'Bric::Util::Grp::CategorySet';
use constant key_name => 'category';

#==============================================================================#
# Fields                               #
#======================================#

#--------------------------------------#
# Public Class Fields

#--------------------------------------#
# Private Class Fields
my $table = 'category';
my $mem_table = 'member';
my $map_table = $table . "_$mem_table";

my $sel_cols = 'a.id, a.site__id, a.directory, a.asset_grp_id, a.active, '.
               'a.uri, a.parent_id, a.name, a.description, ' .
               group_concat_sql('m.grp__id');
my $grp_cols = 'a.id, a.site__id, a.directory, a.asset_grp_id, a.active, '.
               'a.uri, a.parent_id, a.name, a.description';
my @sel_props = qw(id site_id directory asset_grp_id _active uri parent_id name
                   description grp_ids);
my @cols = qw(site__id directory asset_grp_id active uri parent_id
              name description);
my @props = qw(site_id directory asset_grp_id _active uri parent_id
               name description);
my $METHS;

#--------------------------------------#
# Instance Fields

# This method of Bricolage will call 'use fields' for you and set some
# permissions.
BEGIN {
    Bric::register_fields({
                         # Public Fields
                         'id'              => Bric::FIELD_READ,
                         'site_id'         => Bric::FIELD_RDWR,
                         'directory'       => Bric::FIELD_RDWR,
                         'asset_grp_id'    => Bric::FIELD_READ,
                         'uri'             => Bric::FIELD_READ,
                         'parent_id'       => Bric::FIELD_RDWR,
                         'name'            => Bric::FIELD_RDWR,
                         'description'     => Bric::FIELD_RDWR,
                         'grp_ids'         => Bric::FIELD_READ,

                         # Private Fields
                         '_active'           => Bric::FIELD_NONE,
                         '_grp_active'       => Bric::FIELD_NONE,
                         '_attr_obj'         => Bric::FIELD_NONE,
                         '_attr'             => Bric::FIELD_NONE,
                         '_meta'             => Bric::FIELD_NONE,
                         '_save_children'    => Bric::FIELD_NONE,
                         '_update_uri'       => Bric::FIELD_RDWR,
                         '_kw_coll'          => Bric::FIELD_RDWR,
                        });
}

#==============================================================================#

=head1 Interface

=head2 Constructors

=over 4

=item $obj = new Bric::Biz::Category($init);

Create a new object of type Bric::Biz::Category. Once C<save()>d, the new
category will have the same group memberships as the parent, and have the same
permissions granted to its asset group as are granted to the parent's asset
group.

Keys for $init are:

=over 4

=item *

name

The name for this category.

=item *

site_id

The ID for the site this category is in.

=item *

description

A description of this category

=item *

directory

The directory name this category should be associated with.

=back

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub new {
    my ($pkg, $init) = @_;
    $init->{_active} = 1;
    push @{$init->{grp_ids}}, INSTANCE_GROUP_ID;
    $pkg->SUPER::new($init);
}

#------------------------------------------------------------------------------#

=item @objs = Bric::Biz::Category->lookup({ id => $cat_id });

=item @objs = Bric::Biz::Category->lookup({ uri => $uri });

Return an object given an ID or URI, both of which are unique across URIs.

B<Throws:>

=over 4

=item *

Too many category objects found.

=back

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub lookup {
    my $pkg = shift;
    my $cat = $pkg->cache_lookup(@_);
    return $cat if $cat;

    $_[0]->{active} = 'all';
    $cat = $pkg->_do_list(@_);
    # We want @$cat to have only one value.
    throw_dp(error => 'Too many ' . __PACKAGE__ . ' objects found.')
      if @$cat > 1;
    return @$cat ? $cat->[0] : undef;
}

#------------------------------------------------------------------------------#

=item @objs = Bric::Biz::Category->list($crit);

Return a list of category objects based on certain criteria

Criteria keys:

=over 4

=item id

Category ID. May use C<ANY> for a list of possible values.

=item name

The name of the category. May use C<ANY> for a list of possible values.

=item directory

The category directory name. May use C<ANY> for a list of possible values.

=item uri

The category URI. May use C<ANY> for a list of possible values.

=item active

=item description

The category description. May use C<ANY> for a list of possible values.

=item parent_id

The ID category of a parent category. May use C<ANY> for a list of possible
values.

=item grp_id

The ID of a Bric::Util::Grp object to which the category belongs. May use
C<ANY> for a list of possible values.

=item site_id

The ID of a Bric::Biz::Site object with which the category is associated. May
use C<ANY> for a list of possible values.

=item active_sites

A boolean causing only categories associated with active sites to be returned.

=back

B<Throws:>

"Method not implemented"

B<Side Effects:>

NONE

B<Notes:>

This is the default list constructor which should be overridden in all derived
classes even if it just calls 'die'.

=cut

sub list { _do_list(@_) }

#--------------------------------------#

=back

=head2 Destructors

=over 4

=item $cat->DESTROY()

Deletes the object.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub DESTROY {
    # This method should be here even if its empty so that we don't waste time
    # making Bricolage's autoload method try to find it.
}

=back

=head2 Public Class Methods

=over 4

=item my $meths = Bric::Biz::Category->my_meths

=item my (@meths || $meths_aref) = Bric::Biz::Category->my_meths(TRUE)

=item my (@meths || $meths_aref) = Bric::Biz::Category->my_meths(0, TRUE)

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

An anonymous hash of key/value pairs reprsenting the values and display names
to use in a select list.

=back

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub my_meths {
    my ($pkg, $ord, $ident) = @_;

    # We don't got 'em. So get 'em!
    $METHS ||= {
              name        => {
                              name     => 'name',
                              get_meth => sub { shift->get_name(@_) },
                              get_args => [],
                              set_meth => sub { shift->set_name(@_) },
                              set_args => [],
                              disp     => 'Name',
                              type     => 'short',
                              len      => 128,
                              req      => 1,
                              props    => { type       => 'text',
                                            length     => 32,
                                            maxlength  => 64
                                          }
                             },
              site_id     => {
                              name     => 'site_id',
                              get_meth => sub { shift->get_site_id(@_) },
                              get_args => [],
                              set_meth => sub { shift->set_site_id(@_) },
                              set_args => [],
                              disp     => 'Site ID',
                              type     => 'short',
                              len      => 10,
                              req      => 1,
                                            # Should actually be 'select'.
                                            # Someday...
                              props    => { type       => 'text',
                                            length     => 10,
                                            maxlength  => 10
                                          }
                             },
              site        => {
                              name     => 'site',
                              get_meth => sub { my $s = Bric::Biz::Site->lookup
                                                  ({ id => shift->get_site_id })
                                                  or return;
                                                $s->get_name;
                                            },
                              disp     => 'Site',
                              type     => 'short',
                              req      => 0,
                              props    => { type       => 'text',
                                            length     => 10,
                                            maxlength  => 10
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
                              type     => 'short',
                              props    => { type => 'textarea',
                                            cols => 40,
                                            rows => 4
                                          }
                             },
              directory        => {
                              name     => 'directory',
                              get_meth => sub { shift->get_directory(@_) },
                              get_args => [],
                              set_meth => sub { shift->set_directory(@_) },
                              set_args => [],
                              disp     => 'Directory',
                              type     => 'short',
                              len      => 128,
                              req      => 1,
                              props    => { type       => 'text',
                                            length     => 32,
                                            maxlength  => 128
                                          }
                             },
              uri         => {
                              name     => 'uri',
                              get_meth => sub { shift->get_uri(@_) },
                              get_args => [],
                              disp => 'URI',
                              type     => 'short',
                              len      => 256,
                              search   => 1,
                              props    => { type       => 'text',
                                            length     => 32,
                                            maxlength  => 128
                                          }
                             },
              ad_string   => {
                              name     => 'ad_string',
                              get_meth => sub { shift->get_ad_string(@_) },
                              get_args => [],
                              set_meth => sub { shift->set_ad_string(@_) },
                              set_args => [],
                              disp     => 'Ad String',
                              type     => 'short',
                              len      => 1024,
                              props    => { type       => 'text',
                                            length     => 32,
                                            maxlength  => 1024
                                          }
                             },
              ad_string2  => {
                              name     => 'ad_string2',
                              get_meth => sub { shift->get_ad_string2(@_) },
                              get_args => [],
                              set_meth => sub { shift->set_ad_string2(@_) },
                              set_args => [],
                              disp     => 'Ad String 2',
                              type     => 'short',
                              len      => 1024,
                              props    => { type       => 'text',
                                            length     => 32,
                                            maxlength  => 1024
                                          }
                             },
             };

    if ($ord) {
        return wantarray ? @{$METHS}{&ORD} : [@{$METHS}{&ORD}];
    } elsif ($ident) {
        return wantarray ? $METHS->{uri} : [$METHS->{uri}];
    } else {
        return $METHS;
    }
}

##############################################################################

=item my (@person_ids || $person_ids_aref) = Bric::Biz::Person->list_ids($params)

Returns a list or anonymous array of Bric::Biz::Category object IDs based on the
search criteria passed via an anonymous hash. The supported lookup keys are the
same as those for C<list()>.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub list_ids { _do_list(@_, 1) }

##############################################################################

=item $cat = Bric::Biz::Category->site_root_category($site || $site_id)

=item $cat_id = Bric::Biz::Category->site_root_category_id($site || $site_id)

=item $cat = $cat->site_root_category()

=item $cat_id = $cat->site_root_category_id()

Return the root category and the root category ID for a particular site.  If
called as an instance method the site or site ID is not necessary;  that
information will be pulled from $cat->get_site_id.

Returns the category or category ID of the root category for this site.

B<Throws:>

=over 4

=item *

Could not determine the site ID for the current site.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub site_root_category {
    my $class = shift;
    my ($site) = @_;

    # Handle being called as a class or instance method.
    my $self = ref $class ? $class : undef;
    $site = $self->get_site_id if $self;

    # Get the site ID whether $site is an object or the ID itself
    my $site_id = ref $site ? $site->get_id : $site;

    unless ($site_id) {
        my $msg = 'Could not determine the site ID for the current site';
        throw_dp(error => $msg);
    }

    my $sr = $class->list({parent_id => 0,
                           site_id   => $site_id});

    return $sr->[0];
}

sub site_root_category_id {
    my $class = shift;
    my ($site) = @_;

    my $c_obj = $class->site_root_category($site);

    return unless $c_obj;
    return $c_obj->get_id;
}

sub create_new_root_category {
    my $class = shift;
    my ($site) = @_;
    my $cat = Bric::Biz::Category->new;

    my $name = $site->get_name;

    $cat->_set([qw(site_id directory uri parent_id name description)],
               [$site->get_id, '', '/', 0, "$name Root Category",
                "$name root category"]);
    $cat->save;
}

##############################################################################

=back

=head2 Public Instance Methods

=over

=item @objs = $cat->ancestry();

Return all the parent category of this category

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub ancestry {
    my $self = shift;
    my $cur = $self;
    my @objs = ($cur);

    while ($cur = $cur->get_parent) {
        unshift @objs, $cur;
    }

    return wantarray ? @objs : \@objs;
}

#------------------------------------------------------------------------------#

=item my $path = $cat->ancestry_path();

An alias for get_uri().

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

=item my $uri = $cat->get_uri();

Returns the list of ancestors for this category formatted into a URI.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub ancestry_path { shift->get_uri }

#------------------------------------------------------------------------------#

=item my $path = $cat->ancestry_dir();

Returns the list of ancestors for this category formatted into a localized
directory structure.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub ancestry_dir {
    Bric::Util::Trans::FS->cat_dir('', map { $_->get_directory }
                                   shift->ancestry(@_));
}


=item my $dir = $cat->set_directory($dir);

Sets this category's directory.

B<Throws:>

NONE

B<Side Effects:>

Sets the I<_update_uri> flag, which means that when the category's information
is saved to the database, the URI field needs to be updated for itself and all
its children.

B<Notes:>

NONE

=cut

sub set_directory {
    my ($self, $dir) = @_;
    throw_dp(error => "Cannot change the directory of the root category")
      if $self->is_root_category;
    $self->_set(['directory', '_update_uri'], [$dir, 1]);
}


=item my $dir = $cat->set_parent_id($parent_id);

Sets this category's parent ID, making it a child of that category.

B<Throws:>

NONE

B<Side Effects:>

Sets the I<_update_uri> flag, which means that when the category's information
is saved to the database, the URI field needs to be updated for itself and all
its children.

B<Notes:>

NONE

=cut

sub set_parent_id {
    my ($self, $pid) = @_;
    my $id = $self->_get('id');
    if (defined $id) {
        throw_dp(error => "Cannot change the parent of the root category")
          if $self->is_root_category;
        throw_dp(error => "Categories cannot be their own parent")
          if $id == $pid;
    }
    $self->_set(['parent_id', '_update_uri'], [$pid, 1]);
}


#------------------------------------------------------------------------------#


=item $val = $element->set_ad_string($value);

=item $self = $element->get_ad_string;

=item $val = $element->set_ad_string2($value);

=item $self = $element->get_ad_string2;

Get/Set ad strings on this category.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub set_ad_string {
    my ($self, $value) = @_;
    return $self->set_attr(':ad:string', $value);
}

sub get_ad_string {
    my $self = shift;
    return $self->get_attr(':ad:string');

#    if (defined $name) {
#       return $self->get_attr(':ad:'.$name);
#    } else {
#       my $attrs = $self->get_attr;
#       my @names = grep(substr($_, 0, 4) eq ':ad:', keys %$attrs);
#       return {map { substr($_, 4) => $attrs->{$_} } @names};
#    }
}

sub set_ad_string2 {
    my ($self, $value) = @_;
    return $self->set_attr(':ad:string2', $value);
}

sub get_ad_string2 {
    my $self = shift;
    return $self->get_attr(':ad:string2');
}


### these functions are automatic

=item $name = $cat->get_id;

Return the ID of this category.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=item $name = $cat->get_name;

Return the name of this category.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=item $self = $cat->set_name($name);

Sets the name of this category.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=item $name = $cat->get_site_id;

Return the site ID for this category.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=item $name = $cat->set_site_id($id);

Set the site ID for this category.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=item $desc = $cat->get_description;

Returns the description of this category.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=item $self = $cat->set_description($desc);

Sets the description of this category, first converting non-Unix line endings.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub set_description {
    my ($self, $val) = @_;
    $val =~ s/\r\n?/\n/g if defined $val;
    $self->_set( [ 'description' ] => [ $val ]);
}

#------------------------------------------------------------------------------#

=item $val = $element->set_attr($name, $value);

=item $val = $element->get_attr($name);

Get/Set attributes on this category.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub set_attr {
    my $self = shift;
    my ($name, $val) = @_;
    my ($attr, $attr_obj) = $self->_get('_attr', '_attr_obj');

    if ($attr_obj) {
        $attr_obj->set_attr({'name'     => $name,
                             'sql_type' => 'short',
                             'value'    => $val});
    } else {
        $attr->{$name} = $val;

        $self->_set(['_attr'], [$attr]);
    }

    return $val;
}

sub get_attr {
    my $self = shift;
    my ($name) = @_;
    my $attr = $self->_get('_attr_obj');
    my $id = $self->get_id;

    return unless defined $id;

    unless ($attr) {
        $attr = Bric::Util::Attribute::Category->new({'object_id' => $id,
                                                    'subsys'    => $id});
        $self->_set(['_attr_obj'], [$attr]);
    }

    if (defined $name) {
        return $attr->get_attr({'name' => $name});
    } else {
        return $attr->get_attr_hash;
    }
}


#------------------------------------------------------------------------------#

=item $val = $element->set_meta($name, $field, $value);

=item $val = $element->get_meta($name, $field);

Get/Set attribute metadata on this category.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub set_meta {
    my $self = shift;
    my ($name, $field, $val) = @_;
    my ($meta, $attr_obj) = $self->_get('_meta', '_attr_obj');

    if ($attr_obj) {
        $attr_obj->add_meta({'name'  => $name,
                             'field' => $field,
                             'value' => $val});
    } else {
        push @{$meta->{$name}}, [$field, $val];

        $self->_set(['_meta'], [$meta]);
    }

    return $val;
}

sub get_meta {
    my $self = shift;
    my ($name, $field) = @_;
    my $attr = $self->_get('_attr_obj');
    my $id = $self->get_id;

    return unless $id;

    unless ($attr) {
        $attr = Bric::Util::Attribute::Category->new({'object_id' => $id,
                                                    'subsys'    => $id});
        $self->_set(['_attr_obj'], [$attr]);
    }

    return $attr->get_meta({'name'  => $name,
                            'field' => $field});
}

#------------------------------------------------------------------------------#

=item @keys = $cat->get_keywords;

=item @keys = $cat->get_keywords(@keyword_ids);

Returns a list of keyword objects associated with this category. If passed
a list of keyword IDs, it will return only those keyword objects.

B<Throws:> NONE

B<Side Effects:> NONE

B<Notes:> The old C<keywords()> method has been deprecated. Please use
C<get_keywords()>, instead.

=cut

sub get_keywords {
    my $self = shift;
    my $kw_coll = &$get_kw_coll($self);
    $kw_coll->get_objs(@_);
}

sub keywords {
    warn __PACKAGE__ . "->keywords has been deprecated.\n" .
      "Use ", __PACKAGE__, "->get_keywords instead";
    $_[0]->get_keywords;
}

#------------------------------------------------------------------------------#

=item @cats = $cat->get_children;

Returns the children of this category.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_children {
    my $self = shift;
    my $id = $self->_get('id');
    return unless defined $id;
    return Bric::Biz::Category->list({ parent_id => $id });
}

*children = \&get_children;

#------------------------------------------------------------------------------#

=item my $parent = $cat->get_parent;

Returns the parent of this category or undef if it is a top level category.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_parent {
    my $self = shift;
    my $id   = $self->get_id;
    my $pid  = $self->get_parent_id;

    return if $self->is_root_category;
    return Bric::Biz::Category->lookup({id => $pid});
}

*parent = \&get_parent;  # alias that we will get rid of soon

#------------------------------------------------------------------------------#

=item $success = $cat->add_child([$cat || $cat_id]);

Addes a category as a child of this category.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub add_child {
    my ($self, $cat) = @_;
    my $pid = $self->get_id;
    $_->set_parent_id($pid) for @$cat;
}

#------------------------------------------------------------------------------#

=item $cat = $cat->add_keywords(@keywords);

=item $cat = $cat->add_keywords(\@keywords);

=item $cat = $cat->add_keywords(@keyword_ids);

=item $cat = $cat->add_keywords(\@keyword_ids);

Associates a each of the keyword in a list or array reference of keywords with
the category object.

B<Throws:> NONE.

B<Side Effects:> NONE

B<Notes:> The old C<add_keyword()> method has been deprecated. Please use
C<add_keywords()>, instead.

=cut

sub add_keywords {
    my $self = shift;
    my $kw_coll = &$get_kw_coll($self);
    $self->_set__dirty(1);
    $kw_coll->add_new_objs(ref $_[0] eq 'ARRAY' ? @{$_[0]} : @_);
}

sub add_keyword {
    warn __PACKAGE__ . "->add_keyword has been deprecated.\n" .
      "Use ", __PACKAGE__, "->add_keywords instead";
    $_[0]->add_keywords(@{$_[1]});
}

#------------------------------------------------------------------------------#

=item $cat = $cat->del_keywords(@keywords);

=item $cat = $cat->del_keywords(\@keywords);

=item $cat = $cat->del_keywords(@keyword_ids);

=item $cat = $cat->del_keywords(\@keyword_ids);

Dissociates a list or array reference of keyword objects or IDs from the
category object.

B<Throws:> NONE.

B<Side Effects:> NONE

B<Notes:> The old C<del_keyword()> method has been deprecated. Please use
C<del_keywords()>, instead.

=cut

sub del_keywords {
    my $self = shift;
    my $kw_coll = &$get_kw_coll($self);
    $self->_set__dirty(1);
    $kw_coll->del_objs(ref $_[0] eq 'ARRAY' ? @{$_[0]} : @_);
}

sub del_keyword {
    warn __PACKAGE__ . "->del_keyword has been deprecated.\n" .
      "Use ", __PACKAGE__, "->del_keywords instead";
    $_[0]->del_keywords(@{$_[1]});
}

#------------------------------------------------------------------------------#

=item $att = $att->is_root_category;

Return whether this is a root category or not

B<Throws:>
NONE

B<Side Effects:>
NONE

B<Notes:>
NONE

=cut

sub is_root_category {
    my $self = shift;
    my $parent = $self->get_parent_id;
    return defined $parent && $parent ne '' && $parent == 0 ? $self : undef;
}

#------------------------------------------------------------------------------#

=item $att = $att->is_active;

=item $att = $att->activate;

=item $att = $att->deactivate;

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
    my ($param) = @_;
    my $recurse = $param->{'recurse'};

    $self->_set([qw(_active _grp_active)] => [1, 1])
      unless $self->_get('_active');

    # Recursively activate children if the recurse flag is set.
    if ($recurse) {
        my @cat = $self->get_children;
        foreach (@cat) {
            $_->activate($param);
        }

        $self->_set(['_save_children'], [\@cat]);
    }

    $self->_set__dirty(1);

    return $self;
}

sub deactivate {
    my $self = shift;
    my ($param) = @_;
    my $recurse = $param->{'recurse'};

    # Do not allow deactivation of the root category.
    my $id = $self->get_id;
    return if not defined $id || $self->is_root_category;

    $self->_set([qw(_active _grp_active)] => [0, 0])
      if $self->_get('_active');

    # Recursively activate children if the recurse flag is set.
    if ($recurse) {
        my @cat = $self->get_children;
        foreach (@cat) {
            $_->deactivate($param);
        }

        $self->_set(['_save_children'], [\@cat]);
    }

    $self->_set__dirty(1);

    return $self;
}

#------------------------------------------------------------------------------#

=item $cat = $cat->save

Save this category

B<Throws:> NONE.

B<Side Effects:> A new category will automatically be added to the same category
groups as its parent, and permissions will be granted to its asset group
exactly as they are granted to the parent.

B<Notes:> NONE.

=cut

sub save {
    my $self = shift;
    my $id = $self->get_id;

    my ($dir, $kw_coll) = $self->_get(qw(directory _kw_coll));

    # Set the directory unless its set ('' counts) and its not the root category
    unless ((defined $dir && $dir ne '') || $self->is_root_category) {
        # Set a default directory name.
        my $dir = lc $self->get_name;
        $dir =~ y/[a-z]//cd if $dir;
        $self->set_directory($dir);
    }

    # Save our category information
    if (defined $id) {
        $self->_update_category();
    } else {
        $self->_insert_category();
    }

    # Recursively save children if the _save_children flag is set.
    if ($self->_get('_save_children')) {
        foreach (@{$self->_get('_save_children')}) {
            $_->save;
        }
        $self->_set(['_save_children'], [undef]);
    }

    # Update the keywords.
    $kw_coll->save($self) if $kw_coll;

    $self->_save_attr;
    return $self;
}

#==============================================================================#

=back

=head2 Private Methods

NONE.

=head2 Private Class Methods

NONE

=head2 Private Instance Methods

Several that need documenting!

=over

=item _do_list

=cut

sub _do_list {
    my ($pkg, $params, $ids) = @_;
    my $tables = "$table a, $mem_table m, $map_table c";
    my $wheres = "a.id = c.object_id AND c.member__id = m.id AND m.active = '1' ".
                 'AND a.id <> 0';
    my @params;

    # Set up the active property.
    if (exists $params->{active}) {
        if ($params->{active} eq 'all') {
            delete $params->{active};
        } else {
            $wheres .= " AND a.active = ?";
            push @params, delete $params->{active} ? 1 : 0;
        }
    } else {
        $wheres .= " AND a.active = ?";
        push @params, 1;
    }

    # Set up the other query properties.
    while (my ($k, $v) = each %$params) {
        if ($k eq 'id' or $k eq 'parent_id') {
            # It's a simple numeric comparison.
            $wheres .= ' AND ' . any_where($v, "a.$k = ?", \@params);
            # Keep us from returning the super root category
            if ($k eq 'parent_id'
                and ((ref $v && grep { $_ == 0 } @$v) || $v == 0))
            {
                $wheres .= " AND a.id <> ?";
                push @params, 0;
            }
        } elsif ($k eq 'site_id') {
            $wheres .= ' AND ' . any_where($v, "a.site__id = ?", \@params);
        } elsif ($k eq 'grp_id') {
            # Fancy-schmancy second join.
            $tables .= ", $mem_table m2, $map_table c2";
            $wheres .= " AND a.id = c2.object_id AND c2.member__id = m2.id "
              . " AND m2.active = '1' AND "
              . any_where($v, "m2.grp__id = ?", \@params);
        } elsif ($k eq 'active_sites') {
            next unless $v;
            $tables .= ', site';
            $wheres .= ' AND a.site__id = site.id AND site.active = TRUE';
        } else {
            # It's a simpler string comparison.

            # category uri must end with slash
            if ($k eq 'uri') {
                # note: the regexps here say: if the last character
                # of the URI isn't % or / then add a /
                if (ref $v) {    # ANY, NONE
                    s{(?<=[^%/])$}{/} for @$v;
                } else {         # just a string
                    $v =~ s{(?<=[^%/])$}{/};
                }
            }

            $wheres .= ' AND '
              . any_where($v, "LOWER(a.$k) LIKE LOWER(?)", \@params);
        }
    }

    # Create the where clause and the select and order by clauses.
    my ($qry_cols, $order, $group_by) = $ids
        ? (\'DISTINCT a.id', '', '')
        : (\$sel_cols, 'ORDER BY a.uri', "GROUP BY $grp_cols");

    # Prepare the statement.
    my $sel = prepare_c(qq{
        SELECT $$qry_cols
        FROM   $tables
        WHERE  $wheres
        $group_by
        $order
    }, undef);

    # Just return the IDs, if they're what's wanted.
    return wantarray ? @{col_aref($sel, @params)} : col_aref($sel, @params)
      if $ids;

    execute($sel, @params);
    my (@d, @cats);
    bind_columns($sel, \@d[0..$#sel_props]);
    $pkg = ref $pkg || $pkg;
    while (fetch($sel)) {
        # Create a new Category object.
        my $self = bless {}, $pkg;
        $self->SUPER::new;
        # Parse the group IDs.
        $d[-1] = [ map { split } $d[-1] ];
        $self->_set(\@sel_props, \@d);
        $self->_set__dirty; # Disable the dirty flag.
        push @cats, $self->cache_me;
    }
    return wantarray ? @cats : \@cats;
}

=item _save_attr

=cut

sub _save_attr {
    my $self = shift;
    my ($attr, $meta, $a_obj) = $self->_get('_attr', '_meta', '_attr_obj');
    my $id = $self->get_id;

    unless ($a_obj) {
        $a_obj = Bric::Util::Attribute::Category->new({'object_id' => $id,
                                                     'subsys'    => $id});
        $self->_set(['_attr_obj'], [$a_obj]);

        while (my ($k,$v) = each %$attr) {
            $a_obj->set_attr({'name'     => $k,
                              'sql_type' => 'short',
                              'value'    => $v});
        }

        while (my ($k,$m) = each %$meta) {
            foreach (@$m) {
                my ($f, $v) = @$_;

                $a_obj->add_meta({'name'  => $k,
                                  'field' => $f,
                                  'value' => $v});
            }
        }

    }

    $a_obj->save;
}

=item _load_grp

=cut

sub _load_grp {
    my $self = shift;
    my ($gtype, $id_field, $obj_field) = @_;
    my ($id, $obj) = $self->_get($id_field, $obj_field);

    $gtype = "Bric::Util::Grp::$gtype";

    # Return if we don't even have an ID
    # return unless $id;

    if ($id) {
        # There are no items for this category in the group
        $obj = $gtype->lookup({'id' => $id});
    } else {
        $obj = $gtype->new({'name' => 'Group for Category'});
    }

    # HACK: This should throw an error object.
    unless ($obj) {
        my $err_msg = 'Failed to instantiate group';
        throw_dp(error => $err_msg);
    }

    $self->_set([$obj_field],[$obj]);

    return $obj;
}

=item _update_category

=cut

sub _update_category {
    my $self = shift;
    my ($id) = $self->_get(qw(id));

    my $sth = prepare_c(qq{
        UPDATE $table
        SET    ${\join(',', map {"$_=?"} @cols)}
        WHERE  id = ?
    }, undef);
    my $new_uri;

    if ($self->_get('_update_uri') and not $self->is_root_category) {
        $self->_set(['_update_uri'], [0]);
        $new_uri = Bric::Util::Trans::FS->cat_uri(
            $self->get_parent->get_uri,
            $self->_get('directory'),
        ) . '/';
        $self->_set(['uri'], [$new_uri]);
    }

    execute($sth, $self->_get(@props), $self->get_id);

    my $ag;
    if ($new_uri) {
        # Change the URI in the asset group description.
        $ag = Bric::Util::Grp::Asset->lookup({
            id => $self->_get('asset_grp_id')
        });
        $ag->set_description($new_uri);

        # Update the subcategory URIs.
        for my $subcat ($self->get_children) {
            $subcat->set_directory($subcat->_get('directory'));
            $subcat->_update_category;
        }
    }

    my $gact = $self->_get('_grp_active');
    if (defined $gact) {
        # Deactivate the asset group.
        $ag ||= Bric::Util::Grp::Asset->lookup({
            id => $self->_get('asset_grp_id')
        });
        $ag->deactivate;
        $self->_set(['_grp_active'] => [undef]);
    }

    $ag->save if $ag;
}

=item _insert_category

=cut

sub _insert_category {
    my $self = shift;
    my $site_id = $self->_get('site_id');

    # Prepare the insert statement.
    my $nextval = next_key($table);
    my $sql = "INSERT INTO $table (id,".join(',',@cols).") ".
              "VALUES ($nextval,".join(',', ('?') x @cols).')';

    my $sth = prepare_c($sql, undef);

    # Make sure we can use this code to insert new root categories for newly
    # created sites.  These root categories will set their own uri.
    unless ($self->is_root_category) {
        # Set the URI
        my $uri = Bric::Util::Trans::FS->cat_uri(
            $self->get_parent->get_uri,
            $self->_get('directory')
        ) . '/';
        $self->_set(['uri'], [$uri]);
    }

    # Set up a group. This isn't used anywhere or for anything other than
    # to have a way to get a group ID from a category to track assets and
    # permissions. The assets will pretend they're in the group, even though
    # they're really not. See Bric::Biz::Asset->get_grp_ids to see it at work.
    # XXX Yes, it's ugly that we're abusing the name this way, but it does the
    # trick.
    my $ag_obj = Bric::Util::Grp::Asset->new({
        name        => "Site $site_id Category Assets",
        description => $self->get_uri
    });

    $ag_obj->save;
    my $ag_id = $ag_obj->get_id;
    $self->_set(['asset_grp_id'], [$ag_id]);

    # Insert the new category.
    execute($sth, $self->_get(@props));

    # Set the ID of this object.
    $self->_set(['id'] => [last_key($table)]);

    # Add the category to the 'All Categories' group.
    $self->register_instance(INSTANCE_GROUP_ID, GROUP_PACKAGE);

    # Add it to all of the same groups as the parent category.
    my $parent = $self->get_parent or return $self;
    if (my @gids = grep { $_ != INSTANCE_GROUP_ID } $parent->get_grp_ids) {
        for my $grp (Bric::Util::Grp->list({ id => ANY(@gids) })) {
            $grp->add_member({ obj => $self, no_check => 1 });
            $grp->save;
        }
    }

    # Give its asset group the same permission associations as the parent.
    for my $perm (Bric::Util::Priv->list({
        obj_grp_id => $parent->get_asset_grp_id
    })) {
        # Create a matching permission for the new category.
        $perm = Bric::Util::Priv->new({
            obj_grp => $ag_id,
            usr_grp => $perm->get_usr_grp_id,
            value   => $perm->get_value,
        });
        $perm->save;
    }

    return $self;
}

##############################################################################

=item my $kw_coll = &$get_kw_coll($self)

Returns the collection of keywords for this category. The collection is a
Bric::Util::Coll::Keyword object. See that class and its parent,
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

NONE.

=head1 Author

Garth Webb <garth@perijove.com>

Jeff "japhy" Pinyan <japhy@pobox.com>

David Wheeler <david@justatheory.com>

=head1 See Also

L<perl>, L<Bric::Util::Grp::Category>, L<Bric>, L<Bric::Biz::Keyword>,
L<Bric::Biz::Asset>

=cut
