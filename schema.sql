--
-- PostgreSQL database dump
--

-- Dumped from database version 14.3
-- Dumped by pg_dump version 14.3

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: citext; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public;


--
-- Name: EXTENSION citext; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION citext IS 'data type for case-insensitive character strings';


--
-- Name: continent; Type: TYPE; Schema: public; Owner: pointercrate
--

CREATE TYPE public.continent AS ENUM (
    'Asia',
    'Europe',
    'Australia and Oceania',
    'Africa',
    'North America',
    'South America',
    'Central America'
);


ALTER TYPE public.continent OWNER TO pointercrate;

--
-- Name: email; Type: DOMAIN; Schema: public; Owner: pointercrate
--

CREATE DOMAIN public.email AS public.citext
	CONSTRAINT email_check CHECK ((VALUE OPERATOR(public.~) '^[a-zA-Z0-9.!#$%&''*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$'::public.citext));


ALTER DOMAIN public.email OWNER TO pointercrate;

--
-- Name: record_status; Type: TYPE; Schema: public; Owner: pointercrate
--

CREATE TYPE public.record_status AS ENUM (
    'APPROVED',
    'REJECTED',
    'SUBMITTED',
    'DELETED',
    'UNDER_CONSIDERATION'
);


ALTER TYPE public.record_status OWNER TO pointercrate;

--
-- Name: audit_creator_addition(); Type: FUNCTION; Schema: public; Owner: pointercrate
--

CREATE FUNCTION public.audit_creator_addition() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    BEGIN
        INSERT INTO creator_additions (userid, creator, demon)
            (SELECT id, NEW.creator, NEW.demon
            FROM active_user LIMIT 1);

        RETURN NEW;
    END;
$$;


ALTER FUNCTION public.audit_creator_addition() OWNER TO pointercrate;

--
-- Name: audit_creator_deletion(); Type: FUNCTION; Schema: public; Owner: pointercrate
--

CREATE FUNCTION public.audit_creator_deletion() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    BEGIN
        INSERT INTO creator_deletions (userid, creator, demon)
            (SELECT id, OLD.creator, OLD.demon
            FROM active_user LIMIT 1);

        RETURN NULL;
    END;
$$;


ALTER FUNCTION public.audit_creator_deletion() OWNER TO pointercrate;

--
-- Name: audit_demon_addition(); Type: FUNCTION; Schema: public; Owner: pointercrate
--

CREATE FUNCTION public.audit_demon_addition() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    BEGIN
        INSERT INTO demon_additions (userid, id) (SELECT id , NEW.id FROM active_user LIMIT 1);
        RETURN NEW;
    END;
$$;


ALTER FUNCTION public.audit_demon_addition() OWNER TO pointercrate;

--
-- Name: audit_demon_modification(); Type: FUNCTION; Schema: public; Owner: pointercrate
--

CREATE FUNCTION public.audit_demon_modification() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    name_change CITEXT;
    position_change SMALLINT;
    requirement_change SMALLINT;
    video_change VARCHAR(200);
    thumbnail_change TEXT;
    verifier_change INT;
    publisher_change INT;
BEGIN
    IF (OLD.name <> NEW.name) THEN
        name_change = OLD.name;
    END IF;

    IF (OLD.position <> NEW.position) THEN
        position_change = OLD.position;
    END IF;

    IF (OLD.requirement <> NEW.requirement) THEN
        requirement_change = OLD.requirement;
    END IF;

    IF (OLD.video <> NEW.video) THEN
        video_change = OLD.video;
    END IF;

    IF (OLD.thumbnail <> NEW.thumbnail) THEN
        thumbnail_change = OLD.thumbnail;
    END IF;

    IF (OLD.verifier <> NEW.verifier) THEN
        verifier_change = OLD.verifier;
    END IF;

    IF (OLD.publisher <> NEW.publisher) THEN
        publisher_change = OLD.publisher;
    END IF;

    INSERT INTO demon_modifications (userid, name, position, requirement, video, verifier, publisher, thumbnail, id)
        (SELECT id, name_change, position_change, requirement_change, video_change, verifier_change, publisher_change, thumbnail_change, NEW.id
         FROM active_user LIMIT 1);

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.audit_demon_modification() OWNER TO pointercrate;

--
-- Name: audit_level_comment_addition(); Type: FUNCTION; Schema: public; Owner: pointercrate
--

CREATE FUNCTION public.audit_level_comment_addition() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO level_comment_additions (userid, id) (SELECT id, NEW.id FROM active_user LIMIT 1);
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.audit_level_comment_addition() OWNER TO pointercrate;

--
-- Name: audit_level_comment_deletion(); Type: FUNCTION; Schema: public; Owner: pointercrate
--

CREATE FUNCTION public.audit_level_comment_deletion() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO level_comment_modifications (userid, id, content, visible, progress)
        (SELECT id, OLD.id, OLD.progress, OLD.content, OLD.visible, OLD.progress
         FROM active_user LIMIT 1);

    INSERT INTO level_comment_deletions (userid, id)
        (SELECT id, OLD.id FROM active_user LIMIT 1);

    RETURN NULL;
END;
$$;


ALTER FUNCTION public.audit_level_comment_deletion() OWNER TO pointercrate;

--
-- Name: audit_level_comment_modification(); Type: FUNCTION; Schema: public; Owner: pointercrate
--

CREATE FUNCTION public.audit_level_comment_modification() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    progress_change SMALLINT;
    content_change TEXT;
    visible_change BOOLEAN;
BEGIN
    if (OLD.progress <> NEW.progress) THEN
        progress_change = OLD.progress;
    END IF;

    IF (OLD.content <> NEW.content) THEN
        content_change = OLD.content;
    END IF;

    IF (OLD.visible <> NEW.visible) THEN
        visible_change = OLD.visible;
    END IF;

    INSERT INTO level_comment_modifications (userid, id, content, visible, progress)
        (SELECT id, NEW.id, content_change, visible_change, progress_change
         FROM active_user LIMIT 1);

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.audit_level_comment_modification() OWNER TO pointercrate;

--
-- Name: audit_player_addition(); Type: FUNCTION; Schema: public; Owner: pointercrate
--

CREATE FUNCTION public.audit_player_addition() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    BEGIN
        INSERT INTO player_additions(userid, id)
        (SELECT id, NEW.id FROM active_user LIMIT 1);

        RETURN NEW;
    END;
$$;


ALTER FUNCTION public.audit_player_addition() OWNER TO pointercrate;

--
-- Name: audit_player_deletion(); Type: FUNCTION; Schema: public; Owner: pointercrate
--

CREATE FUNCTION public.audit_player_deletion() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO player_modifications (userid, id, name, banned, nationality, subdivision)
        (SELECT id, OLD.id, OLD.name, OLD.banned, OLD.nationality, OLD.subdivision
         FROM active_user LIMIT 1);

    INSERT INTO player_deletions (userid, id)
        (SELECT id, OLD.id FROM active_user LIMIT 1);

    RETURN NULL;
END;
$$;


ALTER FUNCTION public.audit_player_deletion() OWNER TO pointercrate;

--
-- Name: audit_player_modification(); Type: FUNCTION; Schema: public; Owner: pointercrate
--

CREATE FUNCTION public.audit_player_modification() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    name_change CITEXT;
    banned_change BOOLEAN;
    nationality_change VARCHAR(2);
    subdivision_change VARCHAR(3);
BEGIN
    IF (OLD.name <> NEW.name) THEN
        name_change = OLD.name;
    END IF;

    IF (OLD.banned <> NEW.banned) THEN
        banned_change = OLD.banned;
    END IF;

    IF (OLD.nationality <> NEW.nationality) THEN
        nationality_change = OLD.nationality;
    end if;

    IF (OLD.subdivision <> NEW.subdivision) THEN
        subdivision_change = OLD.subdivision;
    end if;

    INSERT INTO player_modifications (userid, id, name, banned, nationality, subdivision)
        (SELECT id, NEW.id, name_change, banned_change, nationality_change, subdivision_change FROM active_user LIMIT 1);

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.audit_player_modification() OWNER TO pointercrate;

--
-- Name: audit_record_addition(); Type: FUNCTION; Schema: public; Owner: pointercrate
--

CREATE FUNCTION public.audit_record_addition() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    BEGIN
        INSERT INTO record_additions (userid, id) (SELECT id, NEW.id FROM active_user LIMIT 1);
        RETURN NEW;
    END;
$$;


ALTER FUNCTION public.audit_record_addition() OWNER TO pointercrate;

--
-- Name: audit_record_deletion(); Type: FUNCTION; Schema: public; Owner: pointercrate
--

