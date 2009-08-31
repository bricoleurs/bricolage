package Bric::Biz::Asset::Business::Media::Image;

################################################################################

=head1 Name

Bric::Biz::Asset::Business::Media::Image - the media class that represents static
images

=cut

require Bric; our $VERSION = Bric->VERSION;

=head1 Date

$Data$

=head1 Synopsis

 # Creation of new Image objects
 $image = Bric::Biz::Asset::Business::Media::Image->new( $init )
 $image = Bric::Biz::Asset::Business::Media::Image->lookup( { id => $id })
 ($images || @images) = Bric::Biz::Asset::Business::Media::Image->list( $param)

 # list of ids
 ($id_list || @ids) = Bric::Biz::Asset::Business::Media::Image->list_ids($param)

=head1 Description

The Subclass of Media that pretains to Images

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
use Bric::Config qw(:media :thumb);
use Bric::App::Util ();
use Bric::App::Event ();
use Bric::Biz::Workflow qw(MEDIA_WORKFLOW);
use Bric::Util::Priv::Parts::Const qw(:all);
use Bric::Util::Fault qw(throw_error throw_gen throw_forbidden);
use Imager;

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

=head2 Constructors

=over 4

=cut

#-------------------------------#
# Constructors

#------------------------------------------------------------------------------#

=item $image = Bric::Biz::Asset::Business::Media::Image->new($init)

This will create a new image object.

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

#sub new {
#    my ($self, $init) = @_;
#
#    $self = bless {}, $self unless ref $self;

#    $self->SUPER::new($init);

#    return $self;
#}

################################################################################

=item $media = Bric::Biz::Asset::Business::Media::Image->lookup( { id => $id })

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

=item ($imgs || @imgs) = Bric::Biz::Asset::Business::Media::Image->list($param)

Returns a list of image objects that match the params passed in

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

=over

=item (@ids || $ids) = Bric::Biz::Asset::Business::Media::Image->list_ids($param)

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

=item $class_id = Bric::Biz::Asset::Business::Media::Image->get_class_id()

Returns the class id of the Image class

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_class_id {
    return 50;
}

################################################################################

=item my $key_name = Bric::Biz::Asset::Business::Media::Image->key_name()

Returns the key name of this class.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

#sub key_name { 'image' }

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

=over 4

=item my $thumbnail_uri = $image->thumbnail_uri

If the image document has an associated thumbnail image, this method returns
its local URI.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub thumbnail_uri {
    return unless USE_THUMBNAILS;
    my $self = shift;
    my $loc = $self->_thumb_location or return $self->SUPER::thumbnail_uri;
    return $self->SUPER::thumbnail_uri
      unless -e $self->_thumb_file || $self->create_thumbnail;
    return Bric::Util::Trans::FS->cat_uri(
        MEDIA_URI_ROOT,
        Bric::Util::Trans::FS->dir_to_uri($loc)
    );
}

##############################################################################

=item my $new_img = $image->find_or_create_alternate(\%params)

  my $new_image = $image->find_or_create_alternate({
      file_suffix => '_alt',
      et_key_name => 'thumb',
      user        => $user,
      relate      => 0,
      transformer => sub {
          shift->scale( xpixels => 115 )->crop( top => 76 );
      },
  });

Creates an alternate representation of the current image document and returns
it. This is useful for creating thumbnails and the like. Note that the user
must have CREATE access to the start desk in the first available workflow.

The first thing this method does is see if a likely alternate already exists
by looking for a media document in the same site, with the appropriate URI (as
formed by the current media document's category, cover date, and file name as
modified by the C<file_prefix> and C<file_suffix> parameters), and based on
the appropriate element type. If such a media document is found, it is simply
returned and no further actions are taken.

If such a media document does I<not> exist, C<find_or_create_alternate()>
creates it, moves it into workflow, takes other actions as determined by the
parameters, and returns it.

It's important to get the parameters right in order to properly find or create
the alternate representation of an image that you need for your site. So read
these descriptions carefully!

=over

=item title_prefix

=item title_suffix

Strings to add to the beginning and/or end of the media document's title to
create a new title for the new media document. They will also be used to
modify the image description. The prefex defaults to "Thumbnail for " while
the suffix defaults to an empty string.

=item file_prefix

=item file_suffix

String to add to the beginning and/end of the media document's file name to
create a new document's file name. The prefix defaults to the empty string
while the suffix defaults to "_thumb". The resulting file name will be used
both to search for an exsting image with this file name and, if there isn't
one, to provide the file name for the new image document.

