package Bric::Biz::ATType;
###############################################################################

=head1 NAME

Bric::Biz::ATType - A class to represent AssetType types.

=head1 VERSION

$Revision: 1.11 $

=cut

our $VERSION = (qw$Revision: 1.11 $ )[-1];

=head1 DATE

$Date: 2003-01-22 05:36:03 $

=head1 SYNOPSIS

 use Bric::Biz::ATType;

=head1 DESCRIPTION

This class sets up properties that are common to all elements
(Bric::Biz::AssetType) objects of a type.

=cut

#==============================================================================#
# Dependencies                         #
#======================================#

#--------------------------------------#
# Standard Dependencies
use strict;

#--------------------------------------#
# Programatic Dependencies
use Bric::Util::DBI qw(:all);
use Bric::Util::Grp::ElementType;

#==============================================================================#
# Inheritance                          #
#======================================#
use base qw(Bric);

#=============================================================================#
# Function Prototypes                  #
#======================================#
# None.


#==============================================================================#
# Constants                            #
#======================================#
use constant DEBUG => 0;
use constant TABLE  => 'at_type';
use constant COLS   => qw(name description top_level media paginated
			  fixed_url related_story related_media biz_class__id
			  active);
use constant FIELDS => qw(name description top_level media paginated
			  fixed_url related_story related_media biz_class_id
			  _active);
use constant ORD   => qw(name description top_level media paginated
			  fixed_url related_story related_media biz_class_id
			  active);

use constant GROUP_PACKAGE => 'Bric::Util::Grp::ElementType';
use constant INSTANCE_GROUP_ID => 28;

#==============================================================================#
# FIELDS                               #
#======================================#

#--------------------------------------#
# Public Class Fields
# None.

#--------------------------------------#
# Private Class Fields
my $METH;



