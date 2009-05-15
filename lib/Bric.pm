package Bric;

=head1 Name

Bric - The Bricolage base class.

=head1 Version

1.11.2 - Development Track for 2.0.0

=cut

# Set the Version Number.
BEGIN {
    our $VERSION = '1.11.2';
}

=head1 Synopsis

  use base qw(Bric);

=head1 Description

The Bric class is an abstract class should never be used directly. Instead new
classes should be derived from it.

=cut

##############################################################################
# Constants
##############################################################################
use constant FIELD_INVALID => 0x00;
use constant FIELD_NONE    => 0x01;
use constant FIELD_READ    => 0x02;
use constant FIELD_WRITE   => 0x04;
use constant FIELD_RDWR    => FIELD_READ | FIELD_WRITE;

use constant CAN_DO_LIST_IDS => 0;
use constant CAN_DO_LIST => 0;
use constant CAN_DO_LOOKUP => 0;
use constant HAS_CLASS_ID => 0;

use constant HAS_MULTISITE => 0;

##############################################################################
# Dependencies
##############################################################################
# Standard Dependencies
use strict;

##############################################################################
# Programmatic Dependencies
use Bric::Config qw(:qa :mod_perl CACHE_DEBUG_MODE);
use Bric::Util::Fault qw(:all);
use Bric::Util::ApacheReq;

##############################################################################
# Public Instance Fields

# All subclasses should use the RegisterFields function rather than the below
# code

sub ACCESS {
    return {# debug  => FIELD_RDWR,  # public field
             _dirty => FIELD_NONE,  # private field
           };
}

##############################################################################
# Interface
##############################################################################

=head1 Interface

=head2 Constructors

=head3 new

  my $obj = Bric->new($init);

Call this constructor from all derived classes. This sets up some basic fields
and methods.

B<Throws:>

=over 4

=item Exception::Gen

=back

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

##############################################################################

=head3 lookup

  my $obj = Bric->lookup({ id => $obj_id });

This method is similar to C<new()> except it is used only to retrieve a
already existing object of this type from the database whereas C<new()>
creates a new, empty object. All subclasses should override this method in
order to look up their objects in the database. However, they must first call
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

=item Exception::MNI

=back

=cut

sub lookup { throw_mni "lookup() method not implemented" }

##############################################################################

=head3 cache_as

  my $pkg = Bric->cache_as;

Returns the class name to use when caching objects. In this default
implementation, the cache package returned is simply C<ref $self>. Subclasses
may wish to override this default value.

=cut

sub cache_as { ref $_[0] }

##############################################################################

=head3 cache_lookup

  my $obj = Bric->cache_lookup({ id => $obj_id });

Looks up an object in the cache and returns it if it exists. Otherwise it
returns C<undef>. This method is meant to be used by Bric subclasses in their
C<lookup()> methods. See C<lookup()> for an example.

=cut

sub cache_lookup {
    if (defined MOD_PERL) {
        my ($pkg, $param) = @_;
        my $req = Bric::Util::ApacheReq->request;
        # We may be called during Apache startup
        return unless $req;
        my $r = Bric::Util::ApacheReq->instance($req);
        $pkg = $pkg->cache_as || $pkg;
        while (my ($k, $v) = each %$param) {
            if (my $obj = $r->pnotes("$pkg|$k|" . lc $v)) {
                return $obj;
            }
        }
    }
    if (CACHE_DEBUG_MODE && $Bric::CACHE_DEBUG_MODE_RUNTIME) {
        my ($pkg, $param) = @_;
        $pkg = $pkg->cache_as || $pkg;
        while (my ($k, $v) = each %$param) {
            if (exists $Bric::DEBUG_CACHE{"$pkg|$k|" . lc $v}) {
                return $Bric::DEBUG_CACHE{"$pkg|$k|" . lc $v};
            }
        }
    }
    return;
}

##############################################################################

=head3 list

  my @objs = Bric->list($params);
  my $objs_aref = Bric->list($params);

This is an abstract method. All derived classes should override this
method. It takes a list of parameters and searches the database for objects
that meet the parameter serach criteria. It returns a list of objects in an
array context, and an array reference of objects in a scalar context. In the
concrete implementations of this method, classes should also call
C<cache_me()> for every object to be returned.

