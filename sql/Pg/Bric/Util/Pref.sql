--
-- Project: Bricolage API
--
-- Author: David Wheeler <david@justatheory.com>


--
-- SEQUENCES
--

CREATE SEQUENCE seq_pref START 1024;
CREATE SEQUENCE seq_usr_pref START 1024;
CREATE SEQUENCE seq_pref_member START 1024;



-- 
-- TABLE: pref
--        Global preferences.

CREATE TABLE pref (
    id           INTEGER         NOT NULL
                                 DEFAULT NEXTVAL('seq_pref'),
    name         VARCHAR(64)     NOT NULL,
    description  VARCHAR(256),
    value        VARCHAR(256),
    def          VARCHAR(256),
    manual         BOOLEAN         NOT NULL DEFAULT FALSE,
    opt_type     VARCHAR(16)     NOT NULL,
    can_be_overridden  BOOLEAN   NOT NULL DEFAULT FALSE,
    CONSTRAINT pk_pref__id PRIMARY KEY (id)
);

-- 
-- TABLE: usr_pref
--        Preferences overridden by a specific usr.

CREATE TABLE usr_pref (
    id           INTEGER         NOT NULL
                                 DEFAULT NEXTVAL('seq_usr_pref'),
    pref__id     INTEGER         NOT NULL,
    usr__id      INTEGER         NOT NULL,
    value        VARCHAR(256)    NOT NULL,
    CONSTRAINT pk_usr_pref__pref__id__value PRIMARY KEY (id)
);

-- 
-- TABLE: pref
--        Preference options.

CREATE TABLE pref_opt (
    pref__id     INTEGER         NOT NULL,
    value        VARCHAR(256)    NOT NULL,
    description  VARCHAR(256),
    CONSTRAINT pk_pref_opt__pref__id__value PRIMARY KEY (pref__id, value)
);


--
-- TABLE: pref_member
--

CREATE TABLE pref_member (
    id          INTEGER        NOT NULL
                               DEFAULT NEXTVAL('seq_pref_member'),
    object_id   INTEGER        NOT NULL,
    member__id  INTEGER        NOT NULL,
    CONSTRAINT pk_pref_member__id PRIMARY KEY (id)
);



-- 
-- INDEXES.
--

CREATE UNIQUE INDEX udx_pref__name ON pref(LOWER(name));
CREATE UNIQUE INDEX udx_usr_pref__pref__id__usr__id ON usr_pref(pref__id, usr__id);
CREATE INDEX idx_usr_pref__usr__id ON usr_pref(usr__id);
CREATE INDEX fkx_pref__pref__opt ON pref_opt(pref__id);
CREATE INDEX fkx_pref__pref_member ON pref_member(object_id);
CREATE INDEX fkx_member__pref_member ON pref_member(member__id);



