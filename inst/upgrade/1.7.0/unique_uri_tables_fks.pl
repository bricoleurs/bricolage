use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use Bric::Util::DBI qw(rollback);
use bric_upgrade qw(:all);

# check if we're already upgraded.
exit if test_index 'fkx_story__story_uri';

for my $type (qw(story media)) {
    do_sql
      qq{CREATE INDEX fkx_$type\__$type\_uri ON $type\_uri($type\__id)},

      qq{CREATE UNIQUE INDEX udx_$type\_uri__site_id__uri
         ON $type\_uri(lower_text_num(uri, site__id))},

      qq{ALTER TABLE $type\_uri
         ADD CONSTRAINT fk_$type\__$type\_uri FOREIGN KEY ($type\__id)
             REFERENCES $type(id) ON DELETE CASCADE},

      qq{ALTER TABLE $type\_uri
         ADD CONSTRAINT fk_$type\__site__id FOREIGN KEY (site__id)
             REFERENCES site(id) ON DELETE CASCADE},
      ;

    # Use our own DIE.
    local $SIG{__DIE__}= \&error;

    # Get a list of the IDs and use them to add all the required records to
    # the table.
    my $ids = col_aref("SELECT id FROM $type WHERE active = 1");
    $type eq 'story' ? add_story_uris($ids) : add_media_uris($ids);
}

my ($type, $aid, $uri, $ocname, $rolled_back);

sub add_story_uris {
    my $ids = shift;
    my $ins = prepare(q{INSERT INTO story_uri (story__id, site__id, uri)
                        VALUES (?, ?, ?)});

    for $aid (@$ids) {
        my $story = Bric::Biz::Asset::Business::Story->lookup({
            id => $aid
        });

        # Get all the associated output channels. Skip it if there are none.
        my @ocs = $story->get_output_channels or next;
        my $site_id = $story->get_site_id;

        # Fore every combination of category and output channel, insert the
        # URI. Some may be the same as previous ones, but only for this one
        # story.
        my %seen;
        for my $cat ($story->get_categories) {
            for my $oc (@ocs) {
                $ocname = $oc->get_name;
                $uri = lc $story->get_uri($cat, $oc);
                # Skip it if we've seen it before.
                next if $seen{$uri};
                # Make it so.
                execute($ins, $aid, $site_id, $uri);
                $seen{$uri} = 1;
            }
        }
    }
}

sub add_media_uris {
    my $ids = shift;
    my $ins = prepare(q{INSERT INTO media_uri (media__id, site__id, uri)
                        VALUES (?, ?, ?)});

    for my $aid (@$ids) {
        my ($uri, $ocname);
        my $media = Bric::Biz::Asset::Business::Media->lookup({
            id => $aid
        });

        # Get all the associated output channels. Skip it if there are none.
        my @ocs = $media->get_output_channels or next;
        my $site_id = $media->get_site_id;

        # Skip it if there's no category.
        next unless $media->get_category__id;
        my %seen;
        foreach my $oc (@ocs) {
            $ocname = $oc->get_name;
            $uri = lc $media->get_uri($oc);
            # Skip it if we've seen it before.
            next if $seen{$uri};
            # Make it so.
                execute($ins, $aid, $site_id, $uri);
            $seen{$uri} = 1;
        }
    }
}

sub error {
    my $err = shift;
    $uri ||= '';
    $ocname ||= '';
    rollback();
    $err = ref $err ? $err->as_text : $err;
    $|++;
    print qq{

    #######################################################
    !!!!!!!!!!!!! ERROR ERROR ERROR ERROR !!!!!!!!!!!!!!!!!

    There was an error inserting the URIs for $type # $aid
    Most likely it did not have a unique URI. The URI that
    caused the error was:

      $uri

    Non-unique URIs can be created by cloning a document
    and then neglecting to change its slug, cover date,
    and category associations sufficiently to differentiate
    the clone's URI from the original's.

    The above URI was generated for the "$ocname" output
    channel. Please make sure that all of its URIs are
    unique and try again. You'll need to either restore the
    database or clone and fix the issue in the Bricolage
    UI, or drop the new tables "story_uri" and "media_uri",
    fix the issue directly in the database, and then run
    `make upgrade` again.

    For reference, the error encountered was:

    $err

    !!!!!!!!!!!!! ERROR ERROR ERROR ERROR !!!!!!!!!!!!!!!!!
    #######################################################
} unless $rolled_back;
    $rolled_back = 1;
    exit(1);
}

1;
__END__
