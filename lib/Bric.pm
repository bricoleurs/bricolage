package Bric;

=head1 NAME

Bric - The Bricolage base class.

=head1 VERSION

Release Version: 1.5.2 -- Development Track for 1.6.0

File (CVS) Version:

$Revision: 1.35.2.1 $

=cut

our $VERSION = "1.5.2";

=head1 DATE

$Date: 2003-03-23 21:24:26 $

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

use constant FIELD_INVALID => 0x00;
use constant FIELD_NONE    => 0x01;
use constant FIELD_READ    => 0x02;
use constant FIELD_WRITE   => 0x04;
use constant FIELD_RDWR    => FIELD_READ | FIELD_WRITE;

use constant CAN_DO_LIST_IDS => 0;
use constant CAN_DO_LIST => 0;
use constant CAN_DO_LOOKUP => 0;
use constant HAS_CLASS_ID => 0;

#=============================================================================#
# Dependencies                         #
#======================================#

#--------------------------------------#
# Standard Dependencies
use strict;

#--------------------------------------#
# Programmatic Dependencies
use Carp;
use Bric::Util::Fault::Exception::GEN;
use Bric::Config qw(:qa :mod_perl);

# Load the Apache modules if we're in mod_perl.
if (defined MOD_PERL) {
    require Apache;
    require Apache::Request;
}

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
# code. See 'Example.pm' in the CVS module 'doc/codingStandards' for an
# example subclass.

sub ACCESS {
    return { debug  => FIELD_RDWR,  # public field
             _dirty => FIELD_NONE,  # private field
           };
}

#==============================================================================#
# Methods                              #
#======================================#

=head1 METHODS

=cut

########################################

=head2 Constructors

=over 4

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

=item my $obj = __PACKAGE__->lookup({ id => $obj_id })

This method is similar to the 'new' method except it is used only to retrieve
a already existing object of this type from the database whereas 'new' creates
a new, empty object. All subclasses should override this method in order to
look up their objects in the database. However, they must first call
C<cache_lookup()> to see if it can retrieve the object from the cache. If they
can, they should simply return the object. Otherwise, once they look up the
object in the database, they should cache it via the C<cache_me()> method. For
example:

  sub lookup {
      my $pkg = shift;
      my $self = $pkg->cache_lookup(@_);
      return $self if $self;
      # ... Continue to look up object in the database. Then...
      $self->cache_me;
  }

B<Throws:>

=over

=item *

lookup method not implemented.

=back

B<Side Effects> NONE.

B<Notes:> NONE.

=cut

sub lookup {
    # This is an abstract method.  All sub classes must implement this.
    die Bric::Util::Fault::Exception::MNI->new
      ({ msg => "lookup method not implemented" });
}

=item my $obj = __PACKAGE__->cache_lookup({ id => $obj_id })

Looks up an object in the cache and returns it if it exists. Otherwise it
returns an undefined value. This method is meant to be used by Bric subclasses
in their C<lookup()> methods. See C<lookup()> for an example.

B<Throws:> NONE.

B<Side Effects> NONE.

B<Notes:> NONE.

=cut

sub cache_lookup {
    if (defined MOD_PERL) {
        my ($pkg, $param) = @_;
        my $r = Apache::Request->instance(Apache->request);
        $pkg = ref $pkg || $pkg;
        while (my ($k, $v) = each %$param) {
            if (my $obj = $r->pnotes("$pkg|$k|" . lc $v)) {
                return $obj;
            }
        }
    }
    return;
}

#------------------------------------------------------------------------------#

=item my @objs = __PACKAGE__->list($params)

This is an abstract method. All derived classes should override this
method. In the concrete implementations of this method, classes should also
call C<cache_me()> for every object to be returned.

B<Throws:>

=over 4

=item *

list method not implemented.

=back

B<Side Effects> NONE.

B<Notes:> NONE.

=cut

sub list {
    # This is an abstract method.  All sub classes must implement this.
    die Bric::Util::Fault::Exception::MNI->new
      ({ msg => "list method not implemented" });
}

#------------------------------------------------------------------------------#

=back

=head2 Public Class Methods

=over 4

=item my @ids = __PACKAGE__->list_ids($params)

This is an abstract method. All derived classes should override this method.
This method returns a list of IDs rather than objects.

B<Throws:>

=over 4

=item *

list_ids method not implemented

=back

B<Side Effects> NONE.

B<Notes:> NONE.

=cut

sub list_ids {
    # This is an abstract method.  All sub classes must implement this.
    die Bric::Util::Fault::Exception::MNI->new
      ({ msg => "list_ids method not implemented" });
}

