#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

# This upgrade is for PostgreSQL only.
exit if DBD_TYPE ne 'Pg';

exit if fetch_sql q{
    SELECT true
      FROM pg_catalog.pg_trigger t
      JOIN pg_catalog.pg_class   c ON c.oid = t.tgrelid
     WHERE c.relname = 'story_member'
       AND t.tgname  = 'set_member_story_desk_id'
};

do_sql 'CREATE LANGUAGE plpgsql' unless fetch_sql q{
    SELECT true
      FROM pg_catalog.pg_language
     WHERE lanname = 'plpgsql'
       AND lanispl
};

local $/;
do_sql $_ for split /-- split/, <DATA>;

__DATA__
-- Set desk ID to 0 where not on a desk.
UPDATE story SET desk__id = 0
 WHERE desk__id > 0 AND id NOT IN (
SELECT story.id
  FROM story
  JOIN story_member ON story.id = story_member.object_id
  JOIN member       ON story_member.member__id = member.id
  JOIN desk         ON member.grp__id = desk.asset_grp
);

-- split

UPDATE media SET desk__id = 0
 WHERE desk__id > 0 AND id NOT IN (
SELECT media.id
  FROM media
  JOIN media_member ON media.id = media_member.object_id
  JOIN member       ON media_member.member__id = member.id
  JOIN desk         ON member.grp__id = desk.asset_grp
);

-- split

UPDATE template SET desk__id = 0
 WHERE desk__id > 0 AND id NOT IN (
SELECT template.id
  FROM template
  JOIN template_member ON template.id = template_member.object_id
  JOIN member       ON template_member.member__id = member.id
  JOIN desk         ON member.grp__id = desk.asset_grp
);

-- split

-- Set desk ID where asset is on a desk.
UPDATE story
   SET desk__id = desk.id
  FROM story_member
  JOIN member       ON story_member.member__id = member.id
  JOIN desk         ON member.grp__id = desk.asset_grp
 WHERE story.id = story_member.object_id
   AND story.desk__id <> desk.id;

-- split

UPDATE media
   SET desk__id = desk.id
  FROM media_member
  JOIN member       ON media_member.member__id = member.id
  JOIN desk         ON member.grp__id = desk.asset_grp
 WHERE media.id = media_member.object_id
   AND media.desk__id <> desk.id;

-- split

UPDATE template
   SET desk__id = desk.id
  FROM template_member
  JOIN member       ON template_member.member__id = member.id
  JOIN desk         ON member.grp__id = desk.asset_grp
 WHERE template.id = template_member.object_id
   AND template.desk__id <> desk.id;

-- split

/****************************************************************************/
-- Add triggers for story desk memberships.
CREATE OR REPLACE FUNCTION desk_has_story(
) RETURNS TRIGGER LANGUAGE PLPGSQL AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        IF NEW.desk__id = OLD.desk__id THEN RETURN NEW; END IF;
    END IF;
    IF NEW.desk__id > 0 THEN
        IF EXISTS (
            SELECT story_member.object_id
              FROM desk
              JOIN member       ON member.grp__id = desk.asset_grp
              JOIN story_member ON story_member.member__id = member.id
             WHERE desk.id                = NEW.desk__id
               AND story_member.object_id = NEW.id
        ) THEN RETURN NEW; END IF;
        RAISE EXCEPTION 'Desk % should have story % in its group but does not',
            NEW.desk__id, NEW.id;
    ELSIF TG_OP = 'UPDATE' THEN
        IF NOT EXISTS (
            SELECT story_member.object_id
              FROM desk
              JOIN member       ON member.grp__id = desk.asset_grp
              JOIN story_member ON story_member.member__id = member.id
             WHERE desk.id                = OLD.desk__id
               AND story_member.object_id = NEW.id
        ) THEN RETURN NEW; END IF;
        RAISE EXCEPTION 'Desk % should not have story % in its group but does',
            OLD.desk__id, NEW.id;
    ELSE
        RETURN NEW;
    END IF;
END;
$$;

-- split

CREATE CONSTRAINT TRIGGER story_is_on_desk
 AFTER INSERT OR UPDATE ON story
DEFERRABLE INITIALLY DEFERRED
 FOR EACH ROW EXECUTE PROCEDURE desk_has_story();

-- split

CREATE OR REPLACE FUNCTION desk_hasnt_story(
) RETURNS TRIGGER LANGUAGE PLPGSQL AS $$
BEGIN
    IF NOT EXISTS (
        SELECT story_member.object_id
          FROM desk
          JOIN member       ON member.grp__id = desk.asset_grp
          JOIN story_member ON story_member.member__id = member.id
         WHERE desk.id                = OLD.desk__id
           AND story_member.object_id = OLD.id
    ) THEN RETURN NEW; END IF;
    RAISE EXCEPTION 'Desk % should not have story % in its group but does',
        NEW.desk__id, NEW.id;
