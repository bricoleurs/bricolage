package Bric;

=head1 NAME

Bric - The Bricolage base class.

=head1 VERSION

Release Version: 1.1.0

File (CVS) Version:

$Revision: 1.9 $

=cut

our $VERSION = "1.1.0";

=head1 DATE

$Date: 2001-10-09 20:48:53 $

=head1 SYNOPSIS

  use base qw( Bric );

=head1 DESCRIPTION

The Bric class is an abstract class should never be used directly. Instead new
classes should be derived from it.

=cut

#=============================================================================#
# Function Prototypes and Closures     #
#======================================#


#=============================================================================#
# Constants                            #
#======================================#

use constant FIELD_NONE  => 0x00;
use constant FIELD_READ  => 0x01;
use constant FIELD_WRITE => 0x02;
use constant FIELD_RDWR  => FIELD_READ | FIELD_WRITE;

#=============================================================================#
# Dependencies                         #
#======================================#

#--------------------------------------#
# Standard Dependencies
use strict;

#--------------------------------------#
# Programatic Dependencies
use Carp;
use Bric::Util::Fault::Exception::GEN;

#=============================================================================#
# Inheritance                          #
#======================================#
use base qw();

#=============================================================================#
# Fields                               #
#======================================#

#--------------------------------------#
# Public Class Fields


#--------------------------------------#
# Private Class Fields
my $gen = 'Bric::Util::Fault::Exception::GEN';

#--------------------------------------#
# Public Instance Fields

# All subclasses should use the RegisterFields function rather than the below
# code. See 'Example.pm' in the CVS module 'doc/codingStandards' for an example
# subclass.

BEGIN {
    sub ACCESS {
	return {
		# Public Fields
		'debug'        => FIELD_RDWR,

		# Private Fields
		'_dirty'       => FIELD_NONE,
	       };
    }

    my @fields = keys %{ACCESS()};
}

#==============================================================================#
# Methods                              #
#======================================#

=head1 METHODS

=cut

########################################

=head2 Public Class Methods

=over 4

=cut

#--------------------------------------#
# Constructors

#------------------------------------------------------------------------------#

=item $self = Bric->new($init)

Call this constructor from all derived classes. This sets up some basic fields
and methods.

B<Throws:>

NONE

B<Side Effects>

NONE

B<Notes:>

NONE

=cut

sub new {
    my $self = shift;
    my ($init) = @_;

    # Instantiate object
    $self = bless {}, $self unless ref $self;

    # Fill in object state fields and configuration fields
    $self->_set($init) if $init;

    return $self;
}

#------------------------------------------------------------------------------#

=item $self = Bric->lookup($obj_id)

This method is similar to the 'new' method except it is used only to retrieve a
already existing object of this type from the database whereas 'new' creates a
new, empty object. Since this operation is highly class dependant the code
template for this function is the same as for the 'new' method.

B<Throws:>

NONE

B<Side Effects>

NONE

B<Notes:>

On failure, this method returns zero (0) if no records were found and undef if
there was a failure on the lookup itself.

=cut

sub lookup {
    my $self = shift;
    my ($obj_id) = @_;

    # Instantiate object
    $self = bless {}, $self unless ref $self;

    # Fill in object state fields and configuration fields
    $self->_set({'obj_id' => $obj_id}) if $obj_id;

    return $self;
}

#------------------------------------------------------------------------------#

=item $self = Bric->list($param)

This is an abstract method. All derived classes should override this method.

B<Throws:>

I<"list method not implemented">

Thrown when no list method is available.

B<Side Effects>

NONE

B<Notes:>

=cut

sub list {
    # This is an abstract method.  All sub classes must implement this.
    my $msg = "list method not implemented\n";
    die Bric::Util::Fault::Exception::MNI->new({'msg' => $msg});
}

#------------------------------------------------------------------------------#

=item $self = Bric->list_ids(...)

