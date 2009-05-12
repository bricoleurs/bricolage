package Bric::Biz::Asset::Business::Media::Video;

################################################################################

=head1 Name

Bric::Biz::Asset::Business::Media::Video - the media class that represents static
videos

=cut

require Bric; our $VERSION = Bric->VERSION;

=head1 Date

$Data$

=head1 Synopsis

 # Creation of new Video objects
 $video = Bric::Biz::Asset::Business::Media::Video->new( $init )
 $video = Bric::Biz::Asset::Business::Media::Video->lookup( { id => $id })
 ($videos || @videos) = Bric::Biz::Asset::Business::Media::Video->list( $param)

 # list of ids
 ($id_list || @ids) = Bric::Biz::Asset::Business::Media::Video->list_ids($param)

=head1 Description

The Subclass of Media that pretains to Videos 

=cut

#==============================================================================#
# Dependencies                  #
#===============================#

#-------------------------------#
# Standard Dependancies

use strict;

#-------------------------------#
# Programatic Dependancies

#==============================================================================#
# Inheritance                   #
#===============================#

# the parent module should have a 'use' line if you need to import from it.
# use Bric;

use base qw( Bric::Biz::Asset::Business::Media );

#==============================================================================#
# Function Prototypes           #
#===============================#

# None

#==============================================================================#
# Constants                     #
#===============================#

# None

#==============================================================================#
# Fields                        #
#===============================#

#-------------------------------#
# Public Class Fields

# Public Fields should use 'vars'
# use vars qw();

#-------------------------------#
# Private Class Fields

# Private fields use 'my'

#-------------------------------#
# Instance Fields

# None

# This method of Bricolage will call 'use fields for you and set some permissions.

BEGIN {
    Bric::register_fields( {
        # Public Fields

        # Private Fields

    });
}

#==============================================================================#
# Interface Methods             #
#===============================#

=head1 Interface

=head2 Constructrs

=over 4

=cut

#-------------------------------#
# Constructors

#------------------------------------------------------------------------------#

=item $video = Bric::Biz::Asset::Business::Media::Video->new($init)

This will create a new video object.

Supported Keys:

=over 4

=item *

Put Itmes here

=back

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub new {
    my ($self, $init) = @_;
    $self = bless {}, $self unless ref $self;
    return $self->SUPER::new($init);
}

################################################################################

=item $media = Bric::Biz::Asset::Business::Media::Video->lookup( { id => $id })

This will return the matched looked up object

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

#sub lookup {
#    my ($class, $param) = @_;

#    my $self;

#    return $self;
#}

################################################################################

=item ($imgs || @imgs) = Bric::Biz::Asset::Business::Media::Video->list($param)

Returns a list of video objects that match the params passed in

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

#sub _do_list {
#    my ($class, $param) = @_;

#}

################################################################################

#----------------------------#

=back

=head2 Destructors

=over 4

=item $self->DESTROY

dummy method to not wast the time of AUTHLOAD

=cut

sub DESTROY {
    # This method should be here even if its empty so that we don't waste time
    # making Bricolage's autoload method try to find it.
}

################################################################################

#-----------------------------#

=back

=head2 Public Class Methods

=over 4

=item (@ids || $ids) = Bric::Biz::Asset::Business::Media::Video->list_ids($param)

Returns a list of ids that match the particular params

Supported Keys:

=over 4

=item *

Put Keys Here

=back

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

#sub list_ids {
#    my ($class, $params) = @_;

#}

################################################################################

=item $class_id = Bric::Biz::Asset::Business::Media::Video->get_class_id()

Returns the class id of the Video class

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_class_id { 51 }

################################################################################


################################################################################

=item my $key_name = Bric::Biz::Asset::Business::Media::Video->key_name()

Returns the key name of this class.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

#sub key_name { 'video' }

################################################################################

=item my_meths()

Data Dictionary for introspection of the object

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut


#-----------------------------#

=back

=head2 Public Instance Methods

NONE

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

"Michael Soderstrom" <miraso@pacbell.net>

=head1 See Also

L<perl> , L<Bric>, L<Bric::Biz::Asset>, L<Bric::Biz::Asset::Business>,
L<Bric::Biz::Asset::Business::Media>

=cut