END;
$$;

-- split

CREATE CONSTRAINT TRIGGER story_not_on_desk
 AFTER DELETE ON story
DEFERRABLE INITIALLY DEFERRED
 FOR EACH ROW EXECUTE PROCEDURE desk_hasnt_story();

-- split

CREATE OR REPLACE FUNCTION set_member_story_desk_id(
) RETURNS TRIGGER LANGUAGE PLPGSQL AS $$
BEGIN
    UPDATE story
       SET desk__id = desk.id
      FROM member
      JOIN desk ON member.grp__id = desk.asset_grp
     WHERE story.id  = NEW.object_id
       AND member.id = NEW.member__id;
     RETURN NEW;
END;
$$;

-- split

CREATE TRIGGER set_member_story_desk_id
  AFTER INSERT OR UPDATE ON story_member
  FOR EACH ROW EXECUTE PROCEDURE set_member_story_desk_id();

CREATE OR REPLACE FUNCTION unset_member_story_desk_id(
) RETURNS TRIGGER LANGUAGE PLPGSQL AS $$
BEGIN
    UPDATE story
       SET desk__id = 0
      FROM member
      JOIN desk ON member.grp__id = desk.asset_grp
     WHERE story.id  = OLD.object_id
       AND member.id = OLD.member__id
       AND story.desk__id = desk.id;
     RETURN OLD;
END;
$$;

-- split

CREATE TRIGGER unset_member_story_desk_id
  BEFORE DELETE ON story_member
  FOR EACH ROW EXECUTE PROCEDURE unset_member_story_desk_id();

-- split

/****************************************************************************/
-- Add triggers for media desk memberships.
CREATE OR REPLACE FUNCTION desk_has_media(
) RETURNS TRIGGER LANGUAGE PLPGSQL AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        IF NEW.desk__id = OLD.desk__id THEN RETURN NEW; END IF;
    END IF;
    IF NEW.desk__id > 0 THEN
        IF EXISTS (
            SELECT media_member.object_id
              FROM desk
              JOIN member       ON member.grp__id = desk.asset_grp
              JOIN media_member ON media_member.member__id = member.id
             WHERE desk.id                = NEW.desk__id
               AND media_member.object_id = NEW.id
        ) THEN RETURN NEW; END IF;
        RAISE EXCEPTION 'Desk % should have media % in its group but does not',
            NEW.desk__id, NEW.id;
    ELSIF TG_OP = 'UPDATE' THEN
        IF NOT EXISTS (
            SELECT media_member.object_id
              FROM desk
              JOIN member       ON member.grp__id = desk.asset_grp
              JOIN media_member ON media_member.member__id = member.id
             WHERE desk.id                = OLD.desk__id
               AND media_member.object_id = NEW.id
        ) THEN RETURN NEW; END IF;
        RAISE EXCEPTION 'Desk % should not have media % in its group but does',
            OLD.desk__id, NEW.id;
    ELSE
        RETURN NEW;
    END IF;
END;
$$;

-- split

CREATE CONSTRAINT TRIGGER media_is_on_desk
 AFTER INSERT OR UPDATE ON media
DEFERRABLE INITIALLY DEFERRED
 FOR EACH ROW EXECUTE PROCEDURE desk_has_media();

-- split

CREATE OR REPLACE FUNCTION desk_hasnt_media(
) RETURNS TRIGGER LANGUAGE PLPGSQL AS $$
BEGIN
    IF NOT EXISTS (
        SELECT media_member.object_id
          FROM desk
          JOIN member       ON member.grp__id = desk.asset_grp
          JOIN media_member ON media_member.member__id = member.id
         WHERE desk.id                = OLD.desk__id
           AND media_member.object_id = OLD.id
    ) THEN RETURN NEW; END IF;
    RAISE EXCEPTION 'Desk % should not have media % in its group but does',
        NEW.desk__id, NEW.id;
END;
$$;

-- split

CREATE CONSTRAINT TRIGGER media_not_on_desk
 AFTER DELETE ON media
DEFERRABLE INITIALLY DEFERRED
 FOR EACH ROW EXECUTE PROCEDURE desk_hasnt_media();

-- split

CREATE OR REPLACE FUNCTION set_member_media_desk_id(
) RETURNS TRIGGER LANGUAGE PLPGSQL AS $$
BEGIN
    UPDATE media
       SET desk__id = desk.id
      FROM member
      JOIN desk ON member.grp__id = desk.asset_grp
     WHERE media.id  = NEW.object_id
       AND member.id = NEW.member__id;
     RETURN NEW;
END;
$$;

