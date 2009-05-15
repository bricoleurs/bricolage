package Bric::Util::Coll;

=head1 Name

Bric::Util::Coll - Interface for managing collections of objects.

=cut

require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

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

  # See if existing members of the collection have been looked up in the
  # database.
  my $bool = $foo_coll->is_populated;

  # Save all the changes. None will have propagated to the database until save()
  # is called.
  $foo_coll->save;

=head1 Description

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

##############################################################################
# Dependencies
##############################################################################
# Standard Dependencies
use strict;

##############################################################################
# Programmatic Dependences
use Bric::Util::Fault qw(throw_mni throw_da);
use Bric::Config qw(:qa);

##############################################################################
# Inheritance
##############################################################################
use base qw(Bric);

##############################################################################
# Function and Closure Prototypes
##############################################################################
# None.

##############################################################################
# Constants
##############################################################################
use constant DEBUG => 0;

##############################################################################
# Fields
##############################################################################
# Public Class Fields

##############################################################################
# Private Class Fields

##############################################################################

##############################################################################
# Instance Fields
BEGIN {
    Bric::register_fields({
                         # Public Fields
                         objs => Bric::FIELD_READ,
                         new_obj => Bric::FIELD_READ,
                         del_obj => Bric::FIELD_READ,

                         # Private Fields
                         params  => Bric::FIELD_NONE,
                         _pop    => Bric::FIELD_NONE,
                        });
}

##############################################################################
# Class Methods
##############################################################################

=head1 Interface

=head2 Constructors

=over 4

=item my $coll = Bric::Util::Coll->new($params)

Instanticates a new collection. When data is required from the database, the
collection object will call the href() method of the class managed by the
collection (as defined by the class_name() method of the Bric::Util::Coll
subclasses), passing in the $params hash reference as an argument. If $params
is not defined, no data will be retreived from the database.

The class name identified by the class_name() method of Bric::Util::Coll
subclasses must must have an href() class method that works like the list()
method, but returns an anonymous hash instead of a list, where the hash keys
uniquely identify the objects returned (usually IDs).

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
    $self->SUPER::new({ objs => {},
                        params => $params,
                        _pop => $params ? 0 : 1,
                        new_obj => [],
                        del_obj => {} });
}

##############################################################################

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
    throw_mni(error => __PACKAGE__."::lookup() method not implemented.");
}

##############################################################################

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
    throw_mni(error => __PACKAGE__."::list() method not implemented.");
}

##############################################################################

=back

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

##############################################################################

=head2 Public Class Methods

=over 4

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
    throw_mni(error => __PACKAGE__."::list_ids() method not implemented.");
}

##############################################################################

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
    throw_mni(error => __PACKAGE__."::class_name() method not implemented.");
    # Example:
    # return 'Bric::Biz::Person::Parts::Addr';
}

##############################################################################

=back

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
    my $self = shift;
    my ($objs, $new_objs, $del_objs) = $self->_get(qw(objs new_obj del_obj));
    unless ($self->is_populated) {
        # Load the objects from the database, and then remove any deleted
        # objects.
        $self->_populate;
        delete @{$objs}{keys %$del_objs} if %$del_objs;
    }

    if (@_) {
        # Return just the objects that they want.
        return wantarray ? @{$objs}{@_} : [@{$objs}{@_}];
    } else {
        # Give 'em all of the objects.
        return wantarray ? ($self->_sort_objs($objs), @$new_objs)
          : [($self->_sort_objs($objs), @$new_objs)];
    }
}

=item my (@objs || $objs_aref) = $coll->get_new_objs