B<Throws:>

=over 4

=item Exception::MNI

=back

=cut

sub list { throw_mni "list() method not implemented" }

##############################################################################

=head2 Class Methods

=head3 list_ids

  my @ids = Bric->list_ids($params);
  my $ids_aref = Bric->list_ids($params);

This is an abstract method. It takes a list of parameters and searches the
database for objects that meet the parameter serach criteria. It returns a
list of object IDs in an array context, and an array reference of object IDs
in a scalar context.

B<Throws:>

=over 4

=item Exception::MNI

=back

=cut

sub list_ids { throw_mni "list_ids ()method not implemented" }

##############################################################################

=head3 my_meths

  my $meths = Bric->my_meths
  my @meths = Bric->my_meths(1);
  my $meths_aref = Bric->my_meths(1);
  @meths = Bric->my_meths(0, 1);
  $meths_aref = Bric->my_meths(0, 1);

Returns an anonymous hash of introspection data for this object. If called
with a true argument, it will return an ordered list or anonymous array of
introspection data. If a second true argument is passed instead of a first,
then a list or anonymous array of introspection data will be returned for
properties that uniquely identify an object (excluding C<id>, which is
assumed).

Each hash key is the name of a property or attribute of the object. See each
subclass for a list of the properties included in the hash. The value for a
hash key is another anonymous hash containing the following keys:

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

B<Notes:> The method is a no-op here in the Bric base class. See the
subclasses for implementations and detail regarding the properties they
return.

=cut

sub my_meths {}

##############################################################################

=begin private

=head2 Destructors

=head3 DESTROY

This is the default destructor method. Even if nothing is defined within it,
it should still be here so that Perl wont waste time trying to find it in the
C<AUTOLOAD()> method.

=end private

=cut

sub DESTROY {}

=head2 Instance Methods

=head3 get/set

 my $val = $obj->get_field1;
 $obj = $obj->set_field1($val);

This is the AUTOLOAD handler. It translates all set and get operations into
subroutines acting upon the fields in derived classes.

B<Side Effects:> Creates a custom subroutine reference in the object package's
namespace.

B<Throws:>

=over 4

=item Exception::GEN

=back

=cut

