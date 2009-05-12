package Bric::Biz::Element;

###############################################################################

=head1 Name

Bric::Biz::Element - Bricolage Document Element base class

=cut

require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

 my @elements = Bric::Biz::Element->list($params)

 $id = $element->get_id;
 $element = $element->activate;
 $element = $element->deactivate;
 my $active = $element->is_active;
 $element = $element->save;

=head1 Description

This class defins the common structure of elements, the building blocks of
Bricolage story and media documents. There are two types of elements:
container elements and data elements. Container elements can contain any
number of container and data subelements. Data elements contain values, and
corrspond to fields in the Bricolage UI. See
L<Bric::Biz::Element::Container|Bric::Biz::Element::Container>
and
L<Bric::Biz::Element::Field|Bric::Biz::Element::Field>
for details of their interfaces and how they vary from
Bric::Biz::Element.

=cut

#==============================================================================#
# Dependencies                         #
#======================================#

#--------------------------------------#
# Standard Dependencies
use strict;

#--------------------------------------#
# Programatic Dependencies
use Bric::Util::Fault qw(throw_mni);

#==============================================================================#
# Inheritance                          #
#======================================#
use base qw(Bric);

#=============================================================================#
# Function Prototypes                  #
#======================================#

# None

#==============================================================================#
# Constants                            #
#======================================#

# None

#==============================================================================#
# Fields                               #
#======================================#

#--------------------------------------#
# Public Class Fields
# None.

#--------------------------------------#
# Private Class Fields
my ($METHS, @ORD);

#--------------------------------------#
# Instance Fields

BEGIN {
    Bric::register_fields(
               {
                # Public Fields

                # A name for this element that can be displayed
                'name'                          => Bric::FIELD_READ,

                # A unique name for this element to be used internal
                'key_name'                      => Bric::FIELD_READ,

                # A short description of this element
                'description'                   => Bric::FIELD_READ,

                # the parent id of this element
                'parent_id'                     => Bric::FIELD_RDWR,

                # the order in which this element should be returned
                'place'                         => Bric::FIELD_RDWR,

                # The data base id of the Element
                'id'                            => Bric::FIELD_READ,

                # The type of object that this element is associated with
                # will also be used to determine what table to put the data into
                # ( story || media )
                'object_type'                   => Bric::FIELD_RDWR,

                'object_order'                  => Bric::FIELD_RDWR,

                # the id of the object that this is a element for
                object_instance_id              => Bric::FIELD_RDWR,

                # Private Fields

                # the reference to the object
                '_object'                       => Bric::FIELD_NONE,

                # The active flag
                '_active'                       => Bric::FIELD_NONE

        });
}

#==============================================================================#
# Interface Methods                    #
#======================================#

=head1 Interface

=head2 Constructors

=over 4

=cut

#--------------------------------------#
# Constructors
#------------------------------------------------------------------------------#

=item my $element = Bric::Biz::Element->new($init)

Constructs a new element. Its attributes can be initialized via the C<$init>
hash reference. See the subclasses for a list of parameters. Cannot be called
directly, but must be called from a subclass.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub new {
    my ($self, $init) = @_;
    $self = bless {}, $self unless ref $self;
    $self->SUPER::new($init) if $init;
    $self->_set__dirty(1);
    return $self;
}

################################################################################

=item my @elements = Bric::Biz::Element->list($params)

Searches for and returns a list or anonymous array of element objects. Cannot
be called directly, but must be called from a subclass.

B<Throws:>

=over 4

=item Method Not Implemented

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub list {
    throw_mni(error => 'Method not Implemented');
}

################################################################################

#--------------------------------------#

=back

=head2 Destructors

=over 4

=item $element->DESTROY

Dummy method to prevent wasting time trying to AUTOLOAD DESTROY.

=cut

sub DESTROY {
    # This method should be here even if its empty so that we don't waste time
    # making Bricolage's autoload method try to find it.
}

#--------------------------------------#

=back

=head2 Public Class Methods

=over 4

=item $meths = Bric::Biz::Element->my_meths

=item my @meths = Bric::Biz::Element->my_meths(TRUE)

=item my @meths = Bric::Biz::Element->my_meths(0, TRUE)

Returns an anonymous hash of introspection data for this object. If called
with a true argument, it will return an ordered list or anonymous array of
introspection data. If a second true argument is passed instead of a first,
then a list or anonymous array of introspection data will be returned for
properties that uniquely identify an object (excluding C<id>, which is
assumed).

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

=item type

The display field type. Possible values are

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