Note that the suffix will be inserted into the file name I<before> the file
name extension. For example, F<foo.png> will become F<foo_thumb.png>, not
F<foo.png_thumb>.

=item user

The user who will "create" the new media document. Defaults to the current
user. Useful in templates to provide a user who might have more extensive
permissions than the current user.

=item element_type

The media element type on which the alternate will be based. Also used to find
an existing media document.

=item et_key_name

The key name for the element type on which the alternate will be based. Also
used to find an existing media document. If both C<element> and C<et_key_name>
are passed, C<et_key_name> will be used.

=item transformer

A code reference that expects a single argument, an L<Imager|Imager> object,
and returns an L<Imager|Imager> object. Use this code reference to transform
the media document file into a new file to be used for the alternate. For
example, if you wanted to create a new image that's 115 pixels wide and crops
the image to get only the top 76 pixels, you can pass something like this:

    transformer => sub {
        shift->scale( xpixels => 115 )->crop( top => 76 );
    },

Consult the L<Imager|Imager> documentation, and especially
L<Imager::Transformations|Imager::Transformations>, for its complete API,
examples, etc. Note taht the C<transformer> code reference will only be called
if the alternate does not already exist.

=item width

=item height

The height and width, in pixels, to make the alternate image. Only used if an
existing image is not found, and if the C<transformer> parameter has not been
passed.

=item use_thumb

Boolean indicating whether or not to use the thumbnail file to create the
alternate document. If true, the C<transform>, C<width>, and C<height>
parameters will be ignored and the existing thumbnail file will simply be
used. Defaults to false.

=item relate

Boolean to indicate whether or not to relate the new image, if one is created
to the current image. If true, and an alternate is created, it will be added
as a related media document to the original media document's top-level
element. Defaults to true.

=item checkin

Boolean to indicate whether or not to check in the newly created alternate
image document. Defaults to true.

=item move_to_pub

Boolean to indicate whether or not to move in the newly created alternate
image document to a publish desk. Defaults to true. Note that the user must
have READ access to a PUBLISH desk or else an exception will be thrown.

=back

B<Throws:> Exceptions when the user does not have permission to create a media
document in a media workflow, or does not have permission to move it to a
publish desk, or if the necessary libraries to support the desired
transformations are not included in the L<Imager|Imager> build.

B<Side Effects:> If no alternate can be found, a new media document will be
created, put into workflow, and possibly checked in and moved to the publish
desk.

B<Notes:> Isn't the above enough?

=cut

