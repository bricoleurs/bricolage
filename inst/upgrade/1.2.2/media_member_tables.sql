CREATE SEQUENCE seq_audio_member START  1024;

-- -----------------------------------------------------------------------------
-- Table: audio_member
--
-- Description: The link between audio objects and member objects
--

CREATE TABLE audio_member (
    id          NUMERIC(10,0)  NOT NULL
                               DEFAULT NEXTVAL('seq_audio_member'),
    object_id   NUMERIC(10,0)  NOT NULL,
    member__id  NUMERIC(10,0)  NOT NULL,
    CONSTRAINT pk_audio_member__id PRIMARY KEY (id)
);

-- audio_member.
CREATE INDEX fkx_audio__audio_member ON audio_member(object_id);
CREATE INDEX fkx_member__audio_member ON audio_member(member__id);


CREATE SEQUENCE seq_video_member START  1024;

-- -----------------------------------------------------------------------------
-- Table: video_member
--
-- Description: The link between video objects and member objects
--

CREATE TABLE video_member (
    id          NUMERIC(10,0)  NOT NULL
                               DEFAULT NEXTVAL('seq_video_member'),
    object_id   NUMERIC(10,0)  NOT NULL,
    member__id  NUMERIC(10,0)  NOT NULL,
    CONSTRAINT pk_video_member__id PRIMARY KEY (id)
);

-- video_member.
CREATE INDEX fkx_video__video_member ON video_member(object_id);
CREATE INDEX fkx_member__video_member ON video_member(member__id);

