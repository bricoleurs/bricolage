#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);
use Bric::Util::DBI qw(:all);

exit if test_index 'fkx_story__oc__story';

do_sql
  # Create story__output_channel indexes.
  q{CREATE INDEX fkx_story__oc__story
    ON     story__output_channel(story_instance__id)},

  q{CREATE INDEX fkx_story__oc__oc
    ON     story__output_channel(output_channel__id)},

  # Create story__output_channel foreign key constraints.
  q{ALTER TABLE story__output_channel
    ADD CONSTRAINT fk_story__oc__story FOREIGN KEY (story_instance__id)
    REFERENCES story_instance(id) ON DELETE CASCADE},

  q{ALTER TABLE story__output_channel
    ADD CONSTRAINT fk_story__oc__oc FOREIGN KEY (output_channel__id)
    REFERENCES output_channel(id) ON DELETE CASCADE},

  # Create media__output_channel indexes.
  q{CREATE INDEX fkx_media__oc__media
    ON     media__output_channel(media_instance__id)},

  q{CREATE INDEX fkx_media__oc__oc
    ON     media__output_channel(output_channel__id)},

  # Create media__output_channel foreign key constraints.
  q{ALTER TABLE media__output_channel
    ADD CONSTRAINT fk_media__oc__media FOREIGN KEY (media_instance__id)
    REFERENCES media_instance(id) ON DELETE CASCADE},

  q{ALTER TABLE media__output_channel
    ADD CONSTRAINT fk_media__oc__oc FOREIGN KEY (output_channel__id)
    REFERENCES output_channel(id) ON DELETE CASCADE},
  ;

__END__