sub AUTOLOAD {
    my $self = $_[0];
    my $pkg = ref $self or throw_gen "$self is not an object";
    my ($op, $field, $perm, $msg);

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
    throw_gen "Bad AUTOLOAD method format: $AUTOLOAD"
      unless $op and $field;

    throw_gen "Cannot AUTOLOAD private methods: $AUTOLOAD"
      if $field =~ /^_/;

    # Get the permissions for this field
    $perm = $pkg->ACCESS()->{$field} || FIELD_INVALID;

    # field doesn't exist!
    throw_gen "Access denied: '$field' is not a valid field for package $pkg."
      if $perm & FIELD_INVALID;

    # A get request
    if ($op eq 'get') {
        # check permissions
        throw_gen qq{Can't locate object method "get_$field" via package "$pkg"}
          unless $perm & FIELD_READ;

        # setup get method
        *{$AUTOLOAD} = QA_MODE ?
          sub { return $_[0]->{$field} } :    # take a shortcut
          sub { return $_[0]->_get($field) }; # go directly to jail
    }

    # A set request
    elsif ($op eq 'set') {
        # check permissions
        throw_gen qq{Can't locate object method "set_$field" via package "$pkg"}
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
        throw_gen qq{Can't locate object method "$op\_$field" via package "$pkg"};
    }

    # call the darn method - all the parameters are still in @_
    &$AUTOLOAD;
}

##############################################################################

=head3 get_grp_ids

  my @grp_ids = $obj->get_grp_ids;
  my $grp_ids_aref = $obj->get_grp_ids;
  my @grp_ids = Bric->get_grp_ids;
  my $grp_ids_aref = Bric->get_grp_ids;

Return a list of IDs for the Bric::Util::Grp objects to which the object
belongs. When called as a class method, return the value of the class'
C<INSTANCE_GROUP_ID> constant. Values are returned as a list in an array
context, and as an array reference in a scalar context.

=cut

sub get_grp_ids {
    my $self = shift;

    # Don't bother doing anything if this isn't a groupable class.
    return unless defined($self->GROUP_PACKAGE);

    # If it's just a class name, just return the instance class ID.
    return $self->INSTANCE_GROUP_ID unless ref $self;

    # Just return if there are no group IDs.
    return unless exists $self->{grp_ids};

    # Return the group IDs.
    return wantarray ? @{$self->{grp_ids}} : $self->{grp_ids};
}

##############################################################################

=head3 cache_me

  $obj = $obj->cache_me;

Caches the object for later retrieval by the C<lookup()> class method. Should
be called for all objects retrieved from the database, including all objects
to be returned by C<lookup()>, C<list()>, and C<href()> methods.

=cut

sub cache_me {
    my $self = shift;
    if (defined MOD_PERL) {
        my $pkg = $self->cache_as or return;
        # Skip unsaved objects.
        return unless defined $self->{id};
        my $req = Bric::Util::ApacheReq->request;
        # We may be called during Apache startup
        return $self unless $req;
        my $r = Bric::Util::ApacheReq->instance($req);
        # Cache it under its ID.
        $r->pnotes("$pkg|id|$self->{id}" => $self);
        # Cache it under other unique identifiers.
        foreach my $m ($self->my_meths(0, 1)) {
            $r->pnotes("$pkg|$m->{name}|" . lc $m->{get_meth}->($self) => $self);
        }
    }
    if (CACHE_DEBUG_MODE && $Bric::CACHE_DEBUG_MODE_RUNTIME) {
        my $pkg = $self->cache_as or return;
        # Skip unsaved objects.
        return unless defined $self->{id};

        # Cache it under its ID.
        $Bric::DEBUG_CACHE{"$pkg|id|$self->{id}"} = $self;
        # Cache it under other unique identifiers.
        foreach my $m ($self->my_meths(0, 1)) {
            $Bric::DEBUG_CACHE{"$pkg|$m->{name}|" . lc $m->{get_meth}->($self)}
              = $self;
        }
    }
    return $self;
}

##############################################################################

=head3 uncache_me

  $obj->uncache_me;

Remove an object from the cache.  This should be done before an
object's associated data is permanently deleted from the database.

=cut

sub uncache_me {
    my $self = shift;
    if (defined MOD_PERL) {
        my $pkg = $self->cache_as or return;
        # Skip unsaved objects.
        return unless defined $self->{id};
        my $req = Bric::Util::ApacheReq->request;
        # We may be called during Apache startup
        return $self unless $req;
        my $r = Bric::Util::ApacheReq->instance($req);

        # Uncache it under its ID.
        $r->pnotes("$pkg|id|$self->{id}" => undef);
        # Uncache it under other unique identifiers.
        foreach my $m ($self->my_meths(0, 1)) {
            $r->pnotes("$pkg|$m->{name}|" . lc $m->{get_meth}->($self) => undef);
        }
    }
    if (CACHE_DEBUG_MODE && $Bric::CACHE_DEBUG_MODE_RUNTIME) {
        my $pkg = $self->cache_as or return;
        # Skip unsaved objects.
        return unless defined $self->{id};

        $Bric::DEBUG_CACHE{"$pkg|id|$self->{id}"} = undef;
        foreach my $m ($self->my_meths(0, 1)) {
            $Bric::DEBUG_CACHE{"$pkg|$m->{name}|" . lc $m->{get_meth}->($self)}
              = undef;
        }
    }
    return $self;
}

##############################################################################

=head3 register_instance

  $obj = $obj->register_instance;

Add the current object to the appropriate "All" group in the database. These
are groups that contain every instance of a particular type of object.

B<Throws:>

=over

=item Exception::DA

=back

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

##############################################################################

=head3 unregister_instance

  $obj = $obj->unregister_instance;

Remove the current object from the appropriate "All" group in the database.
These are groups that contain every instance of a particular type of object.

B<Throws:>

=over

=item Exception::DA

=back

=cut

sub unregister_instance {
    my $self = shift;

    # Fail if the package has not defined the GROUP_PACKAGE constant.
    return unless defined $self->GROUP_PACKAGE;
    return unless defined $self->INSTANCE_GROUP_ID;

    my $grp_id  = $self->INSTANCE_GROUP_ID;
    my $grp_pkg = $self->GROUP_PACKAGE;
    my $grp     = $grp_pkg->lookup({ id => $grp_id }) or return;

    my @mbs = $grp->get_members;

    my ($mem) = grep($_->get_object->get_id eq $self->get_id, @mbs);

    $grp->delete_members($mem);

    return $self if $grp->save;
}

##############################################################################

=head3 save

  $obj = $obj->save;

Save the current object by setting an internal flag indicating that it has
been saved. Subclasses should override this method to save object data to the
database.

=cut

sub save {
    my $self = shift;
    $self->{_dirty} = 0;
    return $self;
}

##############################################################################

=head2 Functions

=head3 register_fields

  Bric::register_fields({ field1  => Bric::FIELD_READ,
                          field2  => Bric::FIELD::RDWR
                        });

This function is used by sub classes to register their field names and assign
access levels to them.

B<Side Effects>: Defines a subroutine named C<ACCESS()> in the caller's
package.

B<Throws:>

=over 4

=item Exception::GEN

=back

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

    throw_gen error => "Unable to register field names", payload => $@
      if $@;
}

##############################################################################

=begin private

=head2 Private Instance Methods

These methods are designed to be used by subclasses.

=head3 _get__dirty

  my $dirty = $obj->_get__dirty;

Gets the value of the dirty boolean. This attribute indicates whether data in
the object has changed since it was instantiated or last saved, so that the
C<save()> method can determine whether to save data to the database again.

=cut

sub _get__dirty {
    my $self = shift;
    return $self->{'_dirty'};
}

=head3 _set__dirty

  $ojb = $obj->_set__dirty($dirty);

Sets the value of the dirty boolean. This attribute indicates whether data in
the object has changed since it was instantiated or last saved, so that the
C<save()> method can determine whether to save data to the database again.

=cut

sub _set__dirty {
    my $self = shift;
    $self->{'_dirty'} = shift;
    return $self;
}

##############################################################################

=head3 _set

  $obj = $obj->_set(\%values);
  $obj = $obj->_set(\@fields, \@values);

Sets field values. Can be called with either a hash reference of field name
keys and their corresponding values, or as two array references, one
containing all the field names, the other containing the values for those
keys, in order.

B<Notes:> For performance reasons, certain error checking only occurrs in
C<QA_MODE>.

B<Throws:>

=over 4

=item Exception::GEN

=back

=cut

sub _set {
    my $self = shift;

    # Make sure we have arguments.
    throw_gen "Incorrect number of args to _set()." unless @_;

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
            throw_gen error =>  "Error setting value for '$key' in _set().",
              payload => $@ if $@;
        }
    }

    # Set the dirty flag to show that this objects needs an update.
    $self->{_dirty} = 1 if $dirt;
    return $self;
}

