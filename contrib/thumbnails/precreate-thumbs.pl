#!/usr/bin/perl
# Create thumbnails for all images in a Bricolage install.
# Requires that USE_THUMBNAILS be enabled in bricolage.conf.
# You'll also have to run this as your Apache user so you
# have permission to write to comp/data/media/*.

use strict;
use warnings;

# If BRICOLAGE_ROOT doesn't exist, this script will fail;
# change this to wherever your 'lib' directory is.
use lib "$ENV{'BRICOLAGE_ROOT'}/lib";
use Bric::Biz::Asset::Business::Media::Image;

# Creating 20000 image objects would suck, so I fetch the IDs
# then lookup each object as needed
my $ids = Bric::Biz::Asset::Business::Media::Image->list_ids;
print "creating ", scalar(@$ids), " thumbnails\n";
foreach my $id (@$ids) {
    my $img = Bric::Biz::Asset::Business::Media::Image->lookup({id => $id});
    my $res = eval { $img->create_thumbnail() };
    if ($@) {
        print "failed to create thumbnail $id: $@\n";
        print "res = $res\n" if defined $res;
        die;
    } else {
        print $img->get_primary_uri, $/;
    }
}
