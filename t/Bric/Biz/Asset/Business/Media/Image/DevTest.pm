package Bric::Biz::Asset::Business::Media::Image::DevTest;
use strict;
use warnings;
use base qw(Bric::Biz::Asset::Business::Media::DevTest);
use Test::More;
use Bric::Config qw(:media :thumb);
use File::Basename;
use Test::File::Contents;
use Test::Exception;
use Bric::Biz::Person::User::DevTest;

my $fs = Bric::Util::Trans::FS->new;

##############################################################################
sub class { 'Bric::Biz::Asset::Business::Media::Image' }

##############################################################################
sub test_class_id : Test(1) {
    my $self = shift;
    my $class = $self->class;
    is $class->get_class_id, 50, 'Image class ID should be 50';
}

##############################################################################
sub test_thumbnail : Test(9) {
    my $self = shift;
    my $class = $self->class;

    my $image = $self->build_image;
    unless (USE_THUMBNAILS) {
        is $image->thumbnail_uri, undef, 'Should get no thumbnail URI';
        return 'Thumbnails disabled!';
    }

    unless ($Imager::formats{png}) {
        diag $image->thumbnail_uri;
        is $image->thumbnail_uri, '/media/mime/none.png', 'Should get no thumbnail URI';
        return 'PNG support not built in to Imager';
    }

    # Check the thumbnail URI.
    my $loc = $image->get_location or return;
    $loc =~ s{(\.[^.\\/]+)$}{_thumb$1}g or $loc .= '_thumb';
    my $uri = Bric::Util::Trans::FS->cat_uri(
        Bric::Config::MEDIA_URI_ROOT,
        Bric::Util::Trans::FS->dir_to_uri($loc)
    );
    is $image->thumbnail_uri, $uri, 'We should have a thumbnail URI';

    # Check its file location.
    my $tfile = Bric::Util::Trans::FS->cat_file(MEDIA_FILE_ROOT, $loc);
    is $image->_thumb_file, $tfile, 'We should have a thumbnail file';
    ok -e $tfile, 'And the file should exist';

    # Check its dimensions.
    my $img = Imager->new;
    $img->open(file => $tfile, type => 'png') or die "Cannot open $tfile: " . $img->errstr;
    is $img->getwidth, THUMBNAIL_SIZE,  'It should be the proper width';
    is $img->getheight, THUMBNAIL_SIZE, 'It should be the proper heigth';
}

##############################################################################
sub test_alternate_thumb : Test(26) {
    my $self = shift;

    # Gotta have thumbnail support to run this test.
    return 'Thumbnails disabled!' unless USE_THUMBNAILS;
    return 'PNG support not built in to Imager' unless $Imager::formats{png};

    my $image = $self->build_image;
    ok my $mid = $image->get_id, 'We should have an ID';

    ok my $thumb = $image->find_or_create_alternate({
        use_thumb => 1,
    }), 'Create a thumbnail media document';
    $self->add_del_ids($thumb->get_id);

    isa_ok $thumb, ref($image), 'It should be the same type of document as the image';
    isnt $thumb->get_id, $mid, 'It should have a different media ID';

    is $thumb->get_file_name, 'simpsonized_thumb.png',
        'It should have the correct file name';
    is $thumb->get_title, 'Thumbnail for Simpsonized!',
        'It should have the correct title';
    is $thumb->get_description, 'Thumbnail for Whatever',
        'It should have the correct description';
    is $thumb->get_category_id, $image->get_category_id,
        'It should be in the same category as the original image';
    is $thumb->get_element_type_id, $image->get_element_type_id,
        'It should be in the same element_type as the original image';
    is $thumb->get_priority, $image->get_priority,
        'It should have the same priority as the original image';
    is $thumb->get_source_id, $image->get_source_id,
        'It should have the same source as the original image';
    is $thumb->get_site_id, $image->get_site_id,
        'It should have the same site as the original image';
    is $thumb->get_media_type->get_id, $image->get_media_type->get_id,
        'It should have the same media type as the original image';
    is $thumb->get_user_id, undef, 'The user should be undef';
    ok $thumb->get_workflow_id, 'It should have a workflow ID';
    ok $thumb->get_desk_id, 'It should have a desk ID';
    ok $thumb->get_current_desk->can_publish, 'And it should be on a publish desk';
    ok !$thumb->get_checked_out, 'It should not be checked out';
    is $image->get_element->get_related_media_id, $thumb->get_id,
        'It should be related to the original image';

    # Check the events.
    $self->check_events(
        $thumb,
        qw(media_new media_add_workflow media_moved media_save media_checkin media_moved)
    );

    # Make sure it's the same file as the thumbnail.
    my $loc = $image->get_location or return;
    $loc =~ s{(\.[^.\\/]+)$}{_thumb$1}g or $loc .= '_thumb';
    my $tfile = Bric::Util::Trans::FS->cat_file(MEDIA_FILE_ROOT, $loc);
    file_contents_identical $thumb->get_path, $tfile,
        'It should be the same file as the thumbnail';

    # Make sure that the next call simply finds it.
    ok my $alt = $image->find_or_create_alternate({
        use_thumb => 1,
    }), 'Find the just created alternate';
    is $alt->get_id, $thumb->get_id, 'It should be the same object';
}

