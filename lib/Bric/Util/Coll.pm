package Bric::Util::Coll;
###############################################################################

=head1 NAME

Bric::Util::Coll - Interface for managing collections of objects.

=head1 VERSION

$Revision: 1.1 $

=cut

our $VERSION = substr(q$Revision: 1.1 $, 10, -1);

=head1 DATE

$Date: 2001-09-06 21:55:02 $

=head1 SYNOPSIS

  use Bric::Util::Coll::Foo;
  my $foo_coll = Bric::Util::Coll::Foo->new($params);

  # Get all the objects in the collection.
  foreach my $foo ($foo_coll->get_objs) {
      # Do stuff with Foo objects.
  }

  # Create a new object in the collection.
  my Foo $foo = $foo_coll->new_obj($init);

  # Add existing objects to the collection.
  $foo_coll->add_objs(@objs);

  # Delete an object from the collection by reference to its ID.
  $foo_coll->del_objs($foo->get_id);

  # Save all the changes. None will have propagated to the database until save()
  # is called.
  $foo_coll->save;

=head1 DESCRIPTION

This subclassable class assists in the management of collections of objects. It
provides a simple interface that's useful for composition, where there's a need
to store a collection of objects and do things to them, e.g., create new ones,
fetch them, and delete them.

The subclasses of Bric::Util::Coll just have to implement two methods:
class_name(), a class method that returns the name of the class of objects that
make up the collection; and save(), an instance method that takes all the
objects in the collection and saves their changes. The only other requirement
for using this class is the addition of the class method href() to the class
whose objects make up the collection. The href() method functions exactly as
does list(), except that it returns an anonymous hash of objects instead of a
list. The hash keys are the object IDs and the values are the objects
themselves.

You must implement a subclass of Bric::Util::Coll to use it; it cannot be used
on its own.

=cut

################################################################################
# Dependencies
################################################################################
# Standard Dependencies
use strict;

################################################################################
# Programmatic Dependences
use Bric::Util::Fault::Exception::MNI;
#use Bric::Util::Fault::Exception::GEN;

################################################################################
# Inheritance
################################################################################
use base qw(Bric);

################################################################################
# Function and Closure Prototypes
################################################################################
my ($populate);

################################################################################
# Constants
################################################################################
use constant DEBUG => 0;

################################################################################
# Fields
################################################################################
# Public Class Fields

################################################################################
# Private Class Fields

################################################################################

################################################################################
# Instance Fields
BEGIN {
    Bric::register_fields({
			 # Public Fields
			 objs => Bric::FIELD_READ,
			 new_obj => Bric::FIELD_READ,
			 del_obj => Bric::FIELD_READ,

			 # Private Fields
			 params => Bric::FIELD_NONE
			});
}

################################################################################
# Class Methods
################################################################################

=head1 INTERFACE

=head2 Constructors

=over 4

=item $org = Bric::Util::Coll->new($params)

Instanticates a new collection by calling the href() method of the class managed
by the collection. The class name must be identified by the class_name() method
of Bric::Util::Coll subclasses. That class must have an href() class method that
works like the list() method, but returns an anonymous hash instead of a list,
where the hash keys are the object IDs.

B<Throws:>

=over 4

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub new {
    my ($pkg, $params) = @_;
    my $self = bless {}, ref $pkg || $pkg;
    $self->SUPER::new({ objs => {}, params => $params,
			new_obj => [], del_obj => [] });
}

################################################################################

=item my $org = Bric::Util::Coll->lookup()

Not implemented - not needed.

B<Throws:>

=over

=item *

Bric::Util::Coll::lookup() method not implemented.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub lookup {
    die Bric::Util::Fault::Exception::MNI->new(
      {msg => __PACKAGE__."::lookup() method not implemented."});
}

################################################################################

=item Bric::Util::Coll->list()

Not implemented - not needed.

B<Throws:>

=over

=item *

Bric::Util::Coll::list() method not implemented.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub list {
    die Bric::Util::Fault::Exception::MNI->new(
      {msg => __PACKAGE__."::list() method not implemented."});
}

################################################################################

=back 4

=head2 Destructors

=over 4

=item $org->DESTROY

Dummy method to prevent wasting time trying to AUTOLOAD DESTROY.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=back

=cut

sub DESTROY {}

################################################################################

=head2 Public Class Methods

=item Bric::Util::Coll->list_ids()

Not implemented - not needed.

B<Throws:>

=over

=item *