=item *

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
    my ($pkg, $ord, $ident) = @_;
    return if $ident;

    # We don't got 'em. So get 'em!
    $METHS ||= {
                name        => { name     => 'name',
                                 get_meth => sub { shift->get_name(@_) },
                                 get_args => [],
                                 set_meth => sub { shift->set_name(@_) },
                                 set_args => [],
                                 disp     => 'Name',
                                 type     => 'short',
                                 len      => 256,
                                 req      => 1,
                                 props    => { type      => 'text',
                                               length    => 32,
                                               maxlength => 256
                                             }
                               },

                key_name    => { name     => 'key_name',
                                 get_meth => sub { shift->get_key_name(@_) },
                                 get_args => [],
                                 set_meth => sub { shift->set_key_name(@_) },
                                 set_args => [],
                                 disp     => 'Key Name',
                                 type     => 'short',
                                 len      => 256,
                                 req      => 1,
                                 props    => { type      => 'text',
                                               length    => 32,
                                               maxlength => 256
                                             }
                               },

                description => { name     => 'description',
                                 get_meth => sub { shift->get_description(@_) },
                                 get_args => [],
                                 set_meth => sub { shift->set_description(@_) },
                                 set_args => [],
                                 disp     => 'Description',
                                 len      => 256,
                                 type     => 'short',
                                 props    => { type => 'textarea',
                                               cols => 40,
                                               rows => 4
                                             }
                               }
               };

    return !$ord ? $METHS : wantarray ? @{$METHS}{@ORD} : [@{$METHS}{@ORD}];
}

##############################################################################

=item my @elements = Bric::Biz::Element->list($params)

Searches for and returns a list or anonymous array of element object
IDs. Cannot be called directly, but must be called from a subclass.

B<Throws:>

=over 4

=item Method Not Implemented

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub list_ids {
    throw_mni(error => 'Method Not Implemented');
}

################################################################################

=back

=head2 Public Instance Methods

=over 4

=item my $id = $p->get_id

Returns the element ID.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $name = $p->get_name

Returns the element name.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $key_name = $p->get_key_name

Returns the element key name.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $description = $p->get_description

Returns the element description.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $p = $p->set_description( $description )

Sets the element description, first converting non-Unix line endings.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub set_description {
    my ($self, $val) = @_;
    $val =~ s/\r\n?/\n/g if defined $val;
    $self->_set( [ 'description' ] => [ $val ]);
}

=item my $parent_id = $p->get_parent_id

Returns the ID of the element's parent element.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $p->set_parent_id($parent_id)

Sets the ID of the element's parent element.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $place = $p->get_place

Returns the element place, that is, its place in the order of subelements of
the parent element.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $p->set_place($place)

Sets the element place, that is, its place in the order of subelements of
the parent element.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $object_type = $p->get_object_type

Returns the element object type ("story" or "media");

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $p->set_object_type($object_type)

Sets the element object type ("story" or "media");

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $object_instance_id = $element->get_object_instance_id

Returns the ID of the version of the document (story or media) that the
element is associated with.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $element->set_object_instance_id($object_instance_id)

Sets the ID of the version of the document (story or media) that the element
is associated with.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $has_name = $element->has_name($name);

Returns true if an element has a name matching the C<$name> argument. Note
that this is not a direct comparison to the C<name> attribute of the element
object. Rather, it converts C<$name> so that it is all lowercase and its
non-alphanumeric characters are changed to underscores. The resulting value is
then compared to the element's C<key_name> attribute. In general, it's a
better idea to use C<has_key_name()>, or to do direct key name comparisons
yourself. This method is provided for backwards compatability.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub has_name {
    my $self = shift;
    my ($test_name) = @_;
    my $name = $self->get_key_name;
    $test_name =~ y/a-z0-9/_/cs;
    return $name eq lc($test_name);
}

################################################################################

=item my $has_key_name = $element->has_key_name($key_name)

Returns true if an element has a key name matching the C<$key_name> argument.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub has_key_name {
    my $self = shift;
    my ($test_name) = @_;
    return $self->get_key_name eq $test_name;
}

################################################################################

=item $parent_element = $element->get_parent

Returns the parent element object.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_parent {
    my $self = shift;
    my ($pid, $ot) = $self->_get(qw(parent_id object_type));
    return unless $pid && $ot;
    Bric::Biz::Element::Container->lookup({
        id          => $pid,
        object_type => $ot,
    });
}

################################################################################

=item $element = $element->activate

Activates the element.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub activate {
    my ($self) = @_;
    $self->_set( {'_active' => 1 });
    return $self;
}

################################################################################

=item $element = $element->deactivate()

Deactivates the element.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub deactivate {
    my ($self) = @_;
    $self->_set( {'_active' => 0 });
    return $self;
}

################################################################################

=item my $is_active $element->is_active

Returns true if the element is active, and false if it is not.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub is_active {
    my ($self) = @_;
    return $self->_get('_active') ? $self : undef;
}

################################################################################

#==============================================================================#

=back

=head1 Private

NONE

=head2 Private Class Methods

NONE

=head2 Private Instance Methods

NONE

=cut

1;
__END__

=head1 Notes

NONE

=head1 Author

michael soderstrom <miraso@pacbell.net>

=head1 See Also

L<perl>, L<Bric>, L<Bric::Biz::Asset::Business::Story>,
L<Bric::Biz::Asset::Business::Media>, L<Bric::Biz::ElementType>,
L<Bric::Biz::Element::Container>,
L<Bric::Biz::Element::Tile>

=cut