Returns a list or array reference of all of the objects that have been added
to the collection via C<new_objs()>. Note that, once C<save()> has been
called, the new objects are themselves saved, and are no longer considered new
objects. If there are no new objects, C<get_new_objs()> will return an empty
list in an array context, and undef in a scalar context.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_new_objs {
    my $new_objs = $_[0]->_get('new_obj');
    return unless @$new_objs;
    return wantarray ? @$new_objs : $new_objs;
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

=item $self = $coll->del_objs(@objs)

=item $self = $coll->del_objs(@obj_ids)

Deletes the objects in C<@objs> or identified by the IDs in C<@obj_ids> from
the collection, if they're a part of the collection, even if they've been
added by C<add_new_objs()> and the collection has not yet been C<save()>d. All
arguments can be either objects or object IDs; however, if you've constructed
an object already, pass it in rather than the ID, as C<del_objs()> likely will
have to construct the object from the ID, anyway.

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
    # If we're in QA mode, populate the collection. This will help to
    # catch bugs where someone tries to delete an object that isn't in
    # the collection.
    $self->_populate if QA_MODE;
    my ($objs, $del_objs, $new_objs) = $self->_get(qw(objs del_obj new_obj));

    # Create a hash of newly added objects, so that we can delete any from
    # there that have IDs.
    # XXX Next time, use a hash for new objects!
    my %new_idx;
    for (my $i = 0; $i <= $#$new_objs; $i++) {
        my $id = $new_objs->[$i]->get_id;
        next unless defined $id;
        $new_idx{$id} = $i;
    }

    my @remove_new;
    if ($self->is_populated) {
        foreach my $o (@_) {
            # Grab the ID.
            my $id = ref $o ? $o->get_id : $o;
            # Do some error checking if we're in QA_MODE.
            throw_da(error => "Object '$o' (ID=$id) not in collection")
              if QA_MODE && ! $objs->{$id} && ! $new_idx{$id};
            if (defined $new_idx{$id}) {
                # Just skip to the next one if we're removing one that
                # hasn't been saved.
                push @remove_new, delete $new_idx{$id};
                next;
            }
            # Add the object to be deleted to the del_obj hash.
            $del_objs->{$id} = delete $objs->{$id} if $objs->{$id};
        }
    } else {
        foreach my $o (@_) {
            my $id = $o;
            if (ref $o) {
                $id = $o->get_id;
            } else {
                $o = $self->class_name->lookup({ id => $id });
            }

            # Just skip to the next one if we're removing one that
            # hasn't been saved.
            if (defined $new_idx{$id}) {
                # Just skip to the next one if we're removing one that
                # hasn't been saved.
                push @remove_new, delete $new_idx{$id};
                next;
            }
            # Otherwise, store it away for deletion from the database.
            $del_objs->{$id} = $o;
        }
    }

    # Remove any items from new_objs.
    if (@remove_new) {
        # Do it in reverse order so that the numbers don't change!
        for my $idx (sort { $b <=> $a } @remove_new) {
            splice @$new_objs, $idx, 1;
        }
    }
    return $self;
}

=item $coll = $coll->is_populated

Returns true if the collection has been populated with existing objects
from the database, and false if it has not.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub is_populated { $_[0]->_get('_pop') ? $_[0] : undef }

=item $self = $coll->save

Saves the changes made to all the objects in the collection. Must be
overridden.

B<Throws:>

=over

=item *

Bric::Util::Coll::save() method not implemented.

=back

B<Side Effects:> NONE.

B<Notes:> Method must be overridden by subclasses.

=cut

sub save {
    throw_mni(error => __PACKAGE__."::save() method not implemented.");
}

##############################################################################

=back

=head1 Private

=head2 Private Class Methods

=over 4

=item Bric::Util::Coll->_sort_objs($objs_href)

Sorts a list of objects into an internally-specified order. The default is to
sort them by IDs (which are the hash keys in $objs_href), but this method may
be overridden in subclasses to profile different sorting algorithms.

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

=over 4

=item $self = $self->_populate

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

sub _populate {
    my $self = shift;
    my ($objs, $params, $pop) = $self->_get(qw(objs params _pop));
    return $self if $pop;
    my $class = $self->class_name;
    %$objs = (%$objs, %{ $class->href($params) });
    $self->_set(['objs', '_pop'], [$objs, 1]);
};

=back

=head2 Private Functions

NONE.

=cut

1;
__END__

=head1 Notes

NONE.

=head1 Author

David Wheeler <david@justatheory.com>

=head1 See Also

L<Bric|Bric>

=cut