This is an abstract method. All derived classes should override this method.
This method returns a list of IDs rather than objects.

B<Throws:>

=over 4

=item *

"list_ids method not implemented"

=item *

"Other thingy"

=back

B<Side Effects>

NONE

B<Notes:>

=cut

sub list_ids {
    # This is an abstract method.  All sub classes must implement this.
    my $msg = "list method not implemented\n";
    die Bric::Util::Fault::Exception::MNI->new({'msg' => $msg});
}


#--------------------------------------#
# Destructors

#------------------------------------------------------------------------------#

=item $self = $obj->DESTROY(...)

This is the default destructor method. Even if nothing is defined within it, it
should still be here so that Perl wont waste time trying to find it in the
AUTOLOAD section.

B<Throws:>

NONE

B<Side Effects>

NONE

B<Notes:>

=cut

sub DESTROY {}

#------------------------------------------------------------------------------#

=item die "...";

Uses confess rather than die to report errors.

B<Throws:>

Its a 'thrower'.

B<Side Effects>

Halts program execution

B<Notes:>

=cut

$SIG{__DIE__} = sub { Carp::confess(@_) } unless $ENV{MOD_PERL};

#------------------------------------------------------------------------------#

=item warn "...";

Uses cluck rather than warn to output warnings.

B<Throws:>

Its a 'thrower'.

B<Side Effects>

Outputs a warning message

B<Notes:>

=cut

$SIG{__WARN__} = sub { Carp::cluck(@_) } unless $ENV{MOD_PERL};

#------------------------------------------------------------------------------#

=item Bric::register_fields({'field1' => ACCESS, ...})

This function is used by sub classes to register their field names and assign
access levels to them.

B<Throws:>

"Unable to register field names"

B<Side Effects>

Does a 'use fields' and defines a function named 'ACCESS' in the class in which 
this function is called.

B<Notes:>

=cut

sub register_fields {
    my ($fields) = @_;
    my $pkg = caller();
    my $names = join(' ', keys %$fields);
    my $root = __PACKAGE__;

    # Eval this so that the appropriate package is set, and to scope that 
    # package label.
    eval qq{
	package $pkg;

	use vars qw(\@ISA);
	my \$parent;

	foreach (\@ISA) {
	    next unless /^$root/;
	    \$parent = \$_;
	    last;
	}

	my %PARENT = %{\$parent->ACCESS()};
	my %CHILD  = %\$fields;

	sub ACCESS {
	    return {\%PARENT,
                    \%CHILD,
		   };
	}
    };

    if ($@) {
	my $msg = "Unable to register field names";
	die Bric::Util::Fault::Exception::GEN->new({'msg'     => $msg,
						  'payload' => $@});
    }
}

########################################

=head2 Private Class Methods

=cut

########################################

=head2 Public Instance Methods

=cut

#------------------------------------------------------------------------------#

=item $val = $obj->get_B<field>

=item $obj = $obj->set_B<field>

This is the AUTOLOAD handler. It translates all set and get operations into
subroutines acting upon the fields in derived classes.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

No AUTOLOAD method.

=back

B<Side Effects>

Creates a custom subroutine reference in the calling packages namespace

B<Notes:>

=cut

