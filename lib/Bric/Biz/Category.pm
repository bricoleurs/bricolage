package Bric::Biz::Category;
###############################################################################

=head1 NAME

Bric::Biz::Category - A module to group assets into categories.

=head1 VERSION

$Revision: 1.43 $

=cut

our $VERSION = (qw$Revision: 1.43 $ )[-1];

=head1 DATE

$Date: 2003-02-20 21:04:57 $

=head1 SYNOPSIS

 # Return a new category object.
 my $cat = new Bric::Biz::Category($init);

 my $cat = lookup Bric::Biz::Category({'id' => $cat_id});

 my $cat = list Bric::Biz::Category($crit);

 $cat->get_name;
 $cat->get_description;

 # Return a list of keywords associated with this category.
 @keys   = $cat->keywords();
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

 # Add/Delete keywords associated with this category.
 $cat->add_keyword([$kw_id]);
 $cat->del_keyword([$kw_id]);

 # Save information for this category to the database.
 $cat->save;

=head1 DESCRIPTION

Allows assets to be grouped into categories. In addition to assets a category
can contain other categories, allowing a hierarchical layout of categories and
assets.

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
use Bric::Util::Fault::Exception::GEN;
use Bric::Util::Fault::Exception::DP;
use Bric::Util::DBI qw(:standard col_aref);
use Bric::Util::Grp::Asset;

#==============================================================================#
# Inheritance                          #
#======================================#

use base qw(Bric);

#=============================================================================#
# Function Prototypes                  #
#======================================#



#==============================================================================#
# Constants                            #
#======================================#
use constant DEBUG => 0;
use constant ORD => qw(name description uri directory ad_string ad_string2);

use constant ROOT_CATEGORY_ID   => 0;
use constant INSTANCE_GROUP_ID => 26;
use constant GROUP_PACKAGE => 'Bric::Util::Grp::CategorySet';

#==============================================================================#
# Fields                               #
#======================================#

#--------------------------------------#
# Public Class Fields

#--------------------------------------#
# Private Class Fields
my $gen = 'Bric::Util::Fault::Exception::GEN';
my $dp = 'Bric::Util::Fault::Exception::DP';
my $table = 'category';
my $mem_table = 'member';
my $map_table = $table . "_$mem_table";
my $sel_cols = "a.id, a.directory, a.asset_grp_id, a.active, a.uri, " .
  "a.parent_id, a.name, a.description, m.grp__id";
my @sel_props = qw(id directory asset_grp_id _active uri parent_id name
                   description grp_ids);
my @cols = qw(directory asset_grp_id  active uri parent_id name description);
my @props = qw(directory asset_grp_id _active uri parent_id name description);
my $METHS;

#--------------------------------------#
# Instance Fields

# This method of Bricolage will call 'use fields' for you and set some
# permissions.
BEGIN {
    Bric::register_fields({
                         # Public Fields
                         'id'              => Bric::FIELD_READ,
                         'directory'       => Bric::FIELD_RDWR,
                         'asset_grp_id'    => Bric::FIELD_READ,
                         'uri'             => Bric::FIELD_READ,
                         'parent_id'       => Bric::FIELD_RDWR,
                         'name'            => Bric::FIELD_RDWR,
                         'description'     => Bric::FIELD_RDWR,
                         'grp_ids'         => Bric::FIELD_READ,

                         # Private Fields
                         '_attr_obj'         => Bric::FIELD_NONE,
                         '_attr'             => Bric::FIELD_NONE,
                         '_meta'             => Bric::FIELD_NONE,
                         '_save_children'    => Bric::FIELD_NONE,
                         '_update_uri'       => Bric::FIELD_RDWR,
                        });
}

#==============================================================================#

=head1 INTERFACE

=head2 Constructors

=over 4

=item $obj = new Bric::Biz::Category($init);

Create a new object of type Bric::Biz::Category

Keys for $init are:

=over 4

=item *

name

The name for this category.

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

    $cat = $pkg->_do_list(@_);
    # We want @$cat to have only one value.
    die Bric::Util::Fault::Exception::DP->new
      ({ msg => 'Too many ' . __PACKAGE__ . ' objects found.' })
      if @$cat > 1;
    return @$cat ? $cat->[0] : undef;
}

#------------------------------------------------------------------------------#

=item @objs = list Bric::Biz::Category($crit);

Return a list of category objects based on certain criteria

Criteria keys:

=over 4

=item name

=item directory

=item uri

=item active

=item description

=item parent_id

=item grp_id

=back

B<Throws:>

"Method not implemented"

B<Side Effects:>

NONE

B<Notes:>