Bric::Util::Coll::list_ids() method not implemented.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub list_ids {
    die Bric::Util::Fault::Exception::MNI->new(
      {msg => __PACKAGE__."::list_ids() method not implemented."});
}

################################################################################

=item Bric::Util::Coll->class_name()

Returns the name of the class of objects this collection manages. Must be
overridden in subclasses.

B<Throws:>

=over

=item *

Bric::Util::Coll::class_name() method not implemented.

=back

B<Side Effects:> NONE.

B<Notes:> Method must be overridden by subclasses.

=cut

sub class_name {
    die Bric::Util::Fault::Exception::MNI->new(
      {msg => __PACKAGE__."::class_name() method not implemented."});
    # Example:
    # return 'Bric::Biz::Person::Parts::Addr';
}

################################################################################

=head2 Public Instance Methods

=over 4

=item my (@objs || $objs_aref) = $coll->get_objs

=item my (@objs || $objs_aref) = $coll->get_objs(@obj_ids)

Returns a list or anonymous array of the objects stored in the collection.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

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

sub get_objs {
    my ($self, @ids) = @_;
    &$populate($self);
    my ($objs, $new_objs) = $self->_get('objs', 'new_obj');
    if (@ids) {
	return wantarray ? @{$objs}{@ids} : [@{$objs}{@ids}];
    } else {
	return wantarray ? ($self->_sort_objs($objs), @$new_objs)
	  : [($self->_sort_objs($objs), @$new_objs)];
    }
}

=item my $obj = $coll->new_obj($init_href)

Returns a new object that has been added to the collection.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub new_obj {
    my $self = shift;
    my $class = $self->class_name;
    my $new_objs = $self->_get('new_obj');
    push @$new_objs, $class->new(@_);
    return $new_objs->[-1];
}

=item $self = $coll->add_objs(@objs)

Adds existing objects to the collection.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub add_objs {
    my $self = shift;
    my $objs = $self->_get('objs');  # Get the objects.
    $objs->{$_->get_id} = $_ for @_; # Add the new objects.
    return $self;
}

=item $self = $coll->add_new_objs(@objs)

Adds existing objects to the collection as new objects.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub add_new_objs {
    my $self = shift;
    my $new_objs = $self->_get('new_obj');
    push @$new_objs, @_;
    return $self;
}

=item $self = $coll->del_objs(@objs || @obj_ids)

Deletes objects. Use either IDs or objects - but use them consistently!

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

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

sub del_objs {
    my $self = shift;
    &$populate($self);
    my ($objs, $del_objs) = $self->_get('objs', 'del_obj');
    if (@_) {
	push @$del_objs, delete @{$objs}{map { ref $_ ? $_->get_id : $_ } @_};
    } else {
	push @$del_objs, values %$objs;
	%$objs = ();
    }
    return $self;
}

=item $self = $coll->save

Saves the changes made to all the objects in the collection. Must be overridden.

B<Throws:>

=over

=item *

Bric::Util::Coll::save() method not implemented.

=back

B<Side Effects:> NONE.

B<Notes:> Method must be overridden by subclasses.

=cut

sub save {
    die Bric::Util::Fault::Exception::MNI->new(
      {msg => __PACKAGE__."::save() method not implemented."});
}

################################################################################

=back

=head1 PRIVATE

=head2 Private Class Methods

=over 4

=item Bric::Util::Coll->_sort_objs($objs_href)

Sorts a list of objects into an internally-specified order. The default is to
sort them by IDs (which are the hash keys in $objs_href), but this method may be
overridden in subclasses to profile different sorting algorithms.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _sort_objs {
    my ($pkg, $objs) = @_;
    return @{$objs}{sort keys %$objs};
}

=back

=head2 Private Instance Methods

NONE.

=head2 Private Functions

=over 4

=item $self = &$populate($self)

Populates the collection if it has not yet been populated.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

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

$populate = sub {
    my $self = shift;
    my ($objs, $params) = $self->_get('objs', 'params');
    return $self if $params eq 'populated';
    my $class = $self->class_name;
    %$objs = (%$objs, %{ $class->href($params) });
    $self->_set(['objs', 'params'], [$objs, 'populated']);
};

1;
__END__

=back

=head1 NOTES

NONE.

=head1 AUTHOR

David Wheeler <david@wheeler.net>

=head1 SEE ALSO

perl(1),
Bric (2)

=head1 REVISION HISTORY

$Log: Coll.pm,v $
Revision 1.1  2001-09-06 21:55:02  wheeler
Initial revision

=cut