##############################################################################
sub test_alternate : Test(no_plan) {
    my $self = shift;

    # Gotta have thumbnail support to run this test.
    return 'Thumbnails disabled!' unless USE_THUMBNAILS;
    return 'PNG support not built in to Imager' unless $Imager::formats{png};

    my $image = $self->build_image;
    ok my $mid = $image->get_id, 'We should have an ID';
    is $image->get_element_key_name, 'photograph', 'It should be a photograph';

    ok my $et = Bric::Biz::ElementType->lookup({ key_name => 'illustration' }),
        'Look up a different element type';

    # Make the alternate fixed, so the URI will be different. This is a
    # regression.
    $et->set_fixed_uri(1);

    my %params = (
        element_type => $et,
        title_prefix => 'Alt of ',
        title_suffix => ', yo',
        file_prefix  => 'alt_',
        file_suffix  => '_yo',
        relate       => 0,
        checkin      => 0,
        move_to_pub  => 0,
        transformer  => sub {
            shift->scale( xpixels => 75 )->crop( top => 32 );
        },
    );

    # Construct an alternate to our liking.
    ok my $alt = $image->find_or_create_alternate(\%params),
        'Create an alternate media document';
    $self->add_del_ids($alt->get_id);

    # Check its essentials.
    isa_ok $alt, ref($image), 'It should be the same type of document as the image';
    isnt $alt->get_id, $mid, 'It should have a different media ID';

    is $alt->get_file_name, 'alt_simpsonized_yo.png',
        'It should have the correct file name';
    is $alt->get_title, 'Alt of Simpsonized!, yo',
        'It should have the correct title';
    is $alt->get_description, 'Alt of Whatever, yo',
        'It should have the correct description';
    is $alt->get_category_id, $image->get_category_id,
        'It should be in the same category as the original image';
    is $alt->get_element_type_id, $et->get_id,
        'It should be of the element type we specified';
    is $alt->get_priority, $image->get_priority,
        'It should have the same priority as the original image';
    is $alt->get_source_id, $image->get_source_id,
        'It should have the same source as the original image';
    is $alt->get_site_id, $image->get_site_id,
        'It should have the same site as the original image';
    is $alt->get_media_type->get_id, $image->get_media_type->get_id,
        'It should have the same media type as the original image';
    is $alt->get_user_id, Bric::App::Session::get_user_id,
        'The user should be the current user';
    ok $alt->get_workflow_id, 'It should have a workflow ID';
    ok $alt->get_desk_id, 'It should have a desk ID';
    ok !$alt->get_current_desk->can_publish, 'And it should not be on a publish desk';
    ok $alt->get_checked_out, 'It should be checked out';
    isnt $image->get_element->get_related_media_id, $alt->get_id,
        'It should not be related to the original image';

    # Check the events.
    $self->check_events(
        $alt,
        qw(media_new media_add_workflow media_moved media_save)
    );

    # Check its dimensions.
    my $img = Imager->new;
    $img->open(file => $alt->get_path, type => 'png')
        or die 'Cannot open ' . $alt->get_path . ': ' . $img->errstr;
    is $img->getwidth,  75,      'It should be the proper width';
    is $img->getheight, 75 - 32, 'It should be the proper height';

    # Make sure that the next call simply finds it.
    ok my $other = $image->find_or_create_alternate(\%params),
        'Find the just created alternate';
    is $other->get_id, $alt->get_id, 'It should be the same object';

    # Okay, do it again to cover the parameters we've missed.
    my $utest = 'Bric::Biz::Person::User::DevTest';
    ok my $user = $utest->test_class->new({ $utest->new_args }),
        'Create a new user';
    ok $user->save, 'Save that user';
    $self->add_del_ids($user->get_id, 'usr');

    %params = (
        et_key_name => 'illustration',
        width       => 48,
        height      => 48,
        file_suffix => '_foo',
        checkin     => 0,
        user        => $user,
    );

    # At first, we should get permission failures for this user.
    throws_ok {
        $image->find_or_create_alternate(\%params)
    } 'Bric::Util::Fault::Error::Forbidden';
    is $@->error, 'You do not have sufficient permission to create a media document for this site',
        'And it should have the proper message';

    # So let's get this user some permissions.
    ok my ($group) = Bric::Util::Grp->list({ name => 'Media Producers' }),
        'Look up the media producers group';
    ok $group->add_member({ obj => $user }), 'Add the user to that group';
    ok $group->save, 'Save the group';

    # Now it should work!
    local $ENV{FOO} = 1;
    $params{user} = $user = ref($user)->lookup({ login => $user->get_login });
    ok $alt = $image->find_or_create_alternate(\%params),
        'Create a brand new alternate';
    $self->add_del_ids($alt->get_id);

    isa_ok $alt, ref($image), 'It should be the same type of document as the image';
    isnt $alt->get_id, $mid, 'It should have a different media ID';
    isnt $alt->get_id, $other->get_id, 'It should have a different media than the first alternate';

    is $alt->get_file_name, 'simpsonized_foo.png',
        'It should have the correct file name';
    is $alt->get_title, 'Thumbnail for Simpsonized!',
        'It should have the correct title';
    is $alt->get_description, 'Thumbnail for Whatever',
        'It should have the correct description';
    is $alt->get_category_id, $image->get_category_id,
        'It should be in the same category as the original image';
    is $alt->get_element_type_id, $et->get_id,
        'It should be of the element type we specified';
    is $alt->get_element_key_name, 'illustration',
        'Which is to say it should be an illustration';
    is $alt->get_priority, $image->get_priority,
        'It should have the same priority as the original image';
    is $alt->get_source_id, $image->get_source_id,
        'It should have the same source as the original image';
    is $alt->get_site_id, $image->get_site_id,
        'It should have the same site as the original image';
    is $alt->get_media_type->get_id, $image->get_media_type->get_id,
        'It should have the same media type as the original image';
    is $alt->get_user_id, $user->get_id,
        'The user should be the one we specified';
    ok $alt->get_workflow_id, 'It should have a workflow ID';
    ok $alt->get_desk_id, 'It should have a desk ID';
    ok $alt->get_current_desk->can_publish, 'And it should be on a publish desk';
    ok $alt->get_checked_out, 'It should be checked out';
    is $image->get_element->get_related_media_id, $alt->get_id,
        'It should be related to the original image';

    # Check the events.
    $self->check_events(
        $alt,
        qw(media_new media_add_workflow media_moved media_save media_moved)
    );
}

##############################################################################
sub build_image {
    my $self = shift;
    ok my $image = $self->construct(
        name        => 'Simpsonized!',
        file_name   => 'simpsonized.png',
        description => 'Whatever',
    ), 'Create a new image object';

    # Upload an image to it.
    my $basename = 'simpsonized.png';
    my $fn = $fs->cat_file(dirname(__FILE__), $basename );
    ok open my $file, '<', $fn or die "Cannot open $fn: $!";
    ok $image->upload_file($file, $basename), 'Upload a media file';

    # Now save the media.
    ok $image->save, 'Save the media document';
    $self->add_del_ids($image->get_id);
    return $image;
}

sub check_events {
    my ($self, $img) = (shift, shift);
    my @events = map { $_->get_key_name } Bric::Util::Event->list({
        obj_id   => $img->get_id,
        class_id => 46, # media;
        Order    => 'timestamp',
    });
    is_deeply \@events, \@_, 'The proper events should have been logged';
}

1;
