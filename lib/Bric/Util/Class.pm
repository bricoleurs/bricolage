package Bric::Util::Class;
###############################################################################

=head1 NAME

Bric::Util::Class - A module to provide access to the class table

=head1 VERSION

$Revision: 1.6.2.3 $

=cut

our $VERSION = (qw$Revision: 1.6.2.3 $ )[-1];

=head1 DATE

$Date: 2002-11-07 01:23:03 $

=head1 SYNOPSIS

 use Bric::Util::Class;



=head1 DESCRIPTION

Provides access to the class table that maps package names to a display name and
description.

=cut

#==============================================================================#
# Dependencies                         #
#======================================#

#--------------------------------------#
# Standard Dependencies                 

use strict;

#--------------------------------------#
# Programatic Dependencies              
 
use Bric::Util::DBI qw(:standard);

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

use constant TABLE => 'class';
use constant COLS  => qw(key_name pkg_name disp_name plural_name description
			 distributor);

#==============================================================================#
# FIELDS                               #
#======================================#

#--------------------------------------#
# Public Class Fields                   

our $METH;
our (%BY_ID, %BY_KEY, %BY_PKG);

#--------------------------------------#
# Private Class Fields                  



#--------------------------------------#
# Instance Fields                       

# This method of Bricolage will call 'use fields' for you and set some permissions.
BEGIN {
    Bric::register_fields({
			 # Public Fields
			 'id'             => Bric::FIELD_READ,
			 'key_name'       => Bric::FIELD_RDWR,
			 'pkg_name'       => Bric::FIELD_RDWR,
			 'plural_name'    => Bric::FIELD_RDWR,
			 'disp_name'      => Bric::FIELD_RDWR,
			 'description'    => Bric::FIELD_RDWR,
			 'distributor'    => Bric::FIELD_RDWR,

			 # Private Fields

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

=item $obj = Bric::Util::Class->new($init);

Keys for $init are:

=over 4

=item *

key_name

A lowercase unique key name for the class with no spaces or punctuation, such as
'user_grp'.

=item *

pkg_name

The full package name of this class, such as 'Bric::Util::Grp::User'.

=item *

disp_name

The way the package name (usually shortened) should be displayed on the UI, such
as 'User Group'.

=item *

plural_name

The plural form of disp_name.

=item *

description

A description of this package.

=back

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub new {
    my $class = shift;
    my ($init) = @_;

    # Create the object via fields which returns a blessed object.
    my $self = bless {}, $class;

    # Make sure the key name is lowercase.
    $init->{key_name} = lc $init->{key_name} if exists $init->{key_name};

    # Call the parent's constructor.
    $self->SUPER::new($init);

    # Return the object.
    return $self;
}

#------------------------------------------------------------------------------#

=item $obj = Bric::Util::Class->lookup({ id => $id });

=item $obj = Bric::Util::Class->lookup({ pkg_name => $pkg_name });

=item $obj = Bric::Util::Class->lookup({ key_name => $key_name });

Retrieves an existing class record from the database.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub lookup {
    my ($class, $init) = @_;
    my $key = defined $init->{id} ? lc($init->{id}) :
      lc($init->{key_name} or $init->{pkg_name});
    return unless defined $key;
    # Make sure all the classes are loaded and cached.
    $class->list unless %BY_ID;
    return $BY_ID{$key} || $BY_KEY{$key} || $BY_PKG{$key};
}

#------------------------------------------------------------------------------#

=item @objs = Bric::Util::Class->list($param);

The possible keys to $param are the following:

=over 4

=item disp_name

=item plural_name

=item description

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
    my ($param) = @_;
    my (@num, @txt);

    # Pull off the numeric parameters.
    push @num, $param->{'id'} if exists $param->{'id'};
    @txt = keys %$param;

    my $where = join(' AND ', (map { "$_=?" }      @num),
		              (map { "LOWER($_) LIKE ?" } @txt));

    my $ret = _select_class($where, [map {lc $_} @$param{@num,@txt}]);
    my @all;

    my $load_cache = !%BY_ID && (!$param || !%$param) ? 1 : 0;
    foreach my $d (@$ret) {
	# Create the object via fields which returns a blessed object.
	my $self = bless {}, $class;

	# Call the parent's constructor.
	$self->SUPER::new();

	# Set the columns selected as well as the passed ID.
	$self->_set(['id', COLS], $d);

	# Cache the object if necessary.
	$BY_ID{$d->[0]} = $BY_KEY{lc $d->[1]} = $BY_PKG{lc $d->[2]} = $self
	  if $load_cache;
	push @all, $self;
    }
    return wantarray ? @all : \@all;
}

################################################################################

=item $objs_href = Bric::Util::Class->pkg_href();

Returns an anonymous hash of all the class objects in Bricolage. The hash keys
are the lower-cased package names for each class, and the values are the
Bric::Util::Class objects themselves.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub pkg_href {
    list(shift) unless %BY_PKG;
    return \%BY_PKG;
}

################################################################################

=item $objs_href = Bric::Util::Class->id_href();

Returns an anonymous hash of all the class objects in Bricolage. The hash keys
are the object IDs for each class, and the values are the Bric::Util::Class
objects themselves.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub id_href {
    list(shift) unless %BY_ID;
    return \%BY_ID;
}

################################################################################

=item $objs_href = Bric::Util::Class->key_href();

Returns an anonymous hash of all the class objects in Bricolage. The hash keys
are the lower-cased key names for each class, and the values are the
Bric::Util::Class objects themselves.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub key_href {
    list(shift) unless %BY_KEY;
    return \%BY_KEY;
}

#--------------------------------------#

=head2 Destructors

=cut

sub DESTROY {
    # This method should be here even if its empty so that we don't waste time
    # making Bricolage's autoload method try to find it.
}

#--------------------------------------#

=head2 Public Class Methods

=cut

#------------------------------------------------------------------------------#

=item $val = my_meths->{$key}->[0]->($obj);

Introspect this object.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub my_meths {
    # Load field members.
    return $METH if $METH;
    
    $METH = {'key_name'    => {'get_meth' => sub {shift->get_key_name(@_)},
			       'get_args' => [], 
			       'set_meth' => sub {shift->set_key_name(@_)},
			       'set_args' => [],
			       'disp'     => 'Key Name',
			       'search'   => 1,
			       'len'      => 128,
			       'type'     => 'short',
			       'props'    => {'type'       => 'text',
					      'length'     => 64,
					      'max_length' => 64}
			      },
	     'pkg_name'    => {'get_meth' => sub {shift->get_pkg_name(@_)},
			       'get_args' => [], 
			       'set_meth' => sub {shift->set_pkg_name(@_)},
			       'set_args' => [],
			       'disp'     => 'Package',
			       'search'   => 1,
			       'len'      => 128,
			       'type'     => 'short',
			       'props'    => {'type'       => 'text',
					      'length'     => 64,
					      'max_length' => 128}
			      },
	     'disp_name'   => {'get_meth' => sub {shift->get_disp_name(@_)}, 
			       'get_args' => [],
			       'set_meth' => sub {shift->set_disp_name(@_)},
			       'set_args' => [],
			       'disp'     => 'Short Name',
			       'search'   => 0,
			       'len'      => 128,
			       'type'     => 'short',
			       'props'    => {'type'       => 'text',
					      'length'     => 64,
					      'max_length' => 128}
			      },
	     'plural_name' => {'get_meth' => sub {shift->get_plural_name(@_)}, 
			       'get_args' => [],
			       'set_meth' => sub {shift->set_plural_name(@_)},
			       'set_args' => [],
			       'disp'     => 'Plural Name',
			       'search'   => 0,
			       'len'      => 128,
			       'type'     => 'short',
			       'props'    => {'type'       => 'text',
					      'length'     => 64,
					      'max_length' => 128}
			      },
	     'description' => {'get_meth' => sub {shift->get_description(@_)},
			       'get_args' => [], 
			       'set_meth' => sub {shift->set_description(@_)},
			       'set_args' => [],
			       'disp'     => 'Description',
			       'search'   => 0,
			       'len'      => 256,
			       'type'     => 'short',
			       'props'    => {'type'       => 'text',
					      'length'     => 96,
					      'max_length' => 256}
			      },
	     'distributor' => {'get_meth' => sub {shift->get_distributor(@_)},
			       'get_args' => [],
			       'set_meth' => sub {shift->set_distributor(@_)},
			       'set_args' => [],
			       'disp'     => 'Distributor',
			       'search'   => 0,
			       'len'      => 1,
			       'type'     => 'short',
			       'props'    => {'type'       => 'checkbox'}
			      },
	    };
    
    # Load attributes.
    # NONE
    
    return $METH;
}

#--------------------------------------#

=head2 Public Instance Methods

=over 4

=cut

#------------------------------------------------------------------------------#

=item $success = $key->save;

Save changes to the database.

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
 
    if ($id) {
	$self->_update_class();
    } else {
	$self->_insert_class();
    }
}

#==============================================================================#

=head2 Private Methods

=cut


#--------------------------------------#

=head2 Private Class Methods

NONE

=cut


#--------------------------------------#

=head2 Private Instance Methods

NONE

=cut

sub _select_class {
    my ($where, $bind) = @_;
    my (@d, @ret);

    my $sql = 'SELECT '.join(',','id',COLS).' FROM '.TABLE;
    $sql   .= ' WHERE '.$where if $where;
    $sql .= ' ORDER BY disp_name';

    my $sth = prepare_c($sql);
    execute($sth, @$bind);
    bind_columns($sth, \@d[0..(scalar COLS)]);
    
    while (fetch($sth)) {
	push @ret, [@d];
    }
    
    finish($sth);

    return \@ret;
}

sub _update_class {
    my $self = shift;
    
    my $sql = 'UPDATE '.TABLE.
              ' SET '.join(',', map {"$_=?"} COLS).' WHERE id=?';


    my $sth = prepare_c($sql);
    execute($sth, $self->_get(COLS), $self->get_id);
    
    return 1;
}

sub _insert_class {
    my $self = shift;
    my $nextval = next_key(TABLE);

    # Create the insert statement.
    my $sql = 'INSERT INTO '.TABLE." (id,".join(',',COLS).") ".
              "VALUES ($nextval,".join(',', ('?') x COLS).')';
    
    my $sth = prepare_c($sql);
    execute($sth, $self->_get(COLS));
  
    # Set the ID of this object.
    $self->_set(['id'],[last_key(TABLE)]);

    return 1;
}


1;
__END__

=back

=head1 NOTES

NONE

=head1 AUTHOR

"Garth Webb" <garth@perijove.com>
Bricolage Engineering

=head1 SEE ALSO

L<perl>, L<Bric>

=cut
