use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

# check if we're already upgraded.
exit if fetch_sql
  q{SELECT 1
    FROM   pg_class
    WHERE  relname = 'fkx_story__story_uri'}
  ;

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
}
__END__
