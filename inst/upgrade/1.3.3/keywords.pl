#!/usr/bin/perl -w
use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);
use Bric::Util::DBI qw(:all);

# Exit if change already exist in db
exit if fetch_sql( qq{
        SELECT 1 FROM pg_class WHERE RELNAME = 'story_keyword'
} );

my @sql = (
           # setup new tables
           'CREATE TABLE story_keyword (
              story_id          NUMERIC(10,0)  NOT NULL,
              keyword_id        NUMERIC(10,0)  NOT NULL,
              PRIMARY KEY (story_id, keyword_id))',
           'CREATE TABLE media_keyword (
              media_id         NUMERIC(10,0)  NOT NULL,
              keyword_id       NUMERIC(10,0)  NOT NULL,
              PRIMARY KEY (media_id, keyword_id))',
           'CREATE TABLE category_keyword (
              category_id       NUMERIC(10,0)  NOT NULL,
              keyword_id        NUMERIC(10,0)  NOT NULL,
              PRIMARY KEY (category_id, keyword_id))',

           # More should be done to cleanup existing keyword
           # structures.  I tried a few variations but each time I
           # triggered a cascading delete that wiped out most of the
           # database.  Unsurprisingly, PostgreSQL doesn't support
           # dropping these killer constraints short of dropping
           # tables.

           # If we do find a way, or if PostgreSQL grows up to be a
           # real database system, we can add a second upgrade script
           # to complete the repairs.

          );
do_sql( @sql );

# select existing story keyword relationships
my $sth = prepare('SELECT s.id, k.id FROM story s, member m, keyword_member km, keyword k WHERE km.object_id=k.id  and m.id=km.member__id AND s.keyword_grp__id=m.grp__id');
my $insert_sth = prepare('INSERT INTO story_keyword (story_id, keyword_id) VALUES (?, ?)');

# insert them into new table
execute($sth);
my ($story_id, $keyword_id);
bind_columns($sth, \$story_id, \$keyword_id);
while(fetch($sth)) {
    $insert_sth->execute($story_id, $keyword_id);
}
finish($sth);
finish($insert_sth);

# select existing category keyword relationships
$sth = prepare('SELECT c.id, k.id FROM category c, member m, keyword_member km, keyword k WHERE km.object_id=k.id AND m.id=km.member__id AND c.keyword_grp_id=m.grp__id');
$insert_sth = prepare('INSERT INTO category_keyword (category_id, keyword_id) VALUES (?, ?)');

# insert them into new table
execute($sth);
my $category_id;
bind_columns($sth, \$category_id, \$keyword_id);
while(fetch($sth)) {
    $insert_sth->execute($category_id, $keyword_id);
}
finish($sth);
finish($insert_sth);