This is the default list constructor which should be overrided in all derived
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
                              len      => 64,
                              req      => 1,
                              props    => { type       => 'text',
                                            length     => 32,
                                            maxlength  => 64
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
    my @objs;
    my $cur = $self;

    unshift @objs, $cur;

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


=item C<my $dir = $cat->set_directory($dir);>

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
    my $id = $self->_get('id');
    die $dp->new({ msg => "Cannot change the directory of the root category" })
      if defined $id and $id == ROOT_CATEGORY_ID;
    $self->_set(['directory', '_update_uri'], [$dir, 1]);
}


=item C<my $dir = $cat->set_parent_id($parent_id);>

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
        die $dp->new({ msg => "Cannot change the parent of the root category" })
          if $id == ROOT_CATEGORY_ID;
        die $dp->new({ msg => "Categories cannot be their own parent" })
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

=item $name = $cat->get_description;

Returns the description of this category.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=item $self = $cat->set_description($desc);

Sets the description of this category.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

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

=item @keys = $cat->keywords();

Returns a list of keywords associated with this category.

B<Throws:> NONE

B<Side Effects:> NONE

B<Notes:> NONE

=cut

sub keywords {
    my $self = shift;
    return Bric::Biz::Keyword->list({ object => $self });
}

#------------------------------------------------------------------------------#

=item C<my @cats = $cat->get_children;>

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

=item C<my $parent = $cat->get_parent;>

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
    return if
      defined $id and $id == ROOT_CATEGORY_ID or
      not defined $pid;
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

=item $success = $cat->add_keyword([$kw || $kw_id]);

Associates a keyword with this category.

B<Throws:>

No keyword object found for id '$k'

B<Side Effects:> NONE

B<Notes:> NONE

=cut

sub add_keyword {
    my ($self, $keywords) = @_;
    my $keyword;

    foreach my $k (@$keywords) {
        # find object for id
        if (ref $k) {
            $keyword = $k;
        } else {
            $keyword = Bric::Biz::Keyword->lookup({id => $k});
            die $gen->new({ msg => "No keyword object found for id '$k'" })
              unless defined $keyword;
        }

        # associate keyword with this category
        $keyword->associate($self);
    }
}

#------------------------------------------------------------------------------#

=item $success = $cat->del_keyword([$kw || $kw_id]);

Removes keyword associations from this category.

B<Throws:>

No keyword object found for id '$k'

B<Side Effects:> NONE

B<Notes:> NONE

=cut