sub AUTOLOAD {
    my $self = shift;
    my (@params) = @_;
    my ($op, $field);
    my $pkg = ref($self);
    my ($perm, $msg);

    # Get method name
    our $AUTOLOAD;

    no strict 'refs';

    # Skip DESTROY and other ALL CAPs methods
    return if $AUTOLOAD =~ /[A-Z]+$/;

    # Make sure the function was called in the correct form.
    ($op, $field) = $AUTOLOAD =~ /([^_:]+)_(\w+)$/;

    # Check the format and content of this AUTOLOAD request.
    unless ($op && $field) {
	$msg = "Bad AUTOLOAD method format: $AUTOLOAD";
	die Bric::Util::Fault::Exception::GEN->new({'msg' => $msg});
    }
    if ($field =~ /^_/) {
	$msg = "Cannot AUTOLOAD private methods: $AUTOLOAD";
	die Bric::Util::Fault::Exception::GEN->new({'msg' => $msg});
    }

    # Get the permissions for this field or set it to none if it doesn't exist.
    eval "\$perm = $pkg".'::ACCESS->{$field}';
    $perm ||= FIELD_NONE;

    # A get request
    if ($op eq 'get') {
	if ($perm & FIELD_READ) {
	    *{$AUTOLOAD} = sub {
		my $self = shift;
		return $self->_get($field);
	    };
	} else {
	    $msg = "Access denied:  READ access for field '$field' required";
	    die Bric::Util::Fault::Exception::GEN->new({'msg' => $msg});
	}
    }
    # A set request
    elsif ($op eq 'set') {
	if ($perm & FIELD_WRITE) {
	    *{$AUTOLOAD} = sub {
		my ($self, $val) = @_;
		return $self->_set({$field => $val});
	    };
	} else {
	    $msg = "Access denied:  WRITE access for field '$field' required";
	    die Bric::Util::Fault::Exception::GEN->new({'msg' => $msg});
	}
    }
    # A read permission check
    elsif ($op eq 'readable') {

	*{$AUTOLOAD} = sub { $perm & FIELD_READ; }
    }
    # A write permission check
    elsif ($op eq 'writable') {

	*{$AUTOLOAD} = sub { $perm & FIELD_WRITE; }
    } else {
	$msg = "No AUTOLOAD method: $AUTOLOAD";
	die Bric::Util::Fault::Exception::GEN->new({'msg' => $msg});
    }

    # Call the darn method
    &$AUTOLOAD($self, @params);
}

#------------------------------------------------------------------------------#

=item $ids = $obj->get_grp_ids();

Get a list of grp IDs of groups this object belongs to.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_grp_ids {
    my $self = shift;

    # Don't bother doing anything if they didn't define this constant.
    return unless defined($self->GROUP_PACKAGE);

    # Get the group name.
    my $grp = $self->GROUP_PACKAGE;

    # Get the ID. If $self is a package name, we won't be able to get an ID.
    my $id = ref $self ? $self->get_id : undef;

    # If $id is defined, get group IDs. Otherwise, just return
    # INSTANCE_GROUP_ID.
    return defined $id ? $grp->list_ids({ obj => $self })
      : $self->INSTANCE_GROUP_ID;
}

#------------------------------------------------------------------------------#

=item $success = $obj->register_instance();

Add the current object to the appropriate group in the database.  These are
groups that contain every instance of a particular type of object.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub register_instance {
    my ($self, $grp_id, $grp_pkg) = @_;

    # Fail if the package has not defined the GROUP_PACKAGE constant.
    $grp_id ||= $self->INSTANCE_GROUP_ID || return;
    $grp_pkg ||= $self->GROUP_PACKAGE || return;

    # Add the object to the group.
    my $grp = $grp_pkg->lookup({'id' => $grp_id}) || return;
    $grp->add_members([{'obj' => $self}]);

    return $self if $grp->save;
}

#------------------------------------------------------------------------------#

=item $success = $obj->unregister_instance();

Add the current object to the appropriate group in the database. These are
groups that contain every instance of a particular type of object.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub unregister_instance {
    my $self = shift;

    # Fail if the package has not defined the GROUP_PACKAGE constant.
    return unless defined $self->GROUP_PACKAGE;
    return unless defined $self->INSTANCE_GROUP_ID;

    my $grp_id  = $self->INSTANCE_GROUP_ID;
    my $grp_pkg = $self->GROUP_PACKAGE;
    my $grp     = $grp_pkg->lookup({'id' => $grp_id});

    return unless $grp;

    my @mbs = $grp->get_members();

    my ($mem) = grep($_->get_object->get_id eq $self->get_id, @mbs);

    $grp->delete_members($mem);

    return $self if $grp->save;
}