sub find_or_create_alternate {
    my ($self, $p) = @_;

    # Dupe the parameters.
    $p = { %{ $p } };

    for my $spec (
        [ title_prefix => 'Thumbnail for ' ],
        [ title_suffix => ''               ],
        [ file_prefix  => ''               ],
        [ file_suffix  => '_thumb'         ],
        [ checkin      => 1                ],
        [ relate       => 1                ],
        [ move_to_pub  => 1                ],
    ) {
        $p->{ $spec->[0] } = $spec->[1] unless exists $p->{ $spec->[0] };
    }

    # Figure out what element type to use.
    my $et = $p->{et_key_name}
        ? Bric::Biz::ElementType->lookup({ key_name => $p->{et_key_name} })
        : $p->{element_type} || $self->get_element_type;

    # Construct a URI for the alternate image.
    my $image_fn  = $self->get_file_name;
    (my $alt_fn = $p->{file_prefix} . $image_fn)
        =~ s{(\.[^.\\/]+)$}{$p->{file_suffix}$1}gs;
    my $uri = do {
        # We need to use the same element type, so that the URI is correct. So
        # we trick get_element_type() to return the object we want. Yeah, it's
        # a hack, but it's the cleanest way to do it without creating
        # unnecesary pain.
        local $self->{_element_type_object} = $et;
        (my $u = URI::Escape::uri_unescape($self->get_uri($self->get_primary_oc)))
            =~ s{\Q$image_fn\E$}{$alt_fn};
        $u;
    };

    # Return it if it already exists.
    my ($alt) = ref($self)->list({
        site_id      => $self->get_site_id,
        uri          => $uri,
        element_type => $et->get_key_name,
    });
    return $alt if $alt;

    # Temporarily replace the session user object.
    local $HTML::Mason::Commands::session{_bric_user}->{object} = $p->{user}
        if $p->{user};
    my $user = Bric::App::Util::get_user_object;

    # Create a new media document.
    $alt = ref($self)->new({
        priority      => $self->get_priority,
        title         => $p->{title_prefix} . $self->get_title . $p->{title_suffix},
        description   => $p->{title_prefix} . ($self->get_description || '') . $p->{title_suffix},
        site_id       => $self->get_site_id,
        source__id    => $self->get_source__id,
        media_type_id => $self->get_media_type->get_id,
        category__id  => $self->get_category__id,
        element_type  => $et,
        user__id      => $user->get_id,
    });

    $alt->set_cover_date($self->get_cover_date(Bric::Config::ISO_8601_FORMAT));

    # Find and associate a workflow and desk.
    my $wf = $self->get_workflow_object;
    my $desk;
    if ($wf) {
        if ($user->what_can(undef, READ, $wf->get_asset_grp_id, $wf->get_grp_ids) >= READ) {
            $desk = $wf->get_start_desk;
            unless ($user->what_can(
                'Bric::Biz::Asset::Business::Media',
                $desk->get_asset_grp,
            ) >= CREATE) {
                # No CREATE access to the start desk.
                $desk = $wf = undef;
            }
        } else {
            $wf = undef;
        }
    }
    unless ($wf) {
        for my $w (Bric::Biz::Workflow->list({
            site_id => $self->get_site_id,
            type    => MEDIA_WORKFLOW,
        })) {
            next unless $user->what_can(undef, READ, $w->get_asset_grp_id, $w->get_grp_ids) >= READ;
            next unless $user->what_can(
                'Bric::Biz::Asset::Business::Media',
                $w->get_start_desk->get_asset_grp,
            ) >= CREATE;
            $wf = $w;
            $desk = $wf->get_start_desk;
        }
    }
    throw_forbidden(
        error    => 'You do not have sufficient permission to create a media document for this site',
        maketext => ['You do not have sufficient permission to create a media document for this site'],
    ) unless $wf && $desk;

    # Set the start desk and the workflow.
    $alt->set_workflow_id($wf->get_id);
    $alt->save;
    $desk->accept({ asset => $alt });
    $desk->save;

    # Associate an image file.
    if (USE_THUMBNAILS && $p->{use_thumb}) {
        # Add the thumbnail image file to the media document.
        my $path = $self->_thumb_file;
        open my $alt_fh, '<', $path or die "Cannot open '$path': $!\n";
        $alt->upload_file($alt_fh => $alt_fn);
        close $alt_fh;
    } else {
        # Transform the existing image.
        my $img = $self->_modify_image($p);
        $alt->upload_file($img => $alt_fn);
    }

    # Save the new image.
    $alt->save;

    # Log that a new media has been created and generally handled.
    Bric::App::Event::log_event('media_new', $alt);
    Bric::App::Event::log_event('media_add_workflow', $alt, { Workflow => $wf->get_name });
    Bric::App::Event::log_event('media_moved', $alt, { Desk => $desk->get_name });
    Bric::App::Event::log_event('media_save', $alt);

    # Add the alternate to the media document and return it.
    $self->get_element->set_related_media($alt)->save if $p->{relate};

    if ($p->{checkin}) {
        # Go ahead and check it in.
        $alt->checkin;
        Bric::App::Event::log_event('media_checkin', $alt);
    }

    if ($p->{move_to_pub}) {
        # We want to move it to a publish desk.
        my $pub_desk;
        if ($desk->can_publish) {
            $pub_desk = $desk;
        } else {
            # Find pub desk in the workflow to which the user has READ access.
            for my $d (reverse $wf->allowed_desks) {
                if ($d->can_publish && $user->what_can(undef, READ, $d->get_asset_grp) >= READ) {
                    $pub_desk = $d;
                    last;
                }
            }
            throw_forbidden(
                error    => sprintf(
                    'You do not have READ acces to any desks in the "%s" workflow',
                    $wf->get_name
                ),
                maketext => [
                    'You do not have [_1] access to any desks in the "[_2]" workflow',
                    'READ', $wf->get_name,
                ]
            ) unless $pub_desk;
        }

        if ($pub_desk->get_id != $desk->get_id) {
            # Move it to the new desk.
            $desk->transfer({
                to    => $pub_desk,
                asset => $alt,
            });

            # Save both desks.
            $desk->save;
            $pub_desk->save;
            Bric::App::Event::log_event('media_moved', $alt, { Desk => $pub_desk->get_name });
        }
    }

    # Save and return.
    $alt->save if $p->{checkin} || $p->{move_to_pub};
    return $alt;
}

