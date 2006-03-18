CREATE TABLE profile_comp (
    id                 SERIAL,
    end_time           TIMESTAMP  NOT NULL,
    duration           INTERVAL   NOT NULL,
    story_element_id   INTEGER    NOT NULL,  -- (formerly story_container_tile)
    comp_path          VARCHAR(255),
    output_channel_id  INTEGER    NOT NULL,
    mode               INTEGER,    -- 1 = publish, 2 = preview, 3 = syntax
    CONSTRAINT pk_profile_comp__id PRIMARY KEY (id)
);