sub del_keyword {
    my ($self, $keywords) = @_;

    my $keyword;    
    foreach my $k (@$keywords) {
        # find object for id
        if (ref $k) {
            $keyword = $k;
        } else {
            $keyword = Bric::Biz::Keyword->lookup({id => $k});
            die Bric::Util::Fault::Exception::GEN->new(
                 { msg => "No keyword object found for id '$k'" } )
              unless defined $keyword;
        }
        
        # dissociate keyword with this category.
        $keyword->dissociate($self);
    }
    
    return $self;
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
    
    $self->_set(['_active'], [1]);
    
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
    return if !defined $id || $id == ROOT_CATEGORY_ID;

    $self->_set(['_active'], [0]);

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

=item $success = $cat->save

Save this category

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub save {
    my $self = shift;
    my $id = $self->get_id;

    my $dir = $self->_get(qw(directory));

    unless (defined $dir && $dir ne '' ||
            (defined $id && $id == ROOT_CATEGORY_ID)) {
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
    my (@wheres, @params);
    my $extra_tables = '';
    my $extra_wheres = '';

    # Set up the active property.
    if (exists $params->{active}) {
        if ($params->{active} eq 'all') {
            delete $params->{active};
        } else {
            push @wheres, "a.active = ?";
            push @params, $params->{active} ? 1 : 0;
        }
    } else {
        push @wheres, "a.active = ?";
        push @params, 1;
    }

    # Set up the other query properties.
    while (my ($k, $v) = each %$params) {
	if ($k eq 'id' or $k eq 'parent_id') {
            # It's a simple numeric comparison.
	    push @wheres, "a.$k = ?";
	    push @params, $v;
            if ($k eq 'parent_id' and $v == ROOT_CATEGORY_ID) {
                # We want to prevent the root category from returning itself
                push @wheres, "a.id <> ?";
                push @params, ROOT_CATEGORY_ID;
            }
        } elsif ($k eq 'grp_id') {
            # Fancy-schmancy second join.
            $extra_tables = ", $mem_table m2, $map_table c2";
            $extra_wheres = "AND a.id = c2.object_id AND " .
              "c2.member__id = m2.id";
            push @wheres, "m2.grp__id = ?";
            push @params, $v;
	} else {
            # It's a simpler string comparison.
	    push @wheres, "LOWER(a.$k) LIKE ?";
	    push @params, lc $v;
	}
    }

    # Create the where clause and the select and order by clauses.
    my $where = @wheres ? join(' AND ', @wheres) : '';
    my ($qry_cols, $order) = $ids ? (\'DISTINCT a.id', '') :
      (\$sel_cols, 'ORDER BY a.uri');

    # Prepare the statement.
    my $sel = prepare_c(qq{
        SELECT $$qry_cols
        FROM   $table a, $mem_table m, $map_table c $extra_tables
        WHERE  a.id = c.object_id AND c.member__id = m.id
               $extra_wheres AND $where
        $order
    }, undef, DEBUG);

    # Just return the IDs, if they're what's wanted.
    return wantarray ? @{col_aref($sel, @params)} : col_aref($sel, @params)
      if $ids;

    execute($sel, @params);
    my (@d, @cats, $grp_ids);
    bind_columns($sel, \@d[0..$#sel_props]);
    $pkg = ref $pkg || $pkg;
    my $last = -1;
    while (fetch($sel)) {
        if ($d[0] != $last) {
            $last = $d[0];
            # Create a new Category object.
            my $self = bless {}, $pkg;
            $self->SUPER::new;
            $grp_ids = $d[$#d] = [$d[$#d]];
            $self->_set(\@sel_props, \@d);
            # Add the attribute object.
            # HACK: Get rid of this object!
            $self->_set( ['_attr_obj'],
                         [ Bric::Util::Attribute::Category->new
                           ({ object_id => $d[0],
                              subsys => $d[0] })
                         ]
                       );
            $self->_set__dirty; # Disable the dirty flag.
            push @cats, $self->cache_me;
        } else {
            # Append the ID.
            push @$grp_ids, $d[$#d];
        }
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
        die Bric::Util::Fault::Exception::DP->new({'msg' => $err_msg});
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
    });
    my $new_uri;

    if ($self->_get('_update_uri') and $id != ROOT_CATEGORY_ID) {
        $self->_set(['_update_uri'], [0]);
        $new_uri = Bric::Util::Trans::FS->cat_uri
          ( $self->get_parent->get_uri,
            $self->_get('directory')
          );
        $self->_set(['uri'], [$new_uri]);
    }

    execute($sth, $self->_get(@props), $self->get_id);

    if ($new_uri) {
        # Change the URI in the asset group description.
        my $agid = $self->_get('asset_grp_id');
        my $ag = Bric::Util::Grp::Asset->lookup({ id => $agid });
        $ag->set_description($new_uri);
        $ag->save;

        # Update the subcategory URIs.
        for my $subcat ($self->get_children) {
            $subcat->set_directory($subcat->_get('directory'));
            $subcat->_update_category;
        }
    }
}

=item _insert_category

=cut

sub _insert_category {
    my $self = shift;

    # Prepare the insert statement.
    my $nextval = next_key($table);
    my $sql = "INSERT INTO $table (id,".join(',',@cols).") ".
              "VALUES ($nextval,".join(',', ('?') x @cols).')';

    my $sth = prepare_c($sql);

    # Set the URI.
    my $uri = Bric::Util::Trans::FS->cat_uri( $self->get_parent->get_uri,
                                              $self->_get('directory') );

    $self->_set(['uri'], [$uri]);

    # Set up a group. This isn't used anywhere or for anything other than
    # to have a way to get a group ID from a category to track assets. The
    # assets will pretend they're in the group, even though they're really not.
    # See Bric::Biz::Asset->get_grp_ids to see it at work.
    my $ag_obj = Bric::Util::Grp::Asset->new
      ({ name => 'Category Assets',
         description => $uri });
    $ag_obj->save;
    $self->_set(['asset_grp_id'], [$ag_obj->get_id]);

    # Insert the new category.
    execute($sth, $self->_get(@props));

    # Set the ID of this object.
    $self->_set(['id'],[last_key($table)]);

    # Add the category to the 'All Categories' group and return.
    $self->register_instance(INSTANCE_GROUP_ID, GROUP_PACKAGE);
    return $self;
}

1;
__END__

=back

=head1 NOTES

NONE.

=head1 AUTHOR

Garth Webb <garth@perijove.com>

Jeff "japhy" Pinyan <japhy@pobox.com>

David Wheeler <david@wheeler.net>

=head1 SEE ALSO

L<perl>, L<Bric::Util::Grp::Category>, L<Bric>, L<Bric::Biz::Keyword>,
L<Bric::Biz::Asset>

=cut