#--------------------------------------#
# Instance Fields
BEGIN {
    Bric::register_fields({
			 # Public Fields
			 'id'             => Bric::FIELD_RDWR,
			 'name'           => Bric::FIELD_RDWR,
			 'description'    => Bric::FIELD_RDWR,
			 'top_level'      => Bric::FIELD_RDWR,
			 'paginated'      => Bric::FIELD_RDWR,
			 'fixed_url'      => Bric::FIELD_RDWR,
			 'related_story'  => Bric::FIELD_RDWR,
			 'related_media'  => Bric::FIELD_RDWR,
			 'media'          => Bric::FIELD_RDWR,
			 'biz_class_id'   => Bric::FIELD_RDWR,

			 # Private Fields
			 '_active'         => Bric::FIELD_NONE,
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

=item $obj = new Bric::Biz::ATType($init);

Keys for $init are:

=over 4

=item *

name

The name of this type

=item *

description

A short description of this type.

=item *

top_level

A boolean value flagging whether this AssetType represents a top level 
AssetType, rather than a container AssetType.

=item *

paginated

If each of this type of AssetType represents a page of output.

=back

Creates a new ATType object.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub new {
    my $class = shift;
    my ($init) = @_;

    # Create the object via fields which returns a blessed object.
    my $self = bless {}, $class;

    # Set active to true.
    $init->{'_active'} = 1;
    for (qw(top_level media paginated fixed_url related_story related_media)) {
	$init->{$_} = $init->{$_} ? 1 : 0;
    }
    # Call the parent's constructor.
    $self->SUPER::new($init);

    # Return the object.
    return $self;
}

#------------------------------------------------------------------------------#

=item $obj = lookup Bric::Biz::ATType($key_id);

Retrieves an existing AT type from the database.  Takes an AT Type ID.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub lookup {
    my $class = shift;
    my ($init) = @_;
    return unless exists $init->{'id'};

    # Create the object via fields which returns a blessed object.
    my $self = bless {}, $class;

    # Call the parent's constructor.
    $self->SUPER::new();

    my $ret = _select_attype('id=?', [$init->{'id'}]);

    # Set the columns selected as well as the passed ID.
    $self->_set(['id', FIELDS], $ret->[0]);

    # Return the object.
    return $self;
}

#------------------------------------------------------------------------------#

=item @objs = list Bric::Biz::ATType($param);

The possible keys to $param are the following;

=over 4

=item *

name

Lookup ATType by name

=item *

top_level

Return all top level types

=item *

paginated

Return all paginated types.

=item *

active

Return all types that are currently active

=back

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub list {
    my $class = shift;
    my ($param, $id_only) = @_;
    my (@num, @txt);

    # Make sure to set active explictly if its not passed.
    $param->{'active'} = exists $param->{'active'} ? $param->{'active'} : 1;
    delete $param->{active} if $param->{active} eq 'all';

    foreach (keys %$param) {
	if (/^(?:name|description)$/) {
	    push @txt, $_;
	    $param->{$_} = lc $param->{$_};
	} else {
	    push @num, $_;
	}
    }

    my $where = join(' AND ', (map { "$_=?" }             @num),
		              (map { "LOWER($_) LIKE ?" } @txt));

    my $ret = _select_attype($where, [@$param{@num,@txt}], $id_only);

    # $ret is just a bunch of IDs if the $id_only flag is set.  Return them.
    return wantarray ? @$ret : $ret if $id_only;

    my @all;

    foreach my $d (@$ret) {
	# Create the object via fields which returns a blessed object.
	my $self = bless {}, $class;

	# Call the parent's constructor.
	$self->SUPER::new();

	# Set the columns selected as well as the passed ID.
	$self->_set(['id', FIELDS], $d);

	push @all, $self;
    }

    return wantarray ? @all : \@all;
}

#------------------------------------------------------------------------------#

=item (@ids || $ids) = Bric::Biz::Workflow->list_ids();

Return a list of IDs for all known at_type types.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub list_ids {
    my $self = shift;
    my ($param) = @_;
    return $self->list($param, 1);
}

#--------------------------------------#

=back

=head2 Destructors

NONE

=cut

sub DESTROY {
    # This method should be here even if its empty so that we don't waste time
    # making Bricolage's autoload method try to find it.
}

#------------------------------------------------------------------------------#

=head2 Public Class Methods

=over 4

=cut

#------------------------------------------------------------------------------#

=item my $meths = Bric::Biz::ATType->my_meths

=item my (@meths || $meths_aref) = Bric::Biz::ATType->my_meths(TRUE)

Returns an anonymous hash of instrospection data for this object. If called
with a true argument, it will return an ordered list or anonymous array of
intrspection data. The format for each introspection item introspection is as
follows:

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
    my ($pkg, $ord) = @_;

    # Return 'em if we got em.
    return !$ord ? $METH : wantarray ? @{$METH}{&ORD} : [@{$METH}{&ORD}]
      if $METH;

    # We don't got 'em. So get 'em! Start by getting a list of Business Asset
    # Classes.
    my $sel = [];
    my $classes = Bric::Util::Class->pkg_href;
    while (my ($k, $v) = each %$classes) {
	next unless $k =~ /^bric::biz::asset::business::/;
	my $d = [ $v->get_id, $v->get_disp_name ];
	$d->[1] = 'Other Media' if $v->get_key_name eq 'media';
	push @$sel, $d;
    }

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
			      search   => 1,
			      props    => { type       => 'text',
					    length     => 32,
					    maxlength => 64
					  }
			     },
	      description => {
			      name     => 'description',
			      get_meth => sub { shift->get_description(@_) },
			      get_args => [],
			      set_meth => sub { shift->set_description(@_) },
			      set_args => [],
			      disp     => 'Description',
			      len      => 256,
			      req      => 0,
			      type     => 'short',
			      props    => { type => 'textarea',
					    cols => 40,
					    rows => 4
					  }
			     },
	     top_level    => {
			      name     => 'top_level',
			      get_meth => sub {shift->get_top_level(@_)},
			      get_args => [],
			      set_meth => sub {shift->set_top_level(@_)},
			      set_args => [],
			      disp     => 'Type',
			      len      => 1,
			      req      => 0,
			      type     => 'short',
			      props    => { type => 'radio',
					    vals => [ [0, 'Element'], [1, 'Asset']] }
			     },
	     paginated    => {
			      name     => 'paginated',
			      get_meth => sub {shift->get_paginated(@_)},
			      get_args => [],
			      set_meth => sub {shift->set_paginated(@_)},
			      set_args => [],
			      disp     => 'Page',
			      len      => 1,
			      req      => 0,
			      type     => 'short',
			      props    => { type => 'checkbox'}
			     },
	     fixed_url    => {
			      name     => 'fixed_url',
			      get_meth => sub {shift->get_fixed_url(@_)},
			      get_args => [],
			      set_meth => sub {shift->set_fixed_url(@_)},
			      set_args => [],
			      disp     => 'Fixed',
			      len      => 1,
			      req      => 0,
			      type     => 'short',
			      props    => { type => 'checkbox'}
			     },
	     related_story    => {
			      name     => 'related_story',
			      get_meth => sub {shift->get_related_story(@_)},
			      get_args => [],
			      set_meth => sub {shift->set_related_story(@_)},
			      set_args => [],
			      disp     => 'Related Story',
			      len      => 1,
			      req      => 0,
			      type     => 'short',
			      props    => { type => 'checkbox'}
			     },
	     related_media    => {
			      name     => 'related_media',
			      get_meth => sub {shift->get_related_media(@_)},
			      get_args => [],
			      set_meth => sub {shift->set_related_media(@_)},
			      set_args => [],
			      disp     => 'Related Media',
			      len      => 1,
			      req      => 0,
			      type     => 'short',
			      props    => { type => 'checkbox'}
			     },
	     media        => {
			      name     => 'media',
			      get_meth => sub {shift->get_media(@_)},
			      get_args => [],
			      set_meth => sub {shift->set_media(@_)},
			      set_args => [],
			      disp     => 'Content',
			      len      => 1,
			      req      => 0,
			      type     => 'short',
			      props    => { type => 'radio',
					    vals => [ [ 0, 'Story'], [ 1, 'Media'] ]
				      }
			     },
	     biz_class_id => {
			      name     => 'biz_class_id',
			      get_meth => sub {shift->get_biz_class_id(@_)},
			      get_args => [],
			      set_meth => sub {shift->set_biz_class_id(@_)},
			      set_args => [],
			      disp     => 'Content Type',
			      len      => 3,
			      req      => 0,
			      type     => 'short',
			      props    => { type => 'select',
					    vals => $sel }
			     },
	      active      => {
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
			     }
	  };
    return !$ord ? $METH : wantarray ? @{$METH}{&ORD} : [@{$METH}{&ORD}];

}