CREATE FUNCTION public.audit_record_deletion() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    BEGIN
        INSERT INTO record_modifications (userid, id, progress, video, status_, player, demon)
            (SELECT id, OLD.id, OLD.progress, OLD.video, OLD.status_, OLD.player, OLD.demon
            FROM active_user LIMIT 1);

        INSERT INTO record_deletions (userid, id)
            (SELECT id, OLD.id FROM active_user LIMIT 1);

        RETURN NULL;
    END;
$$;


ALTER FUNCTION public.audit_record_deletion() OWNER TO pointercrate;

--
-- Name: audit_record_modification(); Type: FUNCTION; Schema: public; Owner: pointercrate
--

CREATE FUNCTION public.audit_record_modification() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    DECLARE
        progress_change SMALLINT;
        video_change VARCHAR(200);
        status_change RECORD_STATUS;
        player_change INT;
        demon_change INTEGER;
    BEGIN
        if (OLD.progress <> NEW.progress) THEN
            progress_change = OLD.progress;
        END IF;

        IF (OLD.video <> NEW.video) THEN
            video_change = OLD.video;
        END IF;

        IF (OLD.status_ <> NEW.status_) THEN
            status_change = OLD.status_;
        END IF;

        IF (OLD.player <> NEW.player) THEN
            player_change = OLD.player;
        END IF;

        IF (OLD.demon <> NEW.demon) THEN
            demon_change = OLD.demon;
        END IF;

        INSERT INTO record_modifications (userid, id, progress, video, status_, player, demon)
            (SELECT id, NEW.id, progress_change, video_change, status_change, player_change, demon_change
            FROM active_user LIMIT 1);

        RETURN NEW;
    END;
$$;


ALTER FUNCTION public.audit_record_modification() OWNER TO pointercrate;

--
-- Name: audit_record_notes_addition(); Type: FUNCTION; Schema: public; Owner: pointercrate
--

CREATE FUNCTION public.audit_record_notes_addition() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    BEGIN
        INSERT INTO record_notes_additions (userid, id) (SELECT id, NEW.id FROM active_user LIMIT 1);
        RETURN NEW;
    END;
$$;


ALTER FUNCTION public.audit_record_notes_addition() OWNER TO pointercrate;

--
-- Name: audit_record_notes_deletion(); Type: FUNCTION; Schema: public; Owner: pointercrate
--

CREATE FUNCTION public.audit_record_notes_deletion() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    BEGIN
        INSERT INTO record_notes_modifications (userid, id, record, content)
            (SELECT id, OLD.id, OLD.record, OLD.content FROM active_user LIMIT 1);

        INSERT INTO record_notes_deletion (userid, id)
            (SELECT id, OLD.id FROM active_user LIMIT 1);

        RETURN NEW;
    END
$$;


ALTER FUNCTION public.audit_record_notes_deletion() OWNER TO pointercrate;

--
-- Name: audit_record_notes_modification(); Type: FUNCTION; Schema: public; Owner: pointercrate
--

CREATE FUNCTION public.audit_record_notes_modification() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    DECLARE
        record_change INTEGER;
        content_change TEXT;
    BEGIN
        IF (OLD.record <> NEW.record) THEN
            record_change = OLD.record;
        END IF;

        IF (OLD.content <> NEW.content) THEN
            content_change = OLD.content;
        END IF;

        INSERT INTO record_notes_modifications (userid, id, record, content)
            (SELECT id, OLD.id, record_change, content_change FROM active_user LIMIT 1);

        RETURN NEW;
    END;
$$;


ALTER FUNCTION public.audit_record_notes_modification() OWNER TO pointercrate;

--
-- Name: audit_submitter_modification(); Type: FUNCTION; Schema: public; Owner: pointercrate
--

CREATE FUNCTION public.audit_submitter_modification() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    DECLARE
        banned_change BOOLEAN;
    BEGIN
        IF (OLD.banned <> NEW.banned) THEN
            banned_change = OLD.banned;
        END IF;

        INSERT INTO submitter_modifications (userid, submitter, banned)
        (SELECT id, NEW.submitter_id, banned_change FROM active_user LIMIT 1);

        RETURN NEW;
    END;
$$;


ALTER FUNCTION public.audit_submitter_modification() OWNER TO pointercrate;

--
-- Name: audit_user_addition(); Type: FUNCTION; Schema: public; Owner: pointercrate
--

CREATE FUNCTION public.audit_user_addition() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    BEGIN
        -- cannot be logged in during registration
        INSERT INTO user_additions (userid, id) VALUES (0, NEW.member_id);

        RETURN NEW;
    END;
$$;


ALTER FUNCTION public.audit_user_addition() OWNER TO pointercrate;

--
-- Name: audit_user_deletion(); Type: FUNCTION; Schema: public; Owner: pointercrate
--

CREATE FUNCTION public.audit_user_deletion() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    BEGIN
        INSERT INTO user_modifications (userid, id, display_name, youtube_channel, permissions)
            (SELECT id, OLD.member_id, OLD.display_name, OLD.youtube_channel, OLD.permissions
            FROM active_user LIMIT 1);

        INSERT INTO user_deletions (userid, id)
            (SELECT id, OLD.member_id FROM active_user LIMIT 1);

        RETURN NULL;
    END;
$$;


ALTER FUNCTION public.audit_user_deletion() OWNER TO pointercrate;

--
-- Name: audit_user_modification(); Type: FUNCTION; Schema: public; Owner: pointercrate
--

CREATE FUNCTION public.audit_user_modification() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    display_name_change CITEXT;
    youtube_channel_change VARCHAR(200);
    permissions_change BIT(16);
BEGIN
    IF (OLD.display_name <> NEW.display_name) THEN
        display_name_change = OLD.display_name;
    END IF;

    IF (OLD.youtube_channel <> NEW.youtube_channel) THEN
        youtube_channel_change = OLD.youtube_channel;
    END IF;

    IF (OLD.permissions <> NEW.permissions) THEN
        permissions_change = OLD.permissions;
    END IF;

    INSERT INTO user_modifications (userid, id, display_name, youtube_channel, permissions)
        (SELECT id, NEW.member_id, display_name_change, youtube_channel_change, permissions_change FROM active_user LIMIT 1);

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.audit_user_modification() OWNER TO pointercrate;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: records; Type: TABLE; Schema: public; Owner: pointercrate
--

CREATE TABLE public.records (
    id integer NOT NULL,
    progress smallint NOT NULL,
    video character varying(200),
    status_ public.record_status NOT NULL,
    player integer NOT NULL,
    submitter integer NOT NULL,
    demon integer NOT NULL,
    CONSTRAINT records_progress_check CHECK (((progress >= 0) AND (progress <= 100)))
);


ALTER TABLE public.records OWNER TO pointercrate;

--
-- Name: best_records_in(character varying); Type: FUNCTION; Schema: public; Owner: pointercrate
--

CREATE FUNCTION public.best_records_in(country character varying) RETURNS TABLE("like" public.records)
    LANGUAGE sql
    AS $$
    WITH grp AS (
        SELECT records.*,
               RANK() OVER (PARTITION BY demon ORDER BY demon, progress DESC) AS rk
        FROM records
        INNER JOIN players
        ON players.id = player
        WHERE status_='APPROVED' AND players.nationality = country
    )
    SELECT id, progress, video, status_, player, submitter, demon
    FROM grp
    WHERE rk = 1;
$$;


ALTER FUNCTION public.best_records_in(country character varying) OWNER TO pointercrate;

--
-- Name: best_records_local(character varying, character varying); Type: FUNCTION; Schema: public; Owner: pointercrate
--

CREATE FUNCTION public.best_records_local(country character varying, the_subdivision character varying) RETURNS TABLE("like" public.records)
    LANGUAGE sql
    AS $$
WITH grp AS (
    SELECT records.*,
           RANK() OVER (PARTITION BY demon ORDER BY demon, progress DESC) AS rk
    FROM records
        INNER JOIN players
            ON players.id = player
    WHERE status_='APPROVED' AND players.nationality = country AND players.subdivision = the_subdivision
)
SELECT id, progress, video, status_, player, submitter, demon
FROM grp
WHERE rk = 1;
$$;


ALTER FUNCTION public.best_records_local(country character varying, the_subdivision character varying) OWNER TO pointercrate;

--
-- Name: diesel_manage_updated_at(regclass); Type: FUNCTION; Schema: public; Owner: pointercrate
--