##############################################################################

=item Bric::register_fields({'field1' => Bric::FIELD_READ, ...})

This function is used by sub classes to register their field names and assign
access levels to them.

B<Throws:>

=over 4

=item *

Unable to register field names.

=back

B<Side Effects>: Defines a subroutine named C<ACCESS()> in the caller's
package.

B<Notes:> NONE.

=cut

sub register_fields {
    my $fields = shift || {};
    my $pkg    = caller();
    my $root   = __PACKAGE__;

    # need symbolic refs to access the symbol table and install subroutines
    no strict 'refs';

    # find parent class (only handle single inheritence)
    my ($parent) = grep { /^$root/ } (@{"${pkg}::ISA"});

    # setup ACCESS sub for this package
    eval {
        my %ACCESS = ( %{$parent->ACCESS()}, %$fields );
        *{"${pkg}::ACCESS"} = sub { \%ACCESS };
    };

    die $gen->new({msg => "Unable to register field names", payload => $@})
      if $@;
}

#--------------------------------------#
# Destructors
#------------------------------------------------------------------------------#

=back

=head2 Destructors

=over 4

=item $job->DESTROY

This is the default destructor method. Even if nothing is defined within it, it
should still be here so that Perl wont waste time trying to find it in the
AUTOLOAD section.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

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

$SIG{__DIE__} = sub { Carp::confess(@_) } unless MOD_PERL;

#------------------------------------------------------------------------------#

=item warn "...";

Uses cluck rather than warn to output warnings.

B<Throws:>

Its a 'thrower'.

B<Side Effects>

Outputs a warning message

B<Notes:>

=cut

$SIG{__WARN__} = sub { Carp::cluck(@_) } unless MOD_PERL;

#------------------------------------------------------------------------------#

=back

=head2 Private Class Methods

NONE.

=head2 Public Instance Methods

=over 4

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

=item *

Access denied: '$field' is not a valid field for package '$package'

=item *

Access denied:  READ access for field '$field' required

=item *

Access denied:  WRITE access for field '$field' required

=back

B<Side Effects>

Creates a custom subroutine reference in the calling packages namespace

B<Notes:>

=cut

sub AUTOLOAD {
    my $self = $_[0];
    my ($op, $field);
    my $pkg = ref($self);
    my ($perm, $msg);

    # Get method name
    our $AUTOLOAD;

    # need symbolic refs to access the symbol table and call
    # subroutine through $AUTOLOAD
    no strict 'refs';

    # Skip DESTROY and other ALL CAPs methods
    return if $AUTOLOAD =~ /::[A-Z_]+$/;

    # Make sure the function was called in the correct form.
    ($op, $field) = $AUTOLOAD =~ /([^_:]+)_(\w+)$/;

    # Check the format and content of this AUTOLOAD request.
    die $gen->new({msg => "Bad AUTOLOAD method format: $AUTOLOAD"})
      unless $op and $field;

    die $gen->new({msg => "Cannot AUTOLOAD private methods: $AUTOLOAD"})
      if $field =~ /^_/;

    # Get the permissions for this field 
    $perm = $pkg->ACCESS()->{$field} || FIELD_INVALID;

    # field doesn't exist!
    die $gen->new({ msg => "Access denied: '$field' is not a valid field for ".
                           "package $pkg." })
      if $perm & FIELD_INVALID;

    # A get request
    if ($op eq 'get') {
        # check permissions
        die $gen->new({msg => "Access denied:  READ access for field " .
                              "'$field' required"})
          unless $perm & FIELD_READ;

        # setup get method
        *{$AUTOLOAD} = QA_MODE ? 
          sub { return $_[0]->{$field} } :    # take a shortcut
          sub { return $_[0]->_get($field) }; # go directly to jail
    }

    # A set request
    elsif ($op eq 'set') {
        # check permissions
        die $gen->new({msg => "Access denied:  WRITE access for field " .
                              "'$field' required"})
          unless $perm & FIELD_WRITE;

        # setup set method
        *{$AUTOLOAD} = sub { return $_[0]->_set([$field],[$_[1]]) }
    }

    # A read permission check
    elsif ($op eq 'readable') {
        my $val = $perm & FIELD_READ;
	*{$AUTOLOAD} = sub () { $val };
    }

    # A write permission check
    elsif ($op eq 'writable') {
        my $val = $perm & FIELD_WRITE;
	*{$AUTOLOAD} = sub () { $val };
    }

    # otherwise, fail
    else {
	die $gen->new({msg => "No AUTOLOAD method: $AUTOLOAD"});
    }

    # call the darn method - all the parameters are still in @_
    &$AUTOLOAD;
}