#------------------------------------------------------------------------------#

=item $success = $obj->save();

Save the current object to the database.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub save {
    my $self = shift;
    $self->{'_dirty'} = 0;
    return $self;
}

########################################

=head2 Private Instance Methods

=cut

# NOTE: most of these will be through AUTOLOAD only explicitly put methods here
# that need non-generic processing

#------------------------------------------------------------------------------#

=item $obj->_get__dirty()

=item $obj->_set__dirty()

Get and set the _dirty field

B<Throws:> NONE.

B<Side Effects> NONE.

B<Notes:> NONE.

=cut

sub _get__dirty {
    my $self = shift;
    return $self->{'_dirty'};
}

sub _set__dirty {
    my $self = shift;
    $self->{'_dirty'} = shift;
    return $self;
}


#------------------------------------------------------------------------------#

=item $obj = $obj->_set(\%keyvals);

=item $obj = $obj->_set(\@keys, \@values);

The internal function used to set field values.  Can be called with either a
hash reference of keys and their corresponding values, or as two array 
references, one containing all the keys, the other containing all the values

B<Throws:>

=over 4

=item *

Incorrect number of args to _set().

=item *

Error setting value in _set().

=back

B<Side Effects> NONE.

B<Notes:> NONE.

=cut

sub _set {
    my $self = shift;

    # Make sure we have arguments.
    die $gen->new({ msg => "Incorrect number of args to _set()."}) unless @_;

    # Load $k and $v differently if its a hash ref or two array refs.
    my ($k, $v) = @_ == 1 ? ([keys %{$_[0]}],[values %{$_[0]}]) : @_;

    # Set state
    my $dirt = $self->{_dirty};
    # Disable warnings to prevent "Use of uninitialized value in string ne"
    # messages.
    for my $i (0..$#$k) {
	eval {
	    if ((defined $self->{$k->[$i]} && !defined $v->[$i])
		|| (!defined $self->{$k->[$i]} && defined $v->[$i])
		|| $self->{$k->[$i]} ne $v->[$i]) {
		$self->{$k->[$i]} = $v->[$i];
		$dirt = 1;
	    };
	die $gen->new({ msg => "Error setting value for '$k->[$i]' in _set().",
		        payload => $@ }) if $@;
	}
    }

    # Set the dirty flag to show that this objects needs an update.
    $self->{_dirty} = $dirt;
    return $self;
}

#------------------------------------------------------------------------------#

=item @vals || $val = $obj->_get(@keys);

The internal function used to get field values. It accepts a list of key values
to retrieve from the object.

B<Throws:>

NONE

B<Side Effects>

NONE

B<Notes:>

=cut

sub _get {
    my $self = shift;
    my (@keys) = @_;
    my @return;

    # Iterate through the keys and build up a return array.
    for my $i (0..$#keys) {
	# If this is a private field, we need to access it differently.
	eval { push @return, $self->{$keys[$i]}};

	if ($@) {
	    my $msg = "Problems retrieving fields";
	    die Bric::Util::Fault::Exception::GEN->new({'msg'     => $msg,
						      'payload' => $@});
	}
    }

    # Syntax sugar.  Let the user say $n = get_foo rather than ($n) = get_foo
    return wantarray ? @return : $return[0];
}

#------------------------------------------------------------------------------#

=item $vals = $obj->_get_ref(@keys);

The internal function used to get field values and return them as an arrayref.
It accepts a list of key values to retrieve from the object.

B<Throws:>

NONE

B<Side Effects>

NONE

B<Notes:>

=cut

sub _get_ref { [_get(@_)] }


=head1 AUTHOR

"Garth Webb" <garth@perijove.com>

=head1 SEE ALSO

perl(1).

=cut

1;
