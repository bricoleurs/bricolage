package Bric::Biz::Category;
###############################################################################

=head1 NAME

Bric::Biz::Category - A module to group assets into categories.

=head1 VERSION

$Revision: 1.29 $

=cut

our $VERSION = (qw$Revision: 1.29 $ )[-1];

=head1 DATE

$Date: 2002-10-29 21:01:01 $

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

use constant TABLE   => 'category';
use constant MTABLE  => Bric::Util::Grp::Parts::Member::TABLE;
use constant CMTABLE => TABLE . '_' . MTABLE;

use constant SELCOLS    => qw(a.directory a.asset_grp_id  a.active a.uri
                              a.parent_id a.name a.description c.grp__id);
use constant COLS    => qw(directory asset_grp_id  active uri parent_id name
                           description);
use constant FIELDS  => qw(directory asset_grp_id _active uri parent_id name
                           description);
use constant ORD     => qw(name description uri directory ad_string ad_string2);

use constant ROOT_CATEGORY_ID   => 0;
use constant INSTANCE_GROUP_ID => 26;
use constant GROUP_PACKAGE => 'Bric::Util::Grp::CategorySet';

#==============================================================================#
# Fields                               #
#======================================#

#--------------------------------------#
# Public Class Fields
our $METH;

#--------------------------------------#
# Private Class Fields
my $gen = 'Bric::Util::Fault::Exception::GEN';
my $dp = 'Bric::Util::Fault::Exception::DP';

#--------------------------------------#
# Instance Fields

# This method of Bricolage will call 'use fields' for you and set some permissions.
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
                         '_asset_grp'        => Bric::FIELD_NONE,
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

=cut

#--------------------------------------#
# Constructors                          

#------------------------------------------------------------------------------#

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
    my ($pkg, $init) = @_;
    my $ret;
    my $cat_id = $init->{id};
    if (defined $cat_id) {
        $ret = _select_category('a.id = ?', [$cat_id]);
    } elsif (my $uri = $init->{uri}) {
        $ret = _select_category('a.uri = ?', [$uri]);
    } else {
        $dp->new({ msg => "Only 'id' or 'uri' parameter allowed to new" });
    }

    # Check the data.
    return unless $ret->[0];
    die $dp->new({ msg => "Too many category objects found" })
      if @$ret > 1;

    # Construct the object.
    my $self = bless {}, ref $pkg || $pkg;

    # Set the columns selected as well as the passed ID.
    $self->_set(['id', FIELDS, 'grp_ids'], $ret->[0]);

    my $id = $self->get_id;
    my $a_obj = Bric::Util::Attribute::Category->new({'object_id' => $id,
                                                    'subsys'    => $id});
    $self->_set(['_attr_obj'], [$a_obj]);

    return $self;
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

=back

B<Throws:>

"Method not implemented"

B<Side Effects:>

NONE

B<Notes:>

This is the default list constructor which should be overrided in all derived 
classes even if it just calls 'die'.

=cut

sub list {
    my $class = shift;
    my ($param) = @_;
    my ($ret, @objs);
    my (@num, @txt);

    $param->{'active'} = exists $param->{'active'} ? $param->{'active'} :  1;
    # If 'all' is passed as the value of active, don't select based on active.
    delete $param->{'active'} if $param->{'active'} eq 'all';

    foreach (keys %$param) {
        if ($_ eq 'directory' or $_ eq 'name' or 
            $_ eq 'uri' or $_ eq 'description') { push @txt, $_ }
        else { push @num, $_ }
    }

    my $where = join(' AND ', (map { "a.$_ = ?" }             @num),
                              (map { "LOWER(a.$_) LIKE ?" } @txt));

    $ret = _select_category($where, [@$param{@num,@txt}]);

    foreach my $d (@$ret) {
        # Instantiate object
        my $self = bless {}, $class;

        # Set the columns selected as well as the passed ID.
        $self->_set(['id', FIELDS, 'grp_ids'], $d);

        my $id = $self->get_id;
        my $a_obj = Bric::Util::Attribute::Category->new({'object_id' => $id,
                                                        'subsys'    => $id});
        $self->_set(['_attr_obj'], [$a_obj]);

        push @objs, $self;
    }

    return wantarray ? @objs : \@objs;
}

#--------------------------------------#

=head2 Destructors

=cut

#------------------------------------------------------------------------------#

=item $cat->DESTROY()

Deletes the object.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

This method should be here even if its empty so that we don't waste time making 
Bricolage's autoload method try to find it.

=cut

sub DESTROY {
    # This method should be here even if its empty so that we don't waste time
    # making Bricolage's autoload method try to find it.
}

#--------------------------------------#

=head2 Public Class Methods

=over

=item my $meths = Bric::Util::Grp->my_meths

=item my (@meths || $meths_aref) = Bric::Util::Grp->my_meths(TRUE)

Returns an anonymous hash of instrospection data for this object. If called with
a true argument, it will return an ordered list or anonymous array of
intrspection data. The format for each introspection item introspection is as
follows:

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

=item *

type - The display field type. Possible values are

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