###################################################################### ##########

=item my $created_ok = $image->create_thumbnail

Creates a thumbnail image from the supplied image object. Returns 1 on
successful completion or error string if it fails.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub create_thumbnail {
    return unless USE_THUMBNAILS;
    my $self = shift;
    my $just_uploaded = shift;
    my $img = $self->_modify_image({
        warn          => 1,
        just_uploaded => $just_uploaded,
        transformer   => sub {
            my $img = shift;
            # If either dimension is greather than the thumbnail size, create a
            # smaller version by scaling largest side to THUMBNAIL_SIZE
            return $img unless $img->getwidth > THUMBNAIL_SIZE;

            return $img->scale(
                xpixels => THUMBNAIL_SIZE,
                ypixels => THUMBNAIL_SIZE,
                type    => 'min',
            );
        },
    });

    # Save the image or die.
    my $thumbfile = $self->_thumb_file;
    $img->write(file => $thumbfile) or throw_gen(
        error   => "Imager cannot write '$thumbfile'",
        payload => $img->errstr
    );
    return $self;
}

################################################################################

=item ($imgs || @imgs) = $image->upload_file

Overrides the C<upload_file()> method in the parent class and then makes a
call to the C<create_thumbnail()> method.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub upload_file {
    my $self = shift;
    $self->SUPER::upload_file(@_);
    $self->create_thumbnail(1) if USE_THUMBNAILS && !$self->_get('_upload_data');
    return $self;
}

=back

=cut

##############################################################################

=head1 Private

=head2 Private Class Methods

NONE

=head2 Private Instance Methods

=over 4

=item _thumb_location

  my $thumb_location = $self->_thumb_location;

Returns the location of a thumnail image file. This method simply modifies the
value returned by C<get_location> to generate the name of the image file. Returns
C<undef> if the image has no location.

=cut

sub _thumb_location {
    my $self = shift;
    my $loc = $self->get_location or return;
    $loc =~ s{(\.[^.\\/]+)$}{_thumb$1}g or $loc .= '_thumb';
    return $loc;
}

=item _thumb_file

  my $thumb_file = $self->_thumb_file;

Returns the absolute path to the thumnail image file for this image.

=cut

sub _thumb_file {
    my $self = shift;
    my $loc = $self->_thumb_location or return;
    return Bric::Util::Trans::FS->cat_file(MEDIA_FILE_ROOT,  $loc);
}

sub _modify_image {
    my ($self, $p) = @_;

    # Get the media format. Try using the MIME type, and fall back on what Imager
    # guesses.
    my $path = $self->get_path or return;
    my $format;
    if (my $mime = $self->get_media_type) {
        (my $mt = $mime->get_name) =~ s{.*/}{};
        $format = $Imager::FORMATGUESS->(lc ".$mt") || $Imager::FORMATGUESS->(lc $path);
    } else {
        $format = $self::FORMATGUESS->(lc $path);
    }

    unless ($format) {
        throw_gen( "Imager does not recognize the format of file “$path”" )
            unless $p->{warn};
        warn "Imager does not recognize the format file '$path'. No "
          . "thumbnail will be created.\n";
        return;
    }

    unless ($Imager::formats{$format}) {
        throw_gen(
            qq{It looks like the image library to handle the “$format” format is not installed.\n}
        ) unless $p->{warn};
        warn qq{It looks like the image library to handle the "$format" }
          . ' format is not installed. No thumbnail will be created for file '
          . "'$path'.\n";
        return;
    }

    # Create the Imager object.
    my $img = Imager->new;
    unless ( $img->open(file => $path, type => $format) ) {
        throw_gen(
            error  => 'Error creating a thumbnail for "', $self->get_uri, '"',
            payload => $img->errstr
        ) unless $p->{warn};
        warn 'Error creating a thumbnail for "', $self->get_uri, '": ',
            $img->errstr, $/;
        Bric::App::Util::add_msg(
            'Could not create a thumbnail for [_1]: [_2]',
            $self->get_uri,
            $img->errstr,
        ) if $p->{just_uploaded};
        return;
    }

    if (my $cb = $p->{transformer}) {
        # Let the callback transform the image.
        $img = $cb->($img);
    } else {
        # Scale the image.
        $img = $img->scale(
            xpixels => $p->{width}  || THUMBNAIL_SIZE,
            ypixels => $p->{height} || THUMBNAIL_SIZE,
            type    => 'min'
        );
    }

    return $img;
}

=back

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
