/* These queries update the database to allow Output Channels to include the
 * templates of other output channels if they can't be found in the current
 * ouput channel. This feature is new to 1.2.0.
*/

--
-- SEQUENCE: seq_output_channel_include
--

CREATE SEQUENCE seq_output_channel_include START 1024;


--
-- TABLE: output_channel_include
--

CREATE TABLE output_channel_include (
    id          NUMERIC(10,0)  NOT NULL
                               DEFAULT NEXTVAL('seq_output_channel_include'),
    output_channel__id   NUMERIC(10,0)  NOT NULL,
    include_oc_id              NUMERIC(10,0)  NOT NULL
                               CONSTRAINT ck_oc_include__include_oc_id
                                 CHECK (include_oc_id <> output_channel__id),
    CONSTRAINT pk_output_channel_include__id PRIMARY KEY (id)
);

--
-- INDICES: output_channel_include
--

CREATE INDEX fkx_output_channel__oc_include ON output_channel_include(output_channel__id);
CREATE INDEX fkx_oc__oc_include_inc ON output_channel_include(include_oc_id);
CREATE UNIQUE INDEX udx_output_channel_include ON output_channel_include(output_channel__id, include_oc_id);
--
-- FKs: output_channel_include
--

ALTER TABLE    output_channel_include
ADD CONSTRAINT fk_output_channel__oc_include FOREIGN KEY (output_channel__id)
REFERENCES     output_channel(id) ON DELETE CASCADE;

ALTER TABLE    output_channel_include
ADD CONSTRAINT fk_oc__oc_include_inc FOREIGN KEY (include_oc_id)
REFERENCES     output_channel(id) ON DELETE CASCADE;
