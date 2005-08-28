#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);
use Bric::Config qw(STORY_URI_WITH_FILENAME);

exit if fetch_sql q{SELECT 1 FROM category WHERE uri ~ './$'};

# Update the category URIs.
do_sql q{
    UPDATE category
    SET    uri = uri || '/'
    WHERE  uri <> '/'
       AND uri <> ''
};

exit if STORY_URI_WITH_FILENAME;

# Update the story URIs.
do_sql q{
    UPDATE story
    SET    primary_uri = primary_uri || '/'
    WHERE  primary_uri <> '/'
},

q{
    UPDATE story_uri
    SET    uri = uri || '/'
    WHERE  uri <> '/'
},
    ;
