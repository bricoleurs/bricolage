-- Project: Bricolage
-- VERSION: $LastChangedRevision$
--
-- $LastChangedDate: 2005-10-10 03:15:55 -0400 (Mon, 10 Oct 2005) $
--
-- Description: The table that holds the registered Input Channels.
--              This maps to the Bric::Biz::InputChannel Class.
--
--

-- -----------------------------------------------------------------------------
-- Sequences

-- Unique IDs for the input_channel table
CREATE SEQUENCE seq_input_channel START 1024;
CREATE SEQUENCE seq_input_channel_member START 1024;

-- -----------------------------------------------------------------------------
-- Table input_channel
--
-- Description: Holds info on the various input channels and is referenced
--              by templates and elements
--
--

CREATE TABLE input_channel (
    id               INTEGER            NOT NULL
                                    DEFAULT NEXTVAL('seq_input_channel'),
    name             VARCHAR(64)    NOT NULL,
    description      VARCHAR(256),
    site__id         INTEGER        NOT NULL,
    active           BOOLEAN        NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_input_channel__id PRIMARY KEY (id)
);


--
-- TABLE: input_channel_member
--

CREATE TABLE input_channel_member (
    id          INTEGER  NOT NULL
                         DEFAULT NEXTVAL('seq_input_channel_member'),
    object_id   INTEGER  NOT NULL,
    member__id  INTEGER  NOT NULL,
    CONSTRAINT pk_input_channel_member__id PRIMARY KEY (id)
);

-- 
-- INDEXES.
--
CREATE UNIQUE INDEX udx_input_channel__name_site
ON input_channel(lower_text_num(name, site__id));

CREATE INDEX fkx_site__input_channel ON input_channel(site__id);
CREATE INDEX fkx_input_channel__ic_member ON input_channel_member(object_id);
CREATE INDEX fkx_member__ic_member ON input_channel_member(member__id);