-- split

CREATE TRIGGER set_member_media_desk_id
  AFTER INSERT OR UPDATE ON media_member
  FOR EACH ROW EXECUTE PROCEDURE set_member_media_desk_id();

CREATE OR REPLACE FUNCTION unset_member_media_desk_id(
) RETURNS TRIGGER LANGUAGE PLPGSQL AS $$
BEGIN
    UPDATE media
       SET desk__id = 0
      FROM member
      JOIN desk ON member.grp__id = desk.asset_grp
     WHERE media.id  = OLD.object_id
       AND member.id = OLD.member__id
       AND media.desk__id = desk.id;
     RETURN OLD;
END;
$$;

-- split

CREATE TRIGGER unset_member_media_desk_id
  BEFORE DELETE ON media_member
  FOR EACH ROW EXECUTE PROCEDURE unset_member_media_desk_id();

-- split

/****************************************************************************/
-- Add triggers for template desk memberships.
CREATE OR REPLACE FUNCTION desk_has_template(
) RETURNS TRIGGER LANGUAGE PLPGSQL AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        IF NEW.desk__id = OLD.desk__id THEN RETURN NEW; END IF;
    END IF;
    IF NEW.desk__id > 0 THEN
        IF EXISTS (
            SELECT template_member.object_id
              FROM desk
              JOIN member          ON member.grp__id = desk.asset_grp
              JOIN template_member ON template_member.member__id = member.id
             WHERE desk.id                = NEW.desk__id
               AND template_member.object_id = NEW.id
        ) THEN RETURN NEW; END IF;
        RAISE EXCEPTION 'Desk % should have template % in its group but does not',
            NEW.desk__id, NEW.id;
    ELSIF TG_OP = 'UPDATE' THEN
        IF NOT EXISTS (
            SELECT template_member.object_id
              FROM desk
              JOIN member          ON member.grp__id = desk.asset_grp
              JOIN template_member ON template_member.member__id = member.id
             WHERE desk.id                = OLD.desk__id
               AND template_member.object_id = NEW.id
        ) THEN RETURN NEW; END IF;
        RAISE EXCEPTION 'Desk % should not have template % in its group but does',
            OLD.desk__id, NEW.id;
    ELSE
        RETURN NEW;
    END IF;
END;
$$;

-- split

CREATE CONSTRAINT TRIGGER template_is_on_desk
 AFTER INSERT OR UPDATE ON template
DEFERRABLE INITIALLY DEFERRED
 FOR EACH ROW EXECUTE PROCEDURE desk_has_template();

-- split

CREATE OR REPLACE FUNCTION desk_hasnt_template(
) RETURNS TRIGGER LANGUAGE PLPGSQL AS $$
BEGIN
    IF NOT EXISTS (
        SELECT template_member.object_id
          FROM desk
          JOIN member       ON member.grp__id = desk.asset_grp
          JOIN template_member ON template_member.member__id = member.id
         WHERE desk.id                = OLD.desk__id
           AND template_member.object_id = OLD.id
    ) THEN RETURN NEW; END IF;
    RAISE EXCEPTION 'Desk % should not have template % in its group but does',
        NEW.desk__id, NEW.id;
END;
$$;

-- split

CREATE CONSTRAINT TRIGGER template_not_on_desk
 AFTER DELETE ON template
DEFERRABLE INITIALLY DEFERRED
 FOR EACH ROW EXECUTE PROCEDURE desk_hasnt_template();

-- split

CREATE OR REPLACE FUNCTION set_member_template_desk_id(
) RETURNS TRIGGER LANGUAGE PLPGSQL AS $$
BEGIN
    UPDATE template
       SET desk__id = desk.id
      FROM member
      JOIN desk ON member.grp__id = desk.asset_grp
     WHERE template.id  = NEW.object_id
       AND member.id = NEW.member__id;
     RETURN NEW;
END;
$$;

-- split

CREATE TRIGGER set_member_template_desk_id
  AFTER INSERT OR UPDATE ON template_member
  FOR EACH ROW EXECUTE PROCEDURE set_member_template_desk_id();

CREATE OR REPLACE FUNCTION unset_member_template_desk_id(
) RETURNS TRIGGER LANGUAGE PLPGSQL AS $$
BEGIN
    UPDATE template
       SET desk__id = 0
      FROM member
      JOIN desk ON member.grp__id = desk.asset_grp
     WHERE template.id  = OLD.object_id
       AND member.id = OLD.member__id
       AND template.desk__id = desk.id;
     RETURN OLD;
END;
$$;

-- split

CREATE TRIGGER unset_member_template_desk_id
  BEFORE DELETE ON template_member
  FOR EACH ROW EXECUTE PROCEDURE unset_member_template_desk_id();