=item

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
    my ($pkg, $ord) = @_;

    # Return 'em if we got em.
    return !$ord ? $METH : wantarray ? @{$METH}{&ORD} : [@{$METH}{&ORD}]
      if $METH;

    # We don't got 'em. So get 'em!
    $METH = {
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
    return !$ord ? $METH : wantarray ? @{$METH}{&ORD} : [@{$METH}{&ORD}];
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

=item my @grp_ids = $cat->get_grp_ids;

=item my $grp_ids_aref = $cat->get_grp_ids;

Returns a list of group IDs to which this category belongs.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

# FIXME This is only here to prevent the Bric->get_grp_ids() method from
# overriding Bric->get_$something().  When all of the assets have been
# converted to carry their group Ids around with them it will be possible
# to remove Bric->get_grp_ids() so this will no longer be necessary.
sub get_grp_ids {
    wantarray ? @{ $_[0]->_get('grp_ids') } : $_[0]->_get('grp_ids')
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

=cut

sub set_name {
    my ($self, $name) = @_;
    if (my $agid = $self->_get('asset_grp_id')) {
        # Change the name in the asset group description.
        my $ag = Bric::Util::Grp::Asset->lookup({ id => $agid });
        $ag->set_description($name);
        $self->_set(['_asset_grp'], [$ag]);
    }
    $self->_set(['name'], [$name]);
}

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
    return unless defined $id && $id != ROOT_CATEGORY_ID;
    return Bric::Biz::Category->list({parent_id => $id});
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

=head2 Private Methods

=cut

#--------------------------------------#

=head2 Private Class Methods

NONE

=cut


# Add methods here that do not require an object be instantiated, and should not
# be called outside this module (e.g. utility functions for class methods).
# Use same POD comment style as above for 'new'.

#--------------------------------------#

=head2 Private Instance Methods

NONE

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

sub _select_category {
    my ($where, $bind) = @_;
    my (@ret, @d, $d_tmp);

    # The left join in here is allows us to return all of the group IDs with
    # the categories in a single query
    my $columns = join ',', 'a.id', SELCOLS;  # list of columns to return
    my $table = TABLE;      # main table to select from
    my $mtable = MTABLE;    # grp member table from which we get grp__id
    my $cmtable = CMTABLE;  # relational table to get member table row
    my $sql = qq{
        SELECT $columns
        FROM $table a LEFT JOIN (
                $cmtable b JOIN $mtable c
                ON b.member__id = c.id
            ) ON a.id = b.object_id
    };
    $sql .= " WHERE $where" if $where;
    $sql .= " ORDER BY uri";

    my $sth = prepare_c($sql);
    execute($sth, @$bind);
    bind_columns($sth, \@d[0..(scalar SELCOLS)]);
    # Since there are now duplicate values in the result set for every column
    # in category we have to be careful to avoid duplicate objects. This is a
    # good stage to catch it. We'll test the ID of each row to see if it
    # matches the previous. This works because we are ordering by URI, which
    # is unique, and has a 1 to 1 relationship with id.
    while (fetch($sth)) {
        if ($d_tmp && $d[0] == $d_tmp->[0]) {
            # we have a matching ID. Just tack the last entry onto the
            # arrayref in the tmp array
            push @{ $d_tmp->[$#d] }, $d[$#d];
        } else {
            # This is the first row with this ID. Save the old tmp_array if
            # there is one.
            push @ret, $d_tmp if $d_tmp;
            # now load the current row into the tmp aray and convert the last
            # entry into an arrayref
            $d_tmp = [@d];
            $d_tmp->[$#d] = [$d[$#d]];
        }
    }
    # There will always be something left in the tmp array if any records have
    # been fetched.
    push @ret, $d_tmp if $d_tmp;
    finish($sth);
    return \@ret;
}

sub _update_category {
    my $self = shift;
    my ($id, $ag) = $self->_get(qw(id _asset_grp));

    my $sql = 'UPDATE '.TABLE.
              " SET ".join(',', map {"$_=?"} COLS)." WHERE id=?";

    my $sth = prepare_c($sql);

    if ($self->_get('_update_uri') and $id != ROOT_CATEGORY_ID) {
        my $new_uri = Bric::Util::Trans::FS->cat_uri
          ( $self->get_parent->get_uri,
            $self->_get('directory')
          );

        $self->_set(['uri'], [$new_uri]);
    }

    execute($sth, $self->_get(FIELDS), $self->get_id);

    if ($self->_get('_update_uri')) {
        $self->_set(['_update_uri'], [0]);
        my $parent_uri = $self->_get('uri');
        for my $subcat ($self->get_children) {
            $subcat->set_directory($subcat->_get('directory'));
            $subcat->_update_category;
        }
    }
    $ag->save if $ag;

    return 1;
}

sub _insert_category {
    my $self = shift;
    # Set up a group. This isn't used anywhere or for anything other than
    # to have a way to get a group ID from a category to track assets. The
    # assets will pretend they're in the group, even though they're really not.
    # See Bric::Biz::Asset->get_grp_ids to see it at work.
    my $ag_obj = Bric::Util::Grp::Asset->new
      ({ name => 'Category Assets',
         description => $self->_get('name') });
    $ag_obj->save;
    $self->_set(['asset_grp_id'], [$ag_obj->get_id]);
    my $nextval = next_key(TABLE);

    # Create the insert statement.
    my $sql = 'INSERT INTO '.TABLE." (id,".join(',',COLS).") ".
              "VALUES ($nextval,".join(',', ('?') x COLS).')';

    my $sth = prepare_c($sql);

    $self->_set(['uri'], [Bric::Util::Trans::FS->cat_uri(
      $self->get_parent->get_uri,
      $self->_get('directory'),
    )]);

    execute($sth, $self->_get(FIELDS));

    # Set the ID of this object.
    $self->_set(['id'],[last_key(TABLE)]);
    # Add the category to the 'All Categories' group.
    $self->register_instance(INSTANCE_GROUP_ID, GROUP_PACKAGE);
    return $self;
}


1;
__END__

=back

=head1 NOTES

This class is implimented on the backend using the group structure.  The class
Bric::Util::Grp::Category handles all the database interactions.

=head1 AUTHOR

"Garth Webb" <garth@perijove.com>
Bricolage Engineering

=head1 SEE ALSO

L<perl>, L<Bric::Util::Grp::Category>, L<Bric>, L<Bric::Biz::Keyword>, L<Bric::Biz::Asset>

=cut