CREATE FUNCTION public.diesel_manage_updated_at(_tbl regclass) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    EXECUTE format('CREATE TRIGGER set_updated_at BEFORE UPDATE ON %s
                    FOR EACH ROW EXECUTE PROCEDURE diesel_set_updated_at()', _tbl);
END;
$$;


ALTER FUNCTION public.diesel_manage_updated_at(_tbl regclass) OWNER TO pointercrate;

--
-- Name: diesel_set_updated_at(); Type: FUNCTION; Schema: public; Owner: pointercrate
--

CREATE FUNCTION public.diesel_set_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF (
        NEW IS DISTINCT FROM OLD AND
        NEW.updated_at IS NOT DISTINCT FROM OLD.updated_at
    ) THEN
        NEW.updated_at := current_timestamp;
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.diesel_set_updated_at() OWNER TO pointercrate;

--
-- Name: list_at(timestamp without time zone); Type: FUNCTION; Schema: public; Owner: pointercrate
--

CREATE FUNCTION public.list_at(timestamp without time zone) RETURNS TABLE(name public.citext, position_ smallint, requirement smallint, video character varying, thumbnail text, verifier integer, publisher integer, id integer, level_id bigint, current_position smallint)
    LANGUAGE sql STABLE
    AS $_$
SELECT name, CASE WHEN t.position IS NULL THEN demons.position ELSE t.position END, requirement, video, thumbnail, verifier, publisher, demons.id, level_id, demons.position AS current_position
FROM demons
         LEFT OUTER JOIN (
    SELECT DISTINCT ON (id) id, position
    FROM demon_modifications
    WHERE time >= $1 AND position != -1
    ORDER BY id, time
) t
                         ON demons.id = t.id
WHERE NOT EXISTS (SELECT 1 FROM demon_additions WHERE demon_additions.id = demons.id AND time >= $1)
$_$;


ALTER FUNCTION public.list_at(timestamp without time zone) OWNER TO pointercrate;

--
-- Name: record_score(double precision, double precision, double precision, double precision); Type: FUNCTION; Schema: public; Owner: pointercrate
--

CREATE FUNCTION public.record_score(progress double precision, demon double precision, list_size double precision, requirement double precision) RETURNS double precision
    LANGUAGE sql IMMUTABLE
    AS $$
SELECT CASE
           WHEN progress = 100 THEN
                   CASE
                       
                       WHEN 55 < demon AND demon <= 150 THEN
                            56.191 * EXP(LN(2) * ((54.147 - (demon + 3.2)) * LN(50.0)) / 99.0)
                       WHEN 35 < demon AND demon <= 55 THEN
                            212.61 * (EXP(LN(1.036) * (1 - demon))) + 25.071
                       WHEN 20 < demon AND demon <= 35 THEN
                            (250 - 83.389) * (EXP(LN(1.0099685) * (2 - demon))) - 31.152
                       WHEN demon <= 20 THEN
                            (250 - 100.39) * (EXP(LN(1.168) * (1 - demon))) + 100.39
                   
                   END
                                                                 
           WHEN progress < requirement THEN
               0.0
           ELSE
                       CASE
                       
                       WHEN 55 < demon AND demon <= 150 THEN
                            56.191 * EXP(LN(2) * ((54.147 - (demon + 3.2)) * LN(50.0)) / 99.0) * (EXP(LN(5) * (progress - requirement) / (100 - requirement))) / 10
                       WHEN 35 < demon AND demon <= 55 THEN
                            (212.61 * (EXP(LN(1.036) * (1 - demon))) + 25.071) * (EXP(LN(5) * (progress - requirement) / (100 - requirement))) / 10
                       WHEN 20 < demon AND demon <= 35 THEN
                            ((250 - 83.389) * (EXP(LN(1.0099685) * (2 - demon))) - 31.152) * (EXP(LN(5) * (progress - requirement) / (100 - requirement))) / 10
                       WHEN demon <= 20 THEN
                            ((250 - 100.39) * (EXP(LN(1.168) * (1 - demon))) + 100.39) * (EXP(LN(5) * (progress - requirement) / (100 - requirement))) / 10
                   
                       END
           END;
$$;


ALTER FUNCTION public.record_score(progress double precision, demon double precision, list_size double precision, requirement double precision) OWNER TO pointercrate;

--
-- Name: set_initial_thumbnail(); Type: FUNCTION; Schema: public; Owner: pointercrate
--

CREATE FUNCTION public.set_initial_thumbnail() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.video IS NOT NULL AND NOT EXISTS(SELECT 1 FROM players WHERE players.id=NEW.verifier AND players.link_banned) THEN
        NEW.thumbnail := 'https://i.ytimg.com/vi/' || SUBSTRING(NEW.video FROM '%v=#"___________#"%' FOR '#') || '/mqdefault.jpg';
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.set_initial_thumbnail() OWNER TO pointercrate;

--
-- Name: subdivision_ranking_of(character varying); Type: FUNCTION; Schema: public; Owner: pointercrate
--

CREATE FUNCTION public.subdivision_ranking_of(country character varying) RETURNS TABLE(rank bigint, score double precision, subdivision_code character varying, name text)
    LANGUAGE sql
    AS $$
    SELECT RANK() OVER(ORDER BY scores.total_score DESC) AS rank,
           scores.total_score AS score,
           iso_code,
           name
    FROM (
        SELECT iso_code, name,
                SUM(record_score(pseudo_records.progress::FLOAT, pseudo_records.position::FLOAT,
                                 100::FLOAT, pseudo_records.requirement)) as total_score
         FROM (
                  select distinct on (iso_code, demon)
                      iso_code,
                      subdivisions.name,
                      progress,
                      position,
                      CASE WHEN demons.position > 75 THEN 100 ELSE requirement END AS requirement
                  from (
                           select demon, player, progress
                           from records
                           where status_='APPROVED'

                           union

                           select id, verifier, 100
                           from demons
                       ) records
                           inner join demons
                                      on demons.id = records.demon
                           inner join players
                                      on players.id=records.player
                           inner join subdivisions
                                      on (iso_code=players.subdivision and players.nationality = nation)
                  where position <= 150 and not players.banned and nation = country
                  order by iso_code, demon, progress desc
              ) AS pseudo_records
         GROUP BY iso_code, name
     ) scores;
    $$;


ALTER FUNCTION public.subdivision_ranking_of(country character varying) OWNER TO pointercrate;

--
-- Name: __diesel_schema_migrations; Type: TABLE; Schema: public; Owner: pointercrate
--

CREATE TABLE public.__diesel_schema_migrations (
    version character varying(50) NOT NULL,
    run_on timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.__diesel_schema_migrations OWNER TO pointercrate;

--
-- Name: active_user; Type: TABLE; Schema: public; Owner: pointercrate
--

CREATE TABLE public.active_user (
    id integer NOT NULL
);


ALTER TABLE public.active_user OWNER TO pointercrate;

--
-- Name: audit_log2; Type: TABLE; Schema: public; Owner: pointercrate
--

CREATE TABLE public.audit_log2 (
    "time" timestamp without time zone DEFAULT (now() AT TIME ZONE 'utc'::text) NOT NULL,
    audit_id integer NOT NULL,
    userid integer NOT NULL
);


ALTER TABLE public.audit_log2 OWNER TO pointercrate;

--
-- Name: audit_log2_audit_id_seq; Type: SEQUENCE; Schema: public; Owner: pointercrate
--

CREATE SEQUENCE public.audit_log2_audit_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.audit_log2_audit_id_seq OWNER TO pointercrate;

--
-- Name: audit_log2_audit_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: pointercrate
--

ALTER SEQUENCE public.audit_log2_audit_id_seq OWNED BY public.audit_log2.audit_id;


--
-- Name: creator_additions; Type: TABLE; Schema: public; Owner: pointercrate
--

CREATE TABLE public.creator_additions (
    creator integer NOT NULL,
    demon integer NOT NULL
)
INHERITS (public.audit_log2);


ALTER TABLE public.creator_additions OWNER TO pointercrate;

--
-- Name: creator_deletions; Type: TABLE; Schema: public; Owner: pointercrate
--

CREATE TABLE public.creator_deletions (
    creator integer NOT NULL,
    demon integer NOT NULL
)
INHERITS (public.audit_log2);


ALTER TABLE public.creator_deletions OWNER TO pointercrate;

--
-- Name: creators; Type: TABLE; Schema: public; Owner: pointercrate
--

CREATE TABLE public.creators (
    creator integer NOT NULL,
    demon integer NOT NULL
);


ALTER TABLE public.creators OWNER TO pointercrate;

--
-- Name: demon_additions; Type: TABLE; Schema: public; Owner: pointercrate
--

CREATE TABLE public.demon_additions (
    id integer NOT NULL
)
INHERITS (public.audit_log2);


ALTER TABLE public.demon_additions OWNER TO pointercrate;

--
-- Name: demon_modifications; Type: TABLE; Schema: public; Owner: pointercrate
--

CREATE TABLE public.demon_modifications (
    name public.citext,
    "position" smallint,
    requirement smallint,
    video character varying(200),
    verifier integer,
    publisher integer,
    id integer NOT NULL,
    thumbnail text
)
INHERITS (public.audit_log2);


ALTER TABLE public.demon_modifications OWNER TO pointercrate;

--
-- Name: demons; Type: TABLE; Schema: public; Owner: pointercrate
--

CREATE TABLE public.demons (
    name public.citext NOT NULL,
    "position" smallint NOT NULL,
    requirement smallint NOT NULL,
    video character varying(200),
    verifier integer NOT NULL,
    publisher integer NOT NULL,
    id integer NOT NULL,
    level_id bigint,
    thumbnail text DEFAULT 'https://i.ytimg.com/vi/zebrafishes/mqdefault.jpg'::text NOT NULL,
    CONSTRAINT valid_record_req CHECK (((requirement >= 0) AND (requirement <= 100)))
);


ALTER TABLE public.demons OWNER TO pointercrate;

--
-- Name: demons_id_seq; Type: SEQUENCE; Schema: public; Owner: pointercrate
--

CREATE SEQUENCE public.demons_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.demons_id_seq OWNER TO pointercrate;

--
-- Name: demons_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: pointercrate
--

ALTER SEQUENCE public.demons_id_seq OWNED BY public.demons.id;


--
-- Name: download_lock; Type: TABLE; Schema: public; Owner: pointercrate
--

CREATE TABLE public.download_lock (
    level_id bigint NOT NULL
);


ALTER TABLE public.download_lock OWNER TO pointercrate;

--
-- Name: gj_creator; Type: TABLE; Schema: public; Owner: pointercrate
--

CREATE TABLE public.gj_creator (
    user_id bigint NOT NULL,
    name text NOT NULL,
    account_id bigint
);


ALTER TABLE public.gj_creator OWNER TO pointercrate;

--
-- Name: gj_creator_meta; Type: TABLE; Schema: public; Owner: pointercrate
--

CREATE TABLE public.gj_creator_meta (
    user_id bigint NOT NULL,
    cached_at timestamp without time zone NOT NULL,
    absent boolean DEFAULT false NOT NULL
);


ALTER TABLE public.gj_creator_meta OWNER TO pointercrate;

--
-- Name: gj_level; Type: TABLE; Schema: public; Owner: pointercrate
--

CREATE TABLE public.gj_level (
    level_id bigint NOT NULL,
    level_name text NOT NULL,
    description text,
    level_version integer NOT NULL,
    creator_id bigint NOT NULL,
    difficulty smallint NOT NULL,
    is_demon boolean NOT NULL,
    downloads integer NOT NULL,
    main_song smallint,
    gd_version smallint NOT NULL,
    likes integer NOT NULL,
    level_length smallint NOT NULL,
    stars smallint NOT NULL,
    featured integer NOT NULL,
    copy_of bigint,
    two_player boolean NOT NULL,
    custom_song_id bigint,
    coin_amount smallint NOT NULL,
    coins_verified boolean NOT NULL,
    stars_requested smallint,
    is_epic boolean NOT NULL,
    object_amount integer,
    index_46 text,
    index_47 text
);


ALTER TABLE public.gj_level OWNER TO pointercrate;

--
-- Name: gj_level_data; Type: TABLE; Schema: public; Owner: pointercrate
--

CREATE TABLE public.gj_level_data (
    level_id bigint NOT NULL,
    level_data bytea NOT NULL,
    level_password integer,
    time_since_upload text NOT NULL,
    time_since_update text NOT NULL,
    index_36 text
);


ALTER TABLE public.gj_level_data OWNER TO pointercrate;

--
-- Name: gj_level_data_meta; Type: TABLE; Schema: public; Owner: pointercrate
--

CREATE TABLE public.gj_level_data_meta (
    level_id bigint NOT NULL,
    cached_at timestamp without time zone NOT NULL,
    absent boolean DEFAULT false NOT NULL
);


ALTER TABLE public.gj_level_data_meta OWNER TO pointercrate;

--
-- Name: gj_level_meta; Type: TABLE; Schema: public; Owner: pointercrate
--

CREATE TABLE public.gj_level_meta (
    level_id bigint NOT NULL,
    cached_at timestamp without time zone NOT NULL,
    absent boolean DEFAULT false NOT NULL
);


ALTER TABLE public.gj_level_meta OWNER TO pointercrate;

--
-- Name: gj_level_request_meta; Type: TABLE; Schema: public; Owner: pointercrate
--

CREATE TABLE public.gj_level_request_meta (
    request_hash bigint NOT NULL,
    cached_at timestamp without time zone NOT NULL,
    absent boolean DEFAULT false NOT NULL
);


ALTER TABLE public.gj_level_request_meta OWNER TO pointercrate;

--
-- Name: gj_level_request_results; Type: TABLE; Schema: public; Owner: pointercrate
--

CREATE TABLE public.gj_level_request_results (
    level_id bigint NOT NULL,
    request_hash bigint NOT NULL
);


ALTER TABLE public.gj_level_request_results OWNER TO pointercrate;

--
-- Name: gj_newgrounds_song; Type: TABLE; Schema: public; Owner: pointercrate
--

CREATE TABLE public.gj_newgrounds_song (
    song_id bigint NOT NULL,
    song_name text NOT NULL,
    index_3 bigint NOT NULL,
    song_artist text NOT NULL,
    filesize double precision NOT NULL,
    index_6 text,
    index_7 text,
    index_8 text NOT NULL,
    song_link text NOT NULL
);


ALTER TABLE public.gj_newgrounds_song OWNER TO pointercrate;

--
-- Name: gj_newgrounds_song_meta; Type: TABLE; Schema: public; Owner: pointercrate
--

CREATE TABLE public.gj_newgrounds_song_meta (
    song_id bigint NOT NULL,
    cached_at timestamp without time zone NOT NULL,
    absent boolean DEFAULT false NOT NULL
);


ALTER TABLE public.gj_newgrounds_song_meta OWNER TO pointercrate;

--
-- Name: level_comment_additions; Type: TABLE; Schema: public; Owner: pointercrate
--

CREATE TABLE public.level_comment_additions (
    id integer NOT NULL
)
INHERITS (public.audit_log2);


ALTER TABLE public.level_comment_additions OWNER TO pointercrate;

--
-- Name: level_comment_deletions; Type: TABLE; Schema: public; Owner: pointercrate
--

CREATE TABLE public.level_comment_deletions (
    id integer NOT NULL
)
INHERITS (public.audit_log2);


ALTER TABLE public.level_comment_deletions OWNER TO pointercrate;

--
-- Name: level_comment_modifications; Type: TABLE; Schema: public; Owner: pointercrate
--

CREATE TABLE public.level_comment_modifications (
    id integer NOT NULL,
    content text,
    visible boolean,
    progress smallint
)
INHERITS (public.audit_log2);


ALTER TABLE public.level_comment_modifications OWNER TO pointercrate;

--
-- Name: level_comments; Type: TABLE; Schema: public; Owner: pointercrate
--

CREATE TABLE public.level_comments (
    id integer NOT NULL,
    author integer NOT NULL,
    content text NOT NULL,
    visible boolean DEFAULT false NOT NULL,
    progress smallint NOT NULL
);


ALTER TABLE public.level_comments OWNER TO pointercrate;

--
-- Name: level_comments_id_seq; Type: SEQUENCE; Schema: public; Owner: pointercrate
--

CREATE SEQUENCE public.level_comments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.level_comments_id_seq OWNER TO pointercrate;

--
-- Name: level_comments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: pointercrate
--

ALTER SEQUENCE public.level_comments_id_seq OWNED BY public.level_comments.id;


--
-- Name: members; Type: TABLE; Schema: public; Owner: pointercrate
--

CREATE TABLE public.members (
    member_id integer NOT NULL,
    name text NOT NULL,
    display_name text,
    youtube_channel character varying(200) DEFAULT NULL::character varying,
    password_hash text NOT NULL,
    permissions bit(16) DEFAULT '0000000000000000'::bit(16) NOT NULL,
    nationality character varying(2) DEFAULT NULL::character varying,
    email_address public.email
);


ALTER TABLE public.members OWNER TO pointercrate;

--
-- Name: members_member_id_seq; Type: SEQUENCE; Schema: public; Owner: pointercrate
--

CREATE SEQUENCE public.members_member_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.members_member_id_seq OWNER TO pointercrate;

--
-- Name: members_member_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: pointercrate
--

ALTER SEQUENCE public.members_member_id_seq OWNED BY public.members.member_id;


--
-- Name: nationalities; Type: TABLE; Schema: public; Owner: pointercrate
--

CREATE TABLE public.nationalities (
    iso_country_code character varying(2) NOT NULL,
    nation public.citext NOT NULL,
    continent public.continent NOT NULL,
    CONSTRAINT nationalities_iso_country_code_check CHECK ((length((iso_country_code)::text) = 2))
);


ALTER TABLE public.nationalities OWNER TO pointercrate;

--
-- Name: players; Type: TABLE; Schema: public; Owner: pointercrate
--

CREATE TABLE public.players (
    id integer NOT NULL,
    name public.citext NOT NULL,
    banned boolean DEFAULT false NOT NULL,
    nationality character varying(2) DEFAULT NULL::character varying,
    link_banned boolean DEFAULT false,
    subdivision character varying(3) DEFAULT NULL::character varying
);


ALTER TABLE public.players OWNER TO pointercrate;

--
-- Name: nations_with_score; Type: VIEW; Schema: public; Owner: pointercrate
--

CREATE VIEW public.nations_with_score AS
 SELECT rank() OVER (ORDER BY scores.total_score DESC) AS rank,
    scores.total_score AS score,
    nationalities.iso_country_code,
    nationalities.nation,
    nationalities.continent
   FROM (( SELECT pseudo_records.nationality,
            sum(public.record_score((pseudo_records.progress)::double precision, (pseudo_records."position")::double precision, (100)::double precision, (pseudo_records.requirement)::double precision)) AS total_score
           FROM ( SELECT DISTINCT ON (players.nationality, records.demon) players.nationality,
                    records.progress,
                    demons."position",
                        CASE
                            WHEN (demons."position" > 75) THEN 100
                            ELSE (demons.requirement)::integer
                        END AS requirement
                   FROM (((( SELECT records_1.demon,
                            records_1.player,
                            records_1.progress
                           FROM public.records records_1
                          WHERE (records_1.status_ = 'APPROVED'::public.record_status)
                        UNION
                         SELECT demons_1.id,
                            demons_1.verifier,
                            100
                           FROM public.demons demons_1) records
                     JOIN public.demons ON ((demons.id = records.demon)))
                     JOIN public.players ON ((players.id = records.player)))
                     JOIN public.nationalities nationalities_1 ON (((nationalities_1.iso_country_code)::text = (players.nationality)::text)))
                  WHERE ((demons."position" <= 150) AND (NOT players.banned))
                  ORDER BY players.nationality, records.demon, records.progress DESC) pseudo_records
          GROUP BY pseudo_records.nationality) scores
     JOIN public.nationalities ON (((nationalities.iso_country_code)::text = (scores.nationality)::text)));


ALTER TABLE public.nations_with_score OWNER TO pointercrate;

--
-- Name: player_additions; Type: TABLE; Schema: public; Owner: pointercrate
--

CREATE TABLE public.player_additions (
    id integer NOT NULL
)
INHERITS (public.audit_log2);


ALTER TABLE public.player_additions OWNER TO pointercrate;

--
-- Name: player_claims; Type: TABLE; Schema: public; Owner: pointercrate
--

CREATE TABLE public.player_claims (
    id integer NOT NULL,
    member_id integer NOT NULL,
    player_id integer NOT NULL,
    verified boolean DEFAULT false NOT NULL,
    lock_submissions boolean DEFAULT false NOT NULL
);


ALTER TABLE public.player_claims OWNER TO pointercrate;

--
-- Name: player_claims_id_seq; Type: SEQUENCE; Schema: public; Owner: pointercrate
--

CREATE SEQUENCE public.player_claims_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.player_claims_id_seq OWNER TO pointercrate;

--
-- Name: player_claims_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: pointercrate
--

ALTER SEQUENCE public.player_claims_id_seq OWNED BY public.player_claims.id;


--
-- Name: player_deletions; Type: TABLE; Schema: public; Owner: pointercrate
--

CREATE TABLE public.player_deletions (
    id integer NOT NULL
)
INHERITS (public.audit_log2);


ALTER TABLE public.player_deletions OWNER TO pointercrate;

--
-- Name: player_modifications; Type: TABLE; Schema: public; Owner: pointercrate
--

CREATE TABLE public.player_modifications (
    id integer NOT NULL,
    name public.citext,
    banned boolean,
    nationality character varying(2) DEFAULT NULL::character varying,
    subdivision character varying(3) DEFAULT NULL::character varying
)
INHERITS (public.audit_log2);


ALTER TABLE public.player_modifications OWNER TO pointercrate;

--
-- Name: players_id_seq; Type: SEQUENCE; Schema: public; Owner: pointercrate
--

CREATE SEQUENCE public.players_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.players_id_seq OWNER TO pointercrate;

--
-- Name: players_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: pointercrate
--

ALTER SEQUENCE public.players_id_seq OWNED BY public.players.id;


--
-- Name: players_with_score; Type: VIEW; Schema: public; Owner: pointercrate
--

CREATE VIEW public.players_with_score AS
 SELECT players.id,
    players.name,
    rank() OVER (ORDER BY scores.total_score DESC) AS rank,
        CASE
            WHEN (scores.total_score IS NULL) THEN (0.0)::double precision
            ELSE scores.total_score
        END AS score,
    row_number() OVER (ORDER BY scores.total_score DESC) AS index,
    nationalities.iso_country_code,
    nationalities.nation,
    players.subdivision,
    nationalities.continent
   FROM ((( SELECT pseudo_records.player,
            sum(public.record_score(pseudo_records.progress, pseudo_records."position", (100)::double precision, pseudo_records.requirement)) AS total_score
           FROM ( SELECT records.player,
                    records.progress,
                    demons."position",
                        CASE
                            WHEN (demons."position" > 75) THEN 100
                            ELSE (demons.requirement)::integer
                        END AS requirement
                   FROM (public.records
                     JOIN public.demons ON ((demons.id = records.demon)))
                  WHERE ((demons."position" <= 150) AND (records.status_ = 'APPROVED'::public.record_status) AND ((demons."position" <= 75) OR (records.progress = 100)))
                UNION
                 SELECT demons.verifier AS player,
                        CASE
                            WHEN (demons."position" > 150) THEN (0.0)::double precision
                            ELSE (100.0)::double precision
                        END AS progress,
                    demons."position",
                    (100.0)::double precision AS float8
                   FROM public.demons
                UNION
                 SELECT demons.publisher AS player,
                    (0.0)::double precision AS progress,
                    demons."position",
                    (100.0)::double precision AS float8
                   FROM public.demons
                UNION
                 SELECT creators.creator AS player,
                    (0.0)::double precision AS progress,
                    (1.0)::double precision AS "position",
                    (100.0)::double precision AS float8
                   FROM public.creators) pseudo_records
          GROUP BY pseudo_records.player) scores
     JOIN public.players ON ((scores.player = players.id)))
     LEFT JOIN public.nationalities ON (((players.nationality)::text = (nationalities.iso_country_code)::text)))
  WHERE ((NOT players.banned) AND (players.id <> 1534));


ALTER TABLE public.players_with_score OWNER TO pointercrate;

--
-- Name: record_additions; Type: TABLE; Schema: public; Owner: pointercrate
--

CREATE TABLE public.record_additions (
    id integer NOT NULL
)
INHERITS (public.audit_log2);


ALTER TABLE public.record_additions OWNER TO pointercrate;

--
-- Name: record_deletions; Type: TABLE; Schema: public; Owner: pointercrate
--

CREATE TABLE public.record_deletions (
    id integer NOT NULL
)
INHERITS (public.audit_log2);


ALTER TABLE public.record_deletions OWNER TO pointercrate;

--
-- Name: record_modifications; Type: TABLE; Schema: public; Owner: pointercrate
--

CREATE TABLE public.record_modifications (
    id integer NOT NULL,
    progress smallint,
    video character varying(200),
    status_ public.record_status,
    player integer,
    demon integer
)
INHERITS (public.audit_log2);


ALTER TABLE public.record_modifications OWNER TO pointercrate;

--
-- Name: record_notes; Type: TABLE; Schema: public; Owner: pointercrate
--

CREATE TABLE public.record_notes (
    id integer NOT NULL,
    record integer NOT NULL,
    content text NOT NULL,
    is_public boolean DEFAULT false NOT NULL
);


ALTER TABLE public.record_notes OWNER TO pointercrate;

--
-- Name: record_notes_additions; Type: TABLE; Schema: public; Owner: pointercrate
--

CREATE TABLE public.record_notes_additions (
    id integer NOT NULL
)
INHERITS (public.audit_log2);


ALTER TABLE public.record_notes_additions OWNER TO pointercrate;

--
-- Name: record_notes_deletions; Type: TABLE; Schema: public; Owner: pointercrate
--

CREATE TABLE public.record_notes_deletions (
    id integer NOT NULL
)
INHERITS (public.audit_log2);


ALTER TABLE public.record_notes_deletions OWNER TO pointercrate;

--
-- Name: record_notes_id_seq; Type: SEQUENCE; Schema: public; Owner: pointercrate
--

CREATE SEQUENCE public.record_notes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.record_notes_id_seq OWNER TO pointercrate;

--
-- Name: record_notes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: pointercrate
--

ALTER SEQUENCE public.record_notes_id_seq OWNED BY public.record_notes.id;


--
-- Name: record_notes_modifications; Type: TABLE; Schema: public; Owner: pointercrate
--

CREATE TABLE public.record_notes_modifications (
    id integer NOT NULL,
    record integer,
    content text
)
INHERITS (public.audit_log2);


ALTER TABLE public.record_notes_modifications OWNER TO pointercrate;

--
-- Name: records_id_seq; Type: SEQUENCE; Schema: public; Owner: pointercrate
--

CREATE SEQUENCE public.records_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.records_id_seq OWNER TO pointercrate;

--
-- Name: records_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: pointercrate
--

ALTER SEQUENCE public.records_id_seq OWNED BY public.records.id;


--
-- Name: subdivisions; Type: TABLE; Schema: public; Owner: pointercrate
--

CREATE TABLE public.subdivisions (
    iso_code character varying(3) NOT NULL,
    name public.citext NOT NULL,
    nation character varying(2) NOT NULL
);


ALTER TABLE public.subdivisions OWNER TO pointercrate;

--
-- Name: submitter_modifications; Type: TABLE; Schema: public; Owner: pointercrate
--

CREATE TABLE public.submitter_modifications (
    submitter integer NOT NULL,
    banned boolean
)
INHERITS (public.audit_log2);


ALTER TABLE public.submitter_modifications OWNER TO pointercrate;

--
-- Name: submitters; Type: TABLE; Schema: public; Owner: pointercrate
--

CREATE TABLE public.submitters (
    submitter_id integer NOT NULL,
    ip_address inet NOT NULL,
    banned boolean DEFAULT false NOT NULL
);


ALTER TABLE public.submitters OWNER TO pointercrate;

--
-- Name: submitters_submitter_id_seq; Type: SEQUENCE; Schema: public; Owner: pointercrate
--

CREATE SEQUENCE public.submitters_submitter_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.submitters_submitter_id_seq OWNER TO pointercrate;

--
-- Name: submitters_submitter_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: pointercrate
--

ALTER SEQUENCE public.submitters_submitter_id_seq OWNED BY public.submitters.submitter_id;


--
-- Name: user_additions; Type: TABLE; Schema: public; Owner: pointercrate
--

CREATE TABLE public.user_additions (
    id integer NOT NULL
)
INHERITS (public.audit_log2);


ALTER TABLE public.user_additions OWNER TO pointercrate;

--
-- Name: user_deletions; Type: TABLE; Schema: public; Owner: pointercrate
--

CREATE TABLE public.user_deletions (
    id integer NOT NULL
)
INHERITS (public.audit_log2);


ALTER TABLE public.user_deletions OWNER TO pointercrate;

--
-- Name: user_modifications; Type: TABLE; Schema: public; Owner: pointercrate
--

CREATE TABLE public.user_modifications (
    id integer NOT NULL,
    display_name public.citext,
    youtube_channel public.citext,
    permissions bit(16)
)
INHERITS (public.audit_log2);


ALTER TABLE public.user_modifications OWNER TO pointercrate;

--
-- Name: audit_log2 audit_id; Type: DEFAULT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.audit_log2 ALTER COLUMN audit_id SET DEFAULT nextval('public.audit_log2_audit_id_seq'::regclass);


--
-- Name: creator_additions time; Type: DEFAULT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.creator_additions ALTER COLUMN "time" SET DEFAULT (now() AT TIME ZONE 'utc'::text);


--
-- Name: creator_additions audit_id; Type: DEFAULT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.creator_additions ALTER COLUMN audit_id SET DEFAULT nextval('public.audit_log2_audit_id_seq'::regclass);


--
-- Name: creator_deletions time; Type: DEFAULT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.creator_deletions ALTER COLUMN "time" SET DEFAULT (now() AT TIME ZONE 'utc'::text);


--
-- Name: creator_deletions audit_id; Type: DEFAULT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.creator_deletions ALTER COLUMN audit_id SET DEFAULT nextval('public.audit_log2_audit_id_seq'::regclass);


--
-- Name: demon_additions time; Type: DEFAULT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.demon_additions ALTER COLUMN "time" SET DEFAULT (now() AT TIME ZONE 'utc'::text);


--
-- Name: demon_additions audit_id; Type: DEFAULT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.demon_additions ALTER COLUMN audit_id SET DEFAULT nextval('public.audit_log2_audit_id_seq'::regclass);


--
-- Name: demon_modifications time; Type: DEFAULT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.demon_modifications ALTER COLUMN "time" SET DEFAULT (now() AT TIME ZONE 'utc'::text);


--
-- Name: demon_modifications audit_id; Type: DEFAULT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.demon_modifications ALTER COLUMN audit_id SET DEFAULT nextval('public.audit_log2_audit_id_seq'::regclass);


--
-- Name: demons id; Type: DEFAULT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.demons ALTER COLUMN id SET DEFAULT nextval('public.demons_id_seq'::regclass);


--
-- Name: level_comment_additions time; Type: DEFAULT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.level_comment_additions ALTER COLUMN "time" SET DEFAULT (now() AT TIME ZONE 'utc'::text);


--
-- Name: level_comment_additions audit_id; Type: DEFAULT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.level_comment_additions ALTER COLUMN audit_id SET DEFAULT nextval('public.audit_log2_audit_id_seq'::regclass);


--
-- Name: level_comment_deletions time; Type: DEFAULT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.level_comment_deletions ALTER COLUMN "time" SET DEFAULT (now() AT TIME ZONE 'utc'::text);


--
-- Name: level_comment_deletions audit_id; Type: DEFAULT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.level_comment_deletions ALTER COLUMN audit_id SET DEFAULT nextval('public.audit_log2_audit_id_seq'::regclass);


--
-- Name: level_comment_modifications time; Type: DEFAULT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.level_comment_modifications ALTER COLUMN "time" SET DEFAULT (now() AT TIME ZONE 'utc'::text);


--
-- Name: level_comment_modifications audit_id; Type: DEFAULT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.level_comment_modifications ALTER COLUMN audit_id SET DEFAULT nextval('public.audit_log2_audit_id_seq'::regclass);


--
-- Name: level_comments id; Type: DEFAULT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.level_comments ALTER COLUMN id SET DEFAULT nextval('public.level_comments_id_seq'::regclass);


--
-- Name: members member_id; Type: DEFAULT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.members ALTER COLUMN member_id SET DEFAULT nextval('public.members_member_id_seq'::regclass);


--
-- Name: player_additions time; Type: DEFAULT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.player_additions ALTER COLUMN "time" SET DEFAULT (now() AT TIME ZONE 'utc'::text);


--
-- Name: player_additions audit_id; Type: DEFAULT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.player_additions ALTER COLUMN audit_id SET DEFAULT nextval('public.audit_log2_audit_id_seq'::regclass);


--
-- Name: player_claims id; Type: DEFAULT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.player_claims ALTER COLUMN id SET DEFAULT nextval('public.player_claims_id_seq'::regclass);


--
-- Name: player_deletions time; Type: DEFAULT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.player_deletions ALTER COLUMN "time" SET DEFAULT (now() AT TIME ZONE 'utc'::text);


--
-- Name: player_deletions audit_id; Type: DEFAULT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.player_deletions ALTER COLUMN audit_id SET DEFAULT nextval('public.audit_log2_audit_id_seq'::regclass);


--
-- Name: player_modifications time; Type: DEFAULT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.player_modifications ALTER COLUMN "time" SET DEFAULT (now() AT TIME ZONE 'utc'::text);


--
-- Name: player_modifications audit_id; Type: DEFAULT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.player_modifications ALTER COLUMN audit_id SET DEFAULT nextval('public.audit_log2_audit_id_seq'::regclass);


--
-- Name: players id; Type: DEFAULT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.players ALTER COLUMN id SET DEFAULT nextval('public.players_id_seq'::regclass);


--
-- Name: record_additions time; Type: DEFAULT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.record_additions ALTER COLUMN "time" SET DEFAULT (now() AT TIME ZONE 'utc'::text);


--
-- Name: record_additions audit_id; Type: DEFAULT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.record_additions ALTER COLUMN audit_id SET DEFAULT nextval('public.audit_log2_audit_id_seq'::regclass);


--
-- Name: record_deletions time; Type: DEFAULT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.record_deletions ALTER COLUMN "time" SET DEFAULT (now() AT TIME ZONE 'utc'::text);


--
-- Name: record_deletions audit_id; Type: DEFAULT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.record_deletions ALTER COLUMN audit_id SET DEFAULT nextval('public.audit_log2_audit_id_seq'::regclass);


--
-- Name: record_modifications time; Type: DEFAULT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.record_modifications ALTER COLUMN "time" SET DEFAULT (now() AT TIME ZONE 'utc'::text);


--
-- Name: record_modifications audit_id; Type: DEFAULT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.record_modifications ALTER COLUMN audit_id SET DEFAULT nextval('public.audit_log2_audit_id_seq'::regclass);


--
-- Name: record_notes id; Type: DEFAULT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.record_notes ALTER COLUMN id SET DEFAULT nextval('public.record_notes_id_seq'::regclass);


--
-- Name: record_notes_additions time; Type: DEFAULT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.record_notes_additions ALTER COLUMN "time" SET DEFAULT (now() AT TIME ZONE 'utc'::text);


--
-- Name: record_notes_additions audit_id; Type: DEFAULT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.record_notes_additions ALTER COLUMN audit_id SET DEFAULT nextval('public.audit_log2_audit_id_seq'::regclass);


--
-- Name: record_notes_deletions time; Type: DEFAULT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.record_notes_deletions ALTER COLUMN "time" SET DEFAULT (now() AT TIME ZONE 'utc'::text);


--
-- Name: record_notes_deletions audit_id; Type: DEFAULT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.record_notes_deletions ALTER COLUMN audit_id SET DEFAULT nextval('public.audit_log2_audit_id_seq'::regclass);


--
-- Name: record_notes_modifications time; Type: DEFAULT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.record_notes_modifications ALTER COLUMN "time" SET DEFAULT (now() AT TIME ZONE 'utc'::text);


--
-- Name: record_notes_modifications audit_id; Type: DEFAULT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.record_notes_modifications ALTER COLUMN audit_id SET DEFAULT nextval('public.audit_log2_audit_id_seq'::regclass);


--
-- Name: records id; Type: DEFAULT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.records ALTER COLUMN id SET DEFAULT nextval('public.records_id_seq'::regclass);


--
-- Name: submitter_modifications time; Type: DEFAULT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.submitter_modifications ALTER COLUMN "time" SET DEFAULT (now() AT TIME ZONE 'utc'::text);


--
-- Name: submitter_modifications audit_id; Type: DEFAULT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.submitter_modifications ALTER COLUMN audit_id SET DEFAULT nextval('public.audit_log2_audit_id_seq'::regclass);


--
-- Name: submitters submitter_id; Type: DEFAULT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.submitters ALTER COLUMN submitter_id SET DEFAULT nextval('public.submitters_submitter_id_seq'::regclass);


--
-- Name: user_additions time; Type: DEFAULT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.user_additions ALTER COLUMN "time" SET DEFAULT (now() AT TIME ZONE 'utc'::text);


--
-- Name: user_additions audit_id; Type: DEFAULT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.user_additions ALTER COLUMN audit_id SET DEFAULT nextval('public.audit_log2_audit_id_seq'::regclass);


--
-- Name: user_deletions time; Type: DEFAULT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.user_deletions ALTER COLUMN "time" SET DEFAULT (now() AT TIME ZONE 'utc'::text);


--
-- Name: user_deletions audit_id; Type: DEFAULT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.user_deletions ALTER COLUMN audit_id SET DEFAULT nextval('public.audit_log2_audit_id_seq'::regclass);


--
-- Name: user_modifications time; Type: DEFAULT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.user_modifications ALTER COLUMN "time" SET DEFAULT (now() AT TIME ZONE 'utc'::text);


--
-- Name: user_modifications audit_id; Type: DEFAULT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.user_modifications ALTER COLUMN audit_id SET DEFAULT nextval('public.audit_log2_audit_id_seq'::regclass);


--
-- Name: __diesel_schema_migrations __diesel_schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.__diesel_schema_migrations
    ADD CONSTRAINT __diesel_schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: active_user active_user_pkey; Type: CONSTRAINT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.active_user
    ADD CONSTRAINT active_user_pkey PRIMARY KEY (id);


--
-- Name: audit_log2 audit_log2_pkey; Type: CONSTRAINT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.audit_log2
    ADD CONSTRAINT audit_log2_pkey PRIMARY KEY (audit_id);


--
-- Name: creators creators_pkey; Type: CONSTRAINT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.creators
    ADD CONSTRAINT creators_pkey PRIMARY KEY (demon, creator);


--
-- Name: demons demons_level_id_key; Type: CONSTRAINT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.demons
    ADD CONSTRAINT demons_level_id_key UNIQUE (level_id);


--
-- Name: demons demons_pkey; Type: CONSTRAINT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.demons
    ADD CONSTRAINT demons_pkey PRIMARY KEY (id);


--
-- Name: gj_creator_meta gj_creator_meta_pkey; Type: CONSTRAINT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.gj_creator_meta
    ADD CONSTRAINT gj_creator_meta_pkey PRIMARY KEY (user_id);


--
-- Name: gj_creator gj_creator_pkey; Type: CONSTRAINT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.gj_creator
    ADD CONSTRAINT gj_creator_pkey PRIMARY KEY (user_id);


--
-- Name: gj_level_data_meta gj_level_data_meta_pkey; Type: CONSTRAINT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.gj_level_data_meta
    ADD CONSTRAINT gj_level_data_meta_pkey PRIMARY KEY (level_id);


--
-- Name: gj_level_data gj_level_data_pkey; Type: CONSTRAINT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.gj_level_data
    ADD CONSTRAINT gj_level_data_pkey PRIMARY KEY (level_id);


--
-- Name: gj_level_meta gj_level_meta_pkey; Type: CONSTRAINT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.gj_level_meta
    ADD CONSTRAINT gj_level_meta_pkey PRIMARY KEY (level_id);


--
-- Name: gj_level gj_level_pkey; Type: CONSTRAINT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.gj_level
    ADD CONSTRAINT gj_level_pkey PRIMARY KEY (level_id);


--
-- Name: gj_level_request_meta gj_level_request_meta_pkey; Type: CONSTRAINT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.gj_level_request_meta
    ADD CONSTRAINT gj_level_request_meta_pkey PRIMARY KEY (request_hash);


--
-- Name: gj_newgrounds_song_meta gj_newgrounds_song_meta_pkey; Type: CONSTRAINT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.gj_newgrounds_song_meta
    ADD CONSTRAINT gj_newgrounds_song_meta_pkey PRIMARY KEY (song_id);


--
-- Name: gj_newgrounds_song gj_newgrounds_song_pkey; Type: CONSTRAINT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.gj_newgrounds_song
    ADD CONSTRAINT gj_newgrounds_song_pkey PRIMARY KEY (song_id);


--
-- Name: level_comments level_comments_pkey; Type: CONSTRAINT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.level_comments
    ADD CONSTRAINT level_comments_pkey PRIMARY KEY (id);


--
-- Name: members members_name_key; Type: CONSTRAINT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.members
    ADD CONSTRAINT members_name_key UNIQUE (name);


--
-- Name: members members_pkey; Type: CONSTRAINT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.members
    ADD CONSTRAINT members_pkey PRIMARY KEY (member_id);


--
-- Name: nationalities nationalities_nation_key; Type: CONSTRAINT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.nationalities
    ADD CONSTRAINT nationalities_nation_key UNIQUE (nation);


--
-- Name: nationalities nationalities_pkey; Type: CONSTRAINT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.nationalities
    ADD CONSTRAINT nationalities_pkey PRIMARY KEY (iso_country_code);


--
-- Name: player_claims player_claims_pkey; Type: CONSTRAINT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.player_claims
    ADD CONSTRAINT player_claims_pkey PRIMARY KEY (id);


--
-- Name: players players_name_key; Type: CONSTRAINT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.players
    ADD CONSTRAINT players_name_key UNIQUE (name);


--
-- Name: players players_pkey; Type: CONSTRAINT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.players
    ADD CONSTRAINT players_pkey PRIMARY KEY (id);


--
-- Name: record_notes record_notes_pkey; Type: CONSTRAINT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.record_notes
    ADD CONSTRAINT record_notes_pkey PRIMARY KEY (id);


--
-- Name: records records_pkey; Type: CONSTRAINT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.records
    ADD CONSTRAINT records_pkey PRIMARY KEY (id);


--
-- Name: records records_video_key; Type: CONSTRAINT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.records
    ADD CONSTRAINT records_video_key UNIQUE (video);


--
-- Name: subdivisions subdivisions_name_key; Type: CONSTRAINT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.subdivisions
    ADD CONSTRAINT subdivisions_name_key UNIQUE (name);


--
-- Name: subdivisions subdivisions_pkey; Type: CONSTRAINT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.subdivisions
    ADD CONSTRAINT subdivisions_pkey PRIMARY KEY (iso_code, nation);


--
-- Name: submitters submitters_pkey; Type: CONSTRAINT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.submitters
    ADD CONSTRAINT submitters_pkey PRIMARY KEY (submitter_id);


--
-- Name: demons unique_position; Type: CONSTRAINT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.demons
    ADD CONSTRAINT unique_position UNIQUE ("position") DEFERRABLE;


--
-- Name: creators creator_addition_trigger; Type: TRIGGER; Schema: public; Owner: pointercrate
--

CREATE TRIGGER creator_addition_trigger AFTER INSERT ON public.creators FOR EACH ROW EXECUTE FUNCTION public.audit_creator_addition();


--
-- Name: creators creator_deletion_trigger; Type: TRIGGER; Schema: public; Owner: pointercrate
--

CREATE TRIGGER creator_deletion_trigger AFTER DELETE ON public.creators FOR EACH ROW EXECUTE FUNCTION public.audit_creator_deletion();


--
-- Name: demons demon_addition_trigger; Type: TRIGGER; Schema: public; Owner: pointercrate
--

CREATE TRIGGER demon_addition_trigger AFTER INSERT ON public.demons FOR EACH ROW EXECUTE FUNCTION public.audit_demon_addition();


--
-- Name: demons demon_modification_trigger; Type: TRIGGER; Schema: public; Owner: pointercrate
--

CREATE TRIGGER demon_modification_trigger AFTER UPDATE ON public.demons FOR EACH ROW EXECUTE FUNCTION public.audit_demon_modification();


--
-- Name: demons demons_insert_set_thumbnail; Type: TRIGGER; Schema: public; Owner: pointercrate
--

CREATE TRIGGER demons_insert_set_thumbnail BEFORE INSERT OR UPDATE ON public.demons FOR EACH ROW EXECUTE FUNCTION public.set_initial_thumbnail();


--
-- Name: level_comments level_comment_addition_trigger; Type: TRIGGER; Schema: public; Owner: pointercrate
--

CREATE TRIGGER level_comment_addition_trigger AFTER INSERT ON public.level_comments FOR EACH ROW EXECUTE FUNCTION public.audit_level_comment_addition();


--
-- Name: level_comments level_comment_deletion_trigger; Type: TRIGGER; Schema: public; Owner: pointercrate
--

CREATE TRIGGER level_comment_deletion_trigger AFTER DELETE ON public.level_comments FOR EACH ROW EXECUTE FUNCTION public.audit_level_comment_deletion();


--
-- Name: level_comments level_comment_modification_trigger; Type: TRIGGER; Schema: public; Owner: pointercrate
--

CREATE TRIGGER level_comment_modification_trigger AFTER UPDATE ON public.level_comments FOR EACH ROW EXECUTE FUNCTION public.audit_level_comment_modification();


--
-- Name: players player_addition_trigger; Type: TRIGGER; Schema: public; Owner: pointercrate
--

CREATE TRIGGER player_addition_trigger AFTER INSERT ON public.players FOR EACH ROW EXECUTE FUNCTION public.audit_player_addition();


--
-- Name: players player_deletion_trigger; Type: TRIGGER; Schema: public; Owner: pointercrate
--

CREATE TRIGGER player_deletion_trigger AFTER DELETE ON public.players FOR EACH ROW EXECUTE FUNCTION public.audit_player_deletion();


--
-- Name: players player_modification_trigger; Type: TRIGGER; Schema: public; Owner: pointercrate
--

CREATE TRIGGER player_modification_trigger AFTER UPDATE ON public.players FOR EACH ROW EXECUTE FUNCTION public.audit_player_modification();


--
-- Name: records record_addition_trigger; Type: TRIGGER; Schema: public; Owner: pointercrate
--

CREATE TRIGGER record_addition_trigger AFTER INSERT ON public.records FOR EACH ROW EXECUTE FUNCTION public.audit_record_addition();


--
-- Name: records record_deletion_trigger; Type: TRIGGER; Schema: public; Owner: pointercrate
--

CREATE TRIGGER record_deletion_trigger AFTER DELETE ON public.records FOR EACH ROW EXECUTE FUNCTION public.audit_record_deletion();


--
-- Name: records record_modification_trigger; Type: TRIGGER; Schema: public; Owner: pointercrate
--

CREATE TRIGGER record_modification_trigger AFTER UPDATE ON public.records FOR EACH ROW EXECUTE FUNCTION public.audit_record_modification();


--
-- Name: record_notes record_note_addition_trigger; Type: TRIGGER; Schema: public; Owner: pointercrate
--

CREATE TRIGGER record_note_addition_trigger AFTER INSERT ON public.record_notes FOR EACH ROW EXECUTE FUNCTION public.audit_record_notes_addition();


--
-- Name: record_notes record_note_deletion_trigger; Type: TRIGGER; Schema: public; Owner: pointercrate
--

CREATE TRIGGER record_note_deletion_trigger AFTER DELETE ON public.record_notes FOR EACH ROW EXECUTE FUNCTION public.audit_record_notes_modification();


--
-- Name: record_notes record_note_modification_trigger; Type: TRIGGER; Schema: public; Owner: pointercrate
--

CREATE TRIGGER record_note_modification_trigger AFTER UPDATE ON public.record_notes FOR EACH ROW EXECUTE FUNCTION public.audit_record_notes_modification();


--
-- Name: submitters submitter_modification_trigger; Type: TRIGGER; Schema: public; Owner: pointercrate
--

CREATE TRIGGER submitter_modification_trigger AFTER UPDATE ON public.submitters FOR EACH ROW EXECUTE FUNCTION public.audit_submitter_modification();


--
-- Name: members user_addition_trigger; Type: TRIGGER; Schema: public; Owner: pointercrate
--

CREATE TRIGGER user_addition_trigger AFTER INSERT ON public.members FOR EACH ROW EXECUTE FUNCTION public.audit_user_addition();


--
-- Name: members user_deletion_trigger; Type: TRIGGER; Schema: public; Owner: pointercrate
--

CREATE TRIGGER user_deletion_trigger AFTER DELETE ON public.members FOR EACH ROW EXECUTE FUNCTION public.audit_user_deletion();


--
-- Name: members user_modification_trigger; Type: TRIGGER; Schema: public; Owner: pointercrate
--

CREATE TRIGGER user_modification_trigger AFTER UPDATE ON public.members FOR EACH ROW EXECUTE FUNCTION public.audit_user_modification();


--
-- Name: creators creators_creator_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.creators
    ADD CONSTRAINT creators_creator_fkey FOREIGN KEY (creator) REFERENCES public.players(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: creators creators_demon_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.creators
    ADD CONSTRAINT creators_demon_fkey FOREIGN KEY (demon) REFERENCES public.demons(id);


--
-- Name: demons demons_level_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.demons
    ADD CONSTRAINT demons_level_id_fkey FOREIGN KEY (level_id) REFERENCES public.gj_level(level_id);


--
-- Name: demons demons_publisher_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.demons
    ADD CONSTRAINT demons_publisher_fkey FOREIGN KEY (publisher) REFERENCES public.players(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: demons demons_verifier_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.demons
    ADD CONSTRAINT demons_verifier_fkey FOREIGN KEY (verifier) REFERENCES public.players(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: gj_level_data gj_level_data_level_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.gj_level_data
    ADD CONSTRAINT gj_level_data_level_id_fkey FOREIGN KEY (level_id) REFERENCES public.gj_level(level_id);


--
-- Name: level_comments level_comments_author_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.level_comments
    ADD CONSTRAINT level_comments_author_fkey FOREIGN KEY (author) REFERENCES public.members(member_id);


--
-- Name: members members_nationality_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.members
    ADD CONSTRAINT members_nationality_fkey FOREIGN KEY (nationality) REFERENCES public.nationalities(iso_country_code);


--
-- Name: player_claims player_claims_member_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.player_claims
    ADD CONSTRAINT player_claims_member_id_fkey FOREIGN KEY (member_id) REFERENCES public.members(member_id) ON DELETE CASCADE;


--
-- Name: player_claims player_claims_player_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.player_claims
    ADD CONSTRAINT player_claims_player_id_fkey FOREIGN KEY (player_id) REFERENCES public.players(id) ON DELETE RESTRICT;


--
-- Name: players players_nationality_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.players
    ADD CONSTRAINT players_nationality_fkey FOREIGN KEY (nationality) REFERENCES public.nationalities(iso_country_code);


--
-- Name: record_notes record_notes_record_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.record_notes
    ADD CONSTRAINT record_notes_record_fkey FOREIGN KEY (record) REFERENCES public.records(id) ON DELETE CASCADE;


--
-- Name: records records_demon_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.records
    ADD CONSTRAINT records_demon_fkey FOREIGN KEY (demon) REFERENCES public.demons(id);


--
-- Name: records records_player_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.records
    ADD CONSTRAINT records_player_fkey FOREIGN KEY (player) REFERENCES public.players(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: records records_submitter_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.records
    ADD CONSTRAINT records_submitter_fkey FOREIGN KEY (submitter) REFERENCES public.submitters(submitter_id) ON DELETE RESTRICT;


--
-- Name: subdivisions subdivisions_nation_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pointercrate
--

ALTER TABLE ONLY public.subdivisions
    ADD CONSTRAINT subdivisions_nation_fkey FOREIGN KEY (nation) REFERENCES public.nationalities(iso_country_code);


--
-- PostgreSQL database dump complete
--