#------------------------------------------------------------------------------#

=item $ids = $obj->get_grp_ids || $pkg->get_grp_ids;

Return a list of IDs for the Bric::Util::Grp objects to which the object
belongs. When called as a class method, return the value of the class'
C<INSTANCE_GROUP_ID> constant.

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

    # If this is an object and $self->{grp_ids} exists return it
    return wantarray ? @{$self->{grp_ids}} : $self->{grp_ids}
      if defined $id && exists $self->{grp_ids};

    # If $id is defined, get group IDs. Otherwise, just return
    # INSTANCE_GROUP_ID.
    return defined $id ? $grp->list_ids({ obj => $self })
      : $self->INSTANCE_GROUP_ID;
}

##############################################################################

=item $obj = $obj->cache_me;

Caches the object for later retrieval by the C<lookup()> class method. Should
be called for all object retrieved from the database. That includes all
objects to be returned by C<lookup()>, C<list()>, and C<href()> methods.

B<Throws:> NONE.

B<Side Effects> NONE.

B<Notes:> NONE.

=cut

sub cache_me {
    my $self = shift;
    if (defined MOD_PERL) {
        my $pkg = ref $self or return;
        # Skip unsaved objects.
        return unless defined $self->{id};
        my $r = Apache::Request->instance(Apache->request);
        # Cache it under its ID.
        $r->pnotes("$pkg|id|$self->{id}", $self);
        # Cache it under other unique identifiers.
        foreach my $m ($self->my_meths(0, 1)) {
            $r->pnotes("$pkg|$m->{name}|" . lc $m->{get_meth}->($self), $self);
        }
    }
    return $self;
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
    my $grp = $grp_pkg->lookup({ id => $grp_id }) || return;
    $grp->add_member({ obj => $self, no_check => 1 });
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

=back

=head2 Private Instance Methods

=over 4

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

    my ($key, $old_value, $new_value, $dirt);
    for (0 .. $#$k) {
        $key       = $k->[$_];
        $new_value = $v->[$_];
        $old_value = $self->{$key};

        # skip unless new_value is different from old_value
        next if (not defined $new_value and not defined $old_value) or
          (defined $new_value and defined $old_value and 
           $old_value eq $new_value);

        # a change was found, mark for later
        $dirt = 1;

        # fast version, no check for errors
        $self->{$key} = $new_value unless QA_MODE;

        # in QA_MODE check for (impossible?) failures
        if (QA_MODE) {
            eval {
                $self->{$key} = $new_value;
                $dirt = 1;
            };
            die $gen->new({ msg => "Error setting value for '$key' in _set().",
                            payload => $@ }) if $@;
        }
    }

    # Set the dirty flag to show that this objects needs an update.
    $self->{_dirty} = 1 if $dirt;
    return $self;
}

#------------------------------------------------------------------------------#

=item @vals || $val = $obj->_get(@keys);

The internal function used to get field values. It accepts a list of key values
to retrieve from the object.

B<Throws:>

Problems retrieving field 'foo'

B<Side Effects>

NONE

B<Notes:>

Error checking and exception throwing is only performed in QA_MODE for
performance reasons.

=cut

sub _get {
    my $self = shift;

    # producton code - no check for errors
    return wantarray ? @{$self}{@_} : $self->{$_[0]} unless QA_MODE;

    # debugging code
    if (QA_MODE) {
        my @return;

        # Iterate through the keys and build up a return array.
        for (@_) {
            # If this is a private field, we need to access it differently.
            eval { push @return, $self->{$_}};

            if ($@) {
                my $msg = "Problems retrieving field '$_'";
                die Bric::Util::Fault::Exception::GEN->new({'msg'     => $msg,
                                                            'payload' => $@});
            }
        }

        # Syntax sugar. Let the user say $n = get_foo rather than ($n) =
        # get_foo
        return wantarray ? @return : $return[0];
    }

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

sub _get_ref {
    my $self = shift;
    # a faster version for production use
    return [ @{$self}{@_} ] unless QA_MODE;

    # slower version calls _get which includes extra debugging
    # code in QA_MODE
    return [$self->_get(@_)] if QA_MODE;
}

=back

=head1 AUTHOR

Garth Webb <garth@perijove.com>

Sam Tregar <stregar@about-inc.com>

=head1 SEE ALSO

NONE

=cut

1;