#--------------------------------------#

=back

=head2 Public Instance Methods

=over 4

=item $name = $att->get_name();

=item $name = $att->set_name($name);

Get/Set the name of this AT type

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

#------------------------------------------------------------------------------#

=item $desc = $att->get_description();

=item $desc = $att->set_description($desc);

Get/Set the description for this AT type.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

#------------------------------------------------------------------------------#

=item $topl = $att->get_top_level();

=item $topl = $att->set_top_level(1 || 0);

Get/Set the top level flag.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

#------------------------------------------------------------------------------#

=item $page = $att->get_paginated();

=item $page = $att->set_paginated(1 || 0);

Get/Set the paginated flag.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

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
    $self->_set__dirty(1);
    $self->_set(['_active'], [1]) and return $self;
}

sub deactivate {
    my $self = shift;
    $self->_set__dirty(1);
    $self->_set(['_active'], [0]) and return $self;
}

=item $success = $attype->remove;

Deletes the AT type from the database.

B<Throws:>

NONEEE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub remove {
    my $self = shift;
    my $id   = $self->get_id;
    return unless defined $id;
    my $sth = prepare_c('DELETE FROM '.TABLE.' WHERE id=?');
    execute($sth, $id);
    return 1;
}

#------------------------------------------------------------------------------#

=item $att = $att->save;

Save the AT type and/or all changes to the database.

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

    return unless $self->_get__dirty;

    if ($id) {
	$self->_update_attype();
    } else {
	$self->_insert_attype();
    }

    $self->_set__dirty(0);

    return $self;
}

#==============================================================================#

=back

=head2 Private Class Methods

NONE

=head2 Private Instance Methods

Several that need documenting.

=over 4

=item _select_attype

=cut

sub _select_attype {
    my ($where, $bind, $id_only) = @_;
    my (@d, @ret);
    my @cols = 'id';

    # Don't bother selecting the other columns if they just want the IDs.
    push @cols, COLS unless $id_only;

    my $sql = 'SELECT '.join(',',@cols).' FROM '.TABLE;
    $sql   .= ' WHERE '.$where if $where;
    $sql   .= ' ORDER BY name';

    my $sth = prepare_ca($sql, undef, DEBUG);

    if ($id_only) {
	my $ids = col_aref($sth,@$bind);

	return wantarray ? @$ids : $ids;
    } else {
	execute($sth, @$bind);
	bind_columns($sth, \@d[0..(scalar COLS)]);
	while (fetch($sth)) {
	    push @ret, [@d];
	}
	finish($sth);
	return \@ret;
    }
}

=item _update_attype

=cut

sub _update_attype {
    my $self = shift;

    my $sql = 'UPDATE '.TABLE.
              ' SET '.join(',', map {"$_=?"} COLS).' WHERE id=?';


    my $sth = prepare_c($sql);
    execute($sth, $self->_get(FIELDS), $self->get_id);
    return 1;
}

=item _insert_attype

=cut

sub _insert_attype {
    my $self = shift;
    my $nextval = next_key(TABLE);

    # Create the insert statement.
    my $sql = 'INSERT INTO '.TABLE." (id,".join(',',COLS).") ".
              "VALUES ($nextval,".join(',', ('?') x COLS).')';

    my $sth = prepare_c($sql);
    execute($sth, $self->_get(FIELDS));

    # Set the ID of this object.
    $self->_set(['id'],[last_key(TABLE)]);

    # And finally, register this person in the "All Element Types" group.
    $self->register_instance(INSTANCE_GROUP_ID, GROUP_PACKAGE);

    return 1;
}

1;
__END__

=back

=head1 NOTES

NONE

=head1 AUTHOR

Garth Webb <garth@perijove.com>

=head1 SEE ALSO

L<perl>, L<Bric>, L<Bric::Biz::AssetType>

=cut