##############################################################################

=head3 _get

  my @vals = $obj->_get(@fields);
  my $val = $obj->_get($field);

Retrieves field values. If passed a list of field names, it will return a list
of values for those fields. If passed a single field name, it will return a
single value for that field.

B<Notes:> Error checking and exception throwing is only performed in QA_MODE
for performance reasons.

B<Throws:>

=over 4

=item Exception::GEN

=back

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
            throw_gen "Problems retrieving field '$_': $@" if $@;
        }

        # Syntax sugar. Let the user say $n = get_foo rather than ($n) =
        # get_foo
        return wantarray ? @return : $return[0];
    }

}

##############################################################################

=head2 Private Functions

=head3 die

Bricolage overrides all exception handling to use exceptions unless it is
running under C<mod_perl>.

=head3 warn

Bric overrides all C<warn>ings to use exceptions unless it is running under
C<mod_perl>.

=cut

unless (MOD_PERL) {
    $SIG{__DIE__} = \&throw_gen;
    $SIG{__WARN__} = sub {
        print STDERR Bric::Util::Fault::Exception::GEN->new(error => shift)
    };
}

##############################################################################

=end private

=head1 Author

Garth Webb <garth@perijove.com>

Sam Tregar <stregar@about-inc.com>

=head1 See Also

NONE

=cut

1;
